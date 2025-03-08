// File: force-app/ProjectGetTranscript/classes/UserNotesControllerTest.cls
@isTest
private class UserNotesControllerTest {

    @isTest static void testUpdateUserNotesSuccess() {
        // Create a test Task record.
        Task testTask = new Task(
            Subject = 'Call Transcript Test',
            Description = 'Initial Description'
        );
        insert testTask;
        
        // Create a corresponding Task_Transcript__c record.
        // Set Task_ID_Text__c to the testTask Id.
        Task_Transcript__c testTranscript = new Task_Transcript__c(
            Task_ID_Text__c = testTask.Id,
            Transcript__c = 'Original Transcript'
        );
        insert testTranscript;
        
        // Define new user notes.
        String newNotes = 'New user notes content';
        
        Test.startTest();
            // Call the updateUserNotes method with the test Task Id.
            UserNotesController.updateUserNotes(testTask.Id, newNotes);
        Test.stopTest();
        
        // Verify that the Task_Transcript__c record is updated.
        Task_Transcript__c updatedTranscript = [
            SELECT User_Notes__c, Transcript__c 
            FROM Task_Transcript__c 
            WHERE Id = :testTranscript.Id
        ];
        System.assertEquals(newNotes, updatedTranscript.User_Notes__c, 'User notes should be updated on the Task Transcript record.');
        
        // Verify that the Task record's Description is updated with the merged content.
        Task updatedTask = [SELECT Description FROM Task WHERE Id = :testTask.Id];
        System.assert(updatedTask.Description.contains(newNotes), 'Task Description should contain the updated user notes.');
        System.assert(updatedTask.Description.contains('<!-- BEGIN_USER_NOTES -->'), 'Task Description should contain the BEGIN_USER_NOTES marker.');
        System.assert(updatedTask.Description.contains('<!-- END_USER_NOTES -->'), 'Task Description should contain the END_USER_NOTES marker.');
        System.assert(updatedTask.Description.contains('<!-- BEGIN_TRANSCRIPT -->'), 'Task Description should contain the BEGIN_TRANSCRIPT marker.');
        System.assert(updatedTask.Description.contains('<!-- END_TRANSCRIPT -->'), 'Task Description should contain the END_TRANSCRIPT marker.');
    }
    
    @isTest static void testUpdateUserNotesWithNullTaskId() {
        Boolean exceptionThrown = false;
        try {
            UserNotesController.updateUserNotes(null, 'Some notes');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            // No need to check instanceOf; we already know e is an AuraHandledException.
        }
        System.assert(exceptionThrown, 'AuraHandledException was not thrown for null taskId.');
    }
    
    @isTest static void testUpdateUserNotesMissingTranscript() {
        // Create a Task without a corresponding Task_Transcript__c record.
        Task testTask = new Task(
            Subject = 'Test Missing Transcript',
            Description = 'Initial Description'
        );
        insert testTask;
        
        Boolean exceptionThrown = false;
        try {
            UserNotesController.updateUserNotes(testTask.Id, 'Some notes');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'AuraHandledException was not thrown when transcript record is missing.');
    }
}
