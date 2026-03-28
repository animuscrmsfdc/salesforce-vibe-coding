/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-09-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger Lead on Lead (before insert, after insert, before update, after update) {
    
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            LeadTriggerHandler.beforeInsertHandler(Trigger.new);
        }

        when AFTER_INSERT {
            LeadTriggerHandler.afterInsertHandler(Trigger.new);  
        }

        when BEFORE_UPDATE {
            LeadTriggerHandler.beforeUpdateHandler(Trigger.new, Trigger.oldMap);   
        }
    }
}