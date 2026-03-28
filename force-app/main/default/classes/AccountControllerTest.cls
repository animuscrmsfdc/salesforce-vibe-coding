/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class AccountControllerTest {
    @testSetup
    static void setupTestData() {
        // Create Accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 1; i <= 3; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;

        // Create Cases linked to accounts
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < accounts.size(); i++) {
            // Closed cases with varying CreatedDate and ClosedDate
            cases.add(new Case(
                AccountId = accounts[i].Id,
                Status = 'Closed'
            ));
        }
        insert cases;
    }

    @isTest
    static void testUpdateAvgCaseResolutionDays_Positive() {
        // Retrieve Account IDs
        List<Account> accounts = [SELECT Id FROM Account];
        List<Id> accountIds = new List<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        // Call the method
        Test.startTest();
        AccountController.updateAvgCaseResolutionDays(accountIds);
        Test.stopTest();

        // Validate Accounts are updated
        List<Account> updatedAccounts = [SELECT Id, Avg_Case_Resolution_Days__c FROM Account];
        for (Account acc : updatedAccounts) {
            System.assertNotEquals(null, acc.Avg_Case_Resolution_Days__c, 'Average case resolution days should be updated.');
            System.assert(acc.Avg_Case_Resolution_Days__c > 0, 'Average case resolution days should be positive.');
        }
    }

    @isTest
    static void testUpdateAvgCaseResolutionDays_EmptyAccountIds() {
        // Call the method with an empty list
        Test.startTest();
        AccountController.updateAvgCaseResolutionDays(new List<Id>());
        Test.stopTest();

        // Validate no accounts are updated
        List<Account> accounts = [SELECT Id, Avg_Case_Resolution_Days__c FROM Account];
        for (Account acc : accounts) {
            System.assertEquals(null, acc.Avg_Case_Resolution_Days__c, 'No accounts should be updated.');
        }
    }

    @isTest
    static void testUpdateAvgCaseResolutionDays_NoClosedCases() {
        // Insert an account without closed cases
        Account acc = new Account(Name = 'No Closed Cases Account');
        insert acc;

        // Call the method for this account
        Test.startTest();
        AccountController.updateAvgCaseResolutionDays(new List<Id>{acc.Id});
        Test.stopTest();

        // Validate no updates occur
        Account account = [SELECT Id, Avg_Case_Resolution_Days__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, account.Avg_Case_Resolution_Days__c, 'Avg_Case_Resolution_Days__c should not be updated.');
    }

    /* @isTest
    static void testUpdateAvgCaseResolutionDays_NoPermissions() {
        // Test user with limited permissions
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'Standard User' LIMIT 1];

        System.runAs(testUser) {
            List<Account> accounts = [SELECT Id FROM Account];
            List<Id> accountIds = new List<Id>();
            for (Account acc : accounts) {
                accountIds.add(acc.Id);
            }

            Test.startTest();
            AccountController.updateAvgCaseResolutionDays(accountIds);
            Test.stopTest();

            // Validate no updates occurred due to lack of permissions
            List<Account> updatedAccounts = [SELECT Id, Avg_Case_Resolution_Days__c FROM Account];
            for (Account acc : updatedAccounts) {
                System.assertEquals(null, acc.Avg_Case_Resolution_Days__c, 'No updates should occur without permissions.');
            }
        }
    } */
}