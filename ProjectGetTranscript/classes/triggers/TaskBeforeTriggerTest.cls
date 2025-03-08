// File: force-app/ProjectGetTranscript/classes/TaskBeforeTriggerTest.cls
@isTest
private class TaskBeforeTriggerTest {
    
    @isTest static void testRevertDescriptionOnMergedTranscript() {
        // Create a Task record with Transcript_Merged__c set to true.
        Task t = new Task(
            Subject = 'Test BeforeTrigger Task',
            Status = 'Completed',
            Description = 'Original Description',
            Transcript_Merged__c = true,
            ActivityDate = Date.today()  // Required field.
            // Add any other required fields.
        );
        insert t;
        
        // Now update the Task and try to change the Description.
        Task tUpdate = [SELECT Id, Description, Transcript_Merged__c FROM Task WHERE Id = :t.Id];
        tUpdate.Description = 'Changed Description';
        update tUpdate;
        
        // After the before-update trigger, the Description should be reverted to its original value.
        Task tAfter = [SELECT Description FROM Task WHERE Id = :t.Id];
        System.assertEquals('Original Description', tAfter.Description,
            'Description should be reverted because transcript is merged.');
    }
}
