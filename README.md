# Salesforce BI Assistant

A conversational AI component for Salesforce Lightning that lets users ask natural-language questions about their CRM data — with automatic Chart.js visualizations, clickable record links, multi-turn conversation support, and **actionable intelligence** (create tasks, update records, and more). Powered by the **Agentforce Models API**.

<!-- Add a screenshot here: ![BI Assistant](docs/screenshot.png) -->

---

## Features

- **Natural Language → SOQL** — Ask questions in plain English; the LLM generates validated SOQL behind the scenes
- **Chart.js Visualizations** — Bar, line, doughnut, pie, and stacked bar charts rendered automatically based on data shape
- **Chart Drilldown** — Click any chart segment to auto-submit a scoped follow-up question
- **Multi-Turn Conversation** — Follow-up questions like "break that down by region" work naturally with full context
- **Conversation Persistence** — Conversation history survives page refresh via `localStorage`
- **Clickable Record Links** — Opportunity names, account names, case subjects, etc. link directly to the Salesforce record
- **Actionable Intelligence** — LLM suggests concrete CRM actions (create tasks, update cases, log calls) that the user confirms before execution
- **Follow-Up Suggestions** — Three contextual follow-up question chips appear below each analysis
- **SOQL Transparency** — Toggle to reveal the generated SOQL queries in a syntax-highlighted code block
- **CSV Export** — Download query results as a `.csv` file with one click
- **Model Selector** — Switch between Einstein foundation models from the card header UI
- **Model Fallback Chain** — Automatically retries with the next model if the primary model is unavailable
- **Anomaly Detection & Trends** — LLM highlights outliers and includes ↑↓ period-over-period trend indicators
- **Categorized Error Diagnostics** — Invalid field, missing LIMIT, disallowed object, etc. all surface with specific remediation hints
- **Schema Caching** — Schema context cached via Platform Cache (1-hour TTL) to reduce per-request overhead
- **SLDS 2.0 Styling** — Tables, charts, and typography aligned to Lightning Design System Cosmos tokens
- **Security Guardrails** — SOQL validation, action whitelisting, HTML sanitization, `with sharing` enforcement, Einstein Trust Layer

---

## Architecture

```
User Question (+ conversation history)
     │
     ▼
┌──────────────────────────────────────────────────────────────────┐
│  PASS 1 — Generate & Execute SOQL                                │
│                                                                  │
│  [System Prompt + Schema] + [Full Chat History] + [New Question]  │
│       │                                                          │
│       ▼                                                          │
│  Models API  createChatGenerations  ──►  JSON Array of Queries   │
│       │                                                          │
│       ▼                                                          │
│  BIQueryValidator  (security guardrails)                         │
│       │                                                          │
│       ▼                                                          │
│  sanitizeAggregateSoql()  (auto-fix Id in GROUP BY queries)      │
│       │                                                          │
│       ▼                                                          │
│  Database.query()  ──►  List<QueryExecution> (counts + rows)     │
└──────────────────────────────────────────────────────────────────┘
     │
     ▼
┌──────────────────────────────────────────────────────────────────┐
│  PASS 2 — Produce HTML Analysis + Visualizations + Actions       │
│                                                                  │
│  [Question + Query Results]  ──►  Models API  ──►  Response      │
│                                                                  │
│  Output format (4-section delimiter-based):                      │
│    <h3>Analysis...</h3>                                          │
│    <table>...</table>                                            │
│    ===VISUALIZATIONS===                                          │
│    [{"type":"bar","title":"...","data":{...}}]                   │
│    ===ACTIONS===                                                 │
│    [{"type":"create_task","label":"...","fields":{...}}]         │
│    ===SUGGESTIONS===                                             │
│    ["Follow-up question 1", "Follow-up question 2", ...]        │
│                                                                  │
│  LWC splits on delimiters:                                       │
│    • HTML → sanitized → injected into lwc:dom="manual"           │
│    • Visualizations JSON → parsed → rendered as <c-bi-chart>     │
│    • Actions JSON → validated by BIActionValidator → action cards │
│    • Suggestions → rendered as clickable pill buttons            │
└──────────────────────────────────────────────────────────────────┘
     │
     ▼
┌──────────────────────────────────────────────────────────────────┐
│  CONTEXT WINDOW UPDATE                                           │
│                                                                  │
│  Conversation history updated with:                              │
│    • user: the question                                          │
│    • assistant: the SOQL JSON it generated                       │
│    • user: compact results summary                               │
│                                                                  │
│  LWC stores this and sends it back on the next turn              │
│  ──►  enables follow-ups like "break that down by region"        │
└──────────────────────────────────────────────────────────────────┘
     │
     ▼
User sees HTML analysis + interactive charts + clickable record links
     + action cards + follow-up suggestion chips
```

