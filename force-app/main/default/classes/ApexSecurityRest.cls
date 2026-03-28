@RestResource(urlMapping='/apexSecurityRest')
global with sharing class ApexSecurityRest {
    @HttpGet
    global static Contact doGet() {
        Id recordId = RestContext.request.params.get('id');
        Contact result;
        List<Contact> results = [SELECT id, Name, Title, Top_Secret__c, Account.Name FROM Contact WHERE Id = :recordId];
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE,results);
        
        
        // Print stripped records
   		for (Integer i = 0; i < results.size(); i++) 
  		{
      		System.debug('Insecure record access: '+results[i]);
      		System.debug('Secure record access: '+decision.getRecords()[i]);
   		}
 		// Print modified indexes
   			System.debug('Records modified by stripInaccessible: '+decision.getModifiedIndexes());
 
		// Print removed fields
   			System.debug('Fields removed by stripInaccessible: '+decision.getRemovedFields());
	   
        result.Description = result.Account?.Name;
        return null;
    } 
      public class FunctionalException extends Exception{}
      public class SecurityException extends Exception{}
}