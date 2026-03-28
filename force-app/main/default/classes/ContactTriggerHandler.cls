/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-15-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ContactTriggerHandler {
    public static void afterInsertHandler(List<Contact> newContacts){
        Set<Id> accountIds = new Set<Id>();
        for(Contact con : newContacts){
            if(String.isNotBlank(con.AccountId)){
                // write automation logic here
                accountIds.add(con.AccountId);
                String accountId = con.AccountId;
            }
        }
        AccountContactService.updateActiveContacts(accountIds);
    }

    public static void afterUpdateHandler(List<Contact> newContacts, Map<Id, Contact> oldContactsMap){
        Set<Id> accountIds = new Set<Id>();
        for(Contact con : newContacts){
            // capture the account id only if the Active__c field is flipped
            if(String.isNotBlank(con.AccountId) && oldContactsMap.get(con.Id).Active__c != con.Active__c){
                // write automation logic here
                accountIds.add(con.AccountId);
            }
            // checking if the AccountId is changed by the user so we need to recalculate both old and current account
            else if(oldContactsMap.get(con.Id).AccountId != con.AccountId){
                accountIds.add(con.AccountId);
                accountIds.add(oldContactsMap.get(con.Id).AccountId);
            }
        }
        AccountContactService.updateActiveContacts(accountIds);
    }

    public static void afterDeleteHandler(List<Contact> oldContacts){
        Set<Id> accountIds = new Set<Id>();
        for(Contact con : oldContacts){
            if(String.isNotBlank(con.AccountId)){
                // write automation logic here
                accountIds.add(con.AccountId);
                String accountId = con.AccountId;
            }
        }
        AccountContactService.updateActiveContacts(accountIds);
    }

    public static void afterUndeleteHandler(List<Contact> newContacts){
        Set<Id> accountIds = new Set<Id>();
        for(Contact con : newContacts){
            if(String.isNotBlank(con.AccountId)){
                // write automation logic here
                accountIds.add(con.AccountId);
                String accountId = con.AccountId;
            }
        }
        AccountContactService.updateActiveContacts(accountIds);
    }
}