---

## File Inventory

```
sf-bi-assistant/
├── CLAUDE.md                              # Project guide for AI assistants
├── README.md                              # This file
├── sfdx-project.json                      # SFDX project config (API v62.0)
├── scripts/
│   ├── create-test-data.apex              # Part 1: Accounts + Contacts
│   ├── create-test-data-2.apex            # Part 2: Opportunities
│   ├── create-test-data-3.apex            # Part 3: Cases + CaseComments
│   ├── create-test-data-4.apex            # Part 4: Tasks + Events + Summary
│   ├── create-test-data-leads.apex        # Leads (standalone)
│   └── delete-test-data.apex              # Safe cleanup
└── force-app/main/default/
    ├── classes/
    │   ├── BIChatMessage.cls              # DTO for conversation messages
    │   ├── BISchemaService.cls            # Builds schema context (Platform Cache backed)
    │   ├── BIQueryValidator.cls           # Security guardrails for SOQL
    │   ├── BIActionProposal.cls           # DTO for LLM-proposed CRM actions
    │   ├── BIActionValidator.cls          # Whitelist-based security for action proposals
    │   ├── BIActionExecutor.cls           # Validated DML execution (INSERT/UPDATE)
    │   ├── BIAssistantController.cls      # Main orchestrator (Pass 1 + Pass 2 + Actions)
    │   └── BIAssistantTest.cls            # Unit tests (34 tests)
    ├── lwc/
    │   ├── biAssistant/
    │   │   ├── biAssistant.html           # Chat-style UI template
    │   │   ├── biAssistant.js             # State management, Apex calls, parsing
    │   │   ├── biAssistant.css            # SLDS 2.0 styling for analysis content
    │   │   └── biAssistant.js-meta.xml    # Exposed on App/Home/Record/Tab pages
    │   └── biChart/
    │       ├── biChart.html               # Canvas with lwc:dom="manual"
    │       ├── biChart.js                 # Chart.js loading + SLDS-styled rendering
    │       ├── biChart.css                # Chart container styling
    │       └── biChart.js-meta.xml        # Internal child component (not exposed)
    ├── staticresources/
    │   ├── ChartJs.resource               # Chart.js v4.4.7 UMD build
    │   └── ChartJs.resource-meta.xml      # Static resource metadata
    ├── genAiPromptTemplates/
    │   ├── BI_Query_Generator.genAiPromptTemplate-meta.xml   # Pass 1 prompt
    │   └── BI_Analysis_Writer.genAiPromptTemplate-meta.xml   # Pass 2 prompt
    ├── applications/
    │   └── BI_Assistant.app-meta.xml      # Lightning app
    ├── tabs/
    │   └── BI_Assistant.tab-meta.xml      # Custom tab
    └── profiles/
        └── Admin.profile-meta.xml         # Admin profile metadata
```

---

## Prerequisites

### 1. Einstein Generative AI

Your org must have Einstein generative AI enabled:

- **Setup → Einstein → Einstein Setup** → Turn on Einstein
- Requires **Enterprise+** edition with the Einstein AI add-on, or **Unlimited+**

### 2. Foundation Models

You need at least one model configured in Einstein Studio:

- **Setup → Einstein Studio → Foundation Models**
- The model selector in the component header lets users switch between available models at runtime
- Default model: `sfdc_ai__DefaultGPT4Omni` — update `DEFAULT_MODEL` in `BIAssistantController.cls` if needed
- Fallback chain (used automatically if the selected model fails): GPT-4o → GPT-4o mini → Claude 3 Haiku

### 3. Permissions

Users need the **Einstein Generative AI** permission set (or custom equivalent)
that grants access to the Models API.

### 4. Platform Cache (Optional but Recommended)

To enable schema caching (reduces LLM prompt overhead on repeated requests):

- **Setup → Platform Cache** → Create an Org Cache partition named `BIAssistant`
- If not configured, the component falls back gracefully to live schema describes on every request

---

## Deployment

### Option A: Salesforce CLI (sf)

```bash
# Authenticate to your org
sf org login web --alias my-org

# Deploy
sf project deploy start --source-dir force-app --target-org my-org

# Run tests
sf apex run test --class-names BIAssistantTest --target-org my-org --wait 10
```

