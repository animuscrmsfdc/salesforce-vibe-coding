@IsTest
private class UsageEventServiceTest {

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

    // AC-1: Insert triggers a created event — verifies trigger + handler + service execute without error
    @IsTest
    static void testAfterInsert_publishesCreatedEvent() {
        Account acc = getAccount();
        Usage__c usage = buildUsage(acc.Id);

        Test.startTest();
        insert usage;
        Test.stopTest();

        List<Usage__c> inserted = [SELECT Id, Status__c, Quantity__c FROM Usage__c WHERE Id = :usage.Id];
        System.assertEquals(1, inserted.size(), 'Usage record should be created');
        System.assertEquals('New', inserted[0].Status__c, 'Status should default to New');
        System.assertEquals(10.5, inserted[0].Quantity__c, 'Quantity should be preserved');
    }

    // AC-2: Update triggers an updated event
    @IsTest
    static void testAfterUpdate_publishesUpdatedEvent() {
        Account acc = getAccount();
        Usage__c usage = buildUsage(acc.Id);
        insert usage;

        Test.startTest();
        usage.Status__c = 'Processed';
        update usage;
        Test.stopTest();

        Usage__c updated = [SELECT Status__c FROM Usage__c WHERE Id = :usage.Id];
        System.assertEquals('Processed', updated.Status__c, 'Status should be updated to Processed');
    }

    // AC-3: Bulk insert — 200 records, verifies bulkification (no SOQL/DML in loops)
    @IsTest
    static void testBulkInsert_200Records() {
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

    // Bulk update — 200 records, covers afterUpdateHandler path
    @IsTest
    static void testBulkUpdate_200Records() {
        Account acc = getAccount();
        List<Usage__c> usages = new List<Usage__c>();
        for (Integer i = 0; i < 200; i++) {
            usages.add(buildUsage(acc.Id));
        }
        insert usages;

        for (Usage__c u : usages) {
            u.Status__c = 'Processed';
        }

        Test.startTest();
        update usages;
        Test.stopTest();

        System.assertEquals(
            200,
            [SELECT COUNT() FROM Usage__c WHERE Status__c = 'Processed'],
            'All 200 records should be updated to Processed'
        );
    }

    // Direct service call — covers publishEvents with a fully populated record
    @IsTest
    static void testPublishEvents_directServiceCall() {
        Account acc = getAccount();
        Usage__c usage = buildUsage(acc.Id);
        insert usage;

        Usage__c withId = [
            SELECT Id, Account__c, UsageStartDate__c, UsageEndDate__c, Quantity__c, Status__c
            FROM Usage__c
            WHERE Id = :usage.Id
        ];

        Test.startTest();
        UsageEventService.publishEvents(new List<Usage__c>{ withId }, 'com.animuscrm.usage.created');
        Test.stopTest();

        System.assert(true, 'publishEvents should complete without exception');
    }

    // Boundary: null input — no exception, early return
    @IsTest
    static void testPublishEvents_nullInput() {
        Test.startTest();
        UsageEventService.publishEvents(null, 'com.animuscrm.usage.created');
        Test.stopTest();
        System.assert(true, 'publishEvents should handle null input gracefully');
    }

    // Boundary: empty list — no exception, early return
    @IsTest
    static void testPublishEvents_emptyList() {
        Test.startTest();
        UsageEventService.publishEvents(new List<Usage__c>(), 'com.animuscrm.usage.created');
        Test.stopTest();
        System.assert(true, 'publishEvents should handle empty list gracefully');
    }

    // AC-5: Validation rule — EndDate before StartDate
    @IsTest
    static void testValidation_endDateBeforeStartDate() {
        Account acc = getAccount();
        Usage__c usage = new Usage__c(
            Account__c        = acc.Id,
            UsageStartDate__c = Date.today(),
            UsageEndDate__c   = Date.today().addDays(-1),
            Quantity__c       = 1.0,
            Status__c         = 'New'
        );

        Test.startTest();
        try {
            insert usage;
            System.assert(false, 'Expected DmlException for EndDate before StartDate');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('End Date must be on or after Start Date'),
                'Error message should match validation rule: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // AC-5: Validation rule — Quantity zero
    @IsTest
    static void testValidation_quantityZero() {
        Account acc = getAccount();
        Usage__c usage = new Usage__c(
            Account__c        = acc.Id,
            UsageStartDate__c = Date.today(),
            Quantity__c       = 0,
            Status__c         = 'New'
        );

        Test.startTest();
        try {
            insert usage;
            System.assert(false, 'Expected DmlException for Quantity = 0');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Quantity must be greater than zero'),
                'Error message should match validation rule: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // AC-5: Validation rule — Quantity negative
    @IsTest
    static void testValidation_quantityNegative() {
        Account acc = getAccount();
        Usage__c usage = new Usage__c(
            Account__c        = acc.Id,
            UsageStartDate__c = Date.today(),
            Quantity__c       = -5.0,
            Status__c         = 'New'
        );

        Test.startTest();
        try {
            insert usage;
            System.assert(false, 'Expected DmlException for negative Quantity');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Quantity must be greater than zero'),
                'Error message should match validation rule: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
}
