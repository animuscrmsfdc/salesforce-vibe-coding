public with sharing class UsageEventService {

    /**
     * Publishes a Platform_Usages__e CloudEvents-compliant event for each Usage__c record.
     * Bulk-safe: collects all events first, publishes in a single EventBus.publish() call.
     * Errors are logged via Exception_Log__e. Never throws — trigger context must not be interrupted.
     *
     * @param usages    List of Usage__c records. Must have Ids (call from after insert/update only).
     * @param eventType CloudEvents type value (e.g. 'com.animuscrm.usage.created')
     */
    public static void publishEvents(List<Usage__c> usages, String eventType) {
        if (usages == null || usages.isEmpty()) {
            return;
        }

        String orgUrl = URL.getOrgDomainUrl() != null
            ? URL.getOrgDomainUrl().toExternalForm()
            : 'https://unknown.salesforce.com';

        List<Platform_Usages__e> events = new List<Platform_Usages__e>();

        for (Usage__c u : usages) {
            Platform_Usages__e evt = new Platform_Usages__e();
            evt.specversion__c      = '1.0';
            evt.type__c             = eventType;
            evt.source__c           = orgUrl;
            evt.subject__c          = u.Id;
            evt.time__c             = System.now();
            evt.datacontenttype__c  = 'application/json';
            evt.data__c             = JSON.serialize(u);
            events.add(evt);
        }

        try {
            List<Database.SaveResult> results = EventBus.publish(events);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results.get(i).isSuccess()) {
                    for (Database.Error err : results.get(i).getErrors()) {
                        logError(
                            String.valueOf(usages.get(i).Id),
                            err.getStatusCode() + ': ' + err.getMessage()
                        );
                    }
                }
            }
        } catch (Exception e) {
            logError(null, e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    private static void logError(String recordId, String details) {
        try {
            EventBus.publish(new Exception_Log__e(
                Object__c            = 'Usage__c',
                Operation__c         = 'PublishPlatformEvent',
                Record_Id__c         = recordId,
                Exception_Details__c = details
            ));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'UsageEventService.logError failed: ' + e.getMessage());
        }
    }
}
