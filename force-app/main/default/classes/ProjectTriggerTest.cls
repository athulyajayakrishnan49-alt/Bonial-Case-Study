@isTest
private class ProjectTriggerTest {

    @isTest
    static void testBulkInsertAndDelete() {
        // Create test account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create 200 projects
        List<Project__c> projs = new List<Project__c>();
        for (Integer i = 0; i < 200; i++) {
            projs.add(new Project__c(
                Account__c = acc.Id,
                Status__c = 'Planned'
            ));
        }

        Test.startTest();

        // Insert projects
        insert projs;

        // Verify count after insert
        Account checkAcc = [
            SELECT Total_Projects__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        System.assertEquals(
            200,
            checkAcc.Total_Projects__c,
            'Should count 200 projects'
        );

        // Delete projects
        delete projs;

        // Verify count after delete
        checkAcc = [
            SELECT Total_Projects__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        System.assertEquals(
            0,
            checkAcc.Total_Projects__c,
            'Should count 0 projects after delete'
        );

        Test.stopTest();
    }


    @isTest
    static void testReparenting() {
        // Create accounts
        Account acc1 = new Account(Name = 'Account 1');
        Account acc2 = new Account(Name = 'Account 2');
        insert new List<Account>{ acc1, acc2 };

        // Create project linked to acc1
        Project__c p = new Project__c(
            Account__c = acc1.Id,
            Status__c = 'Planned'
        );
        insert p;

        Test.startTest();

        // Reparent project to acc2
        p.Account__c = acc2.Id;
        update p;

        Test.stopTest();

        // Verify counts after reparenting
        System.assertEquals(
            0,
            [SELECT Total_Projects__c FROM Account WHERE Id = :acc1.Id]
                .Total_Projects__c
        );

        System.assertEquals(
            1,
            [SELECT Total_Projects__c FROM Account WHERE Id = :acc2.Id]
                .Total_Projects__c
        );
    }
}