### Option B: VS Code + Salesforce Extension Pack

1. Open the `sf-bi-assistant` folder in VS Code.
2. Authenticate via **SFDX: Authorize an Org**.
3. Right-click `force-app` → **SFDX: Deploy Source to Org**.

### After Deployment

1. **Create a Lightning App Page** (or edit an existing one):
   - Setup → Lightning App Builder → New → App Page
   - Drag `BI Assistant` from the Custom section onto the canvas
   - Save and Activate

2. **Or add to Home Page / Record Page** — the component is exposed on
   `lightning__AppPage`, `lightning__HomePage`, `lightning__RecordPage`,
   and `lightning__Tab`.

---

## Test Data

The `scripts/` directory contains Apex anonymous scripts that create a cohesive set of test records for a fictional B2B company called **Pinnacle Solutions**.

### Loading Test Data

Run all 4 parts in order (Part 1 deletes existing test data first, making this idempotent):

```bash
sf apex run --file scripts/create-test-data.apex --target-org my-org
sf apex run --file scripts/create-test-data-2.apex --target-org my-org
sf apex run --file scripts/create-test-data-3.apex --target-org my-org
sf apex run --file scripts/create-test-data-4.apex --target-org my-org

# Optional: add 25 Lead records
sf apex run --file scripts/create-test-data-leads.apex --target-org my-org
```

### Removing Test Data

```bash
sf apex run --file scripts/delete-test-data.apex --target-org my-org
```

Safe cleanup — only deletes records matching the 15 specific test account names. Never a blanket delete.

### Record Counts

| Object | Count | Details |
|--------|-------|---------|
| Accounts | 15 | Enterprise (4), Mid-Market (6), SMB (5) |
| Contacts | 40 | 2-4 per account, varied titles/departments |
| Opportunities | 35 | 5 Prospecting, 4 Qualification, 4 Proposal, 3 Negotiation, 12 Won, 7 Lost |
| Cases | 30 | High/Medium/Low × New/Working/Closed, 3 escalated |
| Case Comments | 20 | Technical detail on active/resolved cases |
| Tasks | 25 | 15 completed, 10 open |
| Events | 15 | 8 past, 7 upcoming |
| Leads | 25 | 5 Hot, 10 Warm, 10 Cold |
| **Total** | **~205** | |

All dates are relative to `Date.today()` — past 6 months through next 3 months.

---

## Actionable Intelligence

The most powerful feature of BI Assistant: the LLM doesn't just analyze data — it suggests concrete CRM actions the user can take, and executes them with full security validation.

### How It Works

1. Pass 2 detects when analysis naturally leads to action (e.g., stale opportunities → create follow-up task)
2. Action proposals are returned in the `===ACTIONS===` section alongside the HTML analysis
3. Action cards appear below the charts with a label, reasoning, and **Execute / Dismiss** buttons
4. User clicks **Execute** → `LightningConfirm` modal → Apex `confirmAction()` → validated + executed
5. Success shows a green checkmark + **View Record** link; failure shows an inline error message
6. **Dismiss** removes the card without any server call

### Supported Action Types

| Action Type | Object | DML | Required Fields |
|---|---|---|---|
| `create_task` | Task | INSERT | Subject, Status |
| `create_event` | Event | INSERT | Subject, StartDateTime, EndDateTime |
| `update_case_status` | Case | UPDATE | Id, Status |
| `create_followup` | Task | INSERT | Subject, WhatId, ActivityDate |
| `log_call` | Task | INSERT | Subject, Status=Completed, Type=Call |
| `update_opp_stage` | Opportunity | UPDATE | Id, StageName |

### Security (Defense in Depth)

- **LLM is never trusted** — `BIActionValidator` independently validates every field against a strict whitelist
- **`with sharing`** — Respects the running user's record access for all DML
- **FLS checks** — `Schema.DescribeFieldResult.isCreateable()` / `isUpdateable()` verified before any DML
- **Max 3 actions per response** — Enforced in the validator
- **Audit logging** — Every executed action is logged via `System.debug`
- **Client-side debounce** — 1 action per 5 seconds to prevent double-execution

---

## How It Works

### Pass 1: Natural Language → SOQL

The system prompt includes the full org schema (object names, field names/types, picklist values, relationship hints) and rules for SOQL generation. The LLM receives the full conversation history so it understands references like "those", "break it down", "now filter by...", etc.

