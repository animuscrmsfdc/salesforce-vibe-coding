/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-09-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class LeadTriggerHandler {
    
    public static Boolean alreadyExecuted = false;

    public static void beforeInsertHandler(List<Lead> newRecords) {
        for (Lead leadRecord : newRecords){
            // if LeadSource is blank then populate with 'Other'
            if(String.isBlank(leadRecord.LeadSource)){
                leadRecord.LeadSource = 'Other';
            }
            // validation rule to throw error of Industry is blank
            if(String.isBlank(leadRecord.Industry)){
                leadRecord.addError('The Industry field cannot be blank');
            }
        }
    } 
    
    public static void afterInsertHandler(List<Lead> newRecords) {
        List<Task> leadTasks = new List<Task>();
        for (Lead leadRecord : newRecords){
            // create new Task
            Task leadTask = new Task(Subject='Follow up on Lead Status', WhoId=leadRecord.Id);
            leadTasks.add(leadTask);
        }
        insert leadTasks;
        // add new Lead and control it recursively
        if(LeadTriggerHandler.alreadyExecuted == false){
            LeadTriggerHandler.alreadyExecuted = true;
            Lead anotherLead = new Lead(LastName='Test lead single', Status='Open - Not Contacted', Industry='Agriculture', Company='Test Company');
            insert anotherLead;
            
        }
    }

    public static void beforeUpdateHandler(List<Lead> newRecords, Map<Id, Lead> oldRecordsMap) {
        for (Lead leadRecord : newRecords){
            // if LeadSource is blank then populate with 'Other'
            if(String.isBlank(leadRecord.LeadSource)){
                leadRecord.LeadSource = 'Other';
            }
            
            if((leadRecord.Status == 'Closed - Converted' || leadRecord.Status == 'Closed - Not Converted') && 
            oldRecordsMap.get(leadRecord.Id).Status == 'Open - Not Contacted'){
                leadRecord.Status.addError('You cannot directly close an open lead record');
            }
        }
    }
}