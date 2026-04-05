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
