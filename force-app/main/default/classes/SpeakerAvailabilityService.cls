public with sharing class SpeakerAvailabilityService {

    public class Window {
        public Id assignmentId;
        public Datetime startTime;
        public Datetime endTime;
    }

    // Overlap check shared by the trigger (validating a write) and the read-only
    // availability lookup: full-window overlap when both ends are known, otherwise
    // fall back to an exact start-time match.
    public static Boolean overlaps(Datetime newStart, Datetime newEnd, Datetime existStart, Datetime existEnd) {
        if (newEnd != null && existEnd != null) {
            return newStart < existEnd && newEnd > existStart;
        }
        return newStart == existStart;
    }

    // Active (non-cancelled) booking windows per speaker, keyed by assignment Id so
    // callers can exclude a record's own prior window during an update.
    public static Map<Id, Map<Id, Window>> getActiveWindowsBySpeaker(Set<Id> speakerIds) {
        Map<Id, Map<Id, Window>> windowsBySpeaker = new Map<Id, Map<Id, Window>>();
        for (Session_Speaker__c existing : [
            SELECT Id, Speaker__c, Session__r.Session_Date__c, Session__r.End_Date__c
            FROM Session_Speaker__c
            WHERE Speaker__c IN :speakerIds
              AND Session__r.Status__c != 'Cancelled'
        ]) {
            if (existing.Session__r.Session_Date__c == null) continue;
            if (!windowsBySpeaker.containsKey(existing.Speaker__c)) {
                windowsBySpeaker.put(existing.Speaker__c, new Map<Id, Window>());
            }
            Window w = new Window();
            w.assignmentId = existing.Id;
            w.startTime = existing.Session__r.Session_Date__c;
            w.endTime = existing.Session__r.End_Date__c;
            windowsBySpeaker.get(existing.Speaker__c).put(existing.Id, w);
        }
        return windowsBySpeaker;
    }

    // First window (if any) that conflicts with the candidate start/end, excluding
    // excludeAssignmentId (a record's own previous booking during an update).
    public static Window findConflict(Map<Id, Window> windows, Datetime newStart, Datetime newEnd, Id excludeAssignmentId) {
        if (windows == null) return null;
        for (Window w : windows.values()) {
            if (excludeAssignmentId != null && w.assignmentId == excludeAssignmentId) continue;
            if (overlaps(newStart, newEnd, w.startTime, w.endTime)) {
                return w;
            }
        }
        return null;
    }
}
