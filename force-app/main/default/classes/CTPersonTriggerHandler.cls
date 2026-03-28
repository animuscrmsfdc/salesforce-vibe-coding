/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-22-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CTPersonTriggerHandler {
    public static void beforeInsert(List<Person__c> newRecords ) {
        // Before insert operation
        // make sure the health status is green
        // generate unique token for each record
        for(Person__c person : newRecords){
            // update person status
            person.Health_Status__c = 'Green';
            // update unique token
            person.Token__c = CTPersonController.getToken(person.Mobile__c);
        } 
    }

    public static void beforeUpdate(List<Person__c> newRecords, Map<Id, Person__c> oldRecordsMap) {
        // Before update operation
        for(Person__c person : newRecords)
            // check if the Health Status has changed
            // if changed then update the date
            if(person.Health_Status__c != oldRecordsMap.get(person.Id).Health_Status__c){
                person.Status_Update_Date__c = Date.Today();
            }
    }
}