/**
 * BIAssistantTest
 * ---------------
 * Unit tests for the BI Assistant validator and schema service.
 *
 * NOTE: The LLM callout (Models API) uses External Services and cannot
 * be unit-tested with standard Apex mocks. Test the full pipeline in a
 * sandbox with Einstein generative AI enabled, or use the External Services
 * test framework.
 */
@isTest
private class BIAssistantTest {

    // ──────────────────────────────────────────────────────────────
    //  BIQueryValidator
    // ──────────────────────────────────────────────────────────────

    @isTest
    static void validSelectPasses() {
        BIQueryValidator.validate(
            'SELECT Id, Name FROM Account WHERE Name != null LIMIT 10'
        );
        System.assert(true, 'Valid SELECT should pass');
    }

    @isTest
    static void serviceObjectsPasses() {
        // Verify service-specific objects are in the allowed list
        BIQueryValidator.validate(
            'SELECT Id, ParentId FROM CaseComment LIMIT 10'
        );
        BIQueryValidator.validate(
            'SELECT Id, AccountId FROM Entitlement LIMIT 10'
        );
        BIQueryValidator.validate(
            'SELECT Id, CaseId FROM WorkOrder LIMIT 10'
        );
        BIQueryValidator.validate(
            'SELECT Id, AccountId FROM Asset LIMIT 10'
        );
        System.assert(true, 'Service objects should pass validation');
    }

    @isTest
    static void rejectNonSelect() {
        try {
            BIQueryValidator.validate('INSERT INTO Account (Name) VALUES (\'Test\')');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Only SELECT'), e.getMessage());
        }
    }

