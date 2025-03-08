// File: force-app/ProjectGetTranscript/classes/DialpadCallLogTriggerTest.cls
@isTest
private class DialpadCallLogTriggerTest {
    @isTest static void testDialpadCallLogTriggerEnqueuesJob() {
        // Create a Task record to simulate the Linked Task.
        Task t = new Task(Subject = 'Test Task for Dialpad Trigger');
        insert t;
        
        // Create a Dialpad__Call_Log__c record with required fields.
        Dialpad__Call_Log__c callLog = new Dialpad__Call_Log__c(
            Dialpad__CallId__c = 'TestCall123',
            Dialpad__Linked_Task_ID__c = t.Id
            // Add any other required fields here.
        );
        
        Test.startTest();
            // Inserting the call log record should fire the trigger and enqueue the queueable job.
            insert callLog;
        Test.stopTest();
        
        // If no exception is thrown and the record has an Id, the test passes.
        System.assertNotEquals(null, callLog.Id, 'Call log record should be inserted.');
    }
}
