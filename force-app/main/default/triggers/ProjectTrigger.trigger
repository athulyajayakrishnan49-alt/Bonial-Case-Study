trigger ProjectTrigger on Project__c (after insert, after update, after delete, after undelete) {
    
    ProjectTriggerHandler.handleAfterEvents(
        Trigger.new, 
        Trigger.oldMap, 
        Trigger.operationType
    );
}