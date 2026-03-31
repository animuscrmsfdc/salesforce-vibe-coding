@IsTest
private class TestInvocableMethodAccountsTest {

    @TestSetup
    static void setupData() {
        insert new List<Account>{
            new Account(Name = 'Invocable Account 1'),
            new Account(Name = 'Invocable Account 2')
        };
    }

    @IsTest
    static void getAccountNames_validIds_returnsNames() {
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name LIKE 'Invocable Account %'];
        List<Id> ids = new List<Id>();
        for (Account a : accounts) ids.add(a.Id);

        Test.startTest();
        List<String> names = TestInvocableMethodAccounts.getAccountNames(ids);
        Test.stopTest();

        System.assertEquals(2, names.size(), 'Should return 2 account names');
        System.assert(names.contains('Invocable Account 1'), 'Should contain Invocable Account 1');
        System.assert(names.contains('Invocable Account 2'), 'Should contain Invocable Account 2');
    }

    @IsTest
    static void getAccountNames_emptyList_returnsEmpty() {
        Test.startTest();
        List<String> names = TestInvocableMethodAccounts.getAccountNames(new List<Id>());
        Test.stopTest();

        System.assertNotEquals(null, names, 'Result should not be null');
        System.assertEquals(0, names.size(), 'Result should be empty for empty input');
    }
}
