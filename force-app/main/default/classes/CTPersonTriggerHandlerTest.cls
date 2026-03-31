@IsTest
private class CTPersonTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        Person__c p = new Person__c(
            Name       = 'Test Person',
            Mobile__c  = '1234567890'
        );
        insert p;
    }

    // -----------------------------------------------------------------------
    // Scenario 1 — beforeInsert: Health_Status__c set to Green, Token__c populated
    // -----------------------------------------------------------------------
    @IsTest
    static void insertPerson_setsGreenStatusAndToken() {
        Person__c p = new Person__c(
            Name      = 'Insert Person',
            Mobile__c = '9876543210'
        );

        Test.startTest();
        insert p;
        Test.stopTest();

        Person__c inserted = [SELECT Health_Status__c, Token__c FROM Person__c WHERE Id = :p.Id];
        System.assertEquals('Green', inserted.Health_Status__c, 'Health_Status__c should be Green on insert');
        System.assertNotEquals(null, inserted.Token__c, 'Token__c should be populated on insert');
        System.assertNotEquals('', inserted.Token__c, 'Token__c should not be empty string on insert');
    }

    // -----------------------------------------------------------------------
    // Scenario 2 — beforeInsert bulk: 200 persons all get Green and a token
    // -----------------------------------------------------------------------
    @IsTest
    static void bulkInsert_200Persons_allGetGreenStatusAndToken() {
        List<Person__c> people = new List<Person__c>();
        for (Integer i = 0; i < 200; i++) {
            people.add(new Person__c(
                Name      = 'Bulk Person ' + i,
                Mobile__c = '555' + String.valueOf(i).leftPad(7, '0')
            ));
        }

        Test.startTest();
        insert people;
        Test.stopTest();

        List<Person__c> inserted = [SELECT Health_Status__c, Token__c FROM Person__c WHERE Name LIKE 'Bulk Person %'];
        System.assertEquals(200, inserted.size(), '200 persons should be inserted');
        for (Person__c p : inserted) {
            System.assertEquals('Green', p.Health_Status__c, 'Health_Status__c should be Green for every bulk-inserted person');
            System.assertNotEquals(null, p.Token__c, 'Token__c should not be null for any bulk-inserted person');
        }
    }

    // -----------------------------------------------------------------------
    // Scenario 3 — beforeUpdate: changing Health_Status__c sets Status_Update_Date__c to today
    // -----------------------------------------------------------------------
    @IsTest
    static void updatePerson_changeHealthStatus_setsStatusUpdateDate() {
        Person__c p = [SELECT Id, Health_Status__c, Status_Update_Date__c FROM Person__c WHERE Name = 'Test Person' LIMIT 1];

        Test.startTest();
        p.Health_Status__c = 'Red';
        update p;
        Test.stopTest();

        Person__c updated = [SELECT Health_Status__c, Status_Update_Date__c FROM Person__c WHERE Id = :p.Id];
        System.assertEquals('Red', updated.Health_Status__c, 'Health_Status__c should be Red after update');
        System.assertEquals(Date.today(), updated.Status_Update_Date__c, 'Status_Update_Date__c should be today when Health Status changes');
    }

    // -----------------------------------------------------------------------
    // Scenario 4 — beforeUpdate: not changing Health_Status__c leaves Status_Update_Date__c untouched
    // -----------------------------------------------------------------------
    @IsTest
    static void updatePerson_noHealthStatusChange_doesNotSetStatusUpdateDate() {
        Person__c p = [SELECT Id, Health_Status__c, Status_Update_Date__c FROM Person__c WHERE Name = 'Test Person' LIMIT 1];
        // Status_Update_Date__c should be null at this point (never been changed)
        System.assertEquals(null, p.Status_Update_Date__c, 'Status_Update_Date__c should start null');

        Test.startTest();
        // Update a field other than Health_Status__c — use Mobile__c
        p.Mobile__c = '0000000001';
        update p;
        Test.stopTest();

        Person__c updated = [SELECT Status_Update_Date__c FROM Person__c WHERE Id = :p.Id];
        System.assertEquals(null, updated.Status_Update_Date__c, 'Status_Update_Date__c should remain null when Health Status does not change');
    }
}
