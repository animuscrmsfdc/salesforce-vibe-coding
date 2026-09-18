@IsTest
private class SessionSpeakerManagerControllerTest {

    @TestSetup
    static void makeData() {
        Speaker__c speaker = new Speaker__c(First_Name__c = 'Jane', Last_Name__c = 'Doe', Email__c = 'jane.doe@test.animuscrm.com');
        insert speaker;

        Session__c session = new Session__c(
            Name = 'Manager Controller Test Session',
            Session_Date__c = Datetime.now().addDays(1),
            End_Date__c = Datetime.now().addDays(1).addHours(2)
        );
        insert session;

        insert new Session_Speaker__c(Session__c = session.Id, Speaker__c = speaker.Id);
    }

    // ─── searchSessions ──────────────────────────────────────────────────────

    @IsTest
    static void searchSessions_blankTerm_triggersSecureQuery() {
        Test.startTest();
        try {
            List<Session__c> result = SessionSpeakerManagerController.searchSessions('');
            Assert.isNotNull(result, 'Blank term should return a list');
        } catch (System.QueryException e) {
            Assert.isTrue(e.getMessage().contains('Insufficient permissions'),
                'Only a FLS-related QueryException is acceptable here');
        }
        Test.stopTest();
    }

    @IsTest
    static void searchSessions_twoCharTerm_triggersSecureQuery() {
        Test.startTest();
        try {
            List<Session__c> result = SessionSpeakerManagerController.searchSessions('AB');
            Assert.isNotNull(result, 'Short term should return a list');
        } catch (System.QueryException e) {
            Assert.isTrue(e.getMessage().contains('Insufficient permissions'),
                'Only a FLS-related QueryException is acceptable for the short-term path');
        }
        Test.stopTest();
    }

