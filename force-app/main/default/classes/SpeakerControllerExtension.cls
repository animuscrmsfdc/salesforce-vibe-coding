public with sharing class SpeakerControllerExtension {

    public Blob picture { get; set; }
    public String errorMessage { get; set; }

    private final Speaker__c speaker;

    public SpeakerControllerExtension(ApexPages.StandardController stdController) {
        this.speaker = (Speaker__c) stdController.getRecord();
    }

    public PageReference save() {
        errorMessage = '';
        try {
            SObjectAccessDecision upsertDecision = Security.stripInaccessible(
                AccessType.UPSERTABLE,
                new List<Speaker__c>{ speaker }
            );
            upsert (Speaker__c) upsertDecision.getRecords()[0];

            if (picture != null) {
                ContentVersion cv = new ContentVersion();
                cv.Title = 'Speaker_' + speaker.Id;
                cv.PathOnClient = 'Speaker_' + speaker.Id + '.jpg';
                cv.VersionData = picture;
                cv.FirstPublishLocationId = speaker.Id;

                SObjectAccessDecision cvDecision = Security.stripInaccessible(
                    AccessType.CREATABLE,
                    new List<ContentVersion>{ cv }
                );
                ContentVersion toInsert = (ContentVersion) cvDecision.getRecords()[0];
                if (toInsert.FirstPublishLocationId == null) {
                    errorMessage = 'Insufficient permissions to attach a picture to this speaker.';
                    return null;
                }
                insert toInsert;

                Speaker__c toUpdate = new Speaker__c(
                    Id = speaker.Id,
                    Picture_ContentDocument__c = toInsert.Id
                );
                SObjectAccessDecision updateDecision = Security.stripInaccessible(
                    AccessType.UPDATABLE,
                    new List<Speaker__c>{ toUpdate }
                );
                update (Speaker__c) updateDecision.getRecords()[0];
            }

            return new ApexPages.StandardController(speaker).view();
        } catch (System.Exception ex) {
            errorMessage = ex.getMessage();
            return null;
        }
    }
}
