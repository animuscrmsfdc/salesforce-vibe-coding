@IsTest
private class CTLocationTracingControllerTest {

    @TestSetup
    static void makeData() {
        Location__c loc = new Location__c(
            Name       = 'Tracing Test Location',
            Address__c = '789 Test Blvd',
            Pincode__c = '20001'
        );
        insert loc;

        Person__c p = new Person__c(Name = 'Trace Person', Mobile__c = '5550002222');
        insert p;

        Location_Tracing__c trace = new Location_Tracing__c(
            Person__c    = p.Id,
            Location__c  = loc.Id,
            Visit_Date__c = Date.today()
        );
        insert trace;
    }

    @IsTest
    static void getVisitors_returnsNonNull() {
        Location_Tracing__c trace = [SELECT Id FROM Location_Tracing__c LIMIT 1];

        Test.startTest();
        List<Location_Tracing__c> result = CTLocationTracingController.getVisitors(trace.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 tracing record');
    }

    @IsTest
    static void getLocationByPersonIds_returnsMatchingRecords() {
        Person__c p = [SELECT Id FROM Person__c LIMIT 1];

        Test.startTest();
        List<Location_Tracing__c> result =
            CTLocationTracingController.getLocationByPersonIds(new Set<Id>{ p.Id });
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 result for person with a recent visit');
    }

    @IsTest
    static void getLocationByLocationIds_returnsGreenPersonRecords() {
        Location__c loc = [SELECT Id FROM Location__c LIMIT 1];

        Test.startTest();
        List<Location_Tracing__c> result =
            CTLocationTracingController.getLocationByLocationIds(new Set<Id>{ loc.Id });
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @IsTest
    static void checkDuplicates_noDuplicates_returnsEmpty() {
        // Create a second unrelated person and location to pass in
        Location__c loc2 = new Location__c(
            Name       = 'Other Location',
            Address__c = '999 Other St',
            Pincode__c = '30001'
        );
        insert loc2;

        Person__c p2 = new Person__c(Name = 'Other Person', Mobile__c = '5550003333');
        insert p2;

        Location_Tracing__c newTrace = new Location_Tracing__c(
            Person__c    = p2.Id,
            Location__c  = loc2.Id,
            Visit_Date__c = Date.today()
        );

        Test.startTest();
        List<Location_Tracing__c> duplicates =
            CTLocationTracingController.checkDuplicates(new List<Location_Tracing__c>{ newTrace });
        Test.stopTest();

        System.assertNotEquals(null, duplicates, 'Duplicates list should not be null');
        System.assertEquals(0, duplicates.size(), 'Expected no duplicates for a new person+location pair');
    }

    @IsTest
    static void checkDuplicates_findsDuplicate_returnsNonEmpty() {
        Person__c p         = [SELECT Id FROM Person__c LIMIT 1];
        Location__c loc     = [SELECT Id FROM Location__c WHERE Name = 'Tracing Test Location' LIMIT 1];

        // Build the same person+location as already exists
        Location_Tracing__c duplicateCandidate = new Location_Tracing__c(
            Person__c    = p.Id,
            Location__c  = loc.Id,
            Visit_Date__c = Date.today()
        );

        Test.startTest();
        List<Location_Tracing__c> duplicates =
            CTLocationTracingController.checkDuplicates(new List<Location_Tracing__c>{ duplicateCandidate });
        Test.stopTest();

        System.assertNotEquals(null, duplicates, 'Duplicates list should not be null');
        System.assert(duplicates.size() >= 1, 'Expected at least 1 duplicate record returned');
    }
}
