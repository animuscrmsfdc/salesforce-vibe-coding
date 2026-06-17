public with sharing class LoanTriggerHandler {

    public static void beforeUpdateHandler(List<Loan__c> newLoans, Map<Id, Loan__c> oldMap) {
        for (Loan__c loan : newLoans) {
            if (loan.Status__c != oldMap.get(loan.Id).Status__c) {
                loan.Status_Changed_At__c = System.now();
            }
        }
    }

    public static void afterInsertHandler(List<Loan__c> newLoans) {
        LoanService.publishStatusChange(newLoans, null);
    }

    public static void afterUpdateHandler(List<Loan__c> newLoans, Map<Id, Loan__c> oldMap) {
        LoanService.publishStatusChange(newLoans, oldMap);
    }
}
