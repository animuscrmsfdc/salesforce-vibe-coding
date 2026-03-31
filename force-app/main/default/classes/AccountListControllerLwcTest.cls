@IsTest
private class AccountListControllerLwcTest {

    @TestSetup
    static void makeData() {
        insert new Account(Name = 'High Revenue Account', AnnualRevenue = 1000000);
    }

    @IsTest
    static void queryAccountsByRevenue_returnsAboveThreshold() {
        Test.startTest();
        List<Account> result = AccountListControllerLwc.queryAccountsByRevenue(500000);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 account with AnnualRevenue >= 500000');
    }

    @IsTest
    static void queryAccountsByRevenue_noMatchBelowThreshold() {
        Test.startTest();
        List<Account> result = AccountListControllerLwc.queryAccountsByRevenue(2000000);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Expected 0 accounts above 2,000,000 threshold');
    }
}
