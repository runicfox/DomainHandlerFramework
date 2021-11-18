@isTest
public with sharing class ProfilerTest {
    @isTest
    static void testNoLogsException() {
        /**
         * In case the creation of the User record in the @testSetup method generates
         * a Profiler Log, we want to make sure that we're starting with an empty
         * data in the object.
         */
        List<Log__c> logs = [
            SELECT Id
            FROM Log__c
            WHERE RecordType.Name = 'Limit Profile'
        ];
        delete logs;

        /**
         * Usage of the LimitProfilerLogTest presumes that
         * at least one Limit Profile Log will be created.
         * This test will validate that the excepted exception
         * is thrown if no expected Log records are generated.
         */
        String noLogException;
        try {
            LimitProfilerLogTest.checkLimits();
        } catch (Exception e) {
            noLogException = e.getMessage();
        }
        System.assertEquals(
            'No Limit Profile was generated in the Log__c object.',
            noLogException,
            'Exception was not thrown when no Limit Profile Logs were found.'
        );
    }

    @isTest
    static void testProfiler() {
        User user = [
            SELECT Id
            FROM User
            WHERE LastName = 'ProfilerTest'
            LIMIT 1
        ];

        System.runAs(user) {
            Profiler profiler = new Profiler('ProfilerTest');
            profiler.startTracking();

            Account account = new Account(Name = 'Profiler Test Account');

            account = [SELECT Id FROM Account WHERE Id = :account.Id];

            profiler.setObjectId(account.Id);

            EventBus.publish(profiler.process());
        }

        Test.getEventBus().deliver();

        List<Log__c> logs = [
            SELECT
                Id,
                Source__c,
                RecordType.Name,
                Running_User__c,
                Queries_Used__c,
                Query_Rows_Used__c,
                DML_Used__c,
                DML_Rows_Used__c,
                CPU_Used__c,
                Heap_Used__c
            FROM Log__c
            WHERE Source__c = 'ProfilerTest'
        ];

        System.assertNotEquals(
            0,
            logs.size(),
            'Limit Profile Log not created.'
        );
        System.assertEquals(
            'Limit Profile',
            logs[0].RecordType.Name,
            'Log created with incorrect Record Type.'
        );
        System.assertEquals(
            user.Id,
            logs[0].Running_User__c,
            'Log created with incorrect Running User.'
        );
        System.assert(
            logs[0].Queries_Used__c > 1,
            'Profiler failed to record Query usage.'
        );
        System.assert(
            logs[0].Query_Rows_Used__c > 1,
            'Profiler failed to record Query Row usage.'
        );
        System.assert(
            logs[0].DML_Used__c > 1,
            'Profiler failed to record DML usage.'
        );
        System.assert(
            logs[0].DML_Rows_Used__c > 1,
            'Profiler failed to record DML Row usaged.'
        );
        System.assert(
            logs[0].CPU_Used__c > 1,
            'Profiler failed to record CPU usage.'
        );
        System.assert(
            logs[0].Heap_Used__c > 1,
            'Profiler failed to record Heap usage.'
        );

        try {
            LimitProfilerLogTest.checkLimits();
        } catch (Exception e) {
            System.assert(false, e.getMessage());
        }

        String actual;
        String expected = ' process exceeded 0.0% usage of ';
        try {
            LimitProfilerLogTest.checkLimits(0);
        } catch (Exception e) {
            actual = e.getMessage();
        }

        System.assertNotEquals(null, actual, 'Exception was not thrown.');
        System.assert(
            actual.contains(expected),
            'Exception message was not correctly set.'
        );
    }

    @isTest
    static void testProfilerWithTransaction() {
        User user = [
            SELECT Id
            FROM User
            WHERE LastName = 'ProfilerTest'
            LIMIT 1
        ];

        String transactionId = TransactionManager.getTransactionId();

        Profiler profiler = new Profiler('ProfilerTest');
        profiler.startTracking();

        System.runAs(user) {
            Account broker = TestFactory.createAccount();
            insert broker;

            broker = [SELECT Id FROM Account WHERE Id = :broker.Id];

            profiler.setObjectId(broker.Id);

            EventBus.publish(profiler.process());
        }

        Test.getEventBus().deliver();

        List<Log__c> logs = [
            SELECT
                Id,
                Source__c,
                RecordType.Name,
                Running_User__c,
                Transaction_Id__c,
                Queries_Used__c,
                Query_Rows_Used__c,
                DML_Used__c,
                DML_Rows_Used__c,
                CPU_Used__c,
                Heap_Used__c
            FROM Log__c
            WHERE Source__c = 'ProfilerTest'
        ];

        System.assertNotEquals(
            0,
            logs.size(),
            'Limit Profile Log not created.'
        );
        System.assertEquals(
            'Limit Profile',
            logs[0].RecordType.Name,
            'Log created with incorrect Record Type.'
        );
        System.assertEquals(
            user.Id,
            logs[0].Running_User__c,
            'Log created with incorrect Running User.'
        );
        System.assertEquals(
            transactionId,
            logs[0].Transaction_Id__c,
            'Log created with incorrect Transaction Id.'
        );
        System.assert(
            logs[0].Queries_Used__c > 1,
            'Profiler failed to record Query usage.'
        );
        System.assert(
            logs[0].Query_Rows_Used__c > 1,
            'Profiler failed to record Query Row usage.'
        );
        System.assert(
            logs[0].DML_Used__c > 1,
            'Profiler failed to record DML usage.'
        );
        System.assert(
            logs[0].DML_Rows_Used__c > 1,
            'Profiler failed to record DML Row usaged.'
        );
        System.assert(
            logs[0].CPU_Used__c > 1,
            'Profiler failed to record CPU usage.'
        );
        System.assert(
            logs[0].Heap_Used__c > 1,
            'Profiler failed to record Heap usage.'
        );

        try {
            LimitProfilerLogTest.checkLimits();
        } catch (Exception e) {
            System.assert(false, e.getMessage());
        }

        String actual;
        String expected = ' process exceeded 0.0% usage of ';

        try {
            // setting a coefficient of zero will ensure that an exception is thrown.
            LimitProfilerLogTest.checkLimits(0);
        } catch (Exception e) {
            actual = e.getMessage();
        }

        System.assertNotEquals(null, actual, 'Exception was not thrown.');
        System.assert(actual.contains(expected), actual);
    }
}
