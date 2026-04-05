// Part 2 of 4 — Opportunities (35)
Date today = Date.today();
Map<String,Id> am = new Map<String,Id>();
for (Account a : [SELECT Id,Name FROM Account WHERE Name IN ('Meridian Financial Group','Atlas Healthcare Systems','Vanguard Manufacturing','Titan Logistics Corp','Horizon Digital Media','Cobalt Engineering Solutions','Summit Retail Partners','NovaTech Industries','Redwood Consulting Group','Cascade Energy Services','Birch & Bloom Studio','Copper Lane Cafe','Evergreen Landscaping Co','Driftwood Creative Agency','Mosaic Learning Center')]) {
    am.put(a.Name, a.Id);
}

List<Opportunity> opps = new List<Opportunity>();
// Closed Won (12)
opps.add(new Opportunity(Name='Meridian — Platform License Renewal',AccountId=am.get('Meridian Financial Group'),StageName='Closed Won',Amount=185000,CloseDate=today.addDays(-150),Probability=100));
opps.add(new Opportunity(Name='Atlas — EHR Integration Module',AccountId=am.get('Atlas Healthcare Systems'),StageName='Closed Won',Amount=220000,CloseDate=today.addDays(-120),Probability=100));
opps.add(new Opportunity(Name='Vanguard — Shop Floor Automation',AccountId=am.get('Vanguard Manufacturing'),StageName='Closed Won',Amount=310000,CloseDate=today.addDays(-105),Probability=100));
opps.add(new Opportunity(Name='Cobalt — DevOps Toolchain',AccountId=am.get('Cobalt Engineering Solutions'),StageName='Closed Won',Amount=68000,CloseDate=today.addDays(-90),Probability=100));
opps.add(new Opportunity(Name='Horizon — Content Platform',AccountId=am.get('Horizon Digital Media'),StageName='Closed Won',Amount=55000,CloseDate=today.addDays(-75),Probability=100));
opps.add(new Opportunity(Name='Redwood — Analytics Suite',AccountId=am.get('Redwood Consulting Group'),StageName='Closed Won',Amount=42000,CloseDate=today.addDays(-60),Probability=100));
opps.add(new Opportunity(Name='Birch & Bloom — Creative Tools License',AccountId=am.get('Birch & Bloom Studio'),StageName='Closed Won',Amount=12000,CloseDate=today.addDays(-50),Probability=100));
opps.add(new Opportunity(Name='Evergreen — Field Service App',AccountId=am.get('Evergreen Landscaping Co'),StageName='Closed Won',Amount=18000,CloseDate=today.addDays(-40),Probability=100));
opps.add(new Opportunity(Name='Titan — Fleet Tracking Module',AccountId=am.get('Titan Logistics Corp'),StageName='Closed Won',Amount=145000,CloseDate=today.addDays(-30),Probability=100));
opps.add(new Opportunity(Name='NovaTech — API Gateway License',AccountId=am.get('NovaTech Industries'),StageName='Closed Won',Amount=38000,CloseDate=today.addDays(-21),Probability=100));
opps.add(new Opportunity(Name='Summit — POS Integration',AccountId=am.get('Summit Retail Partners'),StageName='Closed Won',Amount=52000,CloseDate=today.addDays(-14),Probability=100));
opps.add(new Opportunity(Name='Cascade — Monitoring Dashboard',AccountId=am.get('Cascade Energy Services'),StageName='Closed Won',Amount=35000,CloseDate=today.addDays(-7),Probability=100));

// Closed Lost (7)
opps.add(new Opportunity(Name='Mosaic — LMS Platform',AccountId=am.get('Mosaic Learning Center'),StageName='Closed Lost',Amount=15000,CloseDate=today.addDays(-130),Description='Lost: Budget constraints'));
opps.add(new Opportunity(Name='Copper Lane — POS System',AccountId=am.get('Copper Lane Cafe'),StageName='Closed Lost',Amount=8500,CloseDate=today.addDays(-110),Description='Lost: Chose competitor (Toast POS)'));
opps.add(new Opportunity(Name='Driftwood — Project Management Suite',AccountId=am.get('Driftwood Creative Agency'),StageName='Closed Lost',Amount=22000,CloseDate=today.addDays(-85),Description='Lost: Went dark after proposal'));
opps.add(new Opportunity(Name='Atlas — Telehealth Expansion',AccountId=am.get('Atlas Healthcare Systems'),StageName='Closed Lost',Amount=175000,CloseDate=today.addDays(-65),Description='Lost: Chose in-house development'));
opps.add(new Opportunity(Name='Horizon — Ad Analytics Add-on',AccountId=am.get('Horizon Digital Media'),StageName='Closed Lost',Amount=32000,CloseDate=today.addDays(-45),Description='Lost: Budget cut'));
opps.add(new Opportunity(Name='Vanguard — QC Module',AccountId=am.get('Vanguard Manufacturing'),StageName='Closed Lost',Amount=95000,CloseDate=today.addDays(-25),Description='Lost: Lost to competitor (Siemens)'));
opps.add(new Opportunity(Name='Redwood — Training Platform',AccountId=am.get('Redwood Consulting Group'),StageName='Closed Lost',Amount=28000,CloseDate=today.addDays(-10),Description='Lost: Chose open-source alternative'));

