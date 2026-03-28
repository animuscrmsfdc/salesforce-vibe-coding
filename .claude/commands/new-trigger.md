Create a new Apex trigger and its handler class for a Salesforce object: $ARGUMENTS

Expected format: <ObjectName__c> [events: before insert, after insert, before update, after update, before delete, after delete, after undelete]

Steps:
1. Create force-app/main/default/triggers/<ObjectName>Trigger.trigger
   - One trigger per object (check if one already exists first)
   - Include all specified events (default: before insert, before update, after insert, after update)
   - Delegate immediately to a handler class — no logic in the trigger body itself

2. Create force-app/main/default/triggers/<ObjectName>Trigger.trigger-meta.xml
   - apiVersion: 66.0, status: Active

3. Create force-app/main/default/classes/<ObjectName>TriggerHandler.cls
   - public with sharing class
   - Separate methods per event: handleBeforeInsert, handleBeforeUpdate, handleAfterInsert, etc.
   - Accept Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap as parameters
   - Static boolean flag to prevent recursion

4. Create force-app/main/default/classes/<ObjectName>TriggerHandler.cls-meta.xml

5. Show deploy command after creation:
   sf project deploy start --metadata ApexTrigger:<ObjectName>Trigger,ApexClass:<ObjectName>TriggerHandler --target-org animuscrm
