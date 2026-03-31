@IsTest
private class CampingListControllerTest {

    @TestSetup
    static void makeData() {
        insert new Camping_Item__c(Name = 'Test Item', Price__c = 10, Quantity__c = 5);
    }

    @IsTest
    static void getItems_returnsAtLeastOne() {
        Test.startTest();
        List<Camping_Item__c> result = CampingListController.getItems();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 camping item');
    }

    @IsTest
    static void saveItem_returnsItemWithId() {
        Camping_Item__c newItem = new Camping_Item__c(
            Name       = 'New Camping Item',
            Price__c   = 20,
            Quantity__c = 3
        );

        Test.startTest();
        Camping_Item__c result = CampingListController.saveItem(newItem);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Returned item should not be null');
        System.assertNotEquals(null, result.Id, 'Returned item should have an Id after save');
    }

    @IsTest
    static void saveItem_persistedInOrg() {
        Camping_Item__c newItem = new Camping_Item__c(
            Name       = 'Persisted Item',
            Price__c   = 50,
            Quantity__c = 1
        );

        Test.startTest();
        Camping_Item__c result = CampingListController.saveItem(newItem);
        Test.stopTest();

        List<Camping_Item__c> found = [SELECT Id FROM Camping_Item__c WHERE Name = 'Persisted Item'];
        System.assertEquals(1, found.size(), 'Saved item should be queryable from the org');
        System.assertEquals(result.Id, found[0].Id, 'Queried Id should match the returned Id');
    }
}
