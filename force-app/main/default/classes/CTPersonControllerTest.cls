@IsTest
private with sharing class CTPersonControllerTest {

    @TestSetup
    static void setupData() {
        List<Person__c> people = new List<Person__c>{
            new Person__c(Name = 'John Smith',  Mobile__c = '1234567890'),
            new Person__c(Name = 'Jane Doe',    Mobile__c = '9876543210')
        };
        insert people;

        List<Location__c> locations = new List<Location__c>{
            new Location__c(Name = 'Loc Green 1', Status__c = 'Green', Address__c = '1 Green St', Pincode__c = '10001'),
            new Location__c(Name = 'Loc Green 2', Status__c = 'Green', Address__c = '2 Green St', Pincode__c = '10002'),
            new Location__c(Name = 'Loc Red 1',   Status__c = 'Red',   Address__c = '1 Red St',   Pincode__c = '20001')
        };
        insert locations;
    }

    // -----------------------------------------------------------------------
    // Scenario 1 — getRecentHealthChanges: returns at least the inserted records
    // -----------------------------------------------------------------------
    @IsTest
    static void getRecentHealthChanges_returnsInsertedRecords() {
        Test.startTest();
        List<Person__c> result = CTPersonController.getRecentHealthChanges();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 2, 'Should return at least the 2 records created in @TestSetup');
    }

    // -----------------------------------------------------------------------
    // Scenario 2 — searchPeople by name: partial name match returns record
    // -----------------------------------------------------------------------
    @IsTest
    static void searchPeople_byName_returnsMatchingRecord() {
        Test.startTest();
        List<Person__c> result = CTPersonController.searchPeople('John');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Should return at least one record matching name John');
        System.assertEquals('John Smith', result[0].Name, 'Returned record name should be John Smith');
    }

    // -----------------------------------------------------------------------
    // Scenario 3 — searchPeople by mobile: partial mobile match returns record
    // -----------------------------------------------------------------------
    @IsTest
    static void searchPeople_byMobile_returnsMatchingRecord() {
        Test.startTest();
        List<Person__c> result = CTPersonController.searchPeople('123');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Should return at least one record matching mobile starting with 123');

        Boolean foundMatch = false;
        for (Person__c p : result) {
            if (p.Mobile__c != null && p.Mobile__c.startsWith('123')) {
                foundMatch = true;
                break;
            }
        }
        System.assert(foundMatch, 'At least one result should have a mobile starting with 123');
    }

    // -----------------------------------------------------------------------
    // Scenario 4 — searchPeople no match: returns empty list
    // -----------------------------------------------------------------------
    @IsTest
    static void searchPeople_noMatch_returnsEmptyList() {
        Test.startTest();
        List<Person__c> result = CTPersonController.searchPeople('ZZZNOTFOUND');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Result should be empty for a term that matches nothing');
    }

    // -----------------------------------------------------------------------
    // Scenario 5 — getPersonById: valid Id returns matching record
    // -----------------------------------------------------------------------
    @IsTest
    static void getPersonById_validId_returnsRecord() {
        Person__c existing = [SELECT Id, Name FROM Person__c WHERE Name = 'John Smith' LIMIT 1];

        Test.startTest();
        Person__c result = CTPersonController.getPersonById(existing.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null for a valid Id');
        System.assertEquals(existing.Id, result.Id, 'Returned record Id should match the queried Id');
    }

    // -----------------------------------------------------------------------
    // Scenario 6 — getPersonById: fake Id returns null
    // -----------------------------------------------------------------------
    @IsTest
    static void getPersonById_fakeId_returnsNull() {
        // Use a syntactically valid but non-existent Person__c Id
        String fakeId = '001000000000001AAA';

        Test.startTest();
        Person__c result = CTPersonController.getPersonById(fakeId);
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when no record matches the given Id');
    }

    // -----------------------------------------------------------------------
    // Scenario 7 — getHealthStatusCount: map contains correct counts per status
    // -----------------------------------------------------------------------
    @IsTest
    static void getHealthStatusCount_returnsCorrectCountsPerStatus() {
        Test.startTest();
        Map<String, Integer> result = CTPersonController.getHealthStatusCount();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('Green'), 'Map should contain key Green');
        System.assert(result.containsKey('Red'),   'Map should contain key Red');
        System.assertEquals(2, result.get('Green'), 'Green count should be 2');
        System.assertEquals(1, result.get('Red'),   'Red count should be 1');
    }
}
