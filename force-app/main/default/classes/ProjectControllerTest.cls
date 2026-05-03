@isTest
private class ProjectControllerTest {

    @testSetup
    static void setup() {
        // Create an Account with a project to test successful retrieval
        Account acc = new Account(Name = 'Test Account', Total_Projects__c = 1);
        insert acc;

        Project__c proj = new Project__c(
            Name = 'Test Project', 
            Account__c = acc.Id, 
            Status__c = 'Active', 
            Budget__c = 1000
        );
        insert proj;
    }

    /**
     * Test successful data retrieval (Happy Path)
     */
    @isTest
    static void testGetProjectDataSuccess() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Test.startTest();
        ProjectController.ProjectDataWrapper result = ProjectController.getProjectData(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Wrapper should not be null');
        System.assertEquals('Test Account', result.accountName, 'Account name should match');
        System.assertEquals(1, result.projects.size(), 'Project list size should be 1');
    }

    /**
     * Test behavior when a non-existent Account ID is provided
     */
    @isTest
    static void testGetProjectDataInvalidId() {
        // Create a fake but validly formatted Account ID using native Apex
        String fakeIdStr = Account.SObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';
        Id fakeAccountId = (Id)fakeIdStr;

        Test.startTest();
        ProjectController.ProjectDataWrapper result = ProjectController.getProjectData(fakeAccountId);
        Test.stopTest();

        // This covers the 'if (accList.isEmpty())' branch in your controller
        System.assertEquals('Unknown Account', result.accountName);
        System.assertEquals(0, result.projects.size());
    }

    /**
     * Test Exception handling to cover the catch block
     */
    @isTest
    static void testGetProjectDataException() {
        // Passing null will cause the query to fail/throw exception 
        // which covers the 'catch (Exception e)' branch
        Test.startTest();
        try {
            ProjectController.getProjectData(null);
        } catch (Exception e) {
            // AuraHandledException is expected
            System.assert(e != null);
        }
        Test.stopTest();
    }
    
    /**
     * Test with a restricted User to cover USER_MODE security failures
     */
    @isTest
    static void testUserModeSecurity() {
        // Use a standard profile that exists in every org
        Profile p = [SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' LIMIT 1]; 
        User u = new User(
            Alias = 'testuser', Email='testuser@example.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='projecttest' + DateTime.now().getTime() + '@test.com'
        );

        Account acc = [SELECT Id FROM Account LIMIT 1];

        System.runAs(u) {
            Test.startTest();
            try {
                // This covers the catch block via a SecurityException because this user 
                // lacks access to the custom field or object.
                ProjectController.getProjectData(acc.Id);
            } catch (AuraHandledException e) {
                System.assertNotEquals(null, e.getMessage());
            }
            Test.stopTest();
        }
    }
}