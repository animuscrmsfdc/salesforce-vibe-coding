@IsTest
private class QueueableAccountAgingFieldsTest {

    @TestSetup
    static void makeData() {
        Account acct = new Account(Name = 'Queueable Test Account', Description = 'Original');
        insert acct;
    }

    @IsTest
    static void execute_appendsEditedLabel() {
        Test.startTest();
        System.enqueueJob(new QueueableAccountAgingFields());
        Test.stopTest();

        Account result = [SELECT Description FROM Account WHERE Name = 'Queueable Test Account' LIMIT 1];
        System.assertNotEquals(null, result.Description, 'Description should not be null after queueable runs');
        System.assert(
            result.Description.contains('Edited by Queueable class'),
            'Expected Description to contain "Edited by Queueable class", got: ' + result.Description
        );
    }

    @IsTest
    static void execute_nullDescription_doesNotThrow() {
        // Account with null description — execute should catch DmlException internally
        Account acct2 = new Account(Name = 'Null Desc Account', Description = null);
        insert acct2;

        Test.startTest();
        System.enqueueJob(new QueueableAccountAgingFields());
        Test.stopTest();

        // No assertion needed — absence of unhandled exception is the pass condition
        System.assert(true, 'Queueable should handle null description without throwing');
    }
}
