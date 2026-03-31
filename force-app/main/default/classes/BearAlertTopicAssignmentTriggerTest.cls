@IsTest
private class BearAlertTopicAssignmentTriggerTest {

    // -----------------------------------------------------------------------
    // Scenario 1 — TopicAssignment on a FeedItem with a non-BearAlert topic.
    // Covers the trigger body up to the inner BearAlert-filter SOQL (feedIds populated,
    // FeedItem loaded, but no BearAlert match so messages list stays empty).
    // -----------------------------------------------------------------------
    @IsTest
    static void insertTopicAssignment_feedItemEntity_triggerFiresWithoutError() {
        Account acc = new Account(Name = 'Bear Test Account');
        insert acc;

        FeedItem post = new FeedItem(ParentId = acc.Id, Body = 'Bear alert test post');
        insert post;

        Topic t;
        List<Topic> existing = [SELECT Id FROM Topic WHERE Name = 'BearTestTopic' LIMIT 1];
        if (!existing.isEmpty()) {
            t = existing[0];
        } else {
            t = new Topic(Name = 'BearTestTopic');
            insert t;
        }

        Test.startTest();
        insert new TopicAssignment(EntityId = post.Id, TopicId = t.Id);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM TopicAssignment WHERE TopicId = :t.Id],
            'TopicAssignment on FeedItem should be inserted successfully');
    }

}
