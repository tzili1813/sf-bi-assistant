// Part 4 of 4 — Tasks (25) + Events (15) + Summary
Date today = Date.today();
Datetime now = Datetime.now();
List<String> AN = new List<String>{'Meridian Financial Group','Atlas Healthcare Systems','Vanguard Manufacturing','Titan Logistics Corp','Horizon Digital Media','Cobalt Engineering Solutions','Summit Retail Partners','NovaTech Industries','Redwood Consulting Group','Cascade Energy Services','Birch & Bloom Studio','Copper Lane Cafe','Evergreen Landscaping Co','Driftwood Creative Agency','Mosaic Learning Center'};
Map<String,Id> am = new Map<String,Id>();
for (Account a : [SELECT Id,Name FROM Account WHERE Name IN :AN]) am.put(a.Name, a.Id);
Map<String,Id> cm = new Map<String,Id>();
for (Contact c : [SELECT Id,FirstName,LastName FROM Contact WHERE Account.Name IN :AN]) cm.put(c.FirstName+' '+c.LastName, c.Id);
Map<String,Id> om = new Map<String,Id>();
for (Opportunity o : [SELECT Id,Name FROM Opportunity WHERE Account.Name IN :AN]) om.put(o.Name, o.Id);
Map<String,Id> csm = new Map<String,Id>();
for (Case c : [SELECT Id,Subject FROM Case WHERE Account.Name IN :AN]) csm.put(c.Subject, c.Id);

