@IsTest
private class AccountSearchControllerTest {

    @TestSetup
    static void makeData() {
        Account acct = new Account(Name = 'SearchableAccount');
        insert acct;
    }

    @IsTest
    static void searchAccounts_blankTerm_returnsEmpty() {
        Test.startTest();
        List<Account> result = AccountSearchController.searchAccounts('');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Blank searchTerm should return empty list');
    }

    @IsTest
    static void searchAccounts_singleChar_returnsEmpty() {
        Test.startTest();
        List<Account> result = AccountSearchController.searchAccounts('S');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Single-char searchTerm should return empty list');
    }

    @IsTest
    static void searchAccounts_validTerm_returnsMatch() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'SearchableAccount' LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ acct.Id });

        Test.startTest();
        List<Account> result = AccountSearchController.searchAccounts('Sea');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 result for SOSL-mocked search');
        System.assertEquals(acct.Id, result[0].Id, 'Returned account Id should match fixed search result');
    }

    @IsTest
    static void searchAccounts_nullTerm_returnsEmpty() {
        Test.startTest();
        List<Account> result = AccountSearchController.searchAccounts(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null for null input');
        System.assertEquals(0, result.size(), 'Null searchTerm should return empty list');
    }
}
