trigger UsageTrigger on Usage__c (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            UsageTriggerHandler.afterInsertHandler(Trigger.new);
        }
        when AFTER_UPDATE {
            UsageTriggerHandler.afterUpdateHandler(Trigger.new, Trigger.oldMap);
        }
    }
}
