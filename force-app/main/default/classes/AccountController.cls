/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AccountController {

    /*   EXERCISE TO FIX - YOU MUST BULKIFY THIS APEX CLASS
        public static void updateAvgCaseResolutionDays(Id accountId){
        Integer totalDays = 0, totalCases = 0;
        // retrive all the cases for this account
        // get resolution days for each account (ClosedDate - CreatedDate)
        for(Case caseObj : [SELECT Id, CreatedDate, ClosedDate
                             FROM Case
                             WHERE IsClosed=true
                            	AND AccountId =: accountId]){
            // increase number of cases
            totalCases++;
            // get duration in days and add it to totalDays
            totalDays += caseObj.CreatedDate.date().daysBetween(caseObj.ClosedDate.date());
        }
        Decimal resolutionDays = totalDays/totalCases;
        // update account object
        Account acc = new Account(Id=accountId, Avg_Case_Resolution_Days__c = resolutionDays);
        update acc;
    } */

    public static void updateAvgCaseResolutionDays(List <Id> accountIds){
        Map<Id, Integer> accountTotalCaseMap = new Map<Id, Integer>();
        Map<Id, Integer> accountTotalCaseDaysMap = new Map<Id, Integer>();
        
        if (Schema.sObjectType.Case.isAccessible() && Schema.sObjectType.Case.fields.ClosedDate.isAccessible()
            && Schema.sObjectType.Case.fields.AccountId.isAccessible()) {
            for(Case caseObj : [SELECT Id, CreatedDate, ClosedDate, AccountId FROM Case WHERE IsClosed=true AND AccountId IN :accountIds]){
                // If map doesnt have current AccountId, then add it
                if(! accountTotalCaseMap.containsKey(caseObj.AccountId)){
                    accountTotalCaseMap.put(caseObj.AccountId, 0);
                    accountTotalCaseDaysMap.put(caseObj.AccountId, 0);
                }
                Integer totalCases = accountTotalCaseMap.get(caseObj.AccountId);
                totalCases++;
                accountTotalCaseMap.put(caseObj.AccountId, totalCases);

                Integer totalDays = accountTotalCaseDaysMap.get(caseObj.AccountId);
                totalDays += caseObj.CreatedDate.date().daysBetween(caseObj.ClosedDate.date());
                accountTotalCaseDaysMap.put(caseObj.AccountId, totalDays);
            }
        }
        // list of accounts to update here below
        if (Schema.sObjectType.Account.isUpdateable() && Schema.sObjectType.Account.fields.Avg_Case_Resolution_Days__c.isUpdateable()) {
            List<Account> accountsToUpdate = new List<Account>();
            for(Id accountId: accountTotalCaseMap.keySet()){
                Decimal resolutionDays = accountTotalCaseDaysMap.get(accountId)/accountTotalCaseMap.get(accountId);
                accountsToUpdate.add(new Account(Id=accountId, Avg_Case_Resolution_Days__c = resolutionDays));
            }
            update accountsToUpdate;
        } else {
            return;
        }
    }
}