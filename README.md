# Salesforce BI Assistant

A natural-language BI assistant built on the **Agentforce Models API** that lets
users query their CRM data in plain English — with multi-turn conversation support.

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
│  Database.query()  ──►  List<QueryExecution> (counts + rows)     │
└──────────────────────────────────────────────────────────────────┘
     │
     ▼
┌──────────────────────────────────────────────────────────────────┐
│  PASS 2 — Produce HTML Analysis                                  │
│                                                                  │
│  [Question + Query Results]  ──►  Models API  ──►  HTML Fragment  │
│                                                                  │
│  Output: BIResult.analysisHtml (clean, user-friendly HTML)       │
└──────────────────────────────────────────────────────────────────┘
     │
     ▼
┌──────────────────────────────────────────────────────────────────┐
│  CONTEXT WINDOW UPDATE                                           │
│                                                                  │
│  Conversation history is updated with:                           │
│    • user: the question                                          │
│    • assistant: the SOQL JSON it generated                       │
│    • user: compact results summary                               │
│                                                                  │
│  LWC stores this and sends it back on the next turn              │
│  ──►  enables follow-ups like "break that down by region"        │
└──────────────────────────────────────────────────────────────────┘
     │
     ▼
User sees HTML analysis (no SOQL, IDs, or technical details)
```

### Multi-Turn Conversation Flow

The LWC maintains a `conversationHistory` array client-side. On every turn:

1. The full history is serialised and sent to Apex.
2. Apex prepends the system prompt (with schema) and appends the new question.
3. The complete message list is passed to `createChatGenerations` — this is
   what gives the LLM context for follow-up questions.
4. After execution, the new turn (question + SOQL response + results summary)
   is appended to the history and returned to the LWC.
5. The LWC stores the updated history for the next turn.

---

## File Inventory

```
sf-bi-assistant/
├── CLAUDE.md                              # Project guide for AI assistants
├── README.md                              # This file
├── sfdx-project.json                      # SFDX project config (API v62.0)
└── force-app/main/default/
    ├── classes/
    │   ├── BIChatMessage.cls              # DTO for conversation messages
    │   ├── BISchemaService.cls            # Builds schema context for the LLM
    │   ├── BIQueryValidator.cls           # Security guardrails for SOQL
    │   ├── BIAssistantController.cls      # Main orchestrator (Pass 1 + Pass 2)
    │   ├── BIAssistantTest.cls            # Unit tests
    │   └── *.cls-meta.xml                 # Apex metadata (API v62.0)
    ├── lwc/
    │   └── biAssistant/
    │       ├── biAssistant.html           # Chat-style UI template
    │       ├── biAssistant.js             # Controller (conversation state mgmt)
    │       ├── biAssistant.css            # Styling
    │       └── biAssistant.js-meta.xml    # LWC metadata (exposed on pages)
    └── genAiPromptTemplates/
        ├── BI_Query_Generator.genAiPromptTemplate-meta.xml   # Pass 1 prompt
        └── BI_Analysis_Writer.genAiPromptTemplate-meta.xml   # Pass 2 prompt
```

---

## Prerequisites

### 1. Einstein Generative AI

Your org must have Einstein generative AI enabled:

- **Setup → Einstein → Einstein Setup** → Turn on Einstein
- Requires **Enterprise+** edition with the Einstein AI add-on, or **Unlimited+**

### 2. Foundation Model

You need at least one model configured in Einstein Studio:

- **Setup → Einstein Studio → Foundation Models**
- Confirm the model's **API Name** (e.g. `sfdc_ai__DefaultGPT4Omni`)
- Update `MODEL_NAME` in `BIAssistantController.cls` if needed

### 3. Permissions

Users need the **Einstein Generative AI** permission set (or custom equivalent)
that grants access to the Models API.

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

## Customization

### Adding/Removing Queryable Objects

Edit `BISchemaService.cls` — update the `OBJECTS_TO_DESCRIBE` list:

```apex
private static final List<String> OBJECTS_TO_DESCRIBE = new List<String>{
    'Account', 'Contact', 'Opportunity', 'Lead', 'Case',
    'Task', 'Event',
    'Product2',        // ← add your objects
    'OpportunityLineItem'
};
```

Then update the `ALLOWED_OBJECTS` set in `BIQueryValidator.cls` to match.

### Changing the LLM Model

Update `MODEL_NAME` in `BIAssistantController.cls`:

```apex
private static final String MODEL_NAME = 'sfdc_ai__DefaultOpenAIGPT4OmniMini';
```

Common options:
- `sfdc_ai__DefaultGPT4Omni` — GPT-4o (best quality)
- `sfdc_ai__DefaultOpenAIGPT4OmniMini` — GPT-4o mini (faster/cheaper)
- `sfdc_ai__DefaultBedrockClaude` — Claude on Bedrock
- Any BYOLLM model configured in Einstein Studio

### Adjusting Query Limits

Edit `BIQueryValidator.cls`:

```apex
private static final Integer MAX_LIMIT = 200;  // change to your preference
```

### Tuning the Prompts

Both prompts live in `BIAssistantController.cls`:

- `pass1SystemPrompt()` — controls SOQL generation behaviour
- `pass2SystemPrompt()` — controls the HTML analysis style and formatting

---

## How It Works — Detailed

### Pass 1: Natural Language → SOQL

The system prompt includes:
- The full org schema (object names, field names/types, picklist values,
  relationship hints)
- Rules: SELECT-only, must include LIMIT, use only schema objects/fields
- Instruction to return a JSON array of `{label, soql}` objects

The LLM receives the full conversation history so it understands
references like "those", "break it down", "now filter by...", etc.

**Validation** runs before execution:
- Must start with `SELECT`
- No DML keywords (checked at word boundaries, including end-of-string)
- LIMIT required and ≤ 200
- All FROM targets validated against allowed list (including subqueries)
- No SQL comment patterns (`--`, `/*`, `*/`)
- No semicolons or UNION keywords

### Pass 2: Results → HTML Analysis

A separate LLM call (single-turn, no history needed) receives:
- The original question
- The query results (serialised, truncated if large)

The prompt instructs the LLM to:
- Write for non-technical users
- Never expose SOQL, record IDs, or API names
- Use styled HTML with SLDS-compatible colours
- Include percentages/comparisons where meaningful

### Context Window Management

After each turn, three messages are appended to the history:
1. `user`: the question asked
2. `assistant`: the SOQL JSON the LLM generated
3. `user`: a compact summary of the results

This means on the next turn, the LLM knows:
- What the user previously asked
- What queries it ran
- What data came back

This enables natural follow-up conversations.

History is capped at 30 messages (~10 turns) to stay within LLM token and Apex heap limits. Oldest turns are evicted first.

### Security

- All SOQL is validated before execution (see above)
- LLM-generated HTML is sanitized before DOM injection — `<script>` tags, `on*` event handlers, and `javascript:` URIs are stripped
- All Apex classes use `with sharing` for FLS/CRUD enforcement
- The Models API routes through the Einstein Trust Layer
