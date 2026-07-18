@IsTest
private class SpeakerAvailabilityServiceTest {

    @TestSetup
    static void makeData() {
        insert new Speaker__c(First_Name__c = 'John', Last_Name__c = 'Smith');
    }

    @IsTest
    static void overlaps_bothEndsKnown_detectsOverlap() {
        Datetime base = Datetime.now();
        System.assert(SpeakerAvailabilityService.overlaps(base, base.addHours(1), base.addMinutes(30), base.addMinutes(90)),
            'Overlapping windows should be detected');
        System.assert(!SpeakerAvailabilityService.overlaps(base, base.addHours(1), base.addHours(1), base.addHours(2)),
            'Back-to-back windows should not overlap');
    }

    @IsTest
    static void overlaps_missingEndTimes_fallsBackToExactStartMatch() {
        Datetime base = Datetime.now();
        System.assert(SpeakerAvailabilityService.overlaps(base, null, base, null), 'Exact same start should match');
        System.assert(!SpeakerAvailabilityService.overlaps(base, null, base.addHours(1), null), 'Different start should not match');
    }

    @IsTest
    static void getActiveWindowsBySpeaker_excludesCancelledSessions() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];
        Datetime base = Datetime.now();

        Session__c active = new Session__c(Name = 'Active', Session_Date__c = base, End_Date__c = base.addHours(1));
        Session__c toCancel = new Session__c(Name = 'To Cancel', Session_Date__c = base.addHours(2), End_Date__c = base.addHours(3));
        insert new List<Session__c>{ active, toCancel };
        insert new List<Session_Speaker__c>{
            new Session_Speaker__c(Session__c = active.Id, Speaker__c = speaker.Id),
            new Session_Speaker__c(Session__c = toCancel.Id, Speaker__c = speaker.Id)
        };
        // Cancel the session after the speaker is already booked — the trigger only
        // blocks *new* assignments to cancelled sessions, not the session's own status change.
        toCancel.Status__c = 'Cancelled';
        update toCancel;

        Test.startTest();
        Map<Id, Map<Id, SpeakerAvailabilityService.Window>> windows =
            SpeakerAvailabilityService.getActiveWindowsBySpeaker(new Set<Id>{ speaker.Id });
        Test.stopTest();

        System.assertEquals(1, windows.get(speaker.Id).size(), 'Only the active session booking should be returned');
    }

    @IsTest
    static void findConflict_excludesGivenAssignmentId() {
        Datetime base = Datetime.now();
        SpeakerAvailabilityService.Window w = new SpeakerAvailabilityService.Window();
        w.assignmentId = Id.valueOf('001000000000001AAA');
        w.startTime = base;
        w.endTime = base.addHours(1);

        Map<Id, SpeakerAvailabilityService.Window> windows = new Map<Id, SpeakerAvailabilityService.Window>{ w.assignmentId => w };

        System.assertEquals(w, SpeakerAvailabilityService.findConflict(windows, base, base.addHours(1), null),
            'Should report a conflict when not excluded');
        System.assertEquals(null, SpeakerAvailabilityService.findConflict(windows, base, base.addHours(1), w.assignmentId),
            'Should not report a conflict against its own excluded assignment Id');
    }
}
