@IsTest
private class MyContactListControllerTest {

    @TestSetup
    static void makeData() {
        insert new Contact(LastName = 'TestContactLast', FirstName = 'TestFirst');
    }

    @IsTest
    static void getContacts_returnsAtLeastOne() {
        Test.startTest();
        List<Contact> result = MyContactListController.getContacts();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 contact');
    }
}
