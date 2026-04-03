trigger ExceptionTrigger on Exception__c (after insert) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            ExceptionTriggerHandler.afterInsertHandler(Trigger.new);
        }
    }
}
