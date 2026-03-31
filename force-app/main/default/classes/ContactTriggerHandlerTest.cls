@IsTest
private with sharing class ContactTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        Account acc1 = new Account(Name = 'Test Account 1');
        Account acc2 = new Account(Name = 'Test Account 2');
        insert new List<Account>{ acc1, acc2 };
    }

    // -----------------------------------------------------------------------
    // Scenario 1 — afterInsert: active Contact linked to Account sets Active_Contacts__c = 1
    // -----------------------------------------------------------------------
    @IsTest
    static void afterInsert_activeContact_incrementsActiveContacts() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        Test.startTest();
        insert new Contact(LastName = 'Active Doe', AccountId = acc.Id, Active__c = true);
        Test.stopTest();

        Account updated = [SELECT Active_Contacts__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1, updated.Active_Contacts__c, 'Active_Contacts__c should be 1 after inserting one active contact');
    }

    // -----------------------------------------------------------------------
    // Scenario 2 — afterUpdate: toggling Active__c false decrements count
    // -----------------------------------------------------------------------
    @IsTest
    static void afterUpdate_toggleActiveToFalse_decrementsActiveContacts() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Contact con = new Contact(LastName = 'Toggle Test', AccountId = acc.Id, Active__c = true);
        insert con;

        Account before = [SELECT Active_Contacts__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1, before.Active_Contacts__c, 'Precondition: should have 1 active contact');

        Test.startTest();
        con.Active__c = false;
        update con;
        Test.stopTest();

        Account after = [SELECT Active_Contacts__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, after.Active_Contacts__c, 'Active_Contacts__c should be 0 after toggling Active__c to false');
    }

    // -----------------------------------------------------------------------
    // Scenario 3 — afterUpdate: changing AccountId recalculates both accounts
    // -----------------------------------------------------------------------
    @IsTest
    static void afterUpdate_changeAccountId_recalculatesBothAccounts() {
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Account acc2 = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];

        Contact con = new Contact(LastName = 'Move Me', AccountId = acc1.Id, Active__c = true);
        insert con;

        Account acc1Before = [SELECT Active_Contacts__c FROM Account WHERE Id = :acc1.Id];
        System.assertEquals(1, acc1Before.Active_Contacts__c, 'Precondition: acc1 should have 1 active contact');

        Test.startTest();
        con.AccountId = acc2.Id;
        update con;
        Test.stopTest();

        Account acc1After = [SELECT Active_Contacts__c FROM Account WHERE Id = :acc1.Id];
        Account acc2After = [SELECT Active_Contacts__c FROM Account WHERE Id = :acc2.Id];

        System.assertEquals(0, acc1After.Active_Contacts__c, 'Old account Active_Contacts__c should be 0 after contact moved away');
        System.assertEquals(1, acc2After.Active_Contacts__c, 'New account Active_Contacts__c should be 1 after contact moved in');
    }

    // -----------------------------------------------------------------------
    // Scenario 4 — afterDelete: deleting a Contact decrements Active_Contacts__c
    // -----------------------------------------------------------------------
    @IsTest
    static void afterDelete_activeContact_decrementsActiveContacts() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Contact con = new Contact(LastName = 'To Delete', AccountId = acc.Id, Active__c = true);
        insert con;

        Account before = [SELECT Active_Contacts__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1, before.Active_Contacts__c, 'Precondition: should have 1 active contact before delete');

        Test.startTest();
        delete con;
        Test.stopTest();

        Account after = [SELECT Active_Contacts__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, after.Active_Contacts__c, 'Active_Contacts__c should be 0 after deleting the contact');
    }

    // -----------------------------------------------------------------------
    // Scenario 5 — afterUndelete: undeleting a Contact increments Active_Contacts__c
    // -----------------------------------------------------------------------
    @IsTest
    static void afterUndelete_activeContact_incrementsActiveContacts() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Contact con = new Contact(LastName = 'Undelete Me', AccountId = acc.Id, Active__c = true);
        insert con;
        delete con;

        Account afterDelete = [SELECT Active_Contacts__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, afterDelete.Active_Contacts__c, 'Precondition: should be 0 after delete');

        Test.startTest();
        undelete con;
        Test.stopTest();

        Account afterUndelete = [SELECT Active_Contacts__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1, afterUndelete.Active_Contacts__c, 'Active_Contacts__c should be 1 after undeleting the contact');
    }

    // -----------------------------------------------------------------------
    // Scenario 6 — Bulk: insert 200 active Contacts to one Account
    // -----------------------------------------------------------------------
    @IsTest
    static void afterInsert_bulk200ActiveContacts_activeContactsEquals200() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            contacts.add(new Contact(LastName = 'Bulk Contact ' + i, AccountId = acc.Id, Active__c = true));
        }

        Test.startTest();
        insert contacts;
        Test.stopTest();

        Account updated = [SELECT Active_Contacts__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(200, updated.Active_Contacts__c, 'Active_Contacts__c should be 200 after bulk inserting 200 active contacts');
    }
}