The LLM is instructed to:
- Always include `Id` in SELECT (except in aggregate/GROUP BY queries)
- Include parent Id fields (e.g. `AccountId`) for record linking
- Generate comparative period queries when temporal context is detected (e.g., "this quarter vs last quarter")
- Return a JSON array of `{label, soql}` objects

**Validation** runs before execution:
- Must start with `SELECT`
- No DML keywords
- LIMIT required and ≤ 200
- All FROM targets validated against allowed list (including subqueries)
- No SQL comment patterns (`--`, `/*`, `*/`), semicolons, or UNION

**Aggregate safety net**: `sanitizeAggregateSoql()` automatically strips standalone `Id` from the SELECT clause of GROUP BY queries — preventing "Field must be grouped or aggregated" errors regardless of LLM output.

### Pass 2: Results → HTML + Visualizations + Actions + Suggestions

A separate LLM call receives the question and query results, then returns a response in **4-section delimiter-based format**:

```
<h3>Analysis heading</h3>
<p>Text with <a href="/{recordId}">clickable record links</a>...</p>
<table>...</table>
===VISUALIZATIONS===
[{"type":"bar","title":"Chart Title","data":{"labels":[...],"datasets":[...]}}]
===ACTIONS===
[{"type":"create_task","label":"Create follow-up for Acme Corp","sobjectType":"Task","fields":{...},"reasoning":"3 stale opportunities"}]
===SUGGESTIONS===
["What is the activity history for Acme Corp?","Which opportunities close this quarter?","Show me all escalated cases"]
```

The LWC splits on each delimiter:
- **HTML** → sanitized → injected into `lwc:dom="manual"` container
- **Visualizations JSON** → parsed → rendered as `<c-bi-chart>` child components
- **Actions JSON** → validated by `BIActionValidator` → rendered as action cards
- **Suggestions** → rendered as clickable pill chips

This delimiter approach avoids the problem of LLMs failing to properly JSON-escape HTML strings.

### Model Fallback Chain

If the selected model is unavailable or errors, `callChatLLM()` automatically retries with fallback models:

1. User-selected model (or `DEFAULT_MODEL` if none selected)
2. `sfdc_ai__DefaultGPT4Omni`
3. `sfdc_ai__DefaultOpenAIGPT4OmniMini`
4. `sfdc_ai__DefaultBedrockAnthropicClaude3Haiku`

Each model gets one retry on transient failure before the chain advances.

### Schema Caching

`BISchemaService.getSchemaContext()` builds a schema description of all 17+ supported objects × ~40 fields per request. With Platform Cache configured:

1. First request builds schema and stores in Org Cache (`local.BIAssistant` partition, 1-hour TTL)
2. Subsequent requests within the hour read from cache
3. A static variable deduplicates multiple calls within the same transaction
4. If cache is unavailable, falls back to live schema describe silently

### Chart Rendering

The `biChart` child component:
1. Loads Chart.js v4.4.7 from a static resource via `loadScript` (deduplicated across instances)
2. Clones the LLM config via `JSON.parse(JSON.stringify())` to escape LWC proxy objects
3. Builds SLDS-styled defaults (fonts, colors, number-formatted tooltips/axes)
4. Deep-merges LLM options over defaults (preserving callback functions)
5. Renders on a `<canvas>` element with `lwc:dom="manual"`
6. Dispatches `CustomEvent('drilldown')` on click → parent auto-constructs a follow-up question

Supported chart types: bar, line, doughnut, pie, stacked bar.

### Record Linking

Pass 1 includes `Id` in all non-aggregate queries. Pass 2 instructs the LLM to render record names as `<a href="/{recordId}">{Name}</a>` links. These pass through the HTML sanitizer (which only strips `<script>`, `on*` events, and `javascript:` URIs) and render as native anchor tags that navigate within Lightning Experience.

### Conversation Persistence

On every response, `_saveState()` serializes `displayMessages` and `conversationHistory` to `localStorage` (`STORAGE_KEY = 'bi-assistant-state'`). On component load, `_restoreState()` rehydrates the state and re-injects HTML into all `lwc:dom="manual"` containers via `setTimeout`. Clearing the conversation also clears the stored state.

### Context Window Management

After each turn, three messages are appended to the history:
1. `user`: the question asked
2. `assistant`: the SOQL JSON the LLM generated
3. `user`: a compact summary of the results

History is capped at 30 messages (~10 turns). Oldest turns are evicted first. The LWC stores history client-side — Apex is stateless.

---

## Security

