// File: force-app/ProjectGetTranscript/classes/MyTaskTriggerHandlerTest.cls
@isTest
private class MyTaskTriggerHandlerTest {
    
    @isTest static void testHandleTaskInsertEnqueuesJob() {
        // Create an eligible Task record.
        Task eligibleTask = new Task(
            Subject = 'Eligible Task',
            Status = 'Completed',                        // Must be 'Completed'
            Dialpad__Call_End_Time__c = System.now(),      // Must be non-null
            Transcript_Merged__c = false,
            Do_Not_Process__c = false
            // Populate any additional required fields.
        );
        insert eligibleTask;
        
        // Create an ineligible Task record for contrast (this one won't be enqueued).
        Task ineligibleTask = new Task(
            Subject = 'Ineligible Task',
            Status = 'In Progress',                        // Not 'Completed'
            Dialpad__Call_End_Time__c = null,              // Call is ongoing
            Transcript_Merged__c = false,
            Do_Not_Process__c = false
            // Populate any additional required fields.
        );
        insert ineligibleTask;
        
        // Retrieve tasks as they would appear in the trigger context.
        List<Task> newTasks = [SELECT Id, Status, Dialpad__Call_End_Time__c, Transcript_Merged__c, Do_Not_Process__c 
                               FROM Task 
                               WHERE Id IN :new List<Id>{eligibleTask.Id, ineligibleTask.Id}];
        
        Test.startTest();
            // Invoke the handler method which should evaluate each Task.
            MyTaskTriggerHandler.handleTaskInsert(newTasks);
        Test.stopTest();
        
        // Query AsyncApexJob to see if a queueable job was enqueued.
        List<AsyncApexJob> jobs = [SELECT Id 
                                   FROM AsyncApexJob 
                                   WHERE JobType = 'Queueable' 
                                     AND CreatedById = :UserInfo.getUserId()];
        System.assert(jobs.size() > 0, 'Expected at least one queueable job to be enqueued for eligible tasks.');
    }
    
    @isTest static void testHandleTaskInsertNoEligibleTask() {
        // Create an ineligible Task record (e.g., not completed, call still ongoing).
        Task task = new Task(
            Subject = 'Ineligible Task',
            Status = 'In Progress',                        // Not completed
            Dialpad__Call_End_Time__c = null,
            Transcript_Merged__c = false,
            Do_Not_Process__c = false
            // Populate required fields as needed.
        );
        insert task;
        
        // Retrieve the inserted task.
        List<Task> tasks = [SELECT Id, Status, Dialpad__Call_End_Time__c, Transcript_Merged__c, Do_Not_Process__c 
                            FROM Task WHERE Id = :task.Id];
        
        Test.startTest();
            MyTaskTriggerHandler.handleTaskInsert(tasks);
        Test.stopTest();
        
        // Query AsyncApexJob to see if any queueable job was enqueued.
        List<AsyncApexJob> jobs = [SELECT Id 
                                   FROM AsyncApexJob 
                                   WHERE JobType = 'Queueable' 
                                     AND CreatedById = :UserInfo.getUserId()];
        System.assertEquals(0, jobs.size(), 'Expected no queueable job to be enqueued for ineligible tasks.');
    }
}
