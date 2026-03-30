public with sharing class UsageTriggerHandler {

    public static void afterInsertHandler(List<Usage__c> newRecords) {
        UsageEventService.publishEvents(newRecords, 'com.animuscrm.usage.created');
    }

    public static void afterUpdateHandler(List<Usage__c> newRecords, Map<Id, Usage__c> oldMap) {
        UsageEventService.publishEvents(newRecords, 'com.animuscrm.usage.updated');
    }
}
