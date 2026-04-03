/**
 * @deprecated Use PlatformEventService.publishEvents() directly.
 * Retained as a compatibility shim for UsageEventServiceTest.
 * Schedule for deletion after test class migration to PlatformEventServiceTest.
 */
public with sharing class UsageEventService {

    public static void publishEvents(List<Usage__c> usages, String eventType) {
        if (usages == null || usages.isEmpty()) {
            return;
        }
        PlatformEventService.publishEvents((List<SObject>) usages, eventType);
    }
}
