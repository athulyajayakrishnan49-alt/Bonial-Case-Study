public with sharing class ProjectTriggerHandler {

    public static void handleProjectCount(List<Project__c> projects) {
        Set<Id> accountIds = new Set<Id>();

        for (Project__c p : projects) {
            if (p.Account__c != null) {
                accountIds.add(p.Account__c);
            }
        }

        updateAccountCounts(accountIds);
    }

    public static void handleReparenting(List<Project__c> newProjects, Map<Id, Project__c> oldMap) {
        Set<Id> accountIds = new Set<Id>();

        for (Project__c p : newProjects) {
            Project__c oldProj = oldMap.get(p.Id);

            // FIX: Handle re-parenting + removal of Account
            if (p.Account__c != oldProj.Account__c) {

                // New Account
                if (p.Account__c != null) {
                    accountIds.add(p.Account__c);
                }

                // Old Account (important for removal case)
                if (oldProj.Account__c != null) {
                    accountIds.add(oldProj.Account__c);
                }
            }
        }

        if (!accountIds.isEmpty()) {
            updateAccountCounts(accountIds);
        }
    }

    private static void updateAccountCounts(Set<Id> accountIds) {
        if (accountIds.isEmpty()) return;

        Map<Id, Integer> accountCountMap = new Map<Id, Integer>();

        for (AggregateResult ar : [
            SELECT Account__c accId, COUNT(Id) total
            FROM Project__c
            WHERE Account__c IN :accountIds
            GROUP BY Account__c
        ]) {
            accountCountMap.put(
                (Id) ar.get('accId'),
                (Integer) ar.get('total')
            );
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Id accId : accountIds) {
            Integer count = accountCountMap.containsKey(accId)
                ? accountCountMap.get(accId)
                : 0;

            accountsToUpdate.add(new Account(
                Id = accId,
                Total_Projects__c = count
            ));
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}