public with sharing class PlatformEventService {

    private static final Integer DATA_MAX_LENGTH = 20000;
    private static final String TRUNCATION_SUFFIX = '...[TRUNCATED]';

    /**
     * Publishes a Platform_Event__e CloudEvents-compliant event for each SObject record.
     * Bulk-safe: collects all events first, publishes in a single EventBus.publish() call.
     * Errors are logged via Exception_Log__e. Never throws — trigger context must not be interrupted.
     *
     * @param records   List of SObject records. Must have Ids (call from after insert/update only).
     * @param eventType CloudEvents type value (e.g. 'com.animuscrm.usage.created')
     */
    public static void publishEvents(List<SObject> records, String eventType) {
        if (records == null || records.isEmpty()) {
            return;
        }

        String orgUrl = URL.getOrgDomainUrl() != null
            ? URL.getOrgDomainUrl().toExternalForm()
            : 'https://unknown.salesforce.com';

        List<Platform_Event__e> events = new List<Platform_Event__e>();

        for (SObject rec : records) {
            Platform_Event__e evt = new Platform_Event__e();
            evt.specversion__c     = '1.0';
            evt.type__c            = eventType;
            evt.source__c          = orgUrl;
            evt.subject__c         = String.valueOf(rec.Id);
            evt.time__c            = System.now();
            evt.datacontenttype__c = 'application/json';
            evt.data__c            = truncateData(JSON.serialize(rec));
            events.add(evt);
        }

        try {
            List<Database.SaveResult> results = EventBus.publish(events);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results.get(i).isSuccess()) {
                    for (Database.Error err : results.get(i).getErrors()) {
                        logError(
                            String.valueOf(records.get(i).Id),
                            err.getStatusCode() + ': ' + err.getMessage()
                        );
                    }
                }
            }
        } catch (Exception e) {
            logError(null, e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    private static String truncateData(String json) {
        if (json == null) {
            return null;
        }
        if (json.length() <= DATA_MAX_LENGTH) {
            return json;
        }
        return json.substring(0, DATA_MAX_LENGTH) + TRUNCATION_SUFFIX;
    }

    private static void logError(String recordId, String details) {
        try {
            EventBus.publish(new Exception_Log__e(
                Object__c            = 'PlatformEventService',
                Operation__c         = 'PublishPlatformEvent',
                Record_Id__c         = recordId,
                Exception_Details__c = details
            ));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'PlatformEventService.logError failed: ' + e.getMessage());
        }
    }
}
