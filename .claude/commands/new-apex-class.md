Create a new Apex class for the animuscrm project: $ARGUMENTS

Expected format: <ClassName> [type: trigger-handler|service|controller|batch|schedulable|queueable|test]

Steps:
1. Create force-app/main/default/classes/<ClassName>.cls
2. Create force-app/main/default/classes/<ClassName>.cls-meta.xml with apiVersion 66.0 and status Active
3. Apply the correct class template based on type:

   trigger-handler: public with sharing class, implements handler pattern (handleBeforeInsert, handleAfterInsert, etc.)
   service:         public with sharing class, static methods, WITH SECURITY_ENFORCED on all SOQL
   controller:      public with sharing class, @AuraEnabled methods, Security.stripInaccessible() on results
   batch:           global class implementing Database.Batchable<SObject>, with start/execute/finish methods
   schedulable:     global class implementing Schedulable, with execute(SchedulableContext sc) method
   queueable:       public class implementing Queueable, with execute(QueueableContext ctx) method
   test:            @IsTest class with @TestSetup, no SeeAllData=true, minimum 90% coverage target

4. All non-test classes must use `with sharing`
5. All SOQL must use bind variables (no string concatenation)
6. Show the deploy command after creation:
   sf project deploy start --metadata ApexClass:<ClassName> --target-org animuscrm
