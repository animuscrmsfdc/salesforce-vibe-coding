/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-22-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
// Bulkified code - regular List to store the values from query
public class UdemyOpportunityCcontroller {
    public static void updateProfile(List<Id> oppIds) {
            List<Opportunity> opps = [SELECT Id, Name, Amount, Profile__c FROM Opportunity WHERE Id IN: oppIds];
            for(Opportunity opp : opps){
                if(opp.Amount == null){
                    opp.Profile__c ='Low';
                } else if(opp.Amount < 10000){
                    opp.Profile__c ='Low';
                } else if (opp.Amount > 10000 && opp.Amount < 50000){
                    opp.Profile__c ='Medium';
                } else if (opp.Amount > 50000){
                    opp.Profile__c ='High';
                }      
            }
            update opps;
        }
}

/* Alternative improved bulkified code - A SOQL For Loop - this is reducing riks of hitting Heap Size in memory by processing in every loop only 200 records
public class UdemyOpportunityCcontroller {
    public static void updateProfile(List<Id> oppIds) {
            for(Opportunity opp : [SELECT Id, Name, Amount, Profile__c FROM Opportunity WHERE Id IN: oppIds]){
                if(opp.Amount == null){
                    opp.Profile__c ='Low';
                } else if(opp.Amount < 10000){
                    opp.Profile__c ='Low';
                } else if (opp.Amount > 10000 && opp.Amount < 50000){
                    opp.Profile__c ='Medium';
                } else if (opp.Amount > 50000){
                    opp.Profile__c ='High';
                }      
            }
            update oppIds;
        }
} */