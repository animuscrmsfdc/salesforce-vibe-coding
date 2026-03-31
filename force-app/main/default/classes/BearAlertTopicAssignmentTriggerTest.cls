@IsTest
private class BearAlertTopicAssignmentTriggerTest {

    // -----------------------------------------------------------------------
    // Scenario 1 — TopicAssignment on a FeedItem entity fires the trigger.
    // The topic name is not 'BearAlert' so no platform events are published,
    // but the full trigger body executes covering all lines.
    // -----------------------------------------------------------------------
    @IsTest
    static void insertTopicAssignment_feedItemEntity_triggerFiresWithoutError() {
        Account acc = new Account(Name = 'Bear Test Account');
        insert acc;

        // Post a Chatter feed item on the account
        FeedItem post = new FeedItem(
            ParentId = acc.Id,
            Body     = 'Bear alert test post'
        );
        insert post;

        // Find or create a Topic
        Topic t;
        List<Topic> existing = [SELECT Id FROM Topic WHERE Name = 'BearTestTopic' LIMIT 1];
        if (!existing.isEmpty()) {
            t = existing[0];
        } else {
            t = new Topic(Name = 'BearTestTopic');
            insert t;
        }

        TopicAssignment ta = new TopicAssignment(
            EntityId = post.Id,
            TopicId  = t.Id
        );

        Test.startTest();
        insert ta;
        Test.stopTest();

        List<TopicAssignment> results = [SELECT Id FROM TopicAssignment WHERE Id = :ta.Id];
        System.assertEquals(1, results.size(), 'TopicAssignment on FeedItem should be inserted successfully');
    }
}
