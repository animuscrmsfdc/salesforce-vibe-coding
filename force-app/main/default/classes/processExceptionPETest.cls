@IsTest
private class processExceptionPETest {

    @IsTest
    static void publishEvent_createsExceptionRecord() {
        Exception_Log__e evt = new Exception_Log__e(
            Object__c           = 'Account',
            Operation__c        = 'insert',
            Record_Id__c        = '001000000000000AAA',
            Exception_Details__c = 'Test exception details'
        );

        Test.startTest();
        Database.SaveResult result = EventBus.publish(evt);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Event publish should succeed, errors: ' + result.getErrors());

        List<Exception__c> created = [SELECT Object__c, Operation__c FROM Exception__c];
        System.assert(created.size() >= 1, 'Expected at least 1 Exception__c record created by trigger');
        System.assertEquals('Account', created[0].Object__c, 'Object__c should match the published event');
        System.assertEquals('insert',  created[0].Operation__c, 'Operation__c should match the published event');
    }

    @IsTest
    static void publishMultipleEvents_createsMultipleRecords() {
        List<Exception_Log__e> events = new List<Exception_Log__e>{
            new Exception_Log__e(Object__c = 'Contact', Operation__c = 'update', Record_Id__c = '003000000000001AAA', Exception_Details__c = 'Error 1'),
            new Exception_Log__e(Object__c = 'Lead',    Operation__c = 'delete', Record_Id__c = '00Q000000000001AAA', Exception_Details__c = 'Error 2')
        };

        Test.startTest();
        List<Database.SaveResult> results = EventBus.publish(events);
        Test.stopTest();

        for (Database.SaveResult r : results) {
            System.assert(r.isSuccess(), 'Each event publish should succeed, errors: ' + r.getErrors());
        }

        List<Exception__c> created = [SELECT Object__c FROM Exception__c];
        System.assert(created.size() >= 2, 'Expected at least 2 Exception__c records from 2 events');
    }
}
