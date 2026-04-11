@IsTest
private class SessionSpeakerTriggerHandlerTest {

    @TestSetup
    static void makeData() {
        insert new Speaker__c(First_Name__c = 'John', Last_Name__c = 'Smith');
    }

    @IsTest
    static void singleBooking_succeeds() {
        Datetime now = Datetime.now();
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];
        Session__c session = new Session__c(
            Name = 'Some Session',
            Session_Date__c = now,
            End_Date__c = now.addHours(1)
        );
        insert session;

        Database.SaveResult result = Database.insert(
            new Session_Speaker__c(Session__c = session.Id, Speaker__c = speaker.Id),
            false
        );

        System.assert(result.isSuccess(), 'Single booking should succeed');
    }

    @IsTest
    static void doubleBooking_sameExactTime_rejected() {
        Datetime now = Datetime.now();
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];

        Session__c session1 = new Session__c(Name = 'Session 1', Session_Date__c = now, End_Date__c = now.addHours(1));
        Session__c session2 = new Session__c(Name = 'Session 2', Session_Date__c = now, End_Date__c = now.addHours(1));
        insert new List<Session__c>{ session1, session2 };

        insert new Session_Speaker__c(Session__c = session1.Id, Speaker__c = speaker.Id);

        Database.SaveResult result = Database.insert(
            new Session_Speaker__c(Session__c = session2.Id, Speaker__c = speaker.Id),
            false
        );

        System.assert(!result.isSuccess(), 'Exact time double-booking should be rejected');
    }

    @IsTest
    static void overlappingSession_rejected() {
        Datetime base = Datetime.now();
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];

        // Session 1: 14:00 – 15:00
        Session__c session1 = new Session__c(
            Name = 'Morning',
            Session_Date__c = base,
            End_Date__c = base.addHours(1)
        );
        // Session 2: 14:30 – 15:30 (overlaps with session1)
        Session__c session2 = new Session__c(
            Name = 'Overlapping',
            Session_Date__c = base.addMinutes(30),
            End_Date__c = base.addMinutes(90)
        );
        insert new List<Session__c>{ session1, session2 };

        insert new Session_Speaker__c(Session__c = session1.Id, Speaker__c = speaker.Id);

        Database.SaveResult result = Database.insert(
            new Session_Speaker__c(Session__c = session2.Id, Speaker__c = speaker.Id),
            false
        );

        System.assert(!result.isSuccess(), 'Overlapping session booking should be rejected');
    }

    @IsTest
    static void nonOverlappingSession_succeeds() {
        Datetime base = Datetime.now();
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];

        // Session 1: 14:00 – 15:00
        Session__c session1 = new Session__c(
            Name = 'First',
            Session_Date__c = base,
            End_Date__c = base.addHours(1)
        );
        // Session 2: 15:00 – 16:00 (back to back, no overlap)
        Session__c session2 = new Session__c(
            Name = 'Second',
            Session_Date__c = base.addHours(1),
            End_Date__c = base.addHours(2)
        );
        insert new List<Session__c>{ session1, session2 };

        insert new Session_Speaker__c(Session__c = session1.Id, Speaker__c = speaker.Id);

        Database.SaveResult result = Database.insert(
            new Session_Speaker__c(Session__c = session2.Id, Speaker__c = speaker.Id),
            false
        );

        System.assert(result.isSuccess(), 'Non-overlapping back-to-back sessions should be allowed');
    }

    @IsTest
    static void cancelledSession_assignmentRejected() {
        Datetime now = Datetime.now();
        Speaker__c speaker = [SELECT Id FROM Speaker__c LIMIT 1];

        Session__c cancelled = new Session__c(
            Name = 'Cancelled Session',
            Session_Date__c = now,
            End_Date__c = now.addHours(1),
            Status__c = 'Cancelled'
        );
        insert cancelled;

        Database.SaveResult result = Database.insert(
            new Session_Speaker__c(Session__c = cancelled.Id, Speaker__c = speaker.Id),
            false
        );

        System.assert(!result.isSuccess(), 'Assignment to a cancelled session should be rejected');
    }
}
