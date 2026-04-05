// ============================================================================
// SF BI Assistant — Test Data Generator (Part 1 of 4)
// Creates Accounts + Contacts. Run all 4 parts in order.
// sf apex run --file scripts/create-test-data.apex --target-org dev-org
// ============================================================================

Date today = Date.today();
List<String> AN = new List<String>{
    'Meridian Financial Group','Atlas Healthcare Systems',
    'Vanguard Manufacturing','Titan Logistics Corp',
    'Horizon Digital Media','Cobalt Engineering Solutions',
    'Summit Retail Partners','NovaTech Industries',
    'Redwood Consulting Group','Cascade Energy Services',
    'Birch & Bloom Studio','Copper Lane Cafe',
    'Evergreen Landscaping Co','Driftwood Creative Agency',
    'Mosaic Learning Center'
};

// Clean up
delete [SELECT Id FROM Event WHERE Account.Name IN :AN];
delete [SELECT Id FROM Task WHERE Account.Name IN :AN];
delete [SELECT Id FROM CaseComment WHERE ParentId IN (SELECT Id FROM Case WHERE Account.Name IN :AN)];
delete [SELECT Id FROM Case WHERE Account.Name IN :AN];
delete [SELECT Id FROM Opportunity WHERE Account.Name IN :AN];
delete [SELECT Id FROM Contact WHERE Account.Name IN :AN];
delete [SELECT Id FROM Account WHERE Name IN :AN];
System.debug('Cleanup complete.');

// ── Accounts (15) ──
List<Account> accts = new List<Account>{
    new Account(Name='Meridian Financial Group',Industry='Financial Services',BillingCountryCode='US',BillingStateCode='NY',AnnualRevenue=45000000,Rating='Hot',NumberOfEmployees=2800,Type='Customer - Direct'),
    new Account(Name='Atlas Healthcare Systems',Industry='Healthcare',BillingCountryCode='US',BillingStateCode='CA',AnnualRevenue=38000000,Rating='Hot',NumberOfEmployees=3200,Type='Customer - Direct'),
    new Account(Name='Vanguard Manufacturing',Industry='Manufacturing',BillingCountryCode='US',BillingStateCode='IL',AnnualRevenue=52000000,Rating='Hot',NumberOfEmployees=4100,Type='Customer - Direct'),
    new Account(Name='Titan Logistics Corp',Industry='Transportation',BillingCountryCode='US',BillingStateCode='TX',AnnualRevenue=29000000,Rating='Warm',NumberOfEmployees=1900,Type='Customer - Direct'),
    new Account(Name='Horizon Digital Media',Industry='Media',BillingCountryCode='US',BillingStateCode='CA',AnnualRevenue=14000000,Rating='Warm',NumberOfEmployees=450,Type='Customer - Direct'),
    new Account(Name='Cobalt Engineering Solutions',Industry='Technology',BillingCountryCode='US',BillingStateCode='WA',AnnualRevenue=18000000,Rating='Warm',NumberOfEmployees=620,Type='Customer - Direct'),
    new Account(Name='Summit Retail Partners',Industry='Retail',BillingCountryCode='US',BillingStateCode='FL',AnnualRevenue=9500000,Rating='Warm',NumberOfEmployees=380,Type='Prospect'),
    new Account(Name='NovaTech Industries',Industry='Technology',BillingCountryCode='US',BillingStateCode='MA',AnnualRevenue=12000000,Rating='Hot',NumberOfEmployees=510,Type='Prospect'),
    new Account(Name='Redwood Consulting Group',Industry='Consulting',BillingCountryCode='US',BillingStateCode='CO',AnnualRevenue=7500000,Rating='Warm',NumberOfEmployees=290,Type='Customer - Direct'),
    new Account(Name='Cascade Energy Services',Industry='Energy',BillingCountryCode='US',BillingStateCode='WA',AnnualRevenue=16000000,Rating='Warm',NumberOfEmployees=540,Type='Prospect'),
    new Account(Name='Birch & Bloom Studio',Industry='Media',BillingCountryCode='US',BillingStateCode='NY',AnnualRevenue=2200000,Rating='Warm',NumberOfEmployees=45,Type='Customer - Direct'),
    new Account(Name='Copper Lane Cafe',Industry='Hospitality',BillingCountryCode='US',BillingStateCode='TX',AnnualRevenue=850000,Rating='Cold',NumberOfEmployees=22,Type='Customer - Direct'),
    new Account(Name='Evergreen Landscaping Co',Industry='Construction',BillingCountryCode='US',BillingStateCode='FL',AnnualRevenue=3100000,Rating='Warm',NumberOfEmployees=65,Type='Customer - Direct'),
    new Account(Name='Driftwood Creative Agency',Industry='Media',BillingCountryCode='US',BillingStateCode='CA',AnnualRevenue=4800000,Rating='Warm',NumberOfEmployees=85,Type='Prospect'),
    new Account(Name='Mosaic Learning Center',Industry='Education',BillingCountryCode='US',BillingStateCode='MA',AnnualRevenue=1500000,Rating='Cold',NumberOfEmployees=35,Type='Customer - Direct')
};
insert accts;
Map<String,Id> am = new Map<String,Id>();
for (Account a : accts) am.put(a.Name, a.Id);
System.debug('Accounts: ' + accts.size());

