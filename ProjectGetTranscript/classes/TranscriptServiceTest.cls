// File: force-app/ProjectGetTranscript/classes/TranscriptServiceTest.cls
@isTest
private class TranscriptServiceTest {
    @isTest static void testMergeTranscriptIntoDescription() {
        // Create a Task record.
        Task t = new Task(
            Subject = 'Test Task',
            Description = 'Task description',
            Status = 'Completed',
            ActivityDate = Date.today()
        );
        insert t;
        
        // Insert a Task Transcript record for that Task.
        Task_Transcript__c tt = new Task_Transcript__c(
            Task_ID_Text__c = String.valueOf(t.Id),
            Transcript__c = 'Alice: Hello'
        );
        insert tt;
        
        String merged = TranscriptService.mergeTranscriptIntoDescription(t);
        String expected = 'Task description\n\n--- Transcript ---\nAlice: Hello';
        System.assertEquals(expected, merged, 'Merged description should be as expected.');
    }
}
