@IsTest
private class GetSpeakerSessionCountTest {

    @TestSetup
    static void makeData() {
        Speaker__c speaker1 = new Speaker__c(First_Name__c = 'Alice', Last_Name__c = 'Smith', Email__c = 'alice@example.com');
        Speaker__c speaker2 = new Speaker__c(First_Name__c = 'Bob',   Last_Name__c = 'Jones', Email__c = 'bob@example.com');
        insert new List<Speaker__c>{ speaker1, speaker2 };

        Session__c session1 = new Session__c(Session_Date__c = Date.today());
        Session__c session2 = new Session__c(Session_Date__c = Date.today().addDays(1));
        insert new List<Session__c>{ session1, session2 };

        insert new List<Session_Speaker__c>{
            new Session_Speaker__c(Speaker__c = speaker1.Id, Session__c = session1.Id),
            new Session_Speaker__c(Speaker__c = speaker1.Id, Session__c = session2.Id),
            new Session_Speaker__c(Speaker__c = speaker2.Id, Session__c = session1.Id)
        };
    }

    // ── ID-based ──────────────────────────────────────────────────────────────

    @IsTest
    static void singleSpeaker_withSessions_returnsCorrectCount() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c WHERE Last_Name__c = 'Smith' LIMIT 1];
        GetSpeakerSessionCount.Request req = new GetSpeakerSessionCount.Request();
        req.speakerId = speaker.Id;

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(2, responses[0].sessionCount, 'Smith should have 2 sessions');
    }

    @IsTest
    static void bulkRequest_multipleSpeakers_returnsCountsInOrder() {
        Speaker__c smith = [SELECT Id FROM Speaker__c WHERE Last_Name__c = 'Smith' LIMIT 1];
        Speaker__c jones = [SELECT Id FROM Speaker__c WHERE Last_Name__c = 'Jones' LIMIT 1];

        GetSpeakerSessionCount.Request req1 = new GetSpeakerSessionCount.Request();
        req1.speakerId = smith.Id;
        GetSpeakerSessionCount.Request req2 = new GetSpeakerSessionCount.Request();
        req2.speakerId = jones.Id;

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req1, req2 }
        );
        Test.stopTest();

        System.assertEquals(2, responses.size());
        System.assertEquals(2, responses[0].sessionCount, 'Smith should have 2 sessions');
        System.assertEquals(1, responses[1].sessionCount, 'Jones should have 1 session');
    }

    @IsTest
    static void speakerWithNoSessions_returnsZero() {
        Speaker__c speaker = new Speaker__c(Last_Name__c = 'NoSessions');
        insert speaker;

        GetSpeakerSessionCount.Request req = new GetSpeakerSessionCount.Request();
        req.speakerId = speaker.Id;

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(0, responses[0].sessionCount, 'Speaker with no sessions should return 0');
    }

    @IsTest
    static void duplicateSpeakerIdsInRequest_returnsCountForEachEntry() {
        Speaker__c smith = [SELECT Id FROM Speaker__c WHERE Last_Name__c = 'Smith' LIMIT 1];

        GetSpeakerSessionCount.Request req1 = new GetSpeakerSessionCount.Request();
        req1.speakerId = smith.Id;
        GetSpeakerSessionCount.Request req2 = new GetSpeakerSessionCount.Request();
        req2.speakerId = smith.Id;

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req1, req2 }
        );
        Test.stopTest();

        System.assertEquals(2, responses.size());
        System.assertEquals(2, responses[0].sessionCount);
        System.assertEquals(2, responses[1].sessionCount);
    }

    // ── Name-based (SOQL LIKE) ────────────────────────────────────────────────

    @IsTest
    static void lookupByFirstName_singleMatch_returnsCorrectCount() {
        GetSpeakerSessionCount.Request req = new GetSpeakerSessionCount.Request();
        req.firstName = 'Alice';

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(null, responses[0].errorMessage, 'Should not error on valid first name');
        System.assertEquals(false, responses[0].isAmbiguous, 'Should not be ambiguous');
        System.assertEquals(2, responses[0].sessionCount, 'Alice should have 2 sessions');
    }

    @IsTest
    static void lookupByLastName_singleMatch_returnsCorrectCount() {
        GetSpeakerSessionCount.Request req = new GetSpeakerSessionCount.Request();
        req.lastName = 'Jones';

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(null, responses[0].errorMessage);
        System.assertEquals(1, responses[0].sessionCount, 'Bob Jones should have 1 session');
    }

    @IsTest
    static void lookupByFirstAndLastName_singleMatch_returnsCorrectCount() {
        GetSpeakerSessionCount.Request req = new GetSpeakerSessionCount.Request();
        req.firstName = 'Alice';
        req.lastName  = 'Smith';

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(null, responses[0].errorMessage);
        System.assertEquals(2, responses[0].sessionCount, 'Alice Smith should have 2 sessions');
    }

    @IsTest
    static void lookupByFirstName_multipleMatches_returnsAmbiguous() {
        Speaker__c alice2 = new Speaker__c(First_Name__c = 'Alice', Last_Name__c = 'Brown');
        insert alice2;

        GetSpeakerSessionCount.Request req = new GetSpeakerSessionCount.Request();
        req.firstName = 'Alice';

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].isAmbiguous, 'Should be ambiguous with two Alices');
        System.assertEquals(2, responses[0].candidates.size(), 'Should return both Alices as candidates');
        System.assertEquals(null, responses[0].sessionCount, 'Count not resolved for ambiguous result');
    }

    @IsTest
    static void lookupByFirstName_noMatch_returnsErrorWithRecentSpeakers() {
        GetSpeakerSessionCount.Request req = new GetSpeakerSessionCount.Request();
        req.firstName = 'Zoltan';

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertNotEquals(null, responses[0].errorMessage, 'Should return an error for unknown name');
        System.assertEquals(false, responses[0].isAmbiguous);
        System.assert(responses[0].candidates.size() > 0, 'Should suggest recent speakers when no match found');
    }

    // ── Email-based (SOQL) ────────────────────────────────────────────────────

    @IsTest
    static void lookupByEmail_singleMatch_returnsCorrectCount() {
        GetSpeakerSessionCount.Request req = new GetSpeakerSessionCount.Request();
        req.email = 'alice@example.com';

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(null, responses[0].errorMessage);
        System.assertEquals(2, responses[0].sessionCount, 'Alice found by email should have 2 sessions');
    }

    @IsTest
    static void lookupByEmail_noMatch_returnsErrorWithRecentSpeakers() {
        GetSpeakerSessionCount.Request req = new GetSpeakerSessionCount.Request();
        req.email = 'nobody@example.com';

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertNotEquals(null, responses[0].errorMessage);
        System.assert(responses[0].candidates.size() > 0, 'Should suggest recent speakers when email not found');
    }

    // ── fullName → SOSL ───────────────────────────────────────────────────────

    @IsTest
    static void lookupByFullName_singleMatch_returnsCorrectCount() {
        Speaker__c alice = [SELECT Id FROM Speaker__c WHERE Last_Name__c = 'Smith' LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ alice.Id });

        GetSpeakerSessionCount.Request req = new GetSpeakerSessionCount.Request();
        req.fullName = 'Alice Smith';

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(null, responses[0].errorMessage);
        System.assertEquals(2, responses[0].sessionCount, 'Alice Smith found by fullName should have 2 sessions');
    }

    // ── Edge cases ────────────────────────────────────────────────────────────

    @IsTest
    static void emptyRequest_returnsEmptyResponse() {
        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>()
        );
        Test.stopTest();

        System.assertEquals(0, responses.size());
    }

    @IsTest
    static void noInput_returnsGracefulErrorMessage() {
        GetSpeakerSessionCount.Request req = new GetSpeakerSessionCount.Request();

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertNotEquals(null, responses[0].errorMessage, 'Should error when no input provided');
        System.assertEquals(false, responses[0].isAmbiguous);
    }
}