// ── Contacts (40) ──
List<Contact> cts = new List<Contact>();
// Enterprise
cts.add(new Contact(FirstName='Sarah',LastName='Chen',Title='VP of Operations',Department='Operations',Email='sarah.chen@meridianfg.example.com',Phone='212-555-0101',AccountId=am.get('Meridian Financial Group')));
cts.add(new Contact(FirstName='James',LastName='Morrison',Title='Director of IT',Department='Technology',Email='james.morrison@meridianfg.example.com',Phone='212-555-0102',AccountId=am.get('Meridian Financial Group')));
cts.add(new Contact(FirstName='Priya',LastName='Sharma',Title='Project Manager',Department='Technology',Email='priya.sharma@meridianfg.example.com',Phone='212-555-0103',AccountId=am.get('Meridian Financial Group')));
cts.add(new Contact(FirstName='David',LastName='Park',Title='Financial Analyst',Department='Finance',Email='david.park@meridianfg.example.com',Phone='212-555-0104',AccountId=am.get('Meridian Financial Group')));
cts.add(new Contact(FirstName='Maria',LastName='Gonzalez',Title='Chief Technology Officer',Department='Technology',Email='maria.gonzalez@atlashc.example.com',Phone='415-555-0201',AccountId=am.get('Atlas Healthcare Systems')));
cts.add(new Contact(FirstName='Robert',LastName='Kim',Title='IT Director',Department='Technology',Email='robert.kim@atlashc.example.com',Phone='415-555-0202',AccountId=am.get('Atlas Healthcare Systems')));
cts.add(new Contact(FirstName='Emily',LastName='Taylor',Title='Clinical Systems Manager',Department='Clinical',Email='emily.taylor@atlashc.example.com',Phone='415-555-0203',AccountId=am.get('Atlas Healthcare Systems')));
cts.add(new Contact(FirstName='Marcus',LastName='Williams',Title='Support Coordinator',Department='Operations',Email='marcus.williams@atlashc.example.com',Phone='415-555-0204',AccountId=am.get('Atlas Healthcare Systems')));
cts.add(new Contact(FirstName='Thomas',LastName='Mueller',Title='VP of Engineering',Department='Engineering',Email='thomas.mueller@vanguardmfg.example.com',Phone='312-555-0301',AccountId=am.get('Vanguard Manufacturing')));
cts.add(new Contact(FirstName='Linda',LastName='Jackson',Title='Operations Manager',Department='Operations',Email='linda.jackson@vanguardmfg.example.com',Phone='312-555-0302',AccountId=am.get('Vanguard Manufacturing')));
cts.add(new Contact(FirstName='Kevin',LastName='O\'Brien',Title='Production Lead',Department='Manufacturing',Email='kevin.obrien@vanguardmfg.example.com',Phone='312-555-0303',AccountId=am.get('Vanguard Manufacturing')));
cts.add(new Contact(FirstName='Angela',LastName='Foster',Title='Director of Supply Chain',Department='Logistics',Email='angela.foster@titanlog.example.com',Phone='214-555-0401',AccountId=am.get('Titan Logistics Corp')));
cts.add(new Contact(FirstName='Ryan',LastName='Nguyen',Title='IT Manager',Department='Technology',Email='ryan.nguyen@titanlog.example.com',Phone='214-555-0402',AccountId=am.get('Titan Logistics Corp')));
cts.add(new Contact(FirstName='Stephanie',LastName='Brooks',Title='Fleet Coordinator',Department='Operations',Email='stephanie.brooks@titanlog.example.com',Phone='214-555-0403',AccountId=am.get('Titan Logistics Corp')));
// Mid-Market
cts.add(new Contact(FirstName='Jason',LastName='Rivera',Title='Head of Product',Department='Product',Email='jason.rivera@horizondm.example.com',Phone='310-555-0501',AccountId=am.get('Horizon Digital Media')));
cts.add(new Contact(FirstName='Nicole',LastName='Chang',Title='Marketing Manager',Department='Marketing',Email='nicole.chang@horizondm.example.com',Phone='310-555-0502',AccountId=am.get('Horizon Digital Media')));
cts.add(new Contact(FirstName='Alex',LastName='Patel',Title='Developer',Department='Engineering',Email='alex.patel@horizondm.example.com',Phone='310-555-0503',AccountId=am.get('Horizon Digital Media')));
cts.add(new Contact(FirstName='Rachel',LastName='Adams',Title='Engineering Director',Department='Engineering',Email='rachel.adams@cobalteng.example.com',Phone='206-555-0601',AccountId=am.get('Cobalt Engineering Solutions')));
cts.add(new Contact(FirstName='Brian',LastName='Cooper',Title='Systems Architect',Department='Engineering',Email='brian.cooper@cobalteng.example.com',Phone='206-555-0602',AccountId=am.get('Cobalt Engineering Solutions')));
cts.add(new Contact(FirstName='Laura',LastName='Martinez',Title='VP of Merchandising',Department='Merchandising',Email='laura.martinez@summitretail.example.com',Phone='305-555-0701',AccountId=am.get('Summit Retail Partners')));
cts.add(new Contact(FirstName='Chris',LastName='Henderson',Title='Store Operations Manager',Department='Operations',Email='chris.henderson@summitretail.example.com',Phone='305-555-0702',AccountId=am.get('Summit Retail Partners')));
cts.add(new Contact(FirstName='Diana',LastName='Reeves',Title='CTO',Department='Technology',Email='diana.reeves@novatech.example.com',Phone='617-555-0801',AccountId=am.get('NovaTech Industries')));
cts.add(new Contact(FirstName='Sam',LastName='Ortiz',Title='Product Manager',Department='Product',Email='sam.ortiz@novatech.example.com',Phone='617-555-0802',AccountId=am.get('NovaTech Industries')));
cts.add(new Contact(FirstName='Megan',LastName='Walsh',Title='QA Lead',Department='Engineering',Email='megan.walsh@novatech.example.com',Phone='617-555-0803',AccountId=am.get('NovaTech Industries')));
cts.add(new Contact(FirstName='Peter',LastName='Grant',Title='Managing Partner',Department='Leadership',Email='peter.grant@redwoodcg.example.com',Phone='303-555-0901',AccountId=am.get('Redwood Consulting Group')));
cts.add(new Contact(FirstName='Olivia',LastName='Hughes',Title='Senior Consultant',Department='Consulting',Email='olivia.hughes@redwoodcg.example.com',Phone='303-555-0902',AccountId=am.get('Redwood Consulting Group')));
cts.add(new Contact(FirstName='Nathan',LastName='Ellis',Title='Director of Operations',Department='Operations',Email='nathan.ellis@cascadeenergy.example.com',Phone='206-555-1001',AccountId=am.get('Cascade Energy Services')));
cts.add(new Contact(FirstName='Hannah',LastName='Scott',Title='Project Coordinator',Department='Projects',Email='hannah.scott@cascadeenergy.example.com',Phone='206-555-1002',AccountId=am.get('Cascade Energy Services')));
// SMB
cts.add(new Contact(FirstName='Sophie',LastName='Bennett',Title='Owner / Creative Director',Department='Leadership',Email='sophie.bennett@birchbloom.example.com',Phone='212-555-1101',AccountId=am.get('Birch & Bloom Studio')));
cts.add(new Contact(FirstName='Jake',LastName='Torres',Title='Studio Manager',Department='Operations',Email='jake.torres@birchbloom.example.com',Phone='212-555-1102',AccountId=am.get('Birch & Bloom Studio')));
cts.add(new Contact(FirstName='Carlos',LastName='Vega',Title='Owner',Department='Management',Email='carlos.vega@copperlane.example.com',Phone='512-555-1201',AccountId=am.get('Copper Lane Cafe')));
cts.add(new Contact(FirstName='Mike',LastName='Dawson',Title='General Manager',Department='Management',Email='mike.dawson@evergreen.example.com',Phone='813-555-1301',AccountId=am.get('Evergreen Landscaping Co')));
cts.add(new Contact(FirstName='Tina',LastName='Flores',Title='Office Administrator',Department='Administration',Email='tina.flores@evergreen.example.com',Phone='813-555-1302',AccountId=am.get('Evergreen Landscaping Co')));
cts.add(new Contact(FirstName='Leo',LastName='Fisher',Title='Founder',Department='Leadership',Email='leo.fisher@driftwood.example.com',Phone='415-555-1401',AccountId=am.get('Driftwood Creative Agency')));
cts.add(new Contact(FirstName='Amy',LastName='Russell',Title='Account Manager',Department='Client Services',Email='amy.russell@driftwood.example.com',Phone='415-555-1402',AccountId=am.get('Driftwood Creative Agency')));
cts.add(new Contact(FirstName='Grace',LastName='Miller',Title='Executive Director',Department='Administration',Email='grace.miller@mosaic.example.com',Phone='617-555-1501',AccountId=am.get('Mosaic Learning Center')));
insert cts;
System.debug('Contacts: ' + cts.size());
System.debug('Part 1 complete — run create-test-data-2.apex next');
