/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-08-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CTLocationController {
    
    public static List<Location__c> getRecentStatusChanges(){
        return [SELECT Id, Name, Address__c, Pincode__c, Status_Update_Date__c 
            FROM Location__c
            ORDER BY Status_Update_Date__c DESC
            Nulls Last
            LIMIT 100];
    }

    public static  List<Location__c> searchLocations(String searchTerm){
        searchTerm = searchTerm +'%';
        return [SELECT Id, Name, Address__c, Pincode__c, Status_Update_Date__c 
            FROM Location__c
            WHERE Name LIKE :searchTerm OR Pincode__c LIKE :searchTerm OR  Address__c LIKE :searchTerm
            ORDER BY Status_Update_Date__c DESC];
    }

    public static Location__c getLocationById(String locationId){
        List<Location__c> location = [SELECT Id, Name, Address__c, Pincode__c, Status_Update_Date__c 
            FROM Location__c
            WHERE Id =: locationId];
            if(location != null && location.size() > 0){
                return location[0];
            }
            return null;
    }

    public static Map<String, Integer> getStatusCount(){
        Map<String, Integer> healthCountMap = new Map<String, Integer>();
        for (AggregateResult ar : [SELECT Health_Status__c, COUNT(Id) total 
                                    FROM Person__c 
                                    GROUP BY Health_Status__c]){
            String healthStatus = String.valueOf(ar.get('Health_Status__c'));
            Integer count = Integer.valueOf(ar.get('total'));
            healthCountMap.put(healthStatus, count);
        }
        return healthCountMap;
    }
}