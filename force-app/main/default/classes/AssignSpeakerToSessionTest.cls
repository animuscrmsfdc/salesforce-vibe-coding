@IsTest
private class AssignSpeakerToSessionTest {

    @TestSetup
    static void makeData() {
        insert new Speaker__c(First_Name__c = 'John', Last_Name__c = 'Smith');
    }

    @IsTest
    static void validAssignment_succeedsWithFriendlyMessage() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];
        Session__c session = new Session__c(
            Name = 'Keynote Session', Session_Date__c = Datetime.now(), End_Date__c = Datetime.now().addHours(1)
        );
        insert session;

        AssignSpeakerToSession.Request req = new AssignSpeakerToSession.Request();
        req.speakerId = speaker.Id;
        req.sessionId = session.Id;
        req.role = 'Keynote';

        // Run as a user holding the Session_Speaker_User permission set so this test's
        // outcome doesn't depend on whichever profile happens to run the org's CI pipeline.
        // Without it, Security.stripInaccessible(CREATABLE) silently drops Role__c for a
        // user with no edit FLS on that field, and the picklist falls back to its default.
        User coordinator = createSessionSpeakerUser();

        List<AssignSpeakerToSession.Response> responses;
        System.runAs(coordinator) {
            Test.startTest();
            responses = AssignSpeakerToSession.assignSpeakers(
                new List<AssignSpeakerToSession.Request>{ req }
            );
            Test.stopTest();
        }

        System.assertEquals(1, responses.size(), 'Should return one response per request');
        System.assert(responses[0].success, 'Assignment should succeed');
        System.assertNotEquals(null, responses[0].sessionSpeakerId, 'Should return the new record Id');
        System.assert(responses[0].message.contains('Keynote Session'), 'Success message should name the session');
        System.assert(responses[0].message.contains((String) responses[0].sessionSpeakerId), 'Success message should include a link to the new record');

        Session_Speaker__c created = [SELECT Role__c FROM Session_Speaker__c WHERE Id = :responses[0].sessionSpeakerId];
        System.assertEquals('Keynote', created.Role__c, 'Role should be set from the request');
    }

    @IsTest
    static void missingIds_returnsFailureWithoutThrowing() {
        AssignSpeakerToSession.Request req = new AssignSpeakerToSession.Request();
        req.speakerId = null;
        req.sessionId = null;

        Test.startTest();
        List<AssignSpeakerToSession.Response> responses = AssignSpeakerToSession.assignSpeakers(
            new List<AssignSpeakerToSession.Request>{ req }
        );
        Test.stopTest();

        System.assert(!responses[0].success, 'Missing Ids should not succeed');
        System.assert(responses[0].message.contains('required'), 'Should explain the missing Ids');
    }

    @IsTest
    static void speakerNotFound_returnsCleanMessage() {
        Session__c session = new Session__c(Name = 'Session', Session_Date__c = Datetime.now());
        insert session;

        // Valid Id format, but no such Speaker__c record exists.
        Speaker__c ghost = new Speaker__c(Last_Name__c = 'Ghost');
        insert ghost;
        delete ghost;

        AssignSpeakerToSession.Request req = new AssignSpeakerToSession.Request();
        req.speakerId = ghost.Id;
        req.sessionId = session.Id;

        Test.startTest();
        List<AssignSpeakerToSession.Response> responses = AssignSpeakerToSession.assignSpeakers(
            new List<AssignSpeakerToSession.Request>{ req }
        );
        Test.stopTest();

        System.assert(!responses[0].success, 'Nonexistent speaker should fail');
        System.assert(responses[0].message.contains('No Speaker record was found'), 'Should explain the speaker was not found');
    }

    @IsTest
    static void sessionNotFound_returnsCleanMessage() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];

        Session__c ghost = new Session__c(Name = 'Ghost Session', Session_Date__c = Datetime.now());
        insert ghost;
        delete ghost;

        AssignSpeakerToSession.Request req = new AssignSpeakerToSession.Request();
        req.speakerId = speaker.Id;
        req.sessionId = ghost.Id;

        Test.startTest();
        List<AssignSpeakerToSession.Response> responses = AssignSpeakerToSession.assignSpeakers(
            new List<AssignSpeakerToSession.Request>{ req }
        );
        Test.stopTest();

        System.assert(!responses[0].success, 'Nonexistent session should fail');
        System.assert(responses[0].message.contains('No Session record was found'), 'Should explain the session was not found');
    }

    @IsTest
    static void invalidRole_returnsCleanMessageWithoutHittingDml() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];
        Session__c session = new Session__c(Name = 'Session', Session_Date__c = Datetime.now());
        insert session;

        AssignSpeakerToSession.Request req = new AssignSpeakerToSession.Request();
        req.speakerId = speaker.Id;
        req.sessionId = session.Id;
        req.role = 'Headliner';

        Test.startTest();
        List<AssignSpeakerToSession.Response> responses = AssignSpeakerToSession.assignSpeakers(
            new List<AssignSpeakerToSession.Request>{ req }
        );
        Test.stopTest();

        System.assert(!responses[0].success, 'Invalid role should fail validation');
        System.assert(responses[0].message.contains('not a valid Role'), 'Should list the invalid role and valid options');
        System.assertEquals(0, [SELECT COUNT() FROM Session_Speaker__c], 'No record should be created for an invalid role');
    }

    @IsTest
    static void cancelledSession_returnsTriggerMessageWithoutThrowing() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];
        Session__c cancelled = new Session__c(Name = 'Cancelled Session', Session_Date__c = Datetime.now(), Status__c = 'Cancelled');
        insert cancelled;

        AssignSpeakerToSession.Request req = new AssignSpeakerToSession.Request();
        req.speakerId = speaker.Id;
        req.sessionId = cancelled.Id;

        Test.startTest();
        List<AssignSpeakerToSession.Response> responses = AssignSpeakerToSession.assignSpeakers(
            new List<AssignSpeakerToSession.Request>{ req }
        );
        Test.stopTest();

        System.assert(!responses[0].success, 'Assignment to a cancelled session should fail');
        System.assert(responses[0].message.contains('cancelled'), 'Trigger error message should be surfaced, not thrown as an exception');
    }

    @IsTest
    static void doubleBooking_returnsTriggerMessageWithoutThrowing() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];
        Datetime base = Datetime.now();
        Session__c session1 = new Session__c(Name = 'Session 1', Session_Date__c = base, End_Date__c = base.addHours(1));
        Session__c session2 = new Session__c(Name = 'Session 2', Session_Date__c = base, End_Date__c = base.addHours(1));
        insert new List<Session__c>{ session1, session2 };
        insert new Session_Speaker__c(Session__c = session1.Id, Speaker__c = speaker.Id);

        AssignSpeakerToSession.Request req = new AssignSpeakerToSession.Request();
        req.speakerId = speaker.Id;
        req.sessionId = session2.Id;

        Test.startTest();
        List<AssignSpeakerToSession.Response> responses = AssignSpeakerToSession.assignSpeakers(
            new List<AssignSpeakerToSession.Request>{ req }
        );
        Test.stopTest();

        System.assert(!responses[0].success, 'Overlapping booking should fail');
        System.assert(responses[0].message.contains('overlapping'), 'Trigger error message should be surfaced, not thrown as an exception');
    }

    @IsTest
    static void duplicateAssignmentToSameSession_rejectedAsOverlap() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];
        Session__c session = new Session__c(Name = 'Session', Session_Date__c = Datetime.now(), End_Date__c = Datetime.now().addHours(1));
        insert session;
        insert new Session_Speaker__c(Session__c = session.Id, Speaker__c = speaker.Id);

        AssignSpeakerToSession.Request req = new AssignSpeakerToSession.Request();
        req.speakerId = speaker.Id;
        req.sessionId = session.Id;

        Test.startTest();
        List<AssignSpeakerToSession.Response> responses = AssignSpeakerToSession.assignSpeakers(
            new List<AssignSpeakerToSession.Request>{ req }
        );
        Test.stopTest();

        System.assert(!responses[0].success, 'Duplicate assignment to the same session should fail');
    }

    @IsTest
    static void bulkRequest_mixOfValidAndInvalid_reportsPerRecordResults() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];
        Session__c session = new Session__c(Name = 'Session', Session_Date__c = Datetime.now());
        insert session;

        AssignSpeakerToSession.Request valid = new AssignSpeakerToSession.Request();
        valid.speakerId = speaker.Id;
        valid.sessionId = session.Id;

        AssignSpeakerToSession.Request invalid = new AssignSpeakerToSession.Request();
        invalid.speakerId = null;
        invalid.sessionId = session.Id;

        Test.startTest();
        List<AssignSpeakerToSession.Response> responses = AssignSpeakerToSession.assignSpeakers(
            new List<AssignSpeakerToSession.Request>{ valid, invalid }
        );
        Test.stopTest();

        System.assertEquals(2, responses.size(), 'Should return one response per request, in order');
        System.assert(responses[0].success, 'First (valid) request should succeed');
        System.assert(!responses[1].success, 'Second (invalid) request should fail without affecting the first');
    }

    private static User createSessionSpeakerUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Session',
            LastName = 'Coordinator',
            Email = 'session.coordinator@animuscrm.test.invalid',
            Username = 'session.coordinator.' + DateTime.now().getTime() + '@animuscrm.test.invalid',
            Alias = 'sescoo',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert u;

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Session_Speaker_User' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);

        return u;
    }
}
