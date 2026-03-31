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
    static void save_withPicture_setsPathAndNoError() {
        Speaker__c speaker = [SELECT Id, First_Name__c, Last_Name__c FROM Speaker__c LIMIT 1];
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(speaker);
        SpeakerControllerExtension ext = new SpeakerControllerExtension(stdCtrl);
        ext.picture = Blob.valueOf('FAKE_IMAGE_DATA');

        Test.startTest();
        PageReference pageRef = ext.save();
        Test.stopTest();

        System.assertEquals('', ext.errorMessage, 'errorMessage should be empty on successful save with picture');

        Speaker__c updated = [SELECT Picture_Path__c FROM Speaker__c WHERE Id = :speaker.Id];
        System.assertNotEquals(null, updated.Picture_Path__c, 'Picture_Path__c should be set after save with picture');
        System.assert(
            updated.Picture_Path__c.startsWith('/servlet/servlet.FileDownload?file='),
            'Picture_Path__c should start with expected servlet path'
        );
    }
}
