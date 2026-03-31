@IsTest
private class AccountUtilsTest {

    @TestSetup
    static void makeData() {
        insert new List<Account>{
            new Account(Name = 'CA Account One', BillingState = 'CA'),
            new Account(Name = 'CA Account Two', BillingState = 'CA'),
            new Account(Name = 'NY Account',     BillingState = 'NY')
        };
    }

    @IsTest
    static void accountsByState_returnsMatchingState() {
        Test.startTest();
        List<Account> result = AccountUtils.accountsByState('CA');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 2, 'Expected at least 2 CA accounts, got: ' + result.size());
    }

    @IsTest
    static void accountsByState_noMatch_returnsEmpty() {
        Test.startTest();
        List<Account> result = AccountUtils.accountsByState('ZZ');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Expected 0 accounts for non-existent state ZZ');
    }

    @IsTest
    static void accountsByState_differentState_notMixed() {
        Test.startTest();
        List<Account> result = AccountUtils.accountsByState('NY');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 NY account');
        System.assert(result.size() >= 1, 'Expected at least 1 NY account');
    }
}
