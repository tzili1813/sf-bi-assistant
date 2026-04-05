// Leads (25) — Pinnacle Solutions inbound/outbound pipeline
// Run via: sf apex run --file scripts/create-test-data-leads.apex --target-org dev-org

// Clean up existing test leads
List<String> testCompanies = new List<String>{
    'Apex Dynamics','Brightpath Analytics','CloudNine Software',
    'DataForge Systems','EchoPoint Media','FrostByte Security',
    'GreenLeaf Biotech','HarborView Insurance','IronClad Compliance',
    'JetStream Aviation','KineticWorks','Luminary Health',
    'MavenBridge Consulting','Northwind Logistics','OakRidge Financial',
    'PrismView Technologies','QuartzNet Solutions','RiverStone Properties',
    'SilverLine Retail','TrueNorth Analytics','UrbanGrid Energy',
    'VelocityStack','WildBloom Events','XenonLabs','ZenithPoint Capital'
};
delete [SELECT Id FROM Lead WHERE Company IN :testCompanies];
System.debug('Existing test leads cleaned up.');

Date today = Date.today();

List<Lead> leads = new List<Lead>();

// ── Hot leads (5) — high intent, recent activity ──
leads.add(new Lead(FirstName='Derek',LastName='Callahan',Company='Apex Dynamics',
    Title='VP of Engineering',Industry='Technology',
    Email='derek.callahan@apexdynamics.example.com',Phone='408-555-2001',
    LeadSource='Web',Status='Working - Contacted',Rating='Hot',
    NumberOfEmployees=320,AnnualRevenue=22000000,
    Description='Requested demo after attending webinar. Very engaged — asked about API integrations and SSO.'));

leads.add(new Lead(FirstName='Vanessa',LastName='Liu',Company='Brightpath Analytics',
    Title='Chief Data Officer',Industry='Technology',
    Email='vanessa.liu@brightpath.example.com',Phone='212-555-2002',
    LeadSource='Partner Referral',Status='Working - Contacted',Rating='Hot',
    NumberOfEmployees=180,AnnualRevenue=15000000,
    Description='Referred by Redwood Consulting. Currently evaluating 3 vendors. Decision expected in 2 weeks.'));

leads.add(new Lead(FirstName='Marcus',LastName='Reed',Company='CloudNine Software',
    Title='Director of Operations',Industry='Technology',
    Email='marcus.reed@cloudnine.example.com',Phone='617-555-2003',
    LeadSource='Web',Status='Working - Contacted',Rating='Hot',
    NumberOfEmployees=450,AnnualRevenue=28000000,
    Description='Downloaded whitepaper and pricing guide same day. Scheduled intro call for this week.'));

leads.add(new Lead(FirstName='Alicia',LastName='Torres',Company='DataForge Systems',
    Title='CTO',Industry='Manufacturing',
    Email='alicia.torres@dataforge.example.com',Phone='312-555-2004',
    LeadSource='Trade Show',Status='Working - Contacted',Rating='Hot',
    NumberOfEmployees=800,AnnualRevenue=45000000,
    Description='Met at SaaS Connect conference. Needs shop floor analytics — similar to Vanguard deal.'));

leads.add(new Lead(FirstName='Jordan',LastName='Blake',Company='EchoPoint Media',
    Title='Head of Digital',Industry='Media',
    Email='jordan.blake@echopoint.example.com',Phone='310-555-2005',
    LeadSource='Web',Status='Working - Contacted',Rating='Hot',
    NumberOfEmployees=210,AnnualRevenue=18000000,
    Description='Inbound from Google Ads campaign. Wants content analytics platform — budget approved for Q2.'));

// ── Warm leads (10) — interested but earlier stage ──
leads.add(new Lead(FirstName='Priya',LastName='Nair',Company='FrostByte Security',
    Title='Security Operations Manager',Industry='Technology',
    Email='priya.nair@frostbyte.example.com',Phone='206-555-2006',
    LeadSource='Web',Status='Open - Not Contacted',Rating='Warm',
    NumberOfEmployees=150,AnnualRevenue=12000000,
    Description='Downloaded security compliance checklist. No response to follow-up email yet.'));

leads.add(new Lead(FirstName='Ethan',LastName='Morales',Company='GreenLeaf Biotech',
    Title='Lab Director',Industry='Biotechnology',
    Email='ethan.morales@greenleaf.example.com',Phone='858-555-2007',
    LeadSource='Partner Referral',Status='Open - Not Contacted',Rating='Warm',
    NumberOfEmployees=95,AnnualRevenue=8000000,
    Description='Referral from Atlas Healthcare contact. Interested in lab data management.'));

