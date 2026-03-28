/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-08-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CTPersonController {
    
        public static String getToken(String mobileNo){
            Blob value = Blob.valueOf(mobileNo);
            Blob hash = Crypto.generateDigest('MD5', value);

            // get the string value of hash blob
            return EncodingUtil.base64Encode(hash);
        }

        public static List<Person__c> getRecentHealthChanges(){
            return [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c FROM Person__c ORDER BY Status_Update_Date__c DESC NULLS LAST LIMIT 100];
        }

        // Search a person by Name Mobile or Token
        public static List<Person__c> searchPeople(String searchTerm){
            searchTerm = searchTerm +'%';
            return [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                FROM Person__c 
                WHERE Name LIKE :searchTerm OR Mobile__c LIKE :searchTerm OR Token__c LIKE :searchTerm 
                ORDER BY Status_Update_Date__c DESC NULLS LAST];
        }

        // Search a person by Id
        public static Person__c getPersonById(String personId){
            List<Person__c> people = [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                FROM Person__c 
                WHERE Id =: personId];
            if(people != null && people.size() > 0){
                return people[0];
            }
            return null;
        }

        public static Map<String, Integer> getHealthStatusCount(){
            Map<String, Integer> healthCountMap = new Map<String, Integer>();
            for (AggregateResult ar : [SELECT Status__c, COUNT(Id) total 
                                        FROM Location__c 
                                        GROUP BY Status__c]){
                String healthStatus = String.valueOf(ar.get('Status__c'));
                Integer count = Integer.valueOf(ar.get('total'));
                healthCountMap.put(healthStatus, count);
            }
            return healthCountMap;
        }
}