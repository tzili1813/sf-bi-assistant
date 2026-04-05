# SF BI Assistant

Conversational AI component for Salesforce Lightning that lets users ask natural-language questions about CRM data. Uses the Agentforce Models API (`aiplatform` namespace) with a two-pass LLM pipeline and multi-turn conversation support.

## Architecture

See `README.md` for the full architecture diagram. In short:

- **Pass 1:** User question + schema + conversation history → Models API → JSON array of SOQL queries → validate → execute
- **Pass 2:** Question + query results → Models API → structured JSON with HTML analysis + Chart.js visualization configs
- **Context window:** Each turn appends 3 messages (question, SOQL, results summary) to history. Capped at 30 messages (~10 turns).

## Key Files

### Apex Classes (`force-app/main/default/classes/`)

| File | Purpose |
|------|---------|
| `BIChatMessage.cls` | DTO for conversation messages (`role`, `content`) |
| `BISchemaService.cls` | Dynamic org schema builder for LLM prompt injection |
| `BIQueryValidator.cls` | Security guardrails — validates all LLM-generated SOQL before execution |
| `BIAssistantController.cls` | Main orchestrator — two-pass pipeline, history management, Models API calls |
| `BIAssistantTest.cls` | Unit tests for validator, schema service, and message serialization |

### LWC — Parent (`force-app/main/default/lwc/biAssistant/`)

| File | Purpose |
|------|---------|
| `biAssistant.html` | Chat-style UI with message bubbles, chart rendering, loading states |
| `biAssistant.js` | State management, Apex calls, JSON parsing, HTML sanitization, conversation history |
| `biAssistant.css` | Bubble styles, table/list rendering for LLM output |
| `biAssistant.js-meta.xml` | Component metadata — exposed on App, Home, Record, and Tab pages |

### LWC — Child (`force-app/main/default/lwc/biChart/`)

| File | Purpose |
|------|---------|
| `biChart.html` | Canvas element with `lwc:dom="manual"` for Chart.js rendering |
| `biChart.js` | Loads Chart.js from static resource, renders charts with SLDS-styled defaults |
| `biChart.css` | Chart wrapper/container styling |
| `biChart.js-meta.xml` | Component metadata — `isExposed=false` (internal child only) |

### Static Resources (`force-app/main/default/staticresources/`)

| File | Purpose |
|------|---------|
| `ChartJs.resource` | Chart.js v4.4.7 UMD build |
| `ChartJs.resource-meta.xml` | Static resource metadata |

### Prompt Templates (`force-app/main/default/genAiPromptTemplates/`)

| File | Purpose |
|------|---------|
| `BI_Query_Generator.genAiPromptTemplate-meta.xml` | Pass 1 system prompt as deployable metadata |
| `BI_Analysis_Writer.genAiPromptTemplate-meta.xml` | Pass 2 system prompt as deployable metadata |

## Deployment

```bash
# Authenticate
sf org login web --alias dev-org

# Deploy
sf project deploy start --source-dir force-app --target-org dev-org

# Run tests
sf apex run test --class-names BIAssistantTest --target-org dev-org --wait 10
```

Then add the `biAssistant` component to a Lightning page via App Builder.

## Test Data

The `scripts/` directory contains Apex anonymous scripts that create a cohesive set of ~180 test records telling the story of a fictional B2B company called Pinnacle Solutions.

```bash
# Load test data (idempotent — part 1 deletes existing test data first)
sf apex run --file scripts/create-test-data.apex --target-org dev-org
sf apex run --file scripts/create-test-data-2.apex --target-org dev-org
sf apex run --file scripts/create-test-data-3.apex --target-org dev-org
sf apex run --file scripts/create-test-data-4.apex --target-org dev-org

# Remove test data only
sf apex run --file scripts/delete-test-data.apex --target-org dev-org
```

**Record counts:** 15 Accounts, 40 Contacts, 35 Opportunities, 30 Cases, 20 CaseComments, 25 Tasks, 15 Events

**Account tiers:** Enterprise (4), Mid-Market (6), SMB (5) — with varied industries, states, and revenue

**Pipeline:** All stages represented — 5 Prospecting, 4 Qualification, 4 Proposal, 3 Negotiation, 12 Closed Won, 7 Closed Lost

**Dates:** All relative to `Date.today()` — past 6 months through next 3 months

**Safe cleanup:** Scripts only delete records matching the 15 specific test account names — never a blanket delete

## Visualization System

Pass 2 returns structured JSON instead of raw HTML:

```json
{
  "analysisHtml": "<h3>Pipeline Summary</h3><p>...</p>",
  "visualizations": [
    {
      "type": "bar",
      "title": "Opportunities by Stage",
      "data": { "labels": [...], "datasets": [...] },
      "placement": "after_analysis"
    }
  ]
}
```

- The LLM chooses the chart type based on data shape (bar, line, doughnut, pie, stacked bar)
- Chart.js v4.4.7 is loaded as a static resource via `lightning/platformResourceLoader`
- The `biChart` child component renders each chart on a `<canvas>` element with SLDS-styled defaults
- **Backward compatible:** If the LLM returns plain HTML (not JSON), `JSON.parse` throws and the catch block renders it as before

**Supported chart types:** bar, line, doughnut, pie, stacked bar (bar with `stacked: true` in scale options)

**SLDS color palette used in charts:**
- Primary: `#0176d3` | Success: `#2e844a` | Warning: `#fe9339` | Error: `#ba0517` | Neutral: `#706e6b`
- Extended: `#1b96ff`, `#57a3fd`, `#8dc0fb`, `#b8d8f9`, `#032d60`

## Customization

- **Allowed objects:** Edit `OBJECTS_TO_DESCRIBE` in `BISchemaService.cls` and `ALLOWED_OBJECTS` in `BIQueryValidator.cls` (keep them in sync)
- **Model name:** Update `MODEL_NAME` in `BIAssistantController.cls` (default: `sfdc_ai__DefaultGPT4Omni`)
- **Query limit:** Adjust `MAX_LIMIT` in `BIQueryValidator.cls` (default: 200)
- **History depth:** Adjust `MAX_HISTORY_MESSAGES` in `BIAssistantController.cls` (default: 30)
- **Prompts:** Edit `pass1SystemPrompt()` and `pass2SystemPrompt()` in `BIAssistantController.cls`
- **Chart defaults:** Edit `defaultOptions` in `biChart.js` (colors, fonts, tooltip formatting, axis formatting)
- **Chart height:** Pass `height` attribute to `<c-bi-chart>` in `biAssistant.html` (default: 300px)

## Conventions

- API version: 62.0
- All Apex classes use `with sharing` for FLS/CRUD enforcement
- User-facing errors use `AuraHandledException`
- LLM-generated HTML is sanitized before DOM injection (script tags, event handlers, javascript: URIs stripped)
- Conversation history lives client-side — Apex is stateless
- Chart.js loaded once per page via `loadScript` (deduplicates across multiple `<c-bi-chart>` instances)
