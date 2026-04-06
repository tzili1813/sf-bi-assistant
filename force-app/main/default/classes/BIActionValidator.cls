/**
 * BIActionValidator
 * -----------------
 * Security guardrails for LLM-proposed Salesforce actions.
 * Mirrors the whitelist-based approach of BIQueryValidator — the LLM is
 * never trusted. Every proposed action is validated against a registry of
 * allowed action types, allowed fields, and FLS/CRUD checks.
 *
 * Throws AuraHandledException on any violation.
 */
public with sharing class BIActionValidator {

    private static final Integer MAX_ACTIONS_PER_RESPONSE = 3;

    // ── Action type registry ─────────────────────────────────────────
    // Each entry defines: sObject type, DML type, required fields, optional fields
    public class ActionDef {
        public String  sobjectType;
        public String  dmlType;          // 'INSERT' or 'UPDATE'
        public Set<String> requiredFields;
        public Set<String> optionalFields;

        public ActionDef(String sobjectType, String dmlType,
                         Set<String> requiredFields, Set<String> optionalFields) {
            this.sobjectType   = sobjectType;
            this.dmlType       = dmlType;
            this.requiredFields = requiredFields;
            this.optionalFields = optionalFields;
        }

        public Set<String> allAllowedFields() {
            Set<String> all = new Set<String>(requiredFields);
            all.addAll(optionalFields);
            return all;
        }
    }

    private static final Map<String, ActionDef> ALLOWED_ACTIONS = new Map<String, ActionDef>{
        'create_task' => new ActionDef('Task', 'INSERT',
            new Set<String>{ 'Subject', 'Status' },
            new Set<String>{ 'WhoId', 'WhatId', 'ActivityDate', 'Priority', 'Description', 'Type' }
        ),
        'create_event' => new ActionDef('Event', 'INSERT',
            new Set<String>{ 'Subject', 'StartDateTime', 'EndDateTime' },
            new Set<String>{ 'WhoId', 'WhatId', 'Location', 'Description' }
        ),
        'update_case_status' => new ActionDef('Case', 'UPDATE',
            new Set<String>{ 'Id', 'Status' },
            new Set<String>{ 'Priority' }
        ),
        'create_followup' => new ActionDef('Task', 'INSERT',
            new Set<String>{ 'Subject', 'WhatId', 'ActivityDate' },
            new Set<String>{ 'Priority', 'Description', 'Status' }
        ),
        'log_call' => new ActionDef('Task', 'INSERT',
            new Set<String>{ 'Subject' },
            new Set<String>{ 'WhoId', 'WhatId', 'Description', 'ActivityDate', 'Status', 'Type' }
        ),
        'update_opp_stage' => new ActionDef('Opportunity', 'UPDATE',
            new Set<String>{ 'Id', 'StageName' },
            new Set<String>{ 'NextStep', 'CloseDate' }
        )
    };

    /**
     * Validate a list of action proposals. Throws on first violation.
     */
    public static void validateAll(List<BIActionProposal> proposals) {
        if (proposals == null || proposals.isEmpty()) return;

        if (proposals.size() > MAX_ACTIONS_PER_RESPONSE) {
            throw buildException(
                'Too many actions proposed (' + proposals.size()
                + '). Maximum is ' + MAX_ACTIONS_PER_RESPONSE + '.'
            );
        }

        for (BIActionProposal p : proposals) {
            validate(p);
        }
    }

    /**
     * Validate a single action proposal.
     */
    public static void validate(BIActionProposal proposal) {
        if (proposal == null) {
            throw buildException('Empty action proposal.');
        }

        // 1. Action type must be in the whitelist
        if (String.isBlank(proposal.actionType) || !ALLOWED_ACTIONS.containsKey(proposal.actionType)) {
            throw buildException(
                'Unknown action type: "' + proposal.actionType + '". '
                + 'Allowed: ' + String.join(new List<String>(ALLOWED_ACTIONS.keySet()), ', ')
            );
        }

        ActionDef def = ALLOWED_ACTIONS.get(proposal.actionType);

        // 2. SObject type must match the definition
        if (proposal.sobjectType == null || !proposal.sobjectType.equalsIgnoreCase(def.sobjectType)) {
            throw buildException(
                'Action "' + proposal.actionType + '" requires sObject type "'
                + def.sobjectType + '" but got "' + proposal.sobjectType + '".'
            );
        }

        // 3. Fields map must be present
        if (proposal.fields == null || proposal.fields.isEmpty()) {
            throw buildException(
                'Action "' + proposal.actionType + '" has no fields specified.'
            );
        }

        Set<String> allowed = def.allAllowedFields();

        // 4. All provided fields must be in the allowed set
        for (String fieldName : proposal.fields.keySet()) {
            if (!allowed.contains(fieldName)) {
                throw buildException(
                    'Field "' + fieldName + '" is not allowed for action "'
                    + proposal.actionType + '". Allowed: ' + String.join(new List<String>(allowed), ', ')
                );
            }
        }

        // 5. All required fields must be present
        for (String req : def.requiredFields) {
            if (!proposal.fields.containsKey(req)) {
                throw buildException(
                    'Required field "' + req + '" is missing for action "'
                    + proposal.actionType + '".'
                );
            }
        }

        // 6. For UPDATE actions, validate record Id exists and is accessible
        if (def.dmlType == 'UPDATE') {
            String recordId = String.valueOf(proposal.fields.get('Id'));
            if (String.isBlank(recordId) || recordId.length() < 15) {
                throw buildException(
                    'Invalid record Id for update action: "' + recordId + '".'
                );
            }
            validateRecordAccess(recordId, def.sobjectType);
        }

        // 7. FLS check — ensure the running user can create/update these fields
        validateFieldLevelSecurity(def.sobjectType, def.dmlType, proposal.fields.keySet());
    }

    /**
     * Verify the user has access to the target record.
     */
    private static void validateRecordAccess(String recordId, String sobjectType) {
        try {
            // Use a simple COUNT query to verify record exists and is accessible
            String soql = 'SELECT COUNT() FROM ' + sobjectType
                        + ' WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\' LIMIT 1';
            Integer count = Database.countQuery(soql);
            if (count == 0) {
                throw buildException(
                    'Record ' + recordId + ' was not found or you do not have access.'
                );
            }
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            throw buildException(
                'Unable to verify access to record ' + recordId + ': ' + ex.getMessage()
            );
        }
    }

    /**
     * Verify FLS for the fields being written.
     */
    private static void validateFieldLevelSecurity(String sobjectType, String dmlType,
                                                    Set<String> fieldNames) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(sobjectType);
        if (sot == null) {
            throw buildException('Unknown sObject type: ' + sobjectType);
        }

        Schema.DescribeSObjectResult dsr = sot.getDescribe();

        // Object-level check
        if (dmlType == 'INSERT' && !dsr.isCreateable()) {
            throw buildException(
                'You do not have permission to create ' + sobjectType + ' records.'
            );
        }
        if (dmlType == 'UPDATE' && !dsr.isUpdateable()) {
            throw buildException(
                'You do not have permission to update ' + sobjectType + ' records.'
            );
        }

        // Field-level check
        Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();
        for (String fn : fieldNames) {
            if (fn.equalsIgnoreCase('Id')) continue; // Id is always readable
            Schema.SObjectField field = fieldMap.get(fn.toLowerCase());
            if (field == null) continue; // Skip unknown fields — Database.insert will catch them

            Schema.DescribeFieldResult dfr = field.getDescribe();
            if (dmlType == 'INSERT' && !dfr.isCreateable()) {
                throw buildException(
                    'You do not have permission to set the "' + fn + '" field on ' + sobjectType + '.'
                );
            }
            if (dmlType == 'UPDATE' && !dfr.isUpdateable()) {
                throw buildException(
                    'You do not have permission to update the "' + fn + '" field on ' + sobjectType + '.'
                );
            }
        }
    }

    /**
     * Expose allowed action types for the prompt engineering layer.
     */
    public static Map<String, ActionDef> getAllowedActions() {
        return ALLOWED_ACTIONS;
    }

    private static AuraHandledException buildException(String msg) {
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }
}
