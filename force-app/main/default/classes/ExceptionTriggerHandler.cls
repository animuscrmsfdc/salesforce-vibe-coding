public with sharing class ExceptionTriggerHandler {

    public static void afterInsertHandler(List<Exception__c> newRecords) {
        List<Feature_Flag__mdt> flags = [
            SELECT Enabled__c
            FROM Feature_Flag__mdt
            WHERE DeveloperName = 'Exception_Event_Publishing'
            LIMIT 1
        ];

        if (flags.isEmpty() || !flags[0].Enabled__c) {
            return;
        }

        PlatformEventService.publishEvents((List<SObject>) newRecords, 'com.animuscrm.exception.created');
    }
}
