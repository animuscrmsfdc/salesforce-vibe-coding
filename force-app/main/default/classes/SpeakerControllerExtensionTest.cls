@IsTest
private class SpeakerControllerExtensionTest {

    @TestSetup
    static void makeData() {
        insert new Speaker__c(First_Name__c = 'Jane', Last_Name__c = 'Doe');
    }

    @IsTest
    static void save_noPicture_returnsPageRefAndNoError() {
        Speaker__c speaker = [SELECT Id, First_Name__c, Last_Name__c FROM Speaker__c LIMIT 1];
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(speaker);
        SpeakerControllerExtension ext = new SpeakerControllerExtension(stdCtrl);

        Test.startTest();
        PageReference pageRef = ext.save();
        Test.stopTest();

        System.assertEquals('', ext.errorMessage, 'errorMessage should be empty on successful save without picture');
        System.assertNotEquals(null, pageRef, 'save() should return a PageReference when no exception occurs');
    }

    @IsTest
    static void save_withPicture_createsContentVersionAndSetsLookup() {
        Speaker__c speaker = [SELECT Id, First_Name__c, Last_Name__c FROM Speaker__c LIMIT 1];
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(speaker);
        SpeakerControllerExtension ext = new SpeakerControllerExtension(stdCtrl);
        ext.picture = Blob.valueOf('FAKE_IMAGE_DATA');

        Test.startTest();
        PageReference pageRef = ext.save();
        Test.stopTest();

        System.assertEquals('', ext.errorMessage, 'errorMessage should be empty on successful save with picture');
        System.assertNotEquals(null, pageRef, 'save() should return a PageReference when no exception occurs');

        Speaker__c updated = [SELECT Picture_ContentDocument__c FROM Speaker__c WHERE Id = :speaker.Id];
        System.assertNotEquals(null, updated.Picture_ContentDocument__c, 'Picture_ContentDocument__c should be set after save with picture');

        ContentVersion cv = [SELECT Id, Title FROM ContentVersion WHERE Id = :updated.Picture_ContentDocument__c];
        System.assert(cv.Title.startsWith('Speaker_'), 'ContentVersion title should start with Speaker_');
    }

    @IsTest
    static void save_withPicture_contentVersionLinkedToSpeaker() {
        Speaker__c speaker = [SELECT Id, First_Name__c, Last_Name__c FROM Speaker__c LIMIT 1];
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(speaker);
        SpeakerControllerExtension ext = new SpeakerControllerExtension(stdCtrl);
        ext.picture = Blob.valueOf('TEST_PICTURE_BYTES');

        Test.startTest();
        ext.save();
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :speaker.Id
            WITH SECURITY_ENFORCED
        ];
        System.assertEquals(1, links.size(), 'Exactly one ContentDocumentLink should exist for the speaker');
    }
}
