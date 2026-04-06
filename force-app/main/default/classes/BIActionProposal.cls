/**
 * BIActionProposal
 * ----------------
 * DTO for LLM-suggested Salesforce actions.
 * The LLM proposes actions in the ===ACTIONS=== section of its response;
 * each action is validated by BIActionValidator before execution by
 * BIActionExecutor.
 */
public class BIActionProposal {
    @AuraEnabled public String actionType;           // e.g., 'create_task', 'update_case_status'
    @AuraEnabled public String label;                // Human-readable description
    @AuraEnabled public String sobjectType;          // e.g., 'Task', 'Case'
    @AuraEnabled public Map<String, Object> fields;  // Field name → value
    @AuraEnabled public String reasoning;            // Why the LLM suggests this
    @AuraEnabled public String proposalId;           // Client-side tracking ID

    public BIActionProposal() {}

    public BIActionProposal(String actionType, String label, String sobjectType,
                            Map<String, Object> fields, String reasoning) {
        this.actionType  = actionType;
        this.label       = label;
        this.sobjectType = sobjectType;
        this.fields      = fields;
        this.reasoning   = reasoning;
    }
}
