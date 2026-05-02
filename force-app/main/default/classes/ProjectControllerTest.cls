@isTest
private class ProjectControllerTest {

    @isTest
    static void testGetProjectData_WithProjects() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Projects
        List<Project__c> projects = new List<Project__c>();
        for (Integer i = 0; i < 5; i++) {
            projects.add(new Project__c(
                Name = 'Project ' + i,
                Account__c = acc.Id,
                Status__c = 'Planned',
                Budget__c = 1000
            ));
        }
        insert projects;

        Test.startTest();
        Map<String, Object> result = ProjectController.getProjectData(acc.Id);
        Test.stopTest();

        // Assertions
        System.assertEquals('Test Account', (String) result.get('accountName'));
        System.assertEquals(acc.Total_Projects__c, result.get('totalProjects'));

        List<Project__c> resultProjects = (List<Project__c>) result.get('projects');
        System.assertEquals(5, resultProjects.size(), 'Should return 5 projects');
    }


    @isTest
    static void testGetProjectData_NoProjects() {
        // Create Account without projects
        Account acc = new Account(Name = 'Empty Account');
        insert acc;

        Test.startTest();
        Map<String, Object> result = ProjectController.getProjectData(acc.Id);
        Test.stopTest();

        // Assertions
        System.assertEquals('Empty Account', (String) result.get('accountName'));
        System.assertEquals(acc.Total_Projects__c, result.get('totalProjects'));

        List<Project__c> resultProjects = (List<Project__c>) result.get('projects');
        System.assertEquals(0, resultProjects.size(), 'Should return 0 projects');
    }


    @isTest
    static void testGetProjectData_InvalidAccount() {
        // Pass a fake Account Id
        Id fakeId = '001000000000000AAA';

        Test.startTest();
        Map<String, Object> result = ProjectController.getProjectData(fakeId);
        Test.stopTest();

        // Assertions
        System.assertEquals('Unknown Account', (String) result.get('accountName'));
        System.assertEquals(0, result.get('totalProjects'));

        List<Project__c> resultProjects = (List<Project__c>) result.get('projects');
        System.assertEquals(0, resultProjects.size(), 'Should return empty project list');
    }


    @isTest
    static void testGetProjectData_NullId() {
        Test.startTest();
        Map<String, Object> result = ProjectController.getProjectData(null);
        Test.stopTest();

        // Assertions (same as invalid account case)
        System.assertEquals('Unknown Account', (String) result.get('accountName'));
        System.assertEquals(0, result.get('totalProjects'));

        List<Project__c> resultProjects = (List<Project__c>) result.get('projects');
        System.assertEquals(0, resultProjects.size(), 'Should handle null safely');
    }
}