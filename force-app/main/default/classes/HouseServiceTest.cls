@IsTest
private class HouseServiceTest {

    @TestSetup
    static void makeData() {
        insert new House__c(Name = 'Test House');
    }

    @IsTest
    static void getRecords_returnsNonNull() {
        Test.startTest();
        List<House__c> result = HouseService.getRecords();
        Test.stopTest();

        System.assertNotEquals(null, result, 'getRecords should return a non-null list');
        System.assert(result.size() >= 1, 'Expected at least 1 House__c record');
    }
}
