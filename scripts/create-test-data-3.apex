// Part 3 of 4 — Cases (30) + CaseComments (20)
List<String> AN = new List<String>{'Meridian Financial Group','Atlas Healthcare Systems','Vanguard Manufacturing','Titan Logistics Corp','Horizon Digital Media','Cobalt Engineering Solutions','Summit Retail Partners','NovaTech Industries','Redwood Consulting Group','Cascade Energy Services','Birch & Bloom Studio','Copper Lane Cafe','Evergreen Landscaping Co','Driftwood Creative Agency','Mosaic Learning Center'};
Map<String,Id> am = new Map<String,Id>();
for (Account a : [SELECT Id,Name FROM Account WHERE Name IN :AN]) am.put(a.Name, a.Id);
Map<String,Id> cm = new Map<String,Id>();
for (Contact c : [SELECT Id,FirstName,LastName FROM Contact WHERE Account.Name IN :AN]) cm.put(c.FirstName+' '+c.LastName, c.Id);

List<Case> cases = new List<Case>();
// High / New (3) — escalated
cases.add(new Case(Subject='Login authentication failing after SSO update',Description='Multiple users unable to authenticate since SSO config change.',AccountId=am.get('Meridian Financial Group'),ContactId=cm.get('Priya Sharma'),Priority='High',Status='New',Origin='Phone',Type='Problem',IsEscalated=true));
cases.add(new Case(Subject='Data sync delay between EHR modules',Description='Patient records taking 15+ min to sync. Critical for patient safety.',AccountId=am.get('Atlas Healthcare Systems'),ContactId=cm.get('Emily Taylor'),Priority='High',Status='New',Origin='Phone',Type='Problem',IsEscalated=true));
cases.add(new Case(Subject='Production line dashboard showing stale data',Description='Real-time metrics frozen since yesterday.',AccountId=am.get('Vanguard Manufacturing'),ContactId=cm.get('Linda Jackson'),Priority='High',Status='New',Origin='Email',Type='Problem',IsEscalated=true));
// High / Working (2)
cases.add(new Case(Subject='API rate limiting affecting integration',Description='Third-party API hitting rate limits during peak hours.',AccountId=am.get('Titan Logistics Corp'),ContactId=cm.get('Ryan Nguyen'),Priority='High',Status='Working',Origin='Web',Type='Problem'));
cases.add(new Case(Subject='Report export timing out for large datasets',Description='Reports with >10k rows fail to export.',AccountId=am.get('Atlas Healthcare Systems'),ContactId=cm.get('Robert Kim'),Priority='High',Status='Working',Origin='Email',Type='Problem'));
// High / Closed (3)
cases.add(new Case(Subject='Critical security patch deployment failed',Description='v2.3.1 patch caused service interruption. Rolled back and redeployed.',AccountId=am.get('Meridian Financial Group'),ContactId=cm.get('James Morrison'),Priority='High',Status='Closed',Origin='Phone',Type='Problem'));
cases.add(new Case(Subject='Database connection pool exhaustion',Description='Connection pool maxing out under load. Fixed.',AccountId=am.get('Vanguard Manufacturing'),ContactId=cm.get('Thomas Mueller'),Priority='High',Status='Closed',Origin='Web',Type='Problem'));
cases.add(new Case(Subject='Payment processing gateway timeout',Description='SSL cert expired on payment gateway. Renewed.',AccountId=am.get('Summit Retail Partners'),ContactId=cm.get('Laura Martinez'),Priority='High',Status='Closed',Origin='Phone',Type='Problem'));
// Medium / New (4)
cases.add(new Case(Subject='Unable to assign user permissions in admin panel',Description='Admin getting insufficient privileges error.',AccountId=am.get('Cobalt Engineering Solutions'),ContactId=cm.get('Rachel Adams'),Priority='Medium',Status='New',Origin='Web',Type='Problem'));
cases.add(new Case(Subject='Dashboard widgets not loading on mobile',Description='iOS app showing blank widgets. Android works fine.',AccountId=am.get('Horizon Digital Media'),ContactId=cm.get('Nicole Chang'),Priority='Medium',Status='New',Origin='Chat',Type='Problem'));
cases.add(new Case(Subject='Feature request: bulk import from CSV',Description='Customer needs to import 5000+ product records monthly.',AccountId=am.get('NovaTech Industries'),ContactId=cm.get('Sam Ortiz'),Priority='Medium',Status='New',Origin='Email',Type='Feature Request'));
cases.add(new Case(Subject='Scheduled report delivery not working',Description='Weekly automated reports stopped being delivered.',AccountId=am.get('Atlas Healthcare Systems'),ContactId=cm.get('Marcus Williams'),Priority='Medium',Status='New',Origin='Email',Type='Problem'));
// Medium / Working (2)
cases.add(new Case(Subject='Custom field validation rule too restrictive',Description='Users unable to save records with valid data.',AccountId=am.get('Redwood Consulting Group'),ContactId=cm.get('Olivia Hughes'),Priority='Medium',Status='Working',Origin='Web',Type='Problem'));
cases.add(new Case(Subject='Integration sync failing for new object type',Description='Custom object not syncing to external system.',AccountId=am.get('Cascade Energy Services'),ContactId=cm.get('Nathan Ellis'),Priority='Medium',Status='Working',Origin='Email',Type='Problem'));
// Medium / Closed (8)
cases.add(new Case(Subject='Search results returning wrong record types',Description='Global search including archived records. Fixed.',AccountId=am.get('Meridian Financial Group'),ContactId=cm.get('David Park'),Priority='Medium',Status='Closed',Origin='Chat',Type='Problem'));
cases.add(new Case(Subject='Email template formatting broken in Outlook',Description='HTML emails rendering incorrectly. Fixed CSS.',AccountId=am.get('Horizon Digital Media'),ContactId=cm.get('Jason Rivera'),Priority='Medium',Status='Closed',Origin='Email',Type='Problem'));
cases.add(new Case(Subject='Billing discrepancy on last invoice',Description='Billed for 50 seats but only using 42. Issued credit.',AccountId=am.get('Cobalt Engineering Solutions'),ContactId=cm.get('Brian Cooper'),Priority='Medium',Status='Closed',Origin='Phone',Type='Problem'));
cases.add(new Case(Subject='User training request for new features',Description='Team of 15 needs training on v3.0. Scheduled sessions.',AccountId=am.get('Titan Logistics Corp'),ContactId=cm.get('Angela Foster'),Priority='Medium',Status='Closed',Origin='Email',Type='Question'));
cases.add(new Case(Subject='Data migration assistance needed',Description='Migrating from legacy system. Provided toolkit.',AccountId=am.get('Vanguard Manufacturing'),ContactId=cm.get('Kevin O\'Brien'),Priority='Medium',Status='Closed',Origin='Web',Type='Question'));
cases.add(new Case(Subject='SSO configuration for Azure AD',Description='SAML SSO with Azure AD. Completed and tested.',AccountId=am.get('NovaTech Industries'),ContactId=cm.get('Diana Reeves'),Priority='Medium',Status='Closed',Origin='Web',Type='Question'));
cases.add(new Case(Subject='Performance optimization for large queries',Description='Slow queries on tables with >1M rows. Added indexes.',AccountId=am.get('Atlas Healthcare Systems'),ContactId=cm.get('Maria Gonzalez'),Priority='Medium',Status='Closed',Origin='Email',Type='Problem'));
cases.add(new Case(Subject='Workflow automation rule not triggering',Description='Auto-assignment rule stopped after field rename. Fixed.',AccountId=am.get('Evergreen Landscaping Co'),ContactId=cm.get('Mike Dawson'),Priority='Medium',Status='Closed',Origin='Chat',Type='Problem'));
// Low / New (2)
cases.add(new Case(Subject='Request for dark mode UI option',Description='Multiple users requesting dark mode.',AccountId=am.get('Driftwood Creative Agency'),ContactId=cm.get('Leo Fisher'),Priority='Low',Status='New',Origin='Web',Type='Feature Request'));
cases.add(new Case(Subject='Minor typo on settings page',Description='Label says Notifcation instead of Notification.',AccountId=am.get('Birch & Bloom Studio'),ContactId=cm.get('Sophie Bennett'),Priority='Low',Status='New',Origin='Chat',Type='Problem'));
// Low / Closed (6)
cases.add(new Case(Subject='How to export data to Excel',Description='Guided customer through export feature.',AccountId=am.get('Mosaic Learning Center'),ContactId=cm.get('Grace Miller'),Priority='Low',Status='Closed',Origin='Phone',Type='Question'));
cases.add(new Case(Subject='Password reset request',Description='User locked out. Reset password and enabled 2FA.',AccountId=am.get('Copper Lane Cafe'),ContactId=cm.get('Carlos Vega'),Priority='Low',Status='Closed',Origin='Phone',Type='Question'));
cases.add(new Case(Subject='Updating company logo in application',Description='Provided instructions for admin portal.',AccountId=am.get('Driftwood Creative Agency'),ContactId=cm.get('Amy Russell'),Priority='Low',Status='Closed',Origin='Email',Type='Question'));
cases.add(new Case(Subject='Calendar integration with Google Workspace',Description='Set up bidirectional calendar sync.',AccountId=am.get('Birch & Bloom Studio'),ContactId=cm.get('Jake Torres'),Priority='Low',Status='Closed',Origin='Web',Type='Question'));
cases.add(new Case(Subject='Request for additional report template',Description='Created custom monthly utilization report.',AccountId=am.get('Evergreen Landscaping Co'),ContactId=cm.get('Tina Flores'),Priority='Low',Status='Closed',Origin='Email',Type='Feature Request'));
cases.add(new Case(Subject='Mobile app notification preferences',Description='Guided through push notification settings.',AccountId=am.get('Redwood Consulting Group'),ContactId=cm.get('Peter Grant'),Priority='Low',Status='Closed',Origin='Chat',Type='Question'));

