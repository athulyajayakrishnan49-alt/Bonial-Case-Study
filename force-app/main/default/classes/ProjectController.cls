public with sharing class ProjectController {
    
    public class ProjectDataWrapper {
        @AuraEnabled public String accountName;
        @AuraEnabled public Integer totalProjects;
        @AuraEnabled public List<Project__c> projects;
    }

    @AuraEnabled(cacheable=true)
    public static ProjectDataWrapper getProjectData(Id accountId, String statusFilter) {
        ProjectDataWrapper wrapper = new ProjectDataWrapper();
        
        try {
            List<Account> accList = [
                SELECT Name, Total_Projects__c 
                FROM Account 
                WHERE Id = :accountId 
                WITH USER_MODE 
                LIMIT 1
            ];

            if (accList.isEmpty()) {
                wrapper.accountName = 'Unknown Account';
                wrapper.totalProjects = 0;
                wrapper.projects = new List<Project__c>();
                return wrapper;
            }

            wrapper.accountName = accList[0].Name;
            wrapper.totalProjects = accList[0].Total_Projects__c != null ? (Integer)accList[0].Total_Projects__c : 0;

            // Build Dynamic Query to support Filtering
            String query = 'SELECT Id, Name, Status__c, Budget__c FROM Project__c WHERE Account__c = :accountId';
            
            // Apply filter if it's not 'All' or blank
            if (String.isNotBlank(statusFilter) && statusFilter != 'All') {
                query += ' AND Status__c = :statusFilter';
            }
            
            query += ' WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 500';

            wrapper.projects = Database.query(query);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return wrapper;
    }
}