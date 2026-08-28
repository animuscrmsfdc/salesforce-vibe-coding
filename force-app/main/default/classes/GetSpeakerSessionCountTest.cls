@IsTest
private class GetSpeakerSessionCountTest {

    @TestSetup
    static void makeData() {
        Speaker__c speaker1 = new Speaker__c(First_Name__c = 'Alice', Last_Name__c = 'Smith');
        Speaker__c speaker2 = new Speaker__c(First_Name__c = 'Bob',   Last_Name__c = 'Jones');
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

        System.assertEquals(1, responses.size(), 'Should return one response per request');
        System.assertEquals(2, responses[0].sessionCount, 'Smith should have 2 session records');
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

        System.assertEquals(2, responses.size(), 'Should return one response per request');
        System.assertEquals(2, responses[0].sessionCount, 'Smith should have 2 session records');
        System.assertEquals(1, responses[1].sessionCount, 'Jones should have 1 session record');
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

        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(0, responses[0].sessionCount, 'Speaker with no sessions should return 0');
    }

    @IsTest
    static void emptyRequest_returnsEmptyResponse() {
        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>()
        );
        Test.stopTest();

        System.assertEquals(0, responses.size(), 'Empty input should return empty response list');
    }

    @IsTest
    static void noInput_returnsGracefulErrorMessage() {
        GetSpeakerSessionCount.Request req = new GetSpeakerSessionCount.Request();

        Test.startTest();
        List<GetSpeakerSessionCount.Response> responses = GetSpeakerSessionCount.getSessionCounts(
            new List<GetSpeakerSessionCount.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertNotEquals(null, responses[0].errorMessage, 'Error message should be set when no input is provided');
        System.assertEquals(false, responses[0].isAmbiguous, 'isAmbiguous should be false on error');
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

        System.assertEquals(2, responses.size(), 'Should return one response per request entry');
        System.assertEquals(2, responses[0].sessionCount, 'First entry should reflect correct count');
        System.assertEquals(2, responses[1].sessionCount, 'Duplicate entry should return same count');
    }
}
