/**
 * BIAssistantController
 * ---------------------
 * Orchestrates the two-pass LLM pipeline with MULTI-TURN conversation:
 *
 *   Pass 1  NL → (schema + conversation history) → LLM → JSON → validate → run
 *   Pass 2  question + results → LLM → HTML analysis for display
 *
 * The LWC maintains the full conversation history client-side and sends it
 * as serialised JSON on every call.  Apex prepends the system prompt, appends
 * the new user question, and forwards the whole list to the Models API
 * createChatGenerations endpoint — giving the LLM multi-turn context so
 * follow-up questions like "break that down by region" work correctly.
 *
 * Uses the Agentforce Models API (aiplatform namespace) so every call
 * goes through the Einstein Trust Layer.
 */
public with sharing class BIAssistantController {

    // ── Model configuration ─────────────────────────────────────────────
    private static final String DEFAULT_MODEL = 'sfdc_ai__DefaultGPT4Omni';
    private static final Integer MAX_HISTORY_MESSAGES = 30; // ~10 turns of context

    // Available models for the UI picker.
    // Add or remove entries to match your org's Einstein Studio configuration.
    private static final List<ModelOption> MODEL_OPTIONS = new List<ModelOption>{
        new ModelOption('sfdc_ai__DefaultGPT4Omni',                       'GPT-4o'),
        new ModelOption('sfdc_ai__DefaultOpenAIGPT4OmniMini',             'GPT-4o mini'),
        new ModelOption('sfdc_ai__DefaultBedrockAnthropicClaude35Sonnet',  'Claude 3.5 Sonnet'),
        new ModelOption('sfdc_ai__DefaultBedrockAnthropicClaude3Sonnet',   'Claude 3 Sonnet'),
        new ModelOption('sfdc_ai__DefaultBedrockAnthropicClaude3Haiku',    'Claude 3 Haiku'),
        new ModelOption('sfdc_ai__DefaultGPT4',                           'GPT-4'),
        new ModelOption('sfdc_ai__DefaultGPT35Turbo',                     'GPT-3.5 Turbo')
    };

    // ── Return wrappers ─────────────────────────────────────────────────
    public class ModelOption {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        public ModelOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    public class BIResult {
        @AuraEnabled public String  analysisHtml;          // Pass 2 HTML output
        @AuraEnabled public String  errorMessage;
        @AuraEnabled public List<QueryExecution> queries;  // Pass 1 execution details
        @AuraEnabled public List<BIChatMessage> updatedHistory; // history to store in LWC
    }

    public class QueryExecution {
        @AuraEnabled public String  soql;
        @AuraEnabled public String  label;
        @AuraEnabled public Integer recordCount;
        @AuraEnabled public List<Map<String, Object>> rows;
    }

    // ── Model list (called from LWC on load) ─────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<ModelOption> getAvailableModels() {
        return MODEL_OPTIONS;
    }

    // ── Main entry point (called from LWC) ──────────────────────────────
    /**
     * @param question              The user's new natural-language question
     * @param conversationHistoryJson  JSON-serialised List<BIChatMessage> from prior turns
     * @param modelName             API name of the model to use (null = default)
     */
    @AuraEnabled
    public static BIResult askQuestion(String question, String conversationHistoryJson, String modelName) {
        BIResult result = new BIResult();

        try {
            // ── Rebuild conversation history ────────────────────────────
            List<BIChatMessage> history = deserializeHistory(conversationHistoryJson);

            // ═══════════════════════════════════════════════════════════
            //  PASS 1 : NL → SOQL via multi-turn chat → validate → run
            // ═══════════════════════════════════════════════════════════
            String schemaContext = BISchemaService.getSchemaContext();

            // Build the full message list for the Models API
            List<BIChatMessage> pass1Messages = new List<BIChatMessage>();

            // 1. System prompt with schema (always first)
            pass1Messages.add(new BIChatMessage('system', pass1SystemPrompt(schemaContext)));

            // 2. Prior conversation turns (user questions + assistant SOQL + result context)
            pass1Messages.addAll(history);

            // 3. Current user question
            pass1Messages.add(new BIChatMessage('user', question));

            // Resolve model name (use provided or default)
            String resolvedModel = String.isNotBlank(modelName) ? modelName : DEFAULT_MODEL;

            // 4. Call the LLM
            String llmJson = callChatLLM(pass1Messages, resolvedModel);

            // 5. Parse + validate + execute
            List<QueryExecution> executions = parseAndExecuteQueries(llmJson);
            result.queries = executions;

            // ═══════════════════════════════════════════════════════════
            //  PASS 2 : Results → HTML analysis (single-turn, no history needed)
            // ═══════════════════════════════════════════════════════════
            String pass2User = buildPass2UserPrompt(question, executions);

            List<BIChatMessage> pass2Messages = new List<BIChatMessage>();
            pass2Messages.add(new BIChatMessage('system', pass2SystemPrompt()));
            pass2Messages.add(new BIChatMessage('user', pass2User));

            String analysisHtml = callChatLLM(pass2Messages, resolvedModel);
            analysisHtml = stripCodeFences(analysisHtml);
            result.analysisHtml = analysisHtml;

            // ═══════════════════════════════════════════════════════════
            //  Update conversation history for next turn
            // ═══════════════════════════════════════════════════════════
            // Append this turn so the LWC can send it back next time:
            //   user: the question
            //   assistant: the SOQL JSON the LLM produced
            //   user: a compact summary of the results (so the LLM knows
            //         what data it has to work with on follow-ups)
            history.add(new BIChatMessage('user', question));
            history.add(new BIChatMessage('assistant', llmJson));
            history.add(new BIChatMessage('user',
                'Query results for context:\n' + buildResultsSummary(executions)));

            // Trim oldest turns to stay within token/heap budget
            while (history.size() > MAX_HISTORY_MESSAGES) {
                history.remove(0);
            }

            result.updatedHistory = history;

        } catch (AuraHandledException ahe) {
            result.errorMessage = ahe.getMessage();
        } catch (Exception ex) {
            result.errorMessage = ex.getMessage();
        }

        return result;
    }

    // ════════════════════════════════════════════════════════════════════
    //  PROMPTS
    // ════════════════════════════════════════════════════════════════════

    private static String pass1SystemPrompt(String schema) {
        return 'You are an expert Salesforce SOQL query generator.\n'
             + 'You receive a natural-language business question and a schema description.\n'
             + 'Return ONLY a valid JSON array of query objects.\n'
             + 'Each object must have:\n'
             + '  "label" (string – short description of what the query answers)\n'
             + '  "soql"  (string – a valid read-only SOQL SELECT query)\n\n'
             + 'Rules:\n'
             + '- Only SELECT statements. Never DML.\n'
             + '- Always include LIMIT (max 200).\n'
             + '- Use only objects and fields from the schema below.\n'
             + '- Always include the Id field in your SELECT clause, UNLESS the query uses GROUP BY '
             + '(aggregate queries cannot include Id unless it is grouped). For aggregate queries, '
             + 'include the grouping field(s) but not Id.\n'
             + '- When querying individual records (non-aggregate), also include parent Id fields '
             + '(e.g. AccountId on Opportunity) so the UI can link to parent records.\n'
             + '- You may return 1-3 queries if the question needs multiple data angles.\n'
             + '- For follow-up questions, use the conversation history to understand context.\n'
             + '- Return ONLY the JSON array — no markdown, no commentary.\n\n'
             + 'SCHEMA:\n' + schema;
    }

    private static String pass2SystemPrompt() {
        return 'You are a business analyst. Given a question and CRM query results, '
             + 'produce a clear, visually appealing analysis WITH data visualizations.\n\n'
             + 'OUTPUT FORMAT:\n'
             + 'Your response MUST have exactly two sections separated by the delimiter ===VISUALIZATIONS===\n\n'
             + 'Section 1: HTML analysis (everything BEFORE the delimiter)\n'
             + 'Section 2: JSON array of chart configurations (everything AFTER the delimiter)\n\n'
             + 'Example output:\n'
             + '<h3>Pipeline Summary</h3>\n'
             + '<p>You have <strong>47</strong> open opportunities...</p>\n'
             + '===VISUALIZATIONS===\n'
             + '[{"type":"bar","title":"Open Opportunities by Stage","data":{"labels":["Prospecting","Qualification"],"datasets":[{"label":"Count","data":[12,8],"backgroundColor":["#0176d3","#1b96ff"]}]}}]\n\n'
             + 'If there are no charts to show, still include the delimiter with an empty array:\n'
             + '<p>Your analysis...</p>\n'
             + '===VISUALIZATIONS===\n'
             + '[]\n\n'
             + 'ANALYSIS HTML RULES:\n'
             + '- Write for a non-technical business user.\n'
             + '- NEVER expose raw SOQL queries or API field names in the output.\n'
             + '- When displaying record names (Opportunity Name, Account Name, Case Subject, Contact Name, Lead Name, etc.), '
             + 'make them clickable links to the Salesforce record using the Id from the query results. '
             + 'Format: <a href="/{recordId}">{Record Name}</a>. '
             + 'Do this in tables, lists, and inline mentions. If no Id is available for a record, show it as plain text.\n'
             + '- Use semantic HTML: headings, tables, lists, emphasis.\n'
             + '- Do NOT apply background-color to table headers or table rows via inline CSS — '
             + 'the UI stylesheet handles table styling. Use inline color only for emphasis text, '
             + 'status badges, and KPI values (green #2e844a for positive, red #ba0517 for negative, '
             + 'orange #fe9339 for warning, gray #706e6b for neutral).\n'
             + '- Use a clean white background, subtle borders, and good spacing.\n'
             + '- If data has counts/amounts, show percentages or comparisons.\n'
             + '- If no results, say so helpfully and suggest alternatives.\n\n'
             + 'VISUALIZATION RULES:\n'
             + 'You MUST include at least one visualization whenever the data supports it.\n'
             + 'Choose the chart type based on the data shape:\n\n'
             + '- BAR chart ("type": "bar"): Use when comparing discrete categories.\n'
             + '  Examples: opportunities by stage, cases by priority, deals by rep.\n'
             + '  Use horizontal bar ("indexAxis": "y" in options) when category labels are long.\n\n'
             + '- LINE chart ("type": "line"): Use when showing trends over time.\n'
             + '  Examples: cases opened per month, revenue over quarters, activity trends.\n'
             + '  Always sort data chronologically on the x-axis.\n\n'
             + '- DOUGHNUT chart ("type": "doughnut"): Use when showing composition / parts of a whole.\n'
             + '  Examples: lead sources as %, case origins, win/loss ratio.\n'
             + '  Best with 2-7 segments. If more than 7, group smallest into "Other".\n\n'
             + '- PIE chart ("type": "pie"): Use sparingly - only for 2-4 categories where '
             + 'relative proportion is the key insight. Prefer doughnut in most cases.\n\n'
             + '- STACKED BAR ("type": "bar" with "stacked": true in scale options): Use when comparing '
             + 'categories AND showing sub-breakdowns within each.\n\n'
             + '- METRIC / KPI (no chart - use HTML): For single numbers, percentages, or '
             + 'comparisons (e.g., "45 open cases, up 12%"), use styled HTML with large numbers, not a chart.\n\n'
             + 'VISUALIZATION OBJECT FORMAT:\n'
             + 'Each object in the JSON array must have:\n'
             + '  "type": chart type string (bar, line, doughnut, pie)\n'
             + '  "title": plain English chart title\n'
             + '  "data": { "labels": [...], "datasets": [{ "label": "...", "data": [...], "backgroundColor": [...] }] }\n\n'
             + 'COLOR PALETTE (use these Salesforce Lightning Design System colors):\n'
             + '  Primary: #0176d3 (blue)\n'
             + '  Accent:  #3A49DA (indigo)\n'
             + '  Success: #2e844a (green)\n'
             + '  Warning: #fe9339 (orange)\n'
             + '  Error:   #ba0517 (red)\n'
             + '  Neutral: #706e6b (gray)\n'
             + '  Extended: #1b96ff, #57a3fd, #8dc0fb, #b8d8f9, #032d60\n\n'
             + 'GUIDELINES:\n'
             + '- For multi-dataset charts, use contrasting colors from the palette.\n'
             + '- Limit to 1-3 visualizations per response. More than 3 is overwhelming.\n'
             + '- Chart title should be plain English, not a field name.\n'
             + '- Data labels should be human-readable (e.g., "Closed Won" not "ClosedWon").\n'
             + '- For currency values, provide raw numbers (the UI will format them).\n'
             + '- Round percentages to 1 decimal place.\n'
             + '- If the query returned 0 or 1 records, skip the chart and use text only.\n\n'
             + 'IMPORTANT: Return ONLY the HTML followed by ===VISUALIZATIONS=== followed by the JSON array.\n'
             + 'No markdown fences, no commentary, no wrapping.';
    }

    private static String buildPass2UserPrompt(String question, List<QueryExecution> execs) {
        String prompt = 'QUESTION:\n' + question + '\n\nRESULTS:\n';
        for (QueryExecution qe : execs) {
            prompt += '\n--- ' + qe.label + ' (' + qe.recordCount + ' records) ---\n';
            if (qe.rows != null && !qe.rows.isEmpty()) {
                // Truncate at row boundaries to keep valid JSON
                Integer maxRows = Math.min(qe.rows.size(), 50);
                String serialized = JSON.serializePretty(qe.rows);
                if (serialized.length() > 8000) {
                    while (maxRows > 1) {
                        List<Map<String, Object>> truncated = new List<Map<String, Object>>();
                        for (Integer i = 0; i < maxRows; i++) {
                            truncated.add(qe.rows[i]);
                        }
                        serialized = JSON.serializePretty(truncated);
                        if (serialized.length() <= 8000) break;
                        maxRows = maxRows / 2;
                    }
                    serialized += '\n... (' + qe.recordCount + ' total records, showing ' + maxRows + ')';
                }
                prompt += serialized + '\n';
            } else {
                prompt += '(no records)\n';
            }
        }
        return prompt;
    }

    // ════════════════════════════════════════════════════════════════════
    //  LLM CALL  –  Multi-turn via Models API createChatGenerations
    // ════════════════════════════════════════════════════════════════════

    private static String callChatLLM(List<BIChatMessage> chatMessages, String modelName) {
        aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();

        // Convert our BIChatMessage list into the Models API request format
        List<aiplatform.ModelsAPI_ChatMessageRequest> apiMessages =
            new List<aiplatform.ModelsAPI_ChatMessageRequest>();

        for (BIChatMessage msg : chatMessages) {
            aiplatform.ModelsAPI_ChatMessageRequest apiMsg =
                new aiplatform.ModelsAPI_ChatMessageRequest();
            apiMsg.role    = msg.role;
            apiMsg.content = msg.content;
            apiMessages.add(apiMsg);
        }

        // Build request body
        aiplatform.ModelsAPI_ChatGenerationsRequest body =
            new aiplatform.ModelsAPI_ChatGenerationsRequest();
        body.messages = apiMessages;

        // Build the request wrapper
        aiplatform.ModelsAPI.createChatGenerations_Request request =
            new aiplatform.ModelsAPI.createChatGenerations_Request();
        request.modelName = modelName;
        request.body      = body;

        // Execute with error handling for callout failures
        aiplatform.ModelsAPI.createChatGenerations_Response response;
        try {
            response = modelsAPI.createChatGenerations(request);
        } catch (Exception ex) {
            throw buildException(
                'Unable to reach the AI service. Please try again in a moment.'
            );
        }

        // Extract generated text
        if (response.Code200 != null
            && response.Code200.generationDetails != null
            && response.Code200.generationDetails.generations != null
            && !response.Code200.generationDetails.generations.isEmpty()) {
            return response.Code200.generationDetails.generations[0].content;
        }

        throw buildException(
            'The AI service returned an unexpected response. Please try again.'
        );
    }

    // ════════════════════════════════════════════════════════════════════
    //  PARSE & EXECUTE
    // ════════════════════════════════════════════════════════════════════

    private static List<QueryExecution> parseAndExecuteQueries(String llmJson) {
        List<QueryExecution> results = new List<QueryExecution>();

        llmJson = stripCodeFences(llmJson);

        List<Object> parsed;
        try {
            Object raw = JSON.deserializeUntyped(llmJson);
            if (raw instanceof List<Object>) {
                parsed = (List<Object>) raw;
            } else if (raw instanceof Map<String, Object>) {
                parsed = new List<Object>{ raw };
            } else {
                throw buildException(
                    'The AI returned an unexpected response format. Please try rephrasing your question.'
                );
            }
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            throw buildException(
                'The AI returned an invalid query format. Please try rephrasing your question.'
            );
        }

        for (Object item : parsed) {
            Map<String, Object> qMap = (Map<String, Object>) item;
            QueryExecution qe = new QueryExecution();
            qe.label = (String) qMap.get('label');
            qe.soql  = (String) qMap.get('soql');

            // Validate before executing
            BIQueryValidator.validate(qe.soql);

            // Auto-fix: remove standalone Id from aggregate queries
            qe.soql = sanitizeAggregateSoql(qe.soql);

            // Execute with friendly error handling
            try {
                List<SObject> records = Database.query(qe.soql);
                qe.recordCount = records.size();
                qe.rows = new List<Map<String, Object>>();

                for (SObject rec : records) {
                    qe.rows.add(rec.getPopulatedFieldsAsMap());
                }
            } catch (QueryException qex) {
                System.debug(LoggingLevel.ERROR,
                    'Query failed — SOQL: ' + qe.soql + ' | Error: ' + qex.getMessage());
                throw buildException(
                    'Query failed: ' + qe.label + '. The AI may have used an invalid field or relationship. '
                    + 'Please try rephrasing your question.'
                );
            }

            results.add(qe);
        }

        return results;
    }

    // ════════════════════════════════════════════════════════════════════
    //  UTILITIES
    // ════════════════════════════════════════════════════════════════════

    /**
     * Build a compact text summary of query results for the conversation
     * history — gives the LLM context for follow-ups without blowing up
     * the token budget.
     */
    private static String buildResultsSummary(List<QueryExecution> execs) {
        String summary = '';
        for (QueryExecution qe : execs) {
            summary += qe.label + ': ' + qe.recordCount + ' records';
            if (qe.rows != null && !qe.rows.isEmpty()) {
                // Include a compact version — first 5 rows, limited fields
                List<Map<String, Object>> subset = qe.rows;
                if (qe.rows.size() > 5) {
                    subset = new List<Map<String, Object>>();
                    for (Integer i = 0; i < 5; i++) {
                        subset.add(qe.rows[i]);
                    }
                }
                String data = JSON.serialize(subset);
                if (data.length() > 2000) {
                    data = data.substring(0, 2000) + '...';
                }
                summary += '\n' + data;
            }
            summary += '\n\n';
        }
        return summary;
    }

    private static List<BIChatMessage> deserializeHistory(String json) {
        if (String.isBlank(json) || json == '[]' || json == 'null') {
            return new List<BIChatMessage>();
        }
        try {
            return (List<BIChatMessage>) System.JSON.deserialize(
                json, List<BIChatMessage>.class
            );
        } catch (Exception ex) {
            return new List<BIChatMessage>();
        }
    }

    private static AuraHandledException buildException(String msg) {
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }

    /**
     * If the SOQL has GROUP BY, remove standalone "Id" from the SELECT clause.
     * LLMs sometimes include Id in aggregate queries, which causes:
     * "Field must be grouped or aggregated: Id"
     */
    @TestVisible
    private static String sanitizeAggregateSoql(String soql) {
        if (soql == null) return soql;
        String lower = soql.toLowerCase().trim();
        if (!lower.contains('group by')) return soql;

        // Locate the SELECT field list between SELECT and the first FROM
        Integer selectEnd = lower.indexOf('select ') + 7;
        Integer fromIdx = lower.indexOf(' from ');
        if (selectEnd < 7 || fromIdx < 0 || fromIdx <= selectEnd) return soql;

        String prefix = soql.substring(0, selectEnd);
        String fieldsPart = soql.substring(selectEnd, fromIdx);
        String suffix = soql.substring(fromIdx);

        // Split by comma, drop any token that is exactly "Id"
        List<String> fields = fieldsPart.split(',');
        List<String> cleaned = new List<String>();
        for (String f : fields) {
            if (f.trim().equalsIgnoreCase('Id')) continue;
            cleaned.add(f);
        }

        if (cleaned.isEmpty()) return soql; // safety: never remove all fields
        return prefix + String.join(cleaned, ',') + suffix;
    }

    private static String stripCodeFences(String text) {
        if (text == null) return '';
        text = text.trim();
        if (text.startsWith('```')) {
            Integer nl = text.indexOf('\n');
            if (nl > 0) text = text.substring(nl + 1);
        }
        if (text.endsWith('```')) {
            text = text.substring(0, text.length() - 3).trim();
        }
        return text;
    }
}
