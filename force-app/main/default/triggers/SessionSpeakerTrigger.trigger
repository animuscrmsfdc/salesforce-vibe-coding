trigger SessionSpeakerTrigger on Session_Speaker__c (before insert, before update) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            SessionSpeakerTriggerHandler.beforeInsertHandler(Trigger.new);
        }
        when BEFORE_UPDATE {
            SessionSpeakerTriggerHandler.beforeUpdateHandler(Trigger.new, Trigger.oldMap);
        }
    }
}
