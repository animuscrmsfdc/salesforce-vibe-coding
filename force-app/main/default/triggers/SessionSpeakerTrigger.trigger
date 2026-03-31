trigger SessionSpeakerTrigger on Session_Speaker__c (before insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            SessionSpeakerTriggerHandler.beforeInsertHandler(Trigger.new);
        }
    }
}
