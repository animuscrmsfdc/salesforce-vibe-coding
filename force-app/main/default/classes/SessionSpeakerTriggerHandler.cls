public with sharing class SessionSpeakerTriggerHandler {

    public static void beforeInsertHandler(List<Session_Speaker__c> newAssignments) {
        validateAndCheckOverlaps(newAssignments, null);
    }

    public static void beforeUpdateHandler(List<Session_Speaker__c> newAssignments, Map<Id, Session_Speaker__c> oldMap) {
        List<Session_Speaker__c> changed = new List<Session_Speaker__c>();
        for (Session_Speaker__c a : newAssignments) {
            Session_Speaker__c old = oldMap.get(a.Id);
            if (a.Speaker__c != old.Speaker__c || a.Session__c != old.Session__c) {
                changed.add(a);
            }
        }
        if (changed.isEmpty()) return;
        validateAndCheckOverlaps(changed, oldMap);
    }

    private static void validateAndCheckOverlaps(List<Session_Speaker__c> assignments, Map<Id, Session_Speaker__c> oldMap) {
        Set<Id> speakerIds = new Set<Id>();
        Set<Id> sessionIds = new Set<Id>();

        for (Session_Speaker__c a : assignments) {
            if (a.Speaker__c != null) speakerIds.add(a.Speaker__c);
            if (a.Session__c != null) sessionIds.add(a.Session__c);
        }

        Map<Id, Session__c> sessionMap = new Map<Id, Session__c>();
        for (Session__c s : [
            SELECT Id, Session_Date__c, End_Date__c, Status__c
            FROM Session__c
            WHERE Id IN :sessionIds
        ]) {
            sessionMap.put(s.Id, s);
        }

        // Validate session status before checking overlaps
        for (Session_Speaker__c a : assignments) {
            Session__c session = sessionMap.get(a.Session__c);
            if (session != null && session.Status__c == 'Cancelled') {
                a.addError('Cannot assign a speaker to a cancelled session.');
            }
        }

        // Lock existing Session_Speaker__c rows for the affected speakers to prevent race conditions.
        // Exclude bookings on cancelled sessions to avoid false-positive overlap rejections.
        List<Session_Speaker__c> existingAssignments = [
            SELECT Id, Speaker__c, Session__r.Session_Date__c, Session__r.End_Date__c
            FROM Session_Speaker__c
            WHERE Speaker__c IN :speakerIds
              AND Session__r.Status__c != 'Cancelled'
            FOR UPDATE
        ];

        // Build overlap map: speakerId -> (existingAssignmentId -> [start, end])
        // Keyed by assignment Id so each record's own previous window can be excluded
        // individually during bulk updates, preventing cross-record exclusion.
        Map<Id, Map<Id, Datetime[]>> speakerWindows = new Map<Id, Map<Id, Datetime[]>>();
        for (Session_Speaker__c existing : existingAssignments) {
            Datetime existStart = existing.Session__r.Session_Date__c;
            Datetime existEnd   = existing.Session__r.End_Date__c;
            if (existStart == null) continue;
            if (!speakerWindows.containsKey(existing.Speaker__c)) {
                speakerWindows.put(existing.Speaker__c, new Map<Id, Datetime[]>());
            }
            speakerWindows.get(existing.Speaker__c).put(existing.Id, new Datetime[]{ existStart, existEnd });
        }

        for (Session_Speaker__c a : assignments) {
            Session__c session = sessionMap.get(a.Session__c);
            if (session == null || session.Session_Date__c == null) continue;

            Datetime newStart = session.Session_Date__c;
            Datetime newEnd   = session.End_Date__c;

            Map<Id, Datetime[]> windows = speakerWindows.get(a.Speaker__c);
            if (windows == null) continue;

            for (Id existingId : windows.keySet()) {
                // On update, skip only this specific assignment's own previous booking
                if (a.Id != null && existingId == a.Id) continue;

                Datetime[] window   = windows.get(existingId);
                Datetime existStart = window[0];
                Datetime existEnd   = window[1];

                Boolean overlaps;
                if (newEnd != null && existEnd != null) {
                    // Full overlap check: newStart < existEnd && newEnd > existStart
                    overlaps = newStart < existEnd && newEnd > existStart;
                } else {
                    // Fall back to exact start-time match when end times are not set
                    overlaps = newStart == existStart;
                }

                if (overlaps) {
                    a.addError('Speaker is already booked for another session at an overlapping date and time.');
                    break;
                }
            }
        }
    }
}
