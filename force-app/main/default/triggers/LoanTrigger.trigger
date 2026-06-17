trigger LoanTrigger on Loan__c (before update, after insert, after update) {
    switch on Trigger.operationType {
        when BEFORE_UPDATE {
            LoanTriggerHandler.beforeUpdateHandler(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            LoanTriggerHandler.afterInsertHandler(Trigger.new);
        }
        when AFTER_UPDATE {
            LoanTriggerHandler.afterUpdateHandler(Trigger.new, Trigger.oldMap);
        }
    }
}
