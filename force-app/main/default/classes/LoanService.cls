public with sharing class LoanService {

    public static void publishStatusChange(List<Loan__c> newLoans, Map<Id, Loan__c> oldMap) {
        if (newLoans == null || newLoans.isEmpty()) {
            return;
        }

        List<Loan_Status_Change__e> events = new List<Loan_Status_Change__e>();

        for (Loan__c loan : newLoans) {
            String previousStatus = (oldMap != null && oldMap.containsKey(loan.Id))
                ? oldMap.get(loan.Id).Status__c
                : null;

            if (oldMap != null && previousStatus == loan.Status__c) {
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
            System.debug(LoggingLevel.ERROR,
                'LoanService.logError failed: ' + e.getMessage());
        }
    }
}
