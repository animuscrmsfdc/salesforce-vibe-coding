@IsTest
private class CTLocationControllerTest {

    @TestSetup
    static void makeData() {
        List<Location__c> locs = new List<Location__c>{
            new Location__c(Name = 'TestLoc Alpha', Address__c = '123 Main St', Pincode__c = '10001'),
            new Location__c(Name = 'TestLoc Beta',  Address__c = '456 Oak Ave',  Pincode__c = '10002')
        };
        insert locs;

        Person__c p = new Person__c(Name = 'John Doe', Mobile__c = '5550001111');
        insert p;
    }

    @IsTest
    static void getRecentStatusChanges_returnsAtLeastTwo() {
        Test.startTest();
        List<Location__c> result = CTLocationController.getRecentStatusChanges();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 2, 'Expected at least 2 location records, got: ' + result.size());
    }

    @IsTest
    static void searchLocations_matchesByName() {
        Test.startTest();
        List<Location__c> result = CTLocationController.searchLocations('TestLoc');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 result for search term "TestLoc"');
    }

    @IsTest
    static void searchLocations_noMatchReturnsEmpty() {
        Test.startTest();
        List<Location__c> result = CTLocationController.searchLocations('ZZZNOTAREAL_XYZ');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Expected 0 results for non-matching term');
    }

    @IsTest
    static void getLocationById_validId_returnsRecord() {
        Location__c loc = [SELECT Id FROM Location__c WHERE Name = 'TestLoc Alpha' LIMIT 1];

        Test.startTest();
        Location__c result = CTLocationController.getLocationById(loc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a Location__c record');
        System.assertEquals(loc.Id, result.Id, 'Returned record Id should match');
    }

    @IsTest
    static void getLocationById_fakeId_returnsNull() {
        // Use a well-formed but non-existent Id
        String fakeId = Location__c.sObjectType.getDescribe().getKeyPrefix() + '000000000000AAA';

        Test.startTest();
        Location__c result = CTLocationController.getLocationById(fakeId);
        Test.stopTest();

        System.assertEquals(null, result, 'Expected null for non-existent record Id');
    }

    @IsTest
    static void getStatusCount_greenPersonIncluded() {
        // Person trigger sets Health_Status__c = 'Green' on insert
        Test.startTest();
        Map<String, Integer> result = CTLocationController.getStatusCount();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('Green'), 'Expected "Green" key in status count map');
        System.assert(result.get('Green') >= 1, 'Expected at least 1 green person');
    }
}
