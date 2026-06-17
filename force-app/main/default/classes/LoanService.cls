public with sharing class LoanService {

    @TestVisible
    private static List<Loan_Status_Change__e> lastPublishedEvents = new List<Loan_Status_Change__e>();

    // Callers must ensure Broker__c is populated on each Loan__c; Trigger.new always satisfies this.
    public static void publishStatusChange(List<Loan__c> newLoans, Map<Id, Loan__c> oldMap) {
        lastPublishedEvents = new List<Loan_Status_Change__e>();
        if (newLoans == null || newLoans.isEmpty()) {
            return;
        }

        List<Loan_Status_Change__e> events = new List<Loan_Status_Change__e>();

        for (Loan__c loan : newLoans) {
            String previousStatus = (oldMap != null && oldMap.containsKey(loan.Id))
                ? oldMap.get(loan.Id).Status__c
                : null;

            if (oldMap != null && oldMap.containsKey(loan.Id) && previousStatus == loan.Status__c) {
                continue;
            }

            Loan_Status_Change__e evt = new Loan_Status_Change__e();
            evt.Loan_Id__c         = String.valueOf(loan.Id);
            evt.Previous_Status__c = previousStatus;
            evt.New_Status__c      = loan.Status__c;
            evt.Broker_Id__c       = loan.Broker__c != null ? String.valueOf(loan.Broker__c) : null;
            evt.Timestamp__c       = System.now();
            events.add(evt);
        }

        if (events.isEmpty()) {
            return;
        }

        lastPublishedEvents = events;
        try {
            List<Database.SaveResult> results = EventBus.publish(events);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results.get(i).isSuccess()) {
                    for (Database.Error err : results.get(i).getErrors()) {
                        logError(
                            events.get(i).Loan_Id__c,
                            err.getStatusCode() + ': ' + err.getMessage()
                        );
                    }
                }
            }
        } catch (Exception e) {
            logError(null, e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @TestVisible
    private static void logError(String loanId, String details) {
        try {
            EventBus.publish(new Exception_Log__e(
                Object__c            = 'LoanService',
                Operation__c         = 'PublishLoanStatusChange',
                Record_Id__c         = loanId,
                Exception_Details__c = details
            ));
        } catch (Exception e) {
            // secondary publish failure: swallow to avoid masking the original error
        }
    }
}
