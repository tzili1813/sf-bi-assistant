/**
 * BIActionExecutor
 * ----------------
 * Executes validated Salesforce actions (DML) proposed by the LLM.
 * Only called AFTER BIActionValidator.validate() has passed.
 *
 * Uses Database.insert / Database.update with allOrNone=false for
 * graceful partial-failure handling.
 *
 * All actions are logged via System.debug for audit trail.
 */
public with sharing class BIActionExecutor {

    /**
     * Result of an executed action.
     */
    public class ActionResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String  recordId;
        @AuraEnabled public String  errorMessage;
        @AuraEnabled public String  recordUrl;    // e.g., "/001xxxxxxxxxxxx"

        public ActionResult(Boolean success, String recordId, String errorMessage) {
            this.success      = success;
            this.recordId     = recordId;
            this.errorMessage = errorMessage;
            this.recordUrl    = (recordId != null) ? '/' + recordId : null;
        }
    }

    /**
     * Execute a single validated action proposal.
     */
    public static ActionResult execute(BIActionProposal proposal) {
        String actionType = proposal.actionType;
        String sobjectType = proposal.sobjectType;
        Map<String, Object> fields = proposal.fields;

        System.debug(LoggingLevel.INFO,
            'BI Action — executing: ' + actionType
            + ' | sObject: ' + sobjectType
            + ' | fields: ' + JSON.serialize(fields));

        try {
            BIActionValidator.ActionDef def = BIActionValidator.getAllowedActions().get(actionType);

            if (def.dmlType == 'INSERT') {
                return executeInsert(sobjectType, fields, actionType);
            } else if (def.dmlType == 'UPDATE') {
                return executeUpdate(sobjectType, fields, actionType);
            } else {
                return new ActionResult(false, null, 'Unsupported DML type: ' + def.dmlType);
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                'BI Action — failed: ' + actionType + ' | error: ' + ex.getMessage());
            return new ActionResult(false, null, ex.getMessage());
        }
    }

    private static ActionResult executeInsert(String sobjectType,
                                              Map<String, Object> fields,
                                              String actionType) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(sobjectType);
        SObject record = sot.newSObject();

        // Apply defaults for specific action types
        if (actionType == 'log_call') {
            // Log a Call defaults
            if (!fields.containsKey('Status')) {
                record.put('Status', 'Completed');
            }
            if (!fields.containsKey('Type')) {
                record.put('Type', 'Call');
            }
        }
        if (actionType == 'create_followup' || actionType == 'create_task') {
            if (!fields.containsKey('Status')) {
                record.put('Status', 'Not Started');
            }
        }

        // Apply provided field values
        applyFields(record, fields, sobjectType);

        Database.SaveResult sr = Database.insert(record, false);
        if (sr.isSuccess()) {
            System.debug(LoggingLevel.INFO,
                'BI Action — success: ' + actionType + ' | recordId: ' + sr.getId());
            return new ActionResult(true, sr.getId(), null);
        } else {
            String err = sr.getErrors()[0].getMessage();
            System.debug(LoggingLevel.ERROR,
                'BI Action — DML error: ' + actionType + ' | error: ' + err);
            return new ActionResult(false, null, err);
        }
    }

    private static ActionResult executeUpdate(String sobjectType,
                                              Map<String, Object> fields,
                                              String actionType) {
        String recordId = String.valueOf(fields.get('Id'));

        Schema.SObjectType sot = Schema.getGlobalDescribe().get(sobjectType);
        SObject record = sot.newSObject(Id.valueOf(recordId));

        // Apply fields (skip Id — already set)
        Map<String, Object> updateFields = new Map<String, Object>(fields);
        updateFields.remove('Id');
        applyFields(record, updateFields, sobjectType);

        Database.SaveResult sr = Database.update(record, false);
        if (sr.isSuccess()) {
            System.debug(LoggingLevel.INFO,
                'BI Action — success: ' + actionType + ' | recordId: ' + recordId);
            return new ActionResult(true, recordId, null);
        } else {
            String err = sr.getErrors()[0].getMessage();
            System.debug(LoggingLevel.ERROR,
                'BI Action — DML error: ' + actionType + ' | error: ' + err);
            return new ActionResult(false, null, err);
        }
    }

    /**
     * Apply field values from a Map to an SObject, handling type coercion.
     */
    private static void applyFields(SObject record, Map<String, Object> fields, String sobjectType) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(sobjectType);
        Map<String, Schema.SObjectField> fieldMap = sot.getDescribe().fields.getMap();

        for (String fieldName : fields.keySet()) {
            Object val = fields.get(fieldName);
            if (val == null) continue;

            Schema.SObjectField sField = fieldMap.get(fieldName.toLowerCase());
            if (sField == null) continue;

            Schema.DisplayType fieldType = sField.getDescribe().getType();

            // Type coercion for common scenarios
            if (fieldType == Schema.DisplayType.DATE && val instanceof String) {
                record.put(fieldName, Date.valueOf((String) val));
            } else if (fieldType == Schema.DisplayType.DATETIME && val instanceof String) {
                record.put(fieldName, Datetime.valueOf(((String) val).replace('T', ' ')));
            } else if (fieldType == Schema.DisplayType.REFERENCE && val instanceof String) {
                record.put(fieldName, Id.valueOf((String) val));
            } else if (fieldType == Schema.DisplayType.DOUBLE && val instanceof String) {
                record.put(fieldName, Double.valueOf((String) val));
            } else if (fieldType == Schema.DisplayType.INTEGER && val instanceof String) {
                record.put(fieldName, Integer.valueOf((String) val));
            } else if (fieldType == Schema.DisplayType.BOOLEAN && val instanceof String) {
                record.put(fieldName, Boolean.valueOf((String) val));
            } else {
                record.put(fieldName, val);
            }
        }
    }
}