List<Task> tasks = new List<Task>();
// Completed (15)
tasks.add(new Task(Subject='Call — Discovery meeting follow-up',WhoId=cm.get('Sarah Chen'),WhatId=om.get('Meridian — Enterprise Analytics Platform'),Status='Completed',Priority='High',ActivityDate=today.addDays(-14)));
tasks.add(new Task(Subject='Call — Quarterly check-in Atlas Healthcare',WhoId=cm.get('Maria Gonzalez'),WhatId=am.get('Atlas Healthcare Systems'),Status='Completed',Priority='Normal',ActivityDate=today.addDays(-21)));
tasks.add(new Task(Subject='Call — Support escalation follow-up',WhoId=cm.get('Thomas Mueller'),WhatId=csm.get('Database connection pool exhaustion'),Status='Completed',Priority='High',ActivityDate=today.addDays(-30)));
tasks.add(new Task(Subject='Email — Sent proposal to Titan Logistics',WhoId=cm.get('Angela Foster'),WhatId=om.get('Titan — Route Optimization AI'),Status='Completed',Priority='Normal',ActivityDate=today.addDays(-10)));
tasks.add(new Task(Subject='Email — Sent renewal pricing',WhoId=cm.get('Rachel Adams'),WhatId=om.get('Cobalt — Security Audit Suite'),Status='Completed',Priority='Normal',ActivityDate=today.addDays(-7)));
tasks.add(new Task(Subject='Follow up — NovaTech demo feedback',WhoId=cm.get('Diana Reeves'),WhatId=om.get('NovaTech — CI/CD Pipeline Package'),Status='Completed',Priority='Normal',ActivityDate=today.addDays(-12)));
tasks.add(new Task(Subject='Call — Vanguard Mfg check-in',WhoId=cm.get('Linda Jackson'),WhatId=am.get('Vanguard Manufacturing'),Status='Completed',Priority='Normal',ActivityDate=today.addDays(-18)));
tasks.add(new Task(Subject='Email — Case resolution confirmation',WhoId=cm.get('Laura Martinez'),WhatId=csm.get('Payment processing gateway timeout'),Status='Completed',Priority='Normal',ActivityDate=today.addDays(-35)));
tasks.add(new Task(Subject='Call — Pipeline review Horizon Digital',WhoId=cm.get('Jason Rivera'),WhatId=om.get('Horizon — Streaming Infrastructure'),Status='Completed',Priority='Normal',ActivityDate=today.addDays(-5)));
tasks.add(new Task(Subject='Email — Sent onboarding to Cascade',WhoId=cm.get('Nathan Ellis'),WhatId=om.get('Cascade — Monitoring Dashboard'),Status='Completed',Priority='Normal',ActivityDate=today.addDays(-5)));
tasks.add(new Task(Subject='Call — Redwood training follow-up',WhoId=cm.get('Olivia Hughes'),WhatId=am.get('Redwood Consulting Group'),Status='Completed',Priority='Normal',ActivityDate=today.addDays(-25)));
tasks.add(new Task(Subject='Email — Summit POS go-live confirmation',WhoId=cm.get('Chris Henderson'),WhatId=om.get('Summit — POS Integration'),Status='Completed',Priority='High',ActivityDate=today.addDays(-12)));
tasks.add(new Task(Subject='Call — Birch & Bloom license activation',WhoId=cm.get('Sophie Bennett'),WhatId=om.get('Birch & Bloom — Creative Tools License'),Status='Completed',Priority='Normal',ActivityDate=today.addDays(-48)));
tasks.add(new Task(Subject='Email — Evergreen field service training',WhoId=cm.get('Mike Dawson'),WhatId=om.get('Evergreen — Field Service App'),Status='Completed',Priority='Normal',ActivityDate=today.addDays(-38)));
tasks.add(new Task(Subject='Call — Mosaic Learning initial outreach',WhoId=cm.get('Grace Miller'),WhatId=om.get('Mosaic — Student Analytics'),Status='Completed',Priority='Normal',ActivityDate=today.addDays(-8)));
// Open (10)
tasks.add(new Task(Subject='Call — Final pricing discussion',WhoId=cm.get('Sarah Chen'),WhatId=om.get('Meridian — Enterprise Analytics Platform'),Status='Not Started',Priority='High',ActivityDate=today.addDays(2)));
tasks.add(new Task(Subject='Follow up — Awaiting contract signature',WhoId=cm.get('Angela Foster'),WhatId=om.get('Titan — Route Optimization AI'),Status='Not Started',Priority='High',ActivityDate=today.addDays(3)));
tasks.add(new Task(Subject='Email — Send onboarding materials',WhoId=cm.get('Laura Martinez'),WhatId=om.get('Summit — POS Integration'),Status='Not Started',Priority='Normal',ActivityDate=today.addDays(1)));
tasks.add(new Task(Subject='Call — Support check-in after escalation',WhoId=cm.get('Priya Sharma'),WhatId=csm.get('Login authentication failing after SSO update'),Status='Not Started',Priority='High',ActivityDate=today.addDays(1)));
tasks.add(new Task(Subject='Email — Send Atlas QBR agenda',WhoId=cm.get('Maria Gonzalez'),WhatId=am.get('Atlas Healthcare Systems'),Status='In Progress',Priority='Normal',ActivityDate=today.addDays(5)));
tasks.add(new Task(Subject='Call — Cobalt contract review',WhoId=cm.get('Rachel Adams'),WhatId=om.get('Cobalt — Security Audit Suite'),Status='Not Started',Priority='Normal',ActivityDate=today.addDays(4)));
tasks.add(new Task(Subject='Follow up — NovaTech decision update',WhoId=cm.get('Sam Ortiz'),WhatId=om.get('NovaTech — CI/CD Pipeline Package'),Status='Not Started',Priority='Normal',ActivityDate=today.addDays(6)));
tasks.add(new Task(Subject='Call — Cascade kickoff planning',WhoId=cm.get('Hannah Scott'),WhatId=om.get('Cascade — Grid Monitoring Expansion'),Status='Not Started',Priority='Normal',ActivityDate=today.addDays(8)));
tasks.add(new Task(Subject='Email — Driftwood proposal follow-up',WhoId=cm.get('Leo Fisher'),WhatId=om.get('Driftwood — Digital Asset Management'),Status='Not Started',Priority='Normal',ActivityDate=today.addDays(7)));
tasks.add(new Task(Subject='Call — Vanguard predictive maintenance discovery',WhoId=cm.get('Thomas Mueller'),WhatId=om.get('Vanguard — Predictive Maintenance'),Status='Not Started',Priority='Normal',ActivityDate=today.addDays(10)));
insert tasks;
System.debug('Tasks: ' + tasks.size());

