@IsTest
private class ContactControllerTest {

    @IsTest
    static void getContacts_throwsAuraHandledException() {
        Test.startTest();
        try {
            ContactController.getContacts();
            System.assert(false, 'Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e, 'AuraHandledException should be thrown');
        }
        Test.stopTest();
    }
}
