@IsTest
private class GetSpeakerAvailabilityTest {

    @TestSetup
    static void makeData() {
        insert new Speaker__c(First_Name__c = 'John', Last_Name__c = 'Smith');
    }

    @IsTest
    static void speakerWithNoBookings_isAvailable() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];
        Datetime base = Datetime.now();

        GetSpeakerAvailability.Request req = new GetSpeakerAvailability.Request();
        req.speakerId = speaker.Id;
        req.startTime = base;
        req.endTime = base.addHours(1);

        Test.startTest();
        List<GetSpeakerAvailability.Response> responses = GetSpeakerAvailability.checkAvailability(
            new List<GetSpeakerAvailability.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return one response per request');
        System.assert(responses[0].isAvailable, 'Speaker with no bookings should be available');
        System.assertEquals(null, responses[0].conflictingSessionId, 'No conflict should be reported');
    }

    @IsTest
    static void overlappingCandidateWindow_isNotAvailable() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];
        Datetime base = Datetime.now();

        Session__c booked = new Session__c(Name = 'Booked', Session_Date__c = base, End_Date__c = base.addHours(1));
        insert booked;
        Session_Speaker__c assignment = new Session_Speaker__c(Session__c = booked.Id, Speaker__c = speaker.Id);
        insert assignment;

        GetSpeakerAvailability.Request req = new GetSpeakerAvailability.Request();
        req.speakerId = speaker.Id;
        req.startTime = base.addMinutes(30);
        req.endTime = base.addMinutes(90);

        Test.startTest();
        List<GetSpeakerAvailability.Response> responses = GetSpeakerAvailability.checkAvailability(
            new List<GetSpeakerAvailability.Request>{ req }
        );
        Test.stopTest();

        System.assert(!responses[0].isAvailable, 'Overlapping candidate window should not be available');
        System.assertEquals(booked.Id, responses[0].conflictingSessionId, 'Should report the conflicting session');
    }

    // Note: there is no test here for a booking on an already-cancelled session being ignored.
    // That state ("Session_Speaker__c whose Session__c is Cancelled") is unreachable via DML
    // in this org: SessionSpeakerTriggerHandler blocks new assignments to a cancelled session,
    // and the No_Speakers_On_Cancelled validation rule blocks cancelling a session that still
    // has assignments. See SessionSpeakerTriggerHandlerTest.cancelledSession_assignmentRejected.

    @IsTest
    static void nullSpeakerId_returnsError() {
        GetSpeakerAvailability.Request req = new GetSpeakerAvailability.Request();
        req.startTime = Datetime.now();

        Test.startTest();
        List<GetSpeakerAvailability.Response> responses =
            GetSpeakerAvailability.checkAvailability(new List<GetSpeakerAvailability.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(
            'Provide a speaker name, email, or Speaker Id.',
            responses[0].errorMessage,
            'Missing speaker should return an error message'
        );
    }
}
