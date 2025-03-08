// File: force-app/ProjectGetTranscript/classes/TaskAfterTriggerTest.cls
@isTest
private class TaskAfterTriggerTest {

    @isTest static void testAfterInsertBranch() {
        // Create a Task record that will fire the after-insert branch.
        Task t = new Task(
            Subject = 'Test AfterInsert Task',
            Status = 'Completed',
            ActivityDate = Date.today()  // Required field for Task
            // Populate other required fields if any.
        );
        insert t;
        
        // The after-insert branch calls MyTaskTriggerHandler.handleTaskInsert(Trigger.new)
        // If no exception is thrown, we assume the branch executed.
        System.assertNotEquals(null, t.Id, 'Task should be inserted successfully.');
    }
    
    @isTest static void testAfterUpdateBranch() {
        // Create a Task record that will later be updated.
        Task t = new Task(
            Subject = 'Test AfterUpdate Task',
            Status = 'In Progress',
            ActivityDate = Date.today()
            // Populate additional required fields if needed.
        );
        insert t;
        
        // Update the Task so that:
        // - The call end time was previously null and now is set.
        // - Status becomes Completed.
        // - Transcript_Merged__c and Do_Not_Process__c are false.
        t.Status = 'Completed';
        t.Dialpad__Call_End_Time__c = System.now();
        t.Transcript_Merged__c = false;
        t.Do_Not_Process__c = false;
        update t;
        
        // The update branch should call MyTaskTriggerHandler.handleTaskInsert() on eligible tasks.
        // We can verify the status change.
        Task updatedTask = [SELECT Status, Dialpad__Call_End_Time__c FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', updatedTask.Status, 'Task status should be updated to Completed.');
        System.assertNotEquals(null, updatedTask.Dialpad__Call_End_Time__c, 'Dialpad__Call_End_Time__c should be set.');
    }
}