// Negotiation (3)
opps.add(new Opportunity(Name='Meridian — Enterprise Analytics Platform',AccountId=am.get('Meridian Financial Group'),StageName='Negotiation/Review',Amount=350000,CloseDate=today.addDays(18),Probability=75,Description='Largest pending deal — final contract review'));
opps.add(new Opportunity(Name='Titan — Route Optimization AI',AccountId=am.get('Titan Logistics Corp'),StageName='Negotiation/Review',Amount=125000,CloseDate=today.addDays(10),Probability=70));
opps.add(new Opportunity(Name='Cobalt — Security Audit Suite',AccountId=am.get('Cobalt Engineering Solutions'),StageName='Negotiation/Review',Amount=78000,CloseDate=today.addDays(25),Probability=65));

// Proposal (4)
opps.add(new Opportunity(Name='Atlas — Patient Portal Upgrade',AccountId=am.get('Atlas Healthcare Systems'),StageName='Proposal/Price Quote',Amount=195000,CloseDate=today.addDays(35),Probability=50));
opps.add(new Opportunity(Name='NovaTech — CI/CD Pipeline Package',AccountId=am.get('NovaTech Industries'),StageName='Proposal/Price Quote',Amount=62000,CloseDate=today.addDays(28),Probability=55));
opps.add(new Opportunity(Name='Summit — Inventory Analytics',AccountId=am.get('Summit Retail Partners'),StageName='Proposal/Price Quote',Amount=47000,CloseDate=today.addDays(40),Probability=45));
opps.add(new Opportunity(Name='Horizon — Streaming Infrastructure',AccountId=am.get('Horizon Digital Media'),StageName='Proposal/Price Quote',Amount=88000,CloseDate=today.addDays(20),Probability=40,Description='Deal slipped from last month'));

// Qualification (4)
opps.add(new Opportunity(Name='Vanguard — Predictive Maintenance',AccountId=am.get('Vanguard Manufacturing'),StageName='Qualification',Amount=240000,CloseDate=today.addDays(55),Probability=25));
opps.add(new Opportunity(Name='Cascade — Grid Monitoring Expansion',AccountId=am.get('Cascade Energy Services'),StageName='Qualification',Amount=72000,CloseDate=today.addDays(45),Probability=30));
opps.add(new Opportunity(Name='Driftwood — Digital Asset Management',AccountId=am.get('Driftwood Creative Agency'),StageName='Qualification',Amount=25000,CloseDate=today.addDays(50),Probability=20));
opps.add(new Opportunity(Name='Birch & Bloom — E-commerce Integration',AccountId=am.get('Birch & Bloom Studio'),StageName='Qualification',Amount=16000,CloseDate=today.addDays(38),Probability=25,Description='Deal slipped from Proposal stage'));

// Prospecting (5)
opps.add(new Opportunity(Name='Meridian — Compliance Automation',AccountId=am.get('Meridian Financial Group'),StageName='Prospecting',Amount=210000,CloseDate=today.addDays(80),Probability=10));
opps.add(new Opportunity(Name='Atlas — Lab Results Integration',AccountId=am.get('Atlas Healthcare Systems'),StageName='Prospecting',Amount=130000,CloseDate=today.addDays(75),Probability=10));
opps.add(new Opportunity(Name='Evergreen — Client Portal',AccountId=am.get('Evergreen Landscaping Co'),StageName='Prospecting',Amount=14000,CloseDate=today.addDays(65),Probability=10));
opps.add(new Opportunity(Name='Mosaic — Student Analytics',AccountId=am.get('Mosaic Learning Center'),StageName='Prospecting',Amount=19000,CloseDate=today.addDays(70),Probability=10));
opps.add(new Opportunity(Name='NovaTech — Microservices Framework',AccountId=am.get('NovaTech Industries'),StageName='Prospecting',Amount=85000,CloseDate=today.addDays(60),Probability=10));

insert opps;
System.debug('Opportunities: ' + opps.size());
System.debug('Part 2 complete — run create-test-data-3.apex next');