leads.add(new Lead(FirstName='Catherine',LastName='Wells',Company='HarborView Insurance',
    Title='VP of Claims',Industry='Insurance',
    Email='catherine.wells@harborview.example.com',Phone='305-555-2008',
    LeadSource='Web',Status='Working - Contacted',Rating='Warm',
    NumberOfEmployees=620,AnnualRevenue=35000000,
    Description='Attended product webinar. Asked questions about claims workflow automation.'));

leads.add(new Lead(FirstName='Omar',LastName='Hassan',Company='IronClad Compliance',
    Title='Compliance Director',Industry='Financial Services',
    Email='omar.hassan@ironclad.example.com',Phone='212-555-2009',
    LeadSource='Trade Show',Status='Working - Contacted',Rating='Warm',
    NumberOfEmployees=110,AnnualRevenue=9500000,
    Description='Exchanged cards at FinTech Summit. Interested in audit trail features.'));

leads.add(new Lead(FirstName='Sierra',LastName='Dawkins',Company='JetStream Aviation',
    Title='Fleet Manager',Industry='Transportation',
    Email='sierra.dawkins@jetstream.example.com',Phone='214-555-2010',
    LeadSource='Web',Status='Open - Not Contacted',Rating='Warm',
    NumberOfEmployees=280,AnnualRevenue=20000000,
    Description='Filled out contact form asking about fleet tracking. Similar use case to Titan Logistics.'));

leads.add(new Lead(FirstName='Trevor',LastName='Nguyen',Company='KineticWorks',
    Title='Operations Lead',Industry='Manufacturing',
    Email='trevor.nguyen@kineticworks.example.com',Phone='503-555-2011',
    LeadSource='Web',Status='Working - Contacted',Rating='Warm',
    NumberOfEmployees=175,AnnualRevenue=11000000,
    Description='Requested case study on manufacturing automation. Sent Vanguard success story.'));

leads.add(new Lead(FirstName='Elena',LastName='Petrova',Company='Luminary Health',
    Title='Practice Administrator',Industry='Healthcare',
    Email='elena.petrova@luminaryhealth.example.com',Phone='415-555-2012',
    LeadSource='Partner Referral',Status='Open - Not Contacted',Rating='Warm',
    NumberOfEmployees=60,AnnualRevenue=4500000,
    Description='Small clinic group looking for patient scheduling solution. Referral from Atlas Healthcare.'));

leads.add(new Lead(FirstName='Ryan',LastName='Whitfield',Company='MavenBridge Consulting',
    Title='Managing Director',Industry='Consulting',
    Email='ryan.whitfield@mavenbridge.example.com',Phone='303-555-2013',
    LeadSource='Trade Show',Status='Working - Contacted',Rating='Warm',
    NumberOfEmployees=130,AnnualRevenue=10000000,
    Description='Met at Dreamforce. Wants analytics for consulting practice. Similar to Redwood deal.'));

leads.add(new Lead(FirstName='Jasmine',LastName='Carter',Company='Northwind Logistics',
    Title='Supply Chain Analyst',Industry='Transportation',
    Email='jasmine.carter@northwind.example.com',Phone='713-555-2014',
    LeadSource='Web',Status='Open - Not Contacted',Rating='Warm',
    NumberOfEmployees=340,AnnualRevenue=24000000,
    Description='Downloaded route optimization ROI calculator. High-fit prospect.'));

leads.add(new Lead(FirstName='Blake',LastName='Simmons',Company='OakRidge Financial',
    Title='Chief Risk Officer',Industry='Financial Services',
    Email='blake.simmons@oakridge.example.com',Phone='704-555-2015',
    LeadSource='Web',Status='Working - Contacted',Rating='Warm',
    NumberOfEmployees=500,AnnualRevenue=30000000,
    Description='Registered for upcoming compliance webinar. Pre-event survey shows strong interest.'));

// ── Cold leads (10) — early stage or unresponsive ──
leads.add(new Lead(FirstName='Natalie',LastName='Fox',Company='PrismView Technologies',
    Title='Product Manager',Industry='Technology',
    Email='natalie.fox@prismview.example.com',Phone='512-555-2016',
    LeadSource='Web',Status='Open - Not Contacted',Rating='Cold',
    NumberOfEmployees=40,AnnualRevenue=3000000,
    Description='Downloaded free trial. No login activity after signup.'));

