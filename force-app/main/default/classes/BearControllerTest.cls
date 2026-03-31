@IsTest
private class BearControllerTest {

    @TestSetup
    static void makeData() {
        Contact supervisor = new Contact(LastName = 'Bear Supervisor');
        insert supervisor;
        insert new Bear__c(Name = 'Grizzly', Supervisor__c = supervisor.Id);
    }

    @IsTest
    static void getAllBears_returnsAtLeastOne() {
        Test.startTest();
        Bear__c[] result = BearController.getAllBears();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 bear record');
    }

    @IsTest
    static void searchBears_emptyTerm_callsGetAllBears() {
        Test.startTest();
        Bear__c[] result = BearController.searchBears('');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null for empty search term');
        System.assert(result.size() >= 1, 'Empty search term should fall through to getAllBears path');
    }

    @IsTest
    static void searchBears_matchingTerm_returnsGrizzly() {
        Test.startTest();
        Bear__c[] result = BearController.searchBears('Gri');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 bear matching "Gri"');

        Boolean foundGrizzly = false;
        for (Bear__c b : result) {
            if (b.Name == 'Grizzly') {
                foundGrizzly = true;
            }
        }
        System.assert(foundGrizzly, 'Expected Grizzly bear in results for search term "Gri"');
    }

    @IsTest
    static void searchBears_noMatch_returnsEmpty() {
        Test.startTest();
        Bear__c[] result = BearController.searchBears('ZZZNOTAREAL_XYZ');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Expected 0 bears for non-matching term');
    }
}
