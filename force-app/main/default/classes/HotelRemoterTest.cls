@IsTest
private class HotelRemoterTest {

    @TestSetup
    static void makeData() {
        insert new Hotel__c(Name = 'Test Hotel');
    }

    @IsTest
    static void findAll_returnsAtLeastOne() {
        Test.startTest();
        List<Hotel__c> result = HotelRemoter.findAll();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 hotel record');
    }

    @IsTest
    static void findAll_containsInsertedHotel() {
        Test.startTest();
        List<Hotel__c> result = HotelRemoter.findAll();
        Test.stopTest();

        Boolean found = false;
        for (Hotel__c h : result) {
            if (h.Name == 'Test Hotel') {
                found = true;
            }
        }
        System.assert(found, 'Expected "Test Hotel" to appear in findAll results');
    }
}
