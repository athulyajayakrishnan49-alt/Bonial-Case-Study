public with sharing class ProjectController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getProjectData(Id accountId) {

        Map<String, Object> result = new Map<String, Object>();

        // Safe Account fetch using List to avoid "Query has no rows" errors
        List<Account> accList = [
            SELECT Name, Total_Projects__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        if (accList.isEmpty()) {
            result.put('accountName', 'Unknown Account');
            result.put('totalProjects', 0);
            result.put('projects', new List<Project__c>());
            return result;
        }

        Account acc = accList[0];
        result.put('accountName', acc.Name);
        result.put('totalProjects', acc.Total_Projects__c);

        // Fetch projects with a performance LIMIT
        List<Project__c> projects = [
            SELECT Id, Name, Status__c, Budget__c
            FROM Project__c
            WHERE Account__c = :accountId
            ORDER BY CreatedDate DESC
            LIMIT 500
        ];

        result.put('projects', projects);
        return result;
    }
}