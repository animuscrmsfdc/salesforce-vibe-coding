public with sharing class LoanService {

    // Loan_Status_Change__e publishing disabled — platform event pending org cleanup.
    public static void publishStatusChange(List<Loan__c> newLoans, Map<Id, Loan__c> oldMap) {
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
