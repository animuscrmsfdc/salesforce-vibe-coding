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

    // Note: there is no test here for excluding a booking on an already-cancelled session.
    // That state ("Session_Speaker__c whose Session__c is Cancelled") is unreachable via DML
    // in this org: SessionSpeakerTriggerHandler blocks new assignments to a cancelled session,
    // and the No_Speakers_On_Cancelled validation rule blocks cancelling a session that still
    // has assignments. See SessionSpeakerTriggerHandlerTest.cancelledSession_assignmentRejected.
    // The Session__r.Status__c != 'Cancelled' filter in getActiveWindowsBySpeaker remains as
    // defensive code for that combination.

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