// ── Events (15) ──
List<Event> events = new List<Event>();
// Past (8)
events.add(new Event(Subject='Product Demo — Meridian Financial',WhoId=cm.get('Sarah Chen'),WhatId=am.get('Meridian Financial Group'),StartDateTime=now.addDays(-60).addHours(10),EndDateTime=now.addDays(-60).addHours(11),Location='Virtual — Zoom'));
events.add(new Event(Subject='QBR — Atlas Healthcare Q4',WhoId=cm.get('Maria Gonzalez'),WhatId=am.get('Atlas Healthcare Systems'),StartDateTime=now.addDays(-35).addHours(14),EndDateTime=now.addDays(-35).addHours(15),Location='On-site — San Francisco'));
events.add(new Event(Subject='Discovery Call — NovaTech',WhoId=cm.get('Diana Reeves'),WhatId=am.get('NovaTech Industries'),StartDateTime=now.addDays(-22).addHours(11),EndDateTime=now.addDays(-22).addHours(12),Location='Virtual — Zoom'));
events.add(new Event(Subject='Technical Deep Dive — Vanguard Mfg',WhoId=cm.get('Thomas Mueller'),WhatId=am.get('Vanguard Manufacturing'),StartDateTime=now.addDays(-15).addHours(9),EndDateTime=now.addDays(-15).addHours(10),Location='On-site — Chicago'));
events.add(new Event(Subject='Proposal Review — Titan Logistics',WhoId=cm.get('Angela Foster'),WhatId=am.get('Titan Logistics Corp'),StartDateTime=now.addDays(-10).addHours(15),EndDateTime=now.addDays(-10).addHours(16),Location='Virtual — Teams'));
events.add(new Event(Subject='Support Retro — Cobalt Engineering',WhoId=cm.get('Rachel Adams'),WhatId=am.get('Cobalt Engineering Solutions'),StartDateTime=now.addDays(-8).addHours(10),EndDateTime=now.addDays(-8).addHours(11),Location='Virtual — Zoom'));
events.add(new Event(Subject='Training — Evergreen Landscaping',WhoId=cm.get('Mike Dawson'),WhatId=am.get('Evergreen Landscaping Co'),StartDateTime=now.addDays(-5).addHours(13),EndDateTime=now.addDays(-5).addHours(14),Location='Virtual — Zoom'));
events.add(new Event(Subject='Onboarding Kickoff — Cascade Energy',WhoId=cm.get('Nathan Ellis'),WhatId=am.get('Cascade Energy Services'),StartDateTime=now.addDays(-3).addHours(10),EndDateTime=now.addDays(-3).addHours(11),Location='Virtual — Zoom'));
// Upcoming (7)
events.add(new Event(Subject='Contract Review — Titan Logistics',WhoId=cm.get('Angela Foster'),WhatId=am.get('Titan Logistics Corp'),StartDateTime=now.addDays(2).addHours(14),EndDateTime=now.addDays(2).addHours(15),Location='Virtual — Teams'));
events.add(new Event(Subject='Executive Briefing — Meridian Financial',WhoId=cm.get('James Morrison'),WhatId=am.get('Meridian Financial Group'),StartDateTime=now.addDays(7).addHours(10),EndDateTime=now.addDays(7).addHours(11),Location='On-site — New York'));
events.add(new Event(Subject='Onboarding — Summit Retail Phase 2',WhoId=cm.get('Laura Martinez'),WhatId=am.get('Summit Retail Partners'),StartDateTime=now.addDays(8).addHours(11),EndDateTime=now.addDays(8).addHours(12),Location='Virtual — Zoom'));
events.add(new Event(Subject='Demo — Cascade Grid Monitoring',WhoId=cm.get('Hannah Scott'),WhatId=am.get('Cascade Energy Services'),StartDateTime=now.addDays(14).addHours(14),EndDateTime=now.addDays(14).addHours(15),Location='Virtual — Zoom'));
events.add(new Event(Subject='QBR — Atlas Healthcare Q1',WhoId=cm.get('Maria Gonzalez'),WhatId=am.get('Atlas Healthcare Systems'),StartDateTime=now.addDays(25).addHours(10),EndDateTime=now.addDays(25).addHours(11),Location='On-site — San Francisco'));
events.add(new Event(Subject='Roadmap Presentation — NovaTech',WhoId=cm.get('Sam Ortiz'),WhatId=am.get('NovaTech Industries'),StartDateTime=now.addDays(12).addHours(15),EndDateTime=now.addDays(12).addHours(16),Location='Virtual — Zoom'));
events.add(new Event(Subject='Renewal Discussion — Redwood Consulting',WhoId=cm.get('Peter Grant'),WhatId=am.get('Redwood Consulting Group'),StartDateTime=now.addDays(20).addHours(11),EndDateTime=now.addDays(20).addHours(12),Location='Virtual — Teams'));
insert events;
System.debug('Events: ' + events.size());

// Summary
Integer acctCt = [SELECT COUNT() FROM Account WHERE Name IN :AN];
Integer ctCt = [SELECT COUNT() FROM Contact WHERE Account.Name IN :AN];
Integer oppCt = [SELECT COUNT() FROM Opportunity WHERE Account.Name IN :AN];
Integer caseCt = [SELECT COUNT() FROM Case WHERE Account.Name IN :AN];
Integer ccCt = [SELECT COUNT() FROM CaseComment WHERE ParentId IN (SELECT Id FROM Case WHERE Account.Name IN :AN)];
System.debug('');
System.debug('═══════════════════════════════════════════');
System.debug('  PINNACLE SOLUTIONS TEST DATA — COMPLETE  ');
System.debug('═══════════════════════════════════════════');
System.debug('  Accounts:      ' + acctCt);
System.debug('  Contacts:      ' + ctCt);
System.debug('  Opportunities: ' + oppCt);
System.debug('  Cases:         ' + caseCt);
System.debug('  Case Comments: ' + ccCt);
System.debug('  Tasks:         ' + tasks.size());
System.debug('  Events:        ' + events.size());
System.debug('  TOTAL:         ' + (acctCt+ctCt+oppCt+caseCt+ccCt+tasks.size()+events.size()));
System.debug('═══════════════════════════════════════════');
