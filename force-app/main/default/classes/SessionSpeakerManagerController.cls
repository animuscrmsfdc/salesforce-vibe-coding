public with sharing class SessionSpeakerManagerController {

    // ─── Session Search ──────────────────────────────────────────────────────

    @AuraEnabled(Cacheable=true)
    public static List<Session__c> searchSessions(String searchTerm) {
        if (String.isBlank(searchTerm) || searchTerm.trim().length() < 3) {
            return [
                SELECT Id, Name, Session_Date__c, End_Date__c,
                       Status__c, Level__c, Description__c, Speaker_Count__c
                FROM Session__c
                WITH SECURITY_ENFORCED
                ORDER BY Session_Date__c DESC NULLS LAST
                LIMIT 10
            ];
        }
        String term = searchTerm.trim();
        List<List<SObject>> results = [
            FIND :term
            IN ALL FIELDS
            RETURNING Session__c(
                Id, Name, Session_Date__c, End_Date__c,
                Status__c, Level__c, Description__c, Speaker_Count__c
                ORDER BY Session_Date__c DESC NULLS LAST
                LIMIT 10
            )
        ];
        return (List<Session__c>) results[0];
    }

    // ─── Speaker Search ──────────────────────────────────────────────────────

    @AuraEnabled(Cacheable=true)
    public static List<Speaker__c> searchSpeakers(String searchTerm) {
        if (String.isBlank(searchTerm) || searchTerm.trim().length() < 3) {
            return [
                SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Bio__c
                FROM Speaker__c
                WITH SECURITY_ENFORCED
                ORDER BY Last_Name__c, First_Name__c
                LIMIT 10
            ];
        }
        String term = searchTerm.trim();
        List<List<SObject>> results = [
            FIND :term
            IN ALL FIELDS
            RETURNING Speaker__c(
                Id, Name, First_Name__c, Last_Name__c, Email__c, Bio__c
                ORDER BY Last_Name__c
                LIMIT 10
            )
        ];
        return (List<Speaker__c>) results[0];
    }

    // ─── Get Session Speakers ────────────────────────────────────────────────

    @AuraEnabled(Cacheable=true)
    public static List<Session_Speaker__c> getSessionSpeakers(Id sessionId) {
        if (sessionId == null) return new List<Session_Speaker__c>();
        return [
            SELECT Id,
                   Session__c,
                   Speaker__c,
                   Speaker__r.Name,
                   Speaker__r.First_Name__c,
                   Speaker__r.Last_Name__c,
                   Speaker__r.Email__c,
                   Role__c,
                   Order__c,
                   Confirmed__c
            FROM Session_Speaker__c
            WHERE Session__c = :sessionId
            WITH SECURITY_ENFORCED
            ORDER BY Order__c NULLS LAST, Speaker__r.Last_Name__c
        ];
    }

    // ─── Get Session Speakers (non-cacheable, for imperative bootstrap) ──────

    @AuraEnabled
    public static List<Session_Speaker__c> getSessionSpeakersLive(Id sessionId) {
        if (sessionId == null) return new List<Session_Speaker__c>();
        return [
            SELECT Id,
                   Session__c,
                   Speaker__c,
                   Speaker__r.Name,
                   Speaker__r.First_Name__c,
                   Speaker__r.Last_Name__c,
                   Speaker__r.Email__c,
                   Role__c,
                   Order__c,
                   Confirmed__c
            FROM Session_Speaker__c
            WHERE Session__c = :sessionId
            WITH SECURITY_ENFORCED
            ORDER BY Order__c NULLS LAST, Speaker__r.Last_Name__c
        ];
    }

    // ─── Save Session ────────────────────────────────────────────────────────

    @AuraEnabled
    public static Session__c saveSession(Session__c session) {
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.UPSERTABLE,
            new List<Session__c>{ session }
        );
        Session__c clean = (Session__c) decision.getRecords()[0];
        upsert clean;
        return [
            SELECT Id, Name, Session_Date__c, End_Date__c,
                   Status__c, Level__c, Description__c, Speaker_Count__c
            FROM Session__c
            WHERE Id = :clean.Id
            WITH SECURITY_ENFORCED
        ];
    }

    // ─── Save Speaker ────────────────────────────────────────────────────────

    @AuraEnabled
    public static Speaker__c saveSpeaker(Speaker__c speaker) {
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.UPSERTABLE,
            new List<Speaker__c>{ speaker }
        );
        Speaker__c clean = (Speaker__c) decision.getRecords()[0];
        upsert clean;
        return [
            SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Bio__c
            FROM Speaker__c
            WHERE Id = :clean.Id
            WITH SECURITY_ENFORCED
        ];
    }

    // ─── Save Session Speaker (Junction) ────────────────────────────────────

    @AuraEnabled
    public static void saveSessionSpeaker(Session_Speaker__c ss) {
        // Master-detail fields (Session__c, Speaker__c) are creatable but not updatable,
        // so UPSERTABLE strips them. Use CREATABLE for inserts, UPDATABLE for updates.
        AccessType accessType = ss.Id == null ? AccessType.CREATABLE : AccessType.UPDATABLE;
        SObjectAccessDecision decision = Security.stripInaccessible(
            accessType,
            new List<Session_Speaker__c>{ ss }
        );
        Session_Speaker__c clean = (Session_Speaker__c) decision.getRecords()[0];
        upsert clean;
    }

    // ─── Remove Session Speaker ──────────────────────────────────────────────

    @AuraEnabled
    public static void removeSessionSpeaker(Id sessionSpeakerId) {
        List<Session_Speaker__c> toDelete = [
            SELECT Id
            FROM Session_Speaker__c
            WHERE Id = :sessionSpeakerId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }
}
