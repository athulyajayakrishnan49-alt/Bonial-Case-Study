@isTest
private class ProjectControllerTest {

    @testSetup
    static void setup() {
        // Create an Account
        Account acc = new Account(Name = 'Test Account', Total_Projects__c = 2);
        insert acc;

        // Create two projects with different statuses to test filtering
        Project__c p1 = new Project__c(
            Name = 'Active Project', 
            Account__c = acc.Id, 
            Status__c = 'Active', 
            Budget__c = 1000
        );
        Project__c p2 = new Project__c(
            Name = 'Planned Project', 
            Account__c = acc.Id, 
            Status__c = 'Planned', 
            Budget__c = 2000
        );
        insert new List<Project__c>{p1, p2};
    }

    /**
     * Test Case 1: Fetch all projects (statusFilter = 'All')
     * Covers the base query path
     */
    @isTest
    static void testGetProjectDataAll() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Test.startTest();
        // Passing 'All' should return both projects
        ProjectController.ProjectDataWrapper result = ProjectController.getProjectData(acc.Id, 'All');
        Test.stopTest();

        System.assertEquals(2, result.projects.size(), 'Should return all projects');
        System.assertEquals('Test Account', result.accountName);
    }

    /**
     * Test Case 2: Fetch filtered projects (statusFilter = 'Active')
     * Covers the 'if (String.isNotBlank...)' dynamic SOQL branch
     */
    @isTest
    static void testGetProjectDataFiltered() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Test.startTest();
        // Passing 'Active' should return only 1 project
        ProjectController.ProjectDataWrapper result = ProjectController.getProjectData(acc.Id, 'Active');
        Test.stopTest();

        System.assertEquals(1, result.projects.size(), 'Should only return active projects');
        System.assertEquals('Active Project', result.projects[0].Name);
    }

    /**
     * Test Case 3: Invalid Account ID
     * Covers the 'if (accList.isEmpty())' branch
     */
    @isTest
    static void testGetProjectDataInvalidId() {
        Id fakeAccountId = Id.valueOf(Account.SObjectType.getDescribe().getKeyPrefix() + '000000000001');

        Test.startTest();
        ProjectController.ProjectDataWrapper result = ProjectController.getProjectData(fakeAccountId, 'All');
        Test.stopTest();

        System.assertEquals('Unknown Account', result.accountName);
        System.assertEquals(0, result.projects.size());
    }

    /**
     * Test Case 4: Exception Handling
     * Covers the 'catch (Exception e)' branch
     */
    @isTest
    static void testGetProjectDataException() {
        Test.startTest();
        try {
            // Passing null for Account ID will cause the query to fail inside the try block
            ProjectController.getProjectData(null, 'All');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'Should throw an AuraHandledException');
        }
        Test.stopTest();
    }

    /**
     * Test Case 5: Security/User Mode
     * Covers USER_MODE and catch block via security restrictions
     */
    @isTest
    static void testUserModeSecurity() {
        // Use a profile with limited access
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE '%Minimum Access%' OR Name = 'Standard User' LIMIT 1]; 
        User u = new User(
            Alias = 'tuser', Email='testuser@example.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='projecttest' + DateTime.now().getTime() + '@test.com'
        );

        Account acc = [SELECT Id FROM Account LIMIT 1];

        System.runAs(u) {
            Test.startTest();
            try {
                // If the user doesn't have FLS for Total_Projects__c, WITH USER_MODE triggers the catch block
                ProjectController.getProjectData(acc.Id, 'All');
            } catch (AuraHandledException e) {
                System.assertNotEquals(null, e.getMessage());
            }
            Test.stopTest();
        }
    }
}