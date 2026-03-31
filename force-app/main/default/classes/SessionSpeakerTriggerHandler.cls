public with sharing class SessionSpeakerTriggerHandler {
    public static void beforeInsertHandler(List<Session_Speaker__c> newAssignments) {
        Set<Id> speakerIds = new Set<Id>();
        Set<Id> sessionIds = new Set<Id>();

        for (Session_Speaker__c a : newAssignments) {
            if (a.Speaker__c != null) speakerIds.add(a.Speaker__c);
            if (a.Session__c != null) sessionIds.add(a.Session__c);
        }

        Map<Id, Datetime> sessionDateMap = new Map<Id, Datetime>();
        for (Session__c s : [SELECT Id, Session_Date__c FROM Session__c WHERE Id IN :sessionIds]) {
            sessionDateMap.put(s.Id, s.Session_Date__c);
        }

        Set<String> existingBookings = new Set<String>();
        for (Session_Speaker__c existing : [
            SELECT Speaker__c, Session__r.Session_Date__c
            FROM Session_Speaker__c
            WHERE Speaker__c IN :speakerIds
        ]) {
            if (existing.Session__r.Session_Date__c != null) {
                existingBookings.add(existing.Speaker__c + '_' + existing.Session__r.Session_Date__c);
            }
        }

        for (Session_Speaker__c a : newAssignments) {
            Datetime sessionDate = sessionDateMap.get(a.Session__c);
            if (sessionDate != null) {
                String key = a.Speaker__c + '_' + sessionDate;
                if (existingBookings.contains(key)) {
                    a.addError('Speaker is already booked for another session at this date and time.');
                }
            }
        }
    }
}
