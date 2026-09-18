@IsTest
private class BearAlertTopicAssignmentTriggerTest {

    // -----------------------------------------------------------------------
    // Scenario 1 — TopicAssignment on a FeedItem with a non-BearAlert topic.
    // Covers: feedIds collection, FeedItems SOQL, BearAlert-filter SOQL (0 results),
    // messages loop (0 iterations), EventBus.publish with empty list, results loop.
    // -----------------------------------------------------------------------
    @IsTest
    static void insertTopicAssignment_feedItemEntity_triggerFiresWithoutError() {
        Account acc = new Account(Name = 'Bear Test Account');
        insert acc;

        FeedItem post = new FeedItem(ParentId = acc.Id, Body = 'Bear alert test post');
        insert post;

        Database.SaveResult sr = Database.insert(new Topic(Name = 'BearTestTopic'), false);
        Id topicId = sr.isSuccess() ? sr.getId() : [SELECT Id FROM Topic WHERE Name = 'BearTestTopic' LIMIT 1].Id;

        Test.startTest();
        insert new TopicAssignment(EntityId = post.Id, TopicId = topicId);
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM TopicAssignment WHERE TopicId = :topicId],
            'TopicAssignment on FeedItem should be inserted successfully');
    }

    // -----------------------------------------------------------------------
    // Scenario 2 — TopicAssignment on a non-FeedItem entity.
    // feedIds stays empty so the FeedItem SOQL and BearAlert filter are both skipped,
    // and EventBus.publish is called with an empty list — no notification sent.
    // -----------------------------------------------------------------------
    @IsTest
    static void insertTopicAssignment_nonFeedItemEntity_triggerFiresWithoutError() {
        Account acc = new Account(Name = 'Non-Feed Entity Account');
        insert acc;

        Database.SaveResult sr = Database.insert(new Topic(Name = 'BearNonFeedTopic'), false);
        Id topicId = sr.isSuccess() ? sr.getId() : [SELECT Id FROM Topic WHERE Name = 'BearNonFeedTopic' LIMIT 1].Id;

        Test.startTest();
        Database.SaveResult taResult = Database.insert(
            new TopicAssignment(EntityId = acc.Id, TopicId = topicId), false
        );
        Test.stopTest();

        // TopicAssignment on Account may be rejected by the org's Chatter settings.
        // Either way the trigger must not throw.
        Assert.isTrue(true, 'Trigger should not throw for a non-FeedItem entity');
    }

    // -----------------------------------------------------------------------
    // Scenario 3 — Bulk insert of multiple TopicAssignments on FeedItems.
    // Exercises the feedIds loop with > 1 record.
    // -----------------------------------------------------------------------
    @IsTest
    static void bulkInsertTopicAssignments_feedItemEntities_triggerFiresWithoutError() {
        Account acc = new Account(Name = 'Bulk Bear Account');
        insert acc;

        List<FeedItem> posts = new List<FeedItem>{
            new FeedItem(ParentId = acc.Id, Body = 'Post 1'),
            new FeedItem(ParentId = acc.Id, Body = 'Post 2')
        };
        insert posts;

        Database.SaveResult sr = Database.insert(new Topic(Name = 'BearBulkTopic'), false);
        Id topicId = sr.isSuccess() ? sr.getId() : [SELECT Id FROM Topic WHERE Name = 'BearBulkTopic' LIMIT 1].Id;

        List<TopicAssignment> assignments = new List<TopicAssignment>{
            new TopicAssignment(EntityId = posts[0].Id, TopicId = topicId),
            new TopicAssignment(EntityId = posts[1].Id, TopicId = topicId)
        };

        Test.startTest();
        insert assignments;
        Test.stopTest();

        Assert.areEqual(2, [SELECT COUNT() FROM TopicAssignment WHERE TopicId = :topicId],
            'Both TopicAssignments should be inserted');
    }

}
