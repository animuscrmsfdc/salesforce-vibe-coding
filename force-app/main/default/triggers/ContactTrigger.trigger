/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-15-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger ContactTrigger on Contact (after insert, after update, after delete, after undelete) {
    switch on Trigger.operationType {
        when  AFTER_INSERT{
            ContactTriggerHandler.afterInsertHandler(Trigger.new);
        }

        when  AFTER_UPDATE{
            ContactTriggerHandler.afterUpdateHandler(Trigger.new, Trigger.oldMap);
        }

        when  AFTER_DELETE{
            ContactTriggerHandler.afterDeleteHandler(Trigger.old);
        }

        when  AFTER_UNDELETE{
            ContactTriggerHandler.afterUndeleteHandler(Trigger.new);
        }
    }
}