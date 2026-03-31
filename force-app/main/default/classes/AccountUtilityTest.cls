@IsTest
private class AccountUtilityTest {

    @TestSetup
    static void makeData() {
        insert new List<Account>{
            new Account(Name = 'Revenue Account A', AnnualRevenue = 1000000),
            new Account(Name = 'Revenue Account B', AnnualRevenue = 500000)
        };
    }

    @IsTest
    static void viewAnnualRevenue_doesNotThrow() {
        Test.startTest();
        AccountUtility.viewAnnualRevenue();
        Test.stopTest();

        System.assert(true, 'viewAnnualRevenue should complete without throwing an exception');
    }
}
