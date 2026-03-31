@IsTest
private class CTPeopleTracingControllerTest {

    @TestSetup
    static void makeData() {
        Person__c p1 = new Person__c(Name = 'Person One',   Mobile__c = '5550010001');
        Person__c p2 = new Person__c(Name = 'Person Two',   Mobile__c = '5550010002');
        Person__c p3 = new Person__c(Name = 'Person Three', Mobile__c = '5550010003');
        insert new List<Person__c>{ p1, p2, p3 };

        People_Tracing__c trace = new People_Tracing__c(
            Person_1__c  = p1.Id,
            Person_2__c  = p2.Id,
            Contact_Date__c = Date.today()
        );
        insert trace;
    }

    @IsTest
    static void getTraces_returnsList() {
        Person__c p1 = [SELECT Id FROM Person__c WHERE Name = 'Person One' LIMIT 1];

        Test.startTest();
        List<People_Tracing__c> result = CTPeopleTracingController.getTraces(p1.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Expected at least 1 tracing record for Person One');
    }

    @IsTest
    static void checkDuplicates_noDuplicates_returnsEmpty() {
        Person__c p1 = [SELECT Id FROM Person__c WHERE Name = 'Person One' LIMIT 1];
        Person__c p3 = [SELECT Id FROM Person__c WHERE Name = 'Person Three' LIMIT 1];

        // p1+p3 pair does not exist
        People_Tracing__c newTrace = new People_Tracing__c(
            Person_1__c = p1.Id,
            Person_2__c = p3.Id
        );

        Test.startTest();
        List<People_Tracing__c> duplicates =
            CTPeopleTracingController.checkDuplicates(new List<People_Tracing__c>{ newTrace });
        Test.stopTest();

        System.assertNotEquals(null, duplicates, 'Duplicates list should not be null');
        System.assertEquals(0, duplicates.size(), 'Expected no duplicates for p1+p3 pair');
    }

    @IsTest
    static void checkDuplicates_findsDuplicate_returnsNonEmpty() {
        Person__c p1 = [SELECT Id FROM Person__c WHERE Name = 'Person One' LIMIT 1];
        Person__c p2 = [SELECT Id FROM Person__c WHERE Name = 'Person Two' LIMIT 1];

        // p1+p2 pair already exists in org
        People_Tracing__c duplicateCandidate = new People_Tracing__c(
            Person_1__c = p1.Id,
            Person_2__c = p2.Id
        );

        Test.startTest();
        List<People_Tracing__c> duplicates =
            CTPeopleTracingController.checkDuplicates(new List<People_Tracing__c>{ duplicateCandidate });
        Test.stopTest();

        System.assertNotEquals(null, duplicates, 'Duplicates list should not be null');
        System.assert(duplicates.size() >= 1, 'Expected at least 1 duplicate for existing p1+p2 pair');
    }

    @IsTest
    static void checkDuplicates_reverseOrder_findsDuplicate() {
        Person__c p1 = [SELECT Id FROM Person__c WHERE Name = 'Person One' LIMIT 1];
        Person__c p2 = [SELECT Id FROM Person__c WHERE Name = 'Person Two' LIMIT 1];

        // reverse order p2+p1 should also be detected as duplicate
        People_Tracing__c reverseCandidate = new People_Tracing__c(
            Person_1__c = p2.Id,
            Person_2__c = p1.Id
        );

        Test.startTest();
        List<People_Tracing__c> duplicates =
            CTPeopleTracingController.checkDuplicates(new List<People_Tracing__c>{ reverseCandidate });
        Test.stopTest();

        System.assertNotEquals(null, duplicates, 'Duplicates list should not be null');
        System.assert(duplicates.size() >= 1, 'Expected reverse pair p2+p1 to be detected as duplicate');
    }
}