insert cases;
Map<String,Id> csm = new Map<String,Id>();
for (Case c : cases) csm.put(c.Subject, c.Id);
System.debug('Cases: ' + cases.size());

// ── CaseComments (20) ──
List<CaseComment> ccs = new List<CaseComment>();
ccs.add(new CaseComment(ParentId=csm.get('Login authentication failing after SSO update'),CommentBody='Escalated to engineering. Affecting 200+ users. P1.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Login authentication failing after SSO update'),CommentBody='Root cause: SAML assertion clock skew after server migration. Fix deployed.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Data sync delay between EHR modules'),CommentBody='Investigating message queue backlog. 15k messages stuck in dead letter queue.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Data sync delay between EHR modules'),CommentBody='Issue started after Saturday maintenance window. Correlating with deploy logs.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Production line dashboard showing stale data'),CommentBody='Waiting on customer to provide VPN access for remote diagnostics.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('API rate limiting affecting integration'),CommentBody='Implemented request queuing with exponential backoff. Testing this afternoon.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('API rate limiting affecting integration'),CommentBody='Customer confirmed: peak hour errors reduced from 340/hr to 2/hr.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Report export timing out for large datasets'),CommentBody='Reproduced: export hangs at 10,001 rows. Working on chunked export.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Critical security patch deployment failed'),CommentBody='Initial deploy caused 502 errors on 3 of 8 servers. Rolled back in 12 min.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Critical security patch deployment failed'),CommentBody='Root cause: incompatible dependency. Fixed and redeployed successfully.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Database connection pool exhaustion'),CommentBody='Increased pool from 50 to 150. Added connection timeout monitoring.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Database connection pool exhaustion'),CommentBody='Deployed hotfix v2.3.1 with optimized caching. Usage dropped 60%.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Payment processing gateway timeout'),CommentBody='SSL cert expired on payment processor side. Contacted vendor.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Payment processing gateway timeout'),CommentBody='Cert renewed. Payment flow restored. Added cert expiry monitoring.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Billing discrepancy on last invoice'),CommentBody='Confirmed: 8 seats deprovisioned but billing not updated. Issuing $4,800 credit.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Performance optimization for large queries'),CommentBody='Added composite indexes. Query time reduced from 45s to 1.2s.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Workflow automation rule not triggering'),CommentBody='Field API name changed during last release. Updated rule criteria.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Custom field validation rule too restrictive'),CommentBody='Scheduled follow-up call to verify fix in sandbox.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('SSO configuration for Azure AD'),CommentBody='SAML config complete. Tested with 3 users. All authenticating via Azure AD.',IsPublished=false));
ccs.add(new CaseComment(ParentId=csm.get('Feature request: bulk import from CSV'),CommentBody='Product team confirmed: CSV bulk import planned for Q3. Customer on beta waitlist.',IsPublished=false));
insert ccs;
System.debug('CaseComments: ' + ccs.size());
System.debug('Part 3 complete — run create-test-data-4.apex next');
