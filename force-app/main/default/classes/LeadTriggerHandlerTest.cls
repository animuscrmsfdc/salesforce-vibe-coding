@IsTest
private class LeadTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        // Insert a lead that will serve as the baseline for update scenarios.
        // Industry is required by the handler; LeadSource is intentionally set here
        // so we can clear it in the update test.
        Lead baseLead = new Lead(
            LastName     = 'TestSetup Lead',
            Company      = 'Test Company',
            Status       = 'Open - Not Contacted',
            Industry     = 'Agriculture',
            LeadSource   = 'Web'
        );
        insert baseLead;
    }

    // -----------------------------------------------------------------------
    // Scenario 1 — beforeInsert: blank LeadSource is defaulted to 'Other'
    // -----------------------------------------------------------------------
    @IsTest
    static void insertLead_blankLeadSource_defaultsToOther() {
        Lead l = new Lead(
            LastName   = 'No Source Lead',
            Company    = 'Acme',
            Status     = 'Open - Not Contacted',
            Industry   = 'Agriculture',
            LeadSource = null
        );

        Test.startTest();
        insert l;
        Test.stopTest();

        Lead inserted = [SELECT LeadSource FROM Lead WHERE Id = :l.Id];
        System.assertEquals('Other', inserted.LeadSource, 'Blank LeadSource should be defaulted to Other');
    }

    // -----------------------------------------------------------------------
    // Scenario 2 — beforeInsert: blank Industry triggers addError
    // -----------------------------------------------------------------------
    @IsTest
    static void insertLead_blankIndustry_failsWithError() {
        Lead l = new Lead(
            LastName   = 'No Industry Lead',
            Company    = 'Acme',
            Status     = 'Open - Not Contacted',
            Industry   = null,
            LeadSource = 'Web'
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();

        System.assert(!result.isSuccess(), 'Insert should fail when Industry is blank');
        System.assert(
            result.getErrors()[0].getMessage().contains('Industry field cannot be blank'),
            'Error message should mention the Industry field'
        );
    }

    // -----------------------------------------------------------------------
    // Scenario 3 — afterInsert: Task created and recursive lead logic executes
    // -----------------------------------------------------------------------
    @IsTest
    static void insertLead_allFieldsPopulated_taskCreatedAndRecursionControlled() {
        LeadTriggerHandler.alreadyExecuted = false;

        Lead l = new Lead(
            LastName   = 'Full Lead',
            Company    = 'Acme',
            Status     = 'Open - Not Contacted',
            Industry   = 'Agriculture',
            LeadSource = 'Web'
        );

        Test.startTest();
        insert l;
        Test.stopTest();

        List<Task> tasks = [SELECT Subject, WhoId FROM Task WHERE WhoId = :l.Id];
        System.assertEquals(1, tasks.size(), 'Exactly one follow-up Task should be created for the lead');
        System.assertEquals('Follow up on Lead Status', tasks[0].Subject, 'Task Subject should match handler logic');

        // The handler inserts one additional lead on first execution; alreadyExecuted prevents further recursion
        System.assert(LeadTriggerHandler.alreadyExecuted, 'alreadyExecuted flag should be true after first insert');
    }

    // -----------------------------------------------------------------------
    // Scenario 4 — beforeUpdate: direct close from 'Open - Not Contacted' fires addError
    // -----------------------------------------------------------------------
    @IsTest
    static void updateLead_directCloseFromOpen_failsWithError() {
        Lead l = [SELECT Id, Status FROM Lead WHERE LastName = 'TestSetup Lead' LIMIT 1];

        Test.startTest();
        l.Status = 'Closed - Converted';
        Database.SaveResult result = Database.update(l, false);
        Test.stopTest();

        System.assert(!result.isSuccess(), 'Update should fail when closing directly from Open - Not Contacted');
        System.assert(
            result.getErrors()[0].getMessage().contains('cannot directly close'),
            'Error message should mention direct close restriction'
        );
    }

    // -----------------------------------------------------------------------
    // Scenario 5 — beforeUpdate: clearing LeadSource defaults it back to 'Other'
    // -----------------------------------------------------------------------
    @IsTest
    static void updateLead_clearLeadSource_defaultsToOther() {
        Lead l = [SELECT Id, LeadSource FROM Lead WHERE LastName = 'TestSetup Lead' LIMIT 1];

        Test.startTest();
        l.LeadSource = null;
        update l;
        Test.stopTest();

        Lead updated = [SELECT LeadSource FROM Lead WHERE Id = :l.Id];
        System.assertEquals('Other', updated.LeadSource, 'Cleared LeadSource on update should be defaulted to Other');
    }

    // -----------------------------------------------------------------------
    // Scenario 6 — bulk insert: 200 leads with blank LeadSource all get 'Other'
    // -----------------------------------------------------------------------
    @IsTest
    static void bulkInsert_200Leads_allDefaultedToOther() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            leads.add(new Lead(
                LastName   = 'Bulk Lead ' + i,
                Company    = 'Bulk Co',
                Status     = 'Open - Not Contacted',
                Industry   = 'Agriculture',
                LeadSource = null
            ));
        }

        LeadTriggerHandler.alreadyExecuted = false;

        Test.startTest();
        insert leads;
        Test.stopTest();

        List<Lead> inserted = [SELECT LeadSource FROM Lead WHERE Company = 'Bulk Co'];
        System.assertEquals(200, inserted.size(), '200 leads should be inserted');
        for (Lead l : inserted) {
            System.assertEquals('Other', l.LeadSource, 'Every bulk-inserted lead should have LeadSource = Other');
        }
    }
}