- **SOQL validation** — All LLM-generated queries pass through `BIQueryValidator` before execution (SELECT-only, allowed objects, LIMIT enforced, injection patterns blocked)
- **Action validation** — All LLM-proposed actions pass through `BIActionValidator` (whitelist of action types, fields, and sObject targets) before any DML runs
- **Aggregate sanitization** — `sanitizeAggregateSoql()` auto-removes `Id` from GROUP BY queries to prevent runtime errors
- **HTML sanitization** — `<script>` tags, `on*` event handlers, and `javascript:` URIs are stripped before DOM injection
- **FLS/CRUD** — All Apex classes use `with sharing` for field-level security and CRUD enforcement; DML actions also verify `isCreateable()`/`isUpdateable()` per field
- **Trust Layer** — All LLM calls route through the Agentforce Models API and Einstein Trust Layer
- **No secrets in code** — All authentication is handled via Salesforce org configuration, not hardcoded credentials
- **Action audit log** — Every executed action is logged via `System.debug` for traceability

---

## Customization

### Adding/Removing Queryable Objects

Edit **both** files (keep them in sync):

1. `BISchemaService.cls` — `OBJECTS_TO_DESCRIBE` list
2. `BIQueryValidator.cls` — `ALLOWED_OBJECTS` set

```apex
// BISchemaService.cls
private static final List<String> OBJECTS_TO_DESCRIBE = new List<String>{
    'Account', 'Contact', 'Opportunity', 'Lead', 'Case',
    'Task', 'Event', 'CaseComment', 'CaseHistory',
    'Product2',            // ← add your objects
    'OpportunityLineItem'
};
```

### Changing the Default LLM Model

Update `DEFAULT_MODEL` in `BIAssistantController.cls`:

```apex
private static final String DEFAULT_MODEL = 'sfdc_ai__DefaultOpenAIGPT4OmniMini';
```

Users can also switch models at runtime using the model selector in the card header. Common options:
- `sfdc_ai__DefaultGPT4Omni` — GPT-4o (best quality)
- `sfdc_ai__DefaultOpenAIGPT4OmniMini` — GPT-4o mini (faster/cheaper)
- `sfdc_ai__DefaultBedrockClaude` — Claude on Bedrock
- Any BYOLLM model configured in Einstein Studio

### Customizing the Fallback Chain

Edit `FALLBACK_MODELS` in `BIAssistantController.cls`:

```apex
private static final List<String> FALLBACK_MODELS = new List<String>{
    'sfdc_ai__DefaultGPT4Omni',
    'sfdc_ai__DefaultOpenAIGPT4OmniMini',
    'sfdc_ai__DefaultBedrockAnthropicClaude3Haiku'
};
```

### Adding Action Types

To extend the action whitelist, add an entry to `ALLOWED_ACTIONS` in `BIActionValidator.cls`:

```apex
ALLOWED_ACTIONS.put('create_note', new ActionConfig(
    'ContentNote', 'insert',
    new Set<String>{'Title', 'Content'},
    new Set<String>{'OwnerId'}
));
```

### Adjusting Query Limits

Edit `BIQueryValidator.cls`:

```apex
private static final Integer MAX_LIMIT = 200;  // change to your preference
```

### Chart Defaults

Edit `biChart.js` to change:
- **Colors**: SLDS color palette in `defaultOptions` (legend labels, tooltips, grid lines)
- **Fonts**: Font family defaults (Salesforce Sans)
- **Tooltips**: Number formatting via `Intl.NumberFormat`
- **Axes**: Compact notation on y-axis, grid line colors

### Chart Height

Pass `height` attribute to `<c-bi-chart>` in `biAssistant.html` (default: 300px):

```html
<c-bi-chart key={viz.id} chart-config={viz} height="400"></c-bi-chart>
```

### SLDS 2.0 Color Palette (used in charts)

| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#0176d3` | Default bars, links |
| Accent | `#3A49DA` | SLDS 2.0 indigo accent |
| Success | `#2e844a` | Positive values, completed actions |
| Warning | `#fe9339` | Caution indicators, action card accent |
| Error | `#ba0517` | Negative values, failed actions |
| Neutral | `#706e6b` | Axis labels, secondary text |
| Extended | `#1b96ff`, `#57a3fd`, `#8dc0fb`, `#b8d8f9`, `#032d60` | Multi-segment charts |

### Tuning the Prompts

Both prompts live in `BIAssistantController.cls`:

- `pass1SystemPrompt()` — controls SOQL generation rules and temporal comparison guidance
- `pass2SystemPrompt()` — controls HTML analysis style, chart selection, record linking, action suggestion rules, anomaly/trend formatting, and follow-up question generation