    @IsTest
    static void searchSessions_validTerm_returnsSoslResults() {
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ session.Id });

        Test.startTest();
        List<Session__c> result = SessionSpeakerManagerController.searchSessions('Manager Controller Test Session');
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'SOSL branch should return the fixed search result');
    }

    // ─── searchSpeakers ──────────────────────────────────────────────────────

    @IsTest
    static void searchSpeakers_blankTerm_returnsAllUpToLimit() {
        Test.startTest();
        List<Speaker__c> result = SessionSpeakerManagerController.searchSpeakers('');
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null for blank speaker search');
        Assert.isTrue(result.size() >= 1, 'Expected at least 1 speaker record');
    }

    @IsTest
    static void searchSpeakers_validTerm_returnsSoslResults() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ speaker.Id });

        Test.startTest();
        List<Speaker__c> result = SessionSpeakerManagerController.searchSpeakers('Jane Doe');
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'SOSL branch should return the fixed speaker result');
    }

    // ─── getSessionSpeakers ──────────────────────────────────────────────────

    @IsTest
    static void getSessionSpeakers_nullId_returnsEmptyList() {
        Test.startTest();
        List<Session_Speaker__c> result = SessionSpeakerManagerController.getSessionSpeakers(null);
        Test.stopTest();

        Assert.isNotNull(result, 'Null Id should return an empty list, not null');
        Assert.areEqual(0, result.size(), 'Null Id should return an empty list');
    }

    @IsTest
    static void getSessionSpeakers_validId_returnsSpeakers() {
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];

        Test.startTest();
        List<Session_Speaker__c> result = SessionSpeakerManagerController.getSessionSpeakers(session.Id);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return the 1 session speaker created in @TestSetup');
    }

    // ─── getSessionSpeakersLive ──────────────────────────────────────────────

    @IsTest
    static void getSessionSpeakersLive_nullId_returnsEmptyList() {
        Test.startTest();
        List<Session_Speaker__c> result = SessionSpeakerManagerController.getSessionSpeakersLive(null);
        Test.stopTest();

        Assert.areEqual(0, result.size(), 'Null Id should return empty list from live method');
    }

    @IsTest
    static void getSessionSpeakersLive_validId_returnsSpeakers() {
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];

        Test.startTest();
        List<Session_Speaker__c> result = SessionSpeakerManagerController.getSessionSpeakersLive(session.Id);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Live method should return session speakers');
    }

    // ─── saveSession ─────────────────────────────────────────────────────────

    @IsTest
    static void saveSession_newSession_persistsAndReturnsWithId() {
        Session__c newSession = new Session__c(
            Name = 'Brand New Session',
            Session_Date__c = Datetime.now().addDays(7),
            End_Date__c = Datetime.now().addDays(7).addHours(1)
        );

        Test.startTest();
        Session__c saved = SessionSpeakerManagerController.saveSession(newSession);
        Test.stopTest();

        Assert.isNotNull(saved.Id, 'Saved session should have an Id after insert');
        Assert.areEqual('Brand New Session', saved.Name, 'Returned session name should match');
    }

    @IsTest
    static void saveSession_updateExisting_persistsChange() {
        Session__c session = [SELECT Id, Name FROM Session__c LIMIT 1];
        session.Name = 'Updated Session Name';

        Test.startTest();
        Session__c saved = SessionSpeakerManagerController.saveSession(session);
        Test.stopTest();

        Assert.areEqual('Updated Session Name', saved.Name, 'Updated name should be persisted and returned');
    }

    // ─── saveSpeaker ─────────────────────────────────────────────────────────

    @IsTest
    static void saveSpeaker_newSpeaker_persistsAndReturnsWithId() {
        Speaker__c newSpeaker = new Speaker__c(First_Name__c = 'John', Last_Name__c = 'Smith');

        Test.startTest();
        Speaker__c saved = SessionSpeakerManagerController.saveSpeaker(newSpeaker);
        Test.stopTest();

        Assert.isNotNull(saved.Id, 'Saved speaker should have an Id after insert');
        Assert.areEqual('John', saved.First_Name__c, 'First name should match');
    }

    @IsTest
    static void saveSpeaker_updateExisting_persistsChange() {
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];
        speaker.Email__c = 'updated@test.animuscrm.com';

        Test.startTest();
        Speaker__c saved = SessionSpeakerManagerController.saveSpeaker(speaker);
        Test.stopTest();

        Assert.areEqual('updated@test.animuscrm.com', saved.Email__c, 'Updated email should be returned');
    }

    // ─── saveSessionSpeaker ──────────────────────────────────────────────────

    @IsTest
    static void saveSessionSpeaker_insert_createsJunctionRecord() {
        Speaker__c extra = new Speaker__c(First_Name__c = 'Extra', Last_Name__c = 'Speaker');
        insert extra;
        Session__c extraSess = new Session__c(
            Name = 'Extra Session',
            Session_Date__c = Datetime.now().addDays(14),
            End_Date__c = Datetime.now().addDays(14).addHours(1)
        );
        insert extraSess;

        Test.startTest();
        SessionSpeakerManagerController.saveSessionSpeaker(
            new Session_Speaker__c(Session__c = extraSess.Id, Speaker__c = extra.Id)
        );
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Session_Speaker__c WHERE Session__c = :extraSess.Id],
            'Junction record should be created');
    }

    @IsTest
    static void saveSessionSpeaker_update_doesNotThrow() {
        Session_Speaker__c ss = [SELECT Id FROM Session_Speaker__c LIMIT 1];

        Test.startTest();
        try {
            SessionSpeakerManagerController.saveSessionSpeaker(ss);
            Assert.isTrue(true, 'Update path should not throw');
        } catch (Exception e) {
            Assert.fail('saveSessionSpeaker update path threw unexpectedly: ' + e.getMessage());
        }
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Session_Speaker__c WHERE Id = :ss.Id],
            'Record should still exist after update');
    }

    // ─── removeSessionSpeaker ────────────────────────────────────────────────

    @IsTest
    static void removeSessionSpeaker_validId_deletesRecord() {
        Session_Speaker__c ss = [SELECT Id FROM Session_Speaker__c LIMIT 1];

        Test.startTest();
        SessionSpeakerManagerController.removeSessionSpeaker(ss.Id);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Session_Speaker__c WHERE Id = :ss.Id],
            'Session speaker should be deleted');
    }

    @IsTest
    static void removeSessionSpeaker_nullId_doesNotThrow() {
        Test.startTest();
        try {
            SessionSpeakerManagerController.removeSessionSpeaker(null);
            Assert.isTrue(true, 'No exception expected for null Id');
        } catch (Exception e) {
            Assert.fail('removeSessionSpeaker should not throw for a null Id: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
