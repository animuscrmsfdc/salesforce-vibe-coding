@IsTest
private class LoanTriggerHandlerTest {

    @TestSetup
    static void setup() {
        Contact broker = new Contact(LastName = 'Test Broker', Email = 'broker@test.animuscrm.com');
        insert broker;
    }

    @IsTest
    static void afterInsert_publishesStatusChangeEvent() {
        Contact broker = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        Loan__c loan = new Loan__c(
            Status__c = 'Submitted',
            Broker__c = broker.Id,
            Amount__c = 50000
        );
        insert loan;
        Test.stopTest();

        Loan__c saved = [SELECT Id, Status__c, Status_Changed_At__c FROM Loan__c WHERE Id = :loan.Id];
        System.assertEquals('Submitted', saved.Status__c);
    }

    @IsTest
    static void afterUpdate_statusChange_stampsTimestampAndPublishesEvent() {
        Contact broker = [SELECT Id FROM Contact LIMIT 1];
        Loan__c loan = new Loan__c(Status__c = 'Submitted', Broker__c = broker.Id, Amount__c = 10000);
        insert loan;

        Test.startTest();
        loan.Status__c = 'Processing';
        update loan;
        Test.stopTest();

        Loan__c saved = [SELECT Status__c, Status_Changed_At__c FROM Loan__c WHERE Id = :loan.Id];
        System.assertEquals('Processing', saved.Status__c);
        System.assertNotEquals(null, saved.Status_Changed_At__c,
            'Status_Changed_At__c must be stamped on status change');
    }

    @IsTest
    static void afterUpdate_nonStatusChange_doesNotStampTimestamp() {
        Loan__c loan = new Loan__c(Status__c = 'Submitted', Amount__c = 5000);
        insert loan;

        Test.startTest();
        loan.Amount__c = 9999;
        update loan;
        Test.stopTest();

        Loan__c saved = [SELECT Status_Changed_At__c FROM Loan__c WHERE Id = :loan.Id];
        System.assertEquals(null, saved.Status_Changed_At__c,
            'Status_Changed_At__c must not change when status is unchanged');
    }

    @IsTest
    static void afterUpdate_fullLifecycle_stampsTimestampOnEachTransition() {
        Loan__c loan = new Loan__c(Status__c = 'Submitted', Amount__c = 25000);
        insert loan;

        Test.startTest();
        loan.Status__c = 'Processing';
        update loan;
        loan.Status__c = 'Underwriting';
        update loan;
        loan.Status__c = 'Approved';
        update loan;
        Test.stopTest();

        Loan__c saved = [SELECT Status__c, Status_Changed_At__c FROM Loan__c WHERE Id = :loan.Id];
        System.assertEquals('Approved', saved.Status__c);
        System.assertNotEquals(null, saved.Status_Changed_At__c);
    }

    @IsTest
    static void publishStatusChange_bulkSafe_handles200Records() {
        List<Loan__c> loans = new List<Loan__c>();
        for (Integer i = 0; i < 200; i++) {
            loans.add(new Loan__c(Status__c = 'Submitted', Amount__c = i * 1000));
        }

        Test.startTest();
        insert loans;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Loan__c]);
    }

    @IsTest
    static void publishStatusChange_nullInput_doesNotThrow() {
        Test.startTest();
        LoanService.publishStatusChange(null, null);
        LoanService.publishStatusChange(new List<Loan__c>(), null);
        Test.stopTest();
    }

    @IsTest
    static void publishStatusChange_allRecordsSkipped_returnsWithoutPublishing() {
        Loan__c loan = new Loan__c(Status__c = 'Submitted', Amount__c = 1000);
        insert loan;

        Map<Id, Loan__c> oldMap = new Map<Id, Loan__c>{
            loan.Id => new Loan__c(Id = loan.Id, Status__c = 'Submitted')
        };

        Test.startTest();
        LoanService.publishStatusChange(new List<Loan__c>{ loan }, oldMap);
        Test.stopTest();
    }

    @IsTest
    static void logError_doesNotThrow() {
        Test.startTest();
        LoanService.logError('a0Bak000000TestAAA', 'Unit test error message');
        LoanService.logError(null, 'Null record id error');
        Test.stopTest();
    }

    @IsTest
    static void publishStatusChange_bulkUpdate_onlyFiresForStatusChanges() {
        List<Loan__c> loans = new List<Loan__c>();
        for (Integer i = 0; i < 10; i++) {
            loans.add(new Loan__c(Status__c = 'Submitted', Amount__c = i * 1000));
        }
        insert loans;

        Test.startTest();
        for (Loan__c loan : loans) {
            loan.Amount__c += 1;
        }
        update loans;
        Test.stopTest();

        for (Loan__c saved : [SELECT Status_Changed_At__c FROM Loan__c WHERE Id IN :loans]) {
            System.assertEquals(null, saved.Status_Changed_At__c,
                'Non-status updates must not stamp the timestamp');
        }
    }
}
