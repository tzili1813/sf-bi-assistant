// ============================================================================
// SF BI Assistant — Test Data Cleanup
// ============================================================================
// Removes all Pinnacle Solutions test data. Safe — only deletes records
// matching the specific test account names.
// Run via: sf apex run --file scripts/delete-test-data.apex --target-org dev-org
// ============================================================================

List<String> TEST_ACCOUNT_NAMES = new List<String>{
    'Meridian Financial Group', 'Atlas Healthcare Systems',
    'Vanguard Manufacturing', 'Titan Logistics Corp',
    'Horizon Digital Media', 'Cobalt Engineering Solutions',
    'Summit Retail Partners', 'NovaTech Industries',
    'Redwood Consulting Group', 'Cascade Energy Services',
    'Birch & Bloom Studio', 'Copper Lane Cafe',
    'Evergreen Landscaping Co', 'Driftwood Creative Agency',
    'Mosaic Learning Center'
};

// Delete in reverse dependency order
Integer evtCount = [SELECT COUNT() FROM Event WHERE Account.Name IN :TEST_ACCOUNT_NAMES];
delete [SELECT Id FROM Event WHERE Account.Name IN :TEST_ACCOUNT_NAMES];
System.debug('Events deleted: ' + evtCount);

Integer taskCount = [SELECT COUNT() FROM Task WHERE Account.Name IN :TEST_ACCOUNT_NAMES];
delete [SELECT Id FROM Task WHERE Account.Name IN :TEST_ACCOUNT_NAMES];
System.debug('Tasks deleted: ' + taskCount);

List<Id> caseIds = new List<Id>();
for (Case c : [SELECT Id FROM Case WHERE Account.Name IN :TEST_ACCOUNT_NAMES]) {
    caseIds.add(c.Id);
}

Integer commentCount = [SELECT COUNT() FROM CaseComment WHERE ParentId IN :caseIds];
delete [SELECT Id FROM CaseComment WHERE ParentId IN :caseIds];
System.debug('Case Comments deleted: ' + commentCount);

Integer caseCount = caseIds.size();
delete [SELECT Id FROM Case WHERE Id IN :caseIds];
System.debug('Cases deleted: ' + caseCount);

Integer oppCount = [SELECT COUNT() FROM Opportunity WHERE Account.Name IN :TEST_ACCOUNT_NAMES];
delete [SELECT Id FROM Opportunity WHERE Account.Name IN :TEST_ACCOUNT_NAMES];
System.debug('Opportunities deleted: ' + oppCount);

Integer ctCount = [SELECT COUNT() FROM Contact WHERE Account.Name IN :TEST_ACCOUNT_NAMES];
delete [SELECT Id FROM Contact WHERE Account.Name IN :TEST_ACCOUNT_NAMES];
System.debug('Contacts deleted: ' + ctCount);

Integer acctCount = [SELECT COUNT() FROM Account WHERE Name IN :TEST_ACCOUNT_NAMES];
delete [SELECT Id FROM Account WHERE Name IN :TEST_ACCOUNT_NAMES];
System.debug('Accounts deleted: ' + acctCount);

System.debug('');
System.debug('═══════════════════════════════════════════');
System.debug('  TEST DATA CLEANUP COMPLETE               ');
System.debug('═══════════════════════════════════════════');
System.debug('  Total records deleted: ' + (evtCount + taskCount + commentCount + caseCount + oppCount + ctCount + acctCount));
System.debug('═══════════════════════════════════════════');
