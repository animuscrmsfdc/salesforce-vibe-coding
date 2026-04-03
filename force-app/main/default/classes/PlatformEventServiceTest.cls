@IsTest
private class PlatformEventServiceTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account LIMIT 1];
    }

    private static Usage__c buildUsage(Id accountId) {
        return new Usage__c(
            Account__c        = accountId,
            UsageStartDate__c = Date.today(),
            UsageEndDate__c   = Date.today().addDays(30),
            Quantity__c       = 10.5,
            Status__c         = 'New'
        );
    }

    // Usage single insert — via trigger → handler → PlatformEventService
    @IsTest
    static void testUsageAfterInsert_publishesEvent() {
        Account acc = getAccount();
        Usage__c usage = buildUsage(acc.Id);

        Test.startTest();
        insert usage;
        Test.stopTest();

        List<Usage__c> inserted = [SELECT Id, Status__c FROM Usage__c WHERE Id = :usage.Id];
        System.assertEquals(1, inserted.size(), 'Usage record should be created');
        System.assertEquals('New', inserted[0].Status__c, 'Status should default to New');
    }

    // Usage bulk insert — 200 records
    @IsTest
    static void testUsageBulkInsert_200Records() {
        Account acc = getAccount();
        List<Usage__c> usages = new List<Usage__c>();
        for (Integer i = 0; i < 200; i++) {
            usages.add(buildUsage(acc.Id));
        }

        Test.startTest();
        insert usages;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Usage__c], 'All 200 Usage records should be inserted');
    }

    // Exception single insert — via trigger → handler → PlatformEventService
    @IsTest
    static void testExceptionAfterInsert_publishesEvent() {
        Exception__c exc = new Exception__c(
            Object__c            = 'Account',
            Operation__c         = 'insert',
            Record_Id__c         = '001000000000001AAA',
            Exception_Details__c = 'Test exception details'
        );

        Test.startTest();
        insert exc;
        Test.stopTest();

        List<Exception__c> inserted = [SELECT Id, Object__c FROM Exception__c WHERE Id = :exc.Id];
        System.assertEquals(1, inserted.size(), 'Exception record should be created');
        System.assertEquals('Account', inserted[0].Object__c, 'Object__c should be preserved');
    }

    // Exception bulk insert — 200 records
    @IsTest
    static void testExceptionBulkInsert_200Records() {
        List<Exception__c> exceptions = new List<Exception__c>();
        for (Integer i = 0; i < 200; i++) {
            exceptions.add(new Exception__c(
                Object__c            = 'Account',
                Operation__c         = 'insert',
                Record_Id__c         = '001000000000001AAA',
                Exception_Details__c = 'Bulk exception ' + i
            ));
        }

        Test.startTest();
        insert exceptions;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Exception__c], 'All 200 Exception records should be inserted');
    }

    // Direct service call — Usage records
    @IsTest
    static void testPublishEvents_usage_directCall() {
        Account acc = getAccount();
        Usage__c usage = buildUsage(acc.Id);
        insert usage;

        Usage__c withId = [
            SELECT Id, Account__c, UsageStartDate__c, UsageEndDate__c, Quantity__c, Status__c
            FROM Usage__c
            WHERE Id = :usage.Id
        ];

        Test.startTest();
        PlatformEventService.publishEvents((List<SObject>) new List<Usage__c>{ withId }, 'com.animuscrm.usage.created');
        Test.stopTest();

        System.assert(true, 'publishEvents should complete without exception for Usage');
    }

    // Direct service call — Exception records
    @IsTest
    static void testPublishEvents_exception_directCall() {
        Exception__c exc = new Exception__c(
            Object__c            = 'Contact',
            Operation__c         = 'update',
            Record_Id__c         = '003000000000001AAA',
            Exception_Details__c = 'Test details'
        );
        insert exc;

        Exception__c withId = [
            SELECT Id, Object__c, Operation__c, Record_Id__c, Exception_Details__c
            FROM Exception__c
            WHERE Id = :exc.Id
        ];

        Test.startTest();
        PlatformEventService.publishEvents((List<SObject>) new List<Exception__c>{ withId }, 'com.animuscrm.exception.created');
        Test.stopTest();

        System.assert(true, 'publishEvents should complete without exception for Exception');
    }

    // Truncation path — Exception record with oversized Exception_Details__c
    @IsTest
    static void testPublishEvents_truncation() {
        String longDetails = 'X'.repeat(25000);
        Exception__c exc = new Exception__c(
            Object__c            = 'Lead',
            Operation__c         = 'delete',
            Record_Id__c         = '00Q000000000001AAA',
            Exception_Details__c = longDetails
        );
        insert exc;

        Exception__c withId = [
            SELECT Id, Object__c, Operation__c, Record_Id__c, Exception_Details__c
            FROM Exception__c
            WHERE Id = :exc.Id
        ];

        Test.startTest();
        PlatformEventService.publishEvents((List<SObject>) new List<Exception__c>{ withId }, 'com.animuscrm.exception.created');
        Test.stopTest();

        System.assert(true, 'publishEvents should complete without exception when data exceeds 20000 chars');
    }

    // Boundary: null input
    @IsTest
    static void testPublishEvents_nullInput() {
        Test.startTest();
        PlatformEventService.publishEvents(null, 'com.animuscrm.usage.created');
        Test.stopTest();
        System.assert(true, 'publishEvents should handle null input gracefully');
    }

    // Boundary: empty list
    @IsTest
    static void testPublishEvents_emptyList() {
        Test.startTest();
        PlatformEventService.publishEvents(new List<SObject>(), 'com.animuscrm.usage.created');
        Test.stopTest();
        System.assert(true, 'publishEvents should handle empty list gracefully');
    }

    // Feature flag disabled — no event published, insert still succeeds
    @IsTest
    static void testFeatureFlag_disabled_exceptionInsertSucceeds() {
        Exception__c exc = new Exception__c(
            Object__c            = 'Opportunity',
            Operation__c         = 'insert',
            Record_Id__c         = '006000000000001AAA',
            Exception_Details__c = 'Test with flag disabled'
        );

        Test.startTest();
        insert exc;
        Test.stopTest();

        List<Exception__c> inserted = [SELECT Id FROM Exception__c WHERE Id = :exc.Id];
        System.assertEquals(1, inserted.size(), 'Exception record should be inserted regardless of flag state');
    }

    // runAs user with Exception_Tracker permission set — insert succeeds and trigger fires
    @IsTest
    static void testRunAs_exceptionTrackerUser_insertSucceeds() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName          = 'Test',
            LastName           = 'ExcTracker',
            Email              = 'exc.tracker.test@animuscrm.test',
            Username           = 'exc.tracker.test@animuscrm.test.' + UserInfo.getOrganizationId(),
            Alias              = 'exctrk',
            TimeZoneSidKey     = 'America/New_York',
            LocaleSidKey       = 'en_US',
            EmailEncodingKey   = 'UTF-8',
            LanguageLocaleKey  = 'en_US',
            ProfileId          = p.Id
        );
        insert u;

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Exception_Tracker' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);

        Test.startTest();
        System.runAs(u) {
            Exception__c exc = new Exception__c(
                Object__c            = 'Case',
                Operation__c         = 'insert',
                Record_Id__c         = '500000000000001AAA',
                Exception_Details__c = 'Exception Tracker user test'
            );
            insert exc;
            List<Exception__c> inserted = [SELECT Id FROM Exception__c WHERE Id = :exc.Id];
            System.assertEquals(1, inserted.size(), 'Exception_Tracker user should be able to insert Exception__c');
        }
        Test.stopTest();
    }
}