    @isTest
    static void rejectDMLKeyword() {
        try {
            BIQueryValidator.validate('SELECT Id FROM Account WHERE delete LIMIT 10');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('blocked keyword'), e.getMessage());
        }
    }

    @isTest
    static void rejectMissingLimit() {
        try {
            BIQueryValidator.validate('SELECT Id FROM Account');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('LIMIT'), e.getMessage());
        }
    }

    @isTest
    static void rejectExcessiveLimit() {
        try {
            BIQueryValidator.validate('SELECT Id FROM Account LIMIT 500');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('exceeds'), e.getMessage());
        }
    }

    @isTest
    static void rejectDisallowedObject() {
        try {
            BIQueryValidator.validate('SELECT Id FROM User LIMIT 10');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('not permitted'), e.getMessage());
        }
    }

    @isTest
    static void rejectSQLComments() {
        try {
            BIQueryValidator.validate('SELECT Id FROM Account -- drop LIMIT 10');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('comment'), e.getMessage());
        }
    }

    @isTest
    static void rejectSQLCommentBlock() {
        try {
            BIQueryValidator.validate('SELECT Id FROM Account /* injection */ LIMIT 10');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('comment'), e.getMessage());
        }
    }

    @isTest
    static void rejectSQLCommentBlockClose() {
        try {
            BIQueryValidator.validate('SELECT Id FROM Account */ LIMIT 10');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('comment'), e.getMessage());
        }
    }

    @isTest
    static void rejectEmptyQuery() {
        try {
            BIQueryValidator.validate('');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Empty'), e.getMessage());
        }
    }

    @isTest
    static void rejectDMLKeywordAtEnd() {
        try {
            BIQueryValidator.validate('SELECT Id FROM Account LIMIT 10 DELETE');
            System.assert(false, 'Should have thrown for trailing DML keyword');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('blocked keyword'), e.getMessage());
        }
    }

    @isTest
    static void rejectSubqueryDisallowedObject() {
        try {
            BIQueryValidator.validate(
                'SELECT Id, (SELECT Id FROM User) FROM Account LIMIT 10'
            );
            System.assert(false, 'Should have thrown for subquery on disallowed object');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('not permitted'), e.getMessage());
        }
    }

    @isTest
    static void rejectSemicolon() {
        try {
            BIQueryValidator.validate('SELECT Id FROM Account LIMIT 10; SELECT Id FROM Contact LIMIT 10');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('semicolon'), e.getMessage());
        }
    }

    @isTest
    static void rejectUnion() {
        try {
            BIQueryValidator.validate('SELECT Id FROM Account LIMIT 10 UNION SELECT Id FROM Contact LIMIT 10');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('UNION'), e.getMessage());
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  sanitizeAggregateSoql
    // ──────────────────────────────────────────────────────────────

    @isTest
    static void sanitizeAggregateRemovesId() {
        String input = 'SELECT Id, Account.Name, COUNT(Id) cnt FROM Case WHERE IsEscalated = true GROUP BY Account.Name LIMIT 10';
        String result = BIAssistantController.sanitizeAggregateSoql(input);
        System.assert(!result.startsWith('SELECT Id,'), 'Id should be removed from aggregate SELECT');
        System.assert(result.contains('Account.Name'), 'Other fields should be preserved');
        System.assert(result.contains('COUNT(Id)'), 'COUNT(Id) should be preserved');
        System.assert(result.contains('GROUP BY'), 'GROUP BY clause should be preserved');
    }

    @isTest
    static void sanitizeNonAggregateKeepsId() {
        String input = 'SELECT Id, Name, StageName FROM Opportunity LIMIT 10';
        String result = BIAssistantController.sanitizeAggregateSoql(input);
        System.assertEquals(input, result, 'Non-aggregate query should be unchanged');
    }

    // ──────────────────────────────────────────────────────────────
    //  categorizeQueryError
    // ──────────────────────────────────────────────────────────────

    @isTest
    static void categorizeErrorNoSuchField() {
        String errorHint = BIAssistantController.categorizeQueryError(
            'No such column \'FakeField__c\' on entity \'Account\''
        );
        System.assert(errorHint.contains('field that does not exist'), errorHint);
    }

    @isTest
    static void categorizeErrorGroupBy() {
        String errorHint = BIAssistantController.categorizeQueryError(
            'Field must be grouped or aggregated: Name'
        );
        System.assert(errorHint.contains('aggregate functions'), errorHint);
    }

    @isTest
    static void categorizeErrorRelationship() {
        String errorHint = BIAssistantController.categorizeQueryError(
            'Didn\'t understand relationship \'FakeRelation__r\' not found'
        );
        System.assert(errorHint.contains('relationship path'), errorHint);
    }

    @isTest
    static void categorizeErrorMalformed() {
        String errorHint = BIAssistantController.categorizeQueryError(
            'unexpected token: WHERE WHERE'
        );
        System.assert(errorHint.contains('invalid query syntax'), errorHint);
    }

    @isTest
    static void categorizeErrorGeneric() {
        String errorHint = BIAssistantController.categorizeQueryError(
            'Some random unknown error'
        );
        System.assert(errorHint.contains('invalid field or relationship'), errorHint);
    }

    @isTest
    static void categorizeErrorNull() {
        String errorHint = BIAssistantController.categorizeQueryError(null);
        System.assert(errorHint.contains('unexpected query error'), errorHint);
    }

    // ──────────────────────────────────────────────────────────────
    //  BISchemaService
    // ──────────────────────────────────────────────────────────────

    @isTest
    static void schemaContextReturnsContent() {
        String schema = BISchemaService.getSchemaContext();
        System.assertNotEquals(null, schema);
        System.assert(schema.contains('Account'),     'Should describe Account');
        System.assert(schema.contains('Opportunity'),  'Should describe Opportunity');
        System.assert(schema.contains('RELATIONSHIP'), 'Should include relationship hints');
    }

    // ──────────────────────────────────────────────────────────────
    //  BIActionValidator
    // ──────────────────────────────────────────────────────────────

    @isTest
    static void actionValidatorAllowsValidTask() {
        BIActionProposal p = new BIActionProposal(
            'create_task', 'Test task', 'Task',
            new Map<String, Object>{
                'Subject' => 'Follow up',
                'Status'  => 'Not Started'
            },
            'Test reasoning'
        );
        // Should not throw
        BIActionValidator.validate(p);
        System.assert(true, 'Valid action should pass');
    }

    @isTest
    static void actionValidatorRejectsUnknownType() {
        BIActionProposal p = new BIActionProposal(
            'delete_everything', 'Bad action', 'Account',
            new Map<String, Object>{ 'Name' => 'Test' },
            'Malicious'
        );
        try {
            BIActionValidator.validate(p);
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Unknown action type'), e.getMessage());
        }
    }

    @isTest
    static void actionValidatorRejectsMissingRequired() {
        BIActionProposal p = new BIActionProposal(
            'create_task', 'Missing status', 'Task',
            new Map<String, Object>{
                'Subject' => 'Follow up'
                // Missing required 'Status'
            },
            'Test'
        );
        try {
            BIActionValidator.validate(p);
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Required field'), e.getMessage());
        }
    }

    @isTest
    static void actionValidatorRejectsDisallowedField() {
        BIActionProposal p = new BIActionProposal(
            'create_task', 'Bad field', 'Task',
            new Map<String, Object>{
                'Subject' => 'Test',
                'Status'  => 'Not Started',
                'OwnerId' => '005000000000001'  // Not in allowed fields
            },
            'Test'
        );
        try {
            BIActionValidator.validate(p);
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('not allowed'), e.getMessage());
        }
    }

    @isTest
    static void actionValidatorRejectsTooManyActions() {
        List<BIActionProposal> proposals = new List<BIActionProposal>();
        for (Integer i = 0; i < 4; i++) {
            proposals.add(new BIActionProposal(
                'create_task', 'Task ' + i, 'Task',
                new Map<String, Object>{
                    'Subject' => 'Test ' + i,
                    'Status'  => 'Not Started'
                },
                'Test'
            ));
        }
        try {
            BIActionValidator.validateAll(proposals);
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Too many actions'), e.getMessage());
        }
    }

    @isTest
    static void actionValidatorRejectsWrongSobjectType() {
        BIActionProposal p = new BIActionProposal(
            'create_task', 'Wrong type', 'Account',  // Should be Task
            new Map<String, Object>{
                'Subject' => 'Test',
                'Status'  => 'Not Started'
            },
            'Test'
        );
        try {
            BIActionValidator.validate(p);
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('requires sObject type'), e.getMessage());
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  BIActionExecutor
    // ──────────────────────────────────────────────────────────────

    @isTest
    static void actionExecutorInsertTask() {
        BIActionProposal p = new BIActionProposal(
            'create_task', 'Test follow-up', 'Task',
            new Map<String, Object>{
                'Subject'      => 'BI Assistant Test Task',
                'Status'       => 'Not Started',
                'Priority'     => 'Normal',
                'ActivityDate' => String.valueOf(Date.today().addDays(7))
            },
            'Test'
        );
        BIActionExecutor.ActionResult result = BIActionExecutor.execute(p);
        System.assert(result.success, 'Task insert should succeed: ' + result.errorMessage);
        System.assertNotEquals(null, result.recordId, 'Should return record Id');
        System.assertNotEquals(null, result.recordUrl, 'Should return record URL');

        // Cleanup
        delete [SELECT Id FROM Task WHERE Id = :result.recordId];
    }

    @isTest
    static void actionExecutorUpdateCase() {
        // Create a test case first
        Case c = new Case(Subject = 'BI Test Case', Status = 'New');
        insert c;

        BIActionProposal p = new BIActionProposal(
            'update_case_status', 'Update case', 'Case',
            new Map<String, Object>{
                'Id'     => c.Id,
                'Status' => 'Working'
            },
            'Test'
        );
        BIActionExecutor.ActionResult result = BIActionExecutor.execute(p);
        System.assert(result.success, 'Case update should succeed: ' + result.errorMessage);

        Case updated = [SELECT Status FROM Case WHERE Id = :c.Id];
        System.assertEquals('Working', updated.Status);
    }

    // ──────────────────────────────────────────────────────────────
    //  BIActionProposal
    // ──────────────────────────────────────────────────────────────

    @isTest
    static void actionProposalSerialization() {
        BIActionProposal p = new BIActionProposal(
            'create_task', 'Test', 'Task',
            new Map<String, Object>{ 'Subject' => 'Hello' },
            'Because'
        );
        String serialized = JSON.serialize(p);
        // Use deserializeUntyped because Map<String, Object> can't be deserialized via typed API
        Map<String, Object> deserialized = (Map<String, Object>) JSON.deserializeUntyped(serialized);
        System.assertEquals('create_task', deserialized.get('actionType'));
        System.assertEquals('Test', deserialized.get('label'));
        System.assertEquals('Task', deserialized.get('sobjectType'));
        // Verify fields round-trip
        Map<String, Object> fields = (Map<String, Object>) deserialized.get('fields');
        System.assertEquals('Hello', fields.get('Subject'));
    }

    // ──────────────────────────────────────────────────────────────
    //  BIChatMessage
    // ──────────────────────────────────────────────────────────────

    @isTest
    static void chatMessageSerialization() {
        BIChatMessage msg = new BIChatMessage('user', 'How many accounts?');
        System.assertEquals('user',               msg.role);
        System.assertEquals('How many accounts?',  msg.content);

        // Round-trip serialization
        String serialized = JSON.serialize(new List<BIChatMessage>{ msg });
        List<BIChatMessage> deserialized =
            (List<BIChatMessage>) JSON.deserialize(serialized, List<BIChatMessage>.class);
        System.assertEquals(1, deserialized.size());
        System.assertEquals('user', deserialized[0].role);
    }
}
