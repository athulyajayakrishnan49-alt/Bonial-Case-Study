trigger ProjectTrigger on Project__c (after insert, after update, after delete, after undelete) {
    // PASTE IT HERE:
    System.debug('TRIGGER RUNNING: Total records = ' + (Trigger.new != null ? Trigger.new.size() : Trigger.old.size()));

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUndelete) {
            ProjectTriggerHandler.handleProjectCount(Trigger.new);
        } 
        else if (Trigger.isUpdate) {
            ProjectTriggerHandler.handleReparenting(Trigger.new, Trigger.oldMap);
        } 
        else if (Trigger.isDelete) {
            ProjectTriggerHandler.handleProjectCount(Trigger.old);
        }
    }
}