leads.add(new Lead(FirstName='Ian',LastName='Crawford',Company='QuartzNet Solutions',
    Title='IT Administrator',Industry='Technology',
    Email='ian.crawford@quartznet.example.com',Phone='469-555-2017',
    LeadSource='Web',Status='Open - Not Contacted',Rating='Cold',
    NumberOfEmployees=25,AnnualRevenue=1800000,
    Description='Visited pricing page 3 times but no form fill. Identified via intent data.'));

leads.add(new Lead(FirstName='Monica',LastName='Reyes',Company='RiverStone Properties',
    Title='Office Manager',Industry='Real Estate',
    Email='monica.reyes@riverstone.example.com',Phone='602-555-2018',
    LeadSource='Other',Status='Open - Not Contacted',Rating='Cold',
    NumberOfEmployees=15,AnnualRevenue=900000,
    Description='Cold outbound — no response to 3 emails. May not be ICP.'));

leads.add(new Lead(FirstName='Kevin',LastName='Park',Company='SilverLine Retail',
    Title='Store Director',Industry='Retail',
    Email='kevin.park@silverline.example.com',Phone='813-555-2019',
    LeadSource='Trade Show',Status='Open - Not Contacted',Rating='Cold',
    NumberOfEmployees=200,AnnualRevenue=14000000,
    Description='Scanned badge at trade show booth but did not engage in conversation.'));

leads.add(new Lead(FirstName='Samantha',LastName='Diaz',Company='TrueNorth Analytics',
    Title='Data Analyst',Industry='Technology',
    Email='samantha.diaz@truenorth.example.com',Phone='206-555-2020',
    LeadSource='Web',Status='Open - Not Contacted',Rating='Cold',
    NumberOfEmployees=30,AnnualRevenue=2200000,
    Description='Blog subscriber. Opened 2 newsletters but no product engagement.'));

leads.add(new Lead(FirstName='Andre',LastName='Thompson',Company='UrbanGrid Energy',
    Title='Sustainability Coordinator',Industry='Energy',
    Email='andre.thompson@urbangrid.example.com',Phone='720-555-2021',
    LeadSource='Web',Status='Open - Not Contacted',Rating='Cold',
    NumberOfEmployees=85,AnnualRevenue=6000000,
    Description='Downloaded sustainability report. Unlikely buyer — wrong persona.'));

leads.add(new Lead(FirstName='Rachel',LastName='Kim',Company='VelocityStack',
    Title='DevOps Engineer',Industry='Technology',
    Email='rachel.kim@velocitystack.example.com',Phone='650-555-2022',
    LeadSource='Web',Status='Open - Not Contacted',Rating='Cold',
    NumberOfEmployees=55,AnnualRevenue=4000000,
    Description='GitHub star on our open-source tool. Individual contributor — no buying authority.'));

leads.add(new Lead(FirstName='Daniel',LastName='Marsh',Company='WildBloom Events',
    Title='Owner',Industry='Entertainment',
    Email='daniel.marsh@wildbloom.example.com',Phone='615-555-2023',
    LeadSource='Other',Status='Open - Not Contacted',Rating='Cold',
    NumberOfEmployees=12,AnnualRevenue=750000,
    Description='Cold outbound. Too small for our platform — better fit for SMB tier if it launches.'));

leads.add(new Lead(FirstName='Lisa',LastName='Cheng',Company='XenonLabs',
    Title='Research Director',Industry='Biotechnology',
    Email='lisa.cheng@xenonlabs.example.com',Phone='858-555-2024',
    LeadSource='Partner Referral',Status='Open - Not Contacted',Rating='Cold',
    NumberOfEmployees=70,AnnualRevenue=5500000,
    Description='Referral from GreenLeaf. Early-stage research lab — 6-12 month buying cycle.'));

leads.add(new Lead(FirstName='Victor',LastName='Santos',Company='ZenithPoint Capital',
    Title='Managing Partner',Industry='Financial Services',
    Email='victor.santos@zenithpoint.example.com',Phone='212-555-2025',
    LeadSource='Trade Show',Status='Open - Not Contacted',Rating='Cold',
    NumberOfEmployees=45,AnnualRevenue=3500000,
    Description='Brief conversation at FinTech Summit. Seemed mildly interested but no follow-up.'));

insert leads;

System.debug('');
System.debug('═══════════════════════════════════════════');
System.debug('  LEADS CREATED: ' + leads.size());
System.debug('═══════════════════════════════════════════');
System.debug('  Hot:  5');
System.debug('  Warm: 10');
System.debug('  Cold: 10');
System.debug('═══════════════════════════════════════════');
