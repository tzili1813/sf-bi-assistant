/**
 * BISchemaService
 * ---------------
 * Builds a concise schema description of key Salesforce objects so the LLM
 * knows which objects/fields are available for SOQL generation.
 *
 * CUSTOMIZATION:
 *   - Edit OBJECTS_TO_DESCRIBE to add/remove queryable objects.
 *   - Edit EXCLUDED_FIELD_TYPES to filter out unwanted field types.
 *   - Output is kept compact to conserve LLM token budget.
 */
public with sharing class BISchemaService {

    // Objects the assistant is allowed to query.
    private static final List<String> OBJECTS_TO_DESCRIBE = new List<String>{
        'Account',
        'Contact',
        'Opportunity',
        'Lead',
        'Case',
        'Task',
        'Event',
        // ── Service Cloud objects ──
        'CaseComment',
        'CaseHistory',
        'Entitlement',
        'ServiceContract',
        'WorkOrder',
        'WorkOrderLineItem',
        'Asset',
        'LiveChatTranscript',
        'MessagingSession'
    };

    // Field types to skip.
    private static final Set<String> EXCLUDED_FIELD_TYPES = new Set<String>{
        'base64', 'address', 'location'
    };

    private static final Integer MAX_FIELDS_PER_OBJECT = 40;

    /**
     * Returns a compact schema description for injection into an LLM prompt.
     */
    public static String getSchemaContext() {
        List<String> sections = new List<String>();

        for (String objName : OBJECTS_TO_DESCRIBE) {
            Schema.SObjectType sot = Schema.getGlobalDescribe().get(objName);
            if (sot == null) continue;

            Schema.DescribeSObjectResult dsr = sot.getDescribe();
            if (!dsr.isAccessible() || !dsr.isQueryable()) continue;

            List<String> fieldLines = new List<String>();
            Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();

            Integer fieldCount = 0;
            for (String fieldName : fieldMap.keySet()) {
                if (fieldCount >= MAX_FIELDS_PER_OBJECT) break;

                Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
                if (!dfr.isAccessible()) continue;

                String fieldType = dfr.getType().name().toLowerCase();
                if (EXCLUDED_FIELD_TYPES.contains(fieldType)) continue;

                String line = '  - ' + dfr.getName() + ' (' + dfr.getType().name() + ')';

                // Picklist values for small picklists
                if ((dfr.getType() == Schema.DisplayType.PICKLIST
                     || dfr.getType() == Schema.DisplayType.MULTIPICKLIST)
                    && dfr.getPicklistValues().size() <= 15) {
                    List<String> vals = new List<String>();
                    for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                        if (pe.isActive()) vals.add(pe.getValue());
                    }
                    if (!vals.isEmpty()) {
                        line += ' values: [' + String.join(vals, ', ') + ']';
                    }
                }

                // Reference targets
                if (dfr.getType() == Schema.DisplayType.REFERENCE) {
                    List<String> refs = new List<String>();
                    for (Schema.SObjectType ref : dfr.getReferenceTo()) {
                        refs.add(ref.getDescribe().getName());
                    }
                    line += ' -> ' + String.join(refs, ', ');
                }

                fieldLines.add(line);
                fieldCount++;
            }

            String section = 'Object: ' + dsr.getName()
                           + ' (Label: ' + dsr.getLabel() + ')\n'
                           + String.join(fieldLines, '\n');
            sections.add(section);
        }

        sections.add(buildRelationshipHints());
        return String.join(sections, '\n\n');
    }

    private static String buildRelationshipHints() {
        return 'RELATIONSHIP HINTS:\n'
             // ── Sales ──
             + '- Opportunity.AccountId -> Account (relationship name: Account)\n'
             + '- Contact.AccountId -> Account (relationship name: Account)\n'
             + '- Task.WhoId -> Contact/Lead; Task.WhatId -> Account/Opportunity/Case\n'
             + '- Opportunity StageName includes "Closed Won" and "Closed Lost"\n'
             // ── Service ──
             + '- Case.ContactId -> Contact; Case.AccountId -> Account\n'
             + '- Case.EntitlementId -> Entitlement\n'
             + '- Case has Status, Priority, Origin, Type, Reason picklist fields\n'
             + '- Case.IsClosed and Case.IsEscalated are boolean fields useful for filtering\n'
             + '- Case.ClosedDate is set when a case is closed; use with CreatedDate to calculate resolution time\n'
             + '- CaseComment.ParentId -> Case (relationship name: Parent)\n'
             + '- CaseHistory.CaseId -> Case; tracks field changes on cases\n'
             + '- Entitlement.AccountId -> Account; represents SLA/support entitlements\n'
             + '- ServiceContract.AccountId -> Account\n'
             + '- WorkOrder.CaseId -> Case; WorkOrder.AccountId -> Account\n'
             + '- WorkOrderLineItem.WorkOrderId -> WorkOrder\n'
             + '- Asset.AccountId -> Account; Asset.ContactId -> Contact\n'
             + '- Asset represents products/items a customer owns (useful for support context)\n'
             + '- LiveChatTranscript.CaseId -> Case; LiveChatTranscript.ContactId -> Contact\n'
             + '- MessagingSession.CaseId -> Case (if using Messaging channels)\n'
             // ── Date helpers ──
             + '- Use LAST_N_DAYS:N, THIS_QUARTER, LAST_QUARTER, THIS_YEAR for date literals\n'
             + '- Aggregate queries: COUNT(), SUM(), AVG(), MIN(), MAX() with GROUP BY';
    }
}
