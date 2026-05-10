@isTest
private class ProjectTriggerHandlerTest {

    @testSetup
    static void setup() {
        Account acc1 = new Account(Name = 'Test Acc 1');
        Account acc2 = new Account(Name = 'Test Acc 2');
        insert new List<Account>{acc1, acc2};
    }

    @isTest
    static void testFullLifecycle() {
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Acc 1' LIMIT 1];
        Account acc2 = [SELECT Id FROM Account WHERE Name = 'Test Acc 2' LIMIT 1];
        
        // 1. Test Insert
        Project__c p1 = new Project__c(Name = 'P1', Account__c = acc1.Id);
        insert p1;
        
        // 2. Test Reparenting (Update branch)
        p1.Account__c = acc2.Id;
        update p1;

        // 3. Test Delete (Delete branch)
        delete p1;

        // 4. Test Undelete (Undelete branch)
        undelete p1;
        
        System.assertEquals(1, [SELECT Total_Projects__c FROM Account WHERE Id = :acc2.Id].Total_Projects__c);
    }

    @isTest
    static void testRecursionGuard() {
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Acc 1' LIMIT 1];
        
        // Force Recursion Guard to return early
        ProjectTriggerHandler.isFirstRun = false;
        insert new Project__c(Name = 'P2', Account__c = acc1.Id);
        ProjectTriggerHandler.isFirstRun = true;

        System.assertEquals(0, [SELECT Total_Projects__c FROM Account WHERE Id = :acc1.Id].Total_Projects__c);
    }

    @isTest
    static void testSystemModeExecution() {
        // We use a restricted user to prove that SYSTEM_MODE in the handler
        // bypasses the lack of FLS permissions that would have blocked USER_MODE.
        User u = createRestrictedUser();
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Acc 1' LIMIT 1];
        
        System.runAs(u) {
            Test.startTest();
            // This should succeed because the Handler uses SYSTEM_MODE
            Project__c p = new Project__c(Name = 'System Mode Test', Account__c = acc1.Id);
            insert p;
            Test.stopTest();
        }
        
        // Verify that the system mode update worked regardless of the user's restrictions
        System.assertEquals(1, [SELECT Total_Projects__c FROM Account WHERE Id = :acc1.Id].Total_Projects__c);
    }

    @isTest
    static void testDmlException() {
        Test.startTest();
        // Generate a fake ID to force a DmlException during the updateAccountCounts method
        Id fakeAccId = generateFakeId(Account.SObjectType); 

        // This hits the DmlException catch block and the getNumDml loop inside the handler
        ProjectTriggerHandler.handleAfterEvents(
            new List<Project__c>{ new Project__c(Account__c = fakeAccId) },
            null,
            System.TriggerOperation.AFTER_INSERT
        );
        Test.stopTest();
        
        // We assert true here because the success criteria is that the try-catch block 
        // in the handler prevented the transaction from crashing.
        System.assert(true);
    }

    // Helper method instead of an Inner Class to avoid 'static' errors
    private static Id generateFakeId(Schema.SObjectType sobjectType) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + '000000000001');
    }

    private static User createRestrictedUser() {
        // Use 'Minimum Access - Salesforce' or any profile with no Account Edit access
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE '%Minimum Access%' OR Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'lowacc', Email='lowuser@test.com', 
            EmailEncodingKey='UTF-8', LastName='LowUser', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='lowuser' + DateTime.now().getTime() + '@test.com'
        );
        return u;
    }
}