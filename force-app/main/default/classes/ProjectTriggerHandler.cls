public with sharing class ProjectTriggerHandler {
    
    // Prevents infinite loops if other automation updates projects
    public static Boolean isFirstRun = true;

    /**
     * Main entry point for the Trigger logic
     */
    public static void handleAfterEvents(List<Project__c> newProjects, Map<Id, Project__c> oldMap, System.TriggerOperation triggerEvent) {
        if (!isFirstRun) return;
        
        Set<Id> accountIds = new Set<Id>();

        // 1. Collect Account IDs from Insert, Update, or Undelete
        if (newProjects != null) {
            for (Project__c p : newProjects) {
                if (p.Account__c != null) {
                    accountIds.add(p.Account__c); 
                }
                
                // Handle Re-parenting: collect the OLD account ID too
                if (triggerEvent == System.TriggerOperation.AFTER_UPDATE && oldMap != null) {
                    Id oldAccId = oldMap.get(p.Id).Account__c;
                    if (oldAccId != null && p.Account__c != oldAccId) {
                        accountIds.add(oldAccId);
                    }
                }
            }
        }

        // 2. Collect Account IDs from Delete (only oldMap is available)
        if (triggerEvent == System.TriggerOperation.AFTER_DELETE && oldMap != null) {
            for (Project__c p : oldMap.values()) {
                if (p.Account__c != null) {
                    accountIds.add(p.Account__c);
                }
            }
        }

        // 3. Process the updates
        if (!accountIds.isEmpty()) {
            updateAccountCounts(accountIds);
        }
    }

    /**
     * Logic to recalculate and update the Account field
     */
    private static void updateAccountCounts(Set<Id> accountIds) {
        List<Account> accountsToUpdate = new List<Account>();
        Map<Id, Integer> countsMap = new Map<Id, Integer>();

        // Aggregate query to get the total number of projects per account
        for (AggregateResult ar : [
            SELECT Account__c accId, COUNT(Id) total 
            FROM Project__c 
            WHERE Account__c IN :accountIds 
            GROUP BY Account__c
        ]) {
            countsMap.put((Id)ar.get('accId'), (Integer)ar.get('total'));
        }

        // Prepare the Account records for update
        for (Id accId : accountIds) {
            Integer count = countsMap.containsKey(accId) ? countsMap.get(accId) : 0;
            accountsToUpdate.add(new Account(
                Id = accId,
                Total_Projects__c = count
            ));
        }

        // 4. Secure DML with Error Handling
        if (!accountsToUpdate.isEmpty()) {
            try {
                // Set recursion guard to false to prevent loops during this DML
                isFirstRun = false;
                
                // SYSTEM_MODE allows the trigger to update the field even if it is Read-Only for the user
                Database.update(accountsToUpdate, AccessLevel.SYSTEM_MODE);
                
            } catch (System.DmlException dmlEx) {
               
                for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
                    System.debug('DML Error on Account ' + dmlEx.getDmlId(i) + ': ' + dmlEx.getDmlMessage(i));
                }
            } finally {
                
                isFirstRun = true;
            }
        }
    }
}