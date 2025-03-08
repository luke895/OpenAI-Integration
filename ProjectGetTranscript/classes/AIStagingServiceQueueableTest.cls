// File: force-app/ProjectGetTranscript/classes/AIStagingServiceQueueableTest.cls
@isTest
private class AIStagingServiceQueueableTest {
    
    // HTTP callout mock that returns valid JSON with a "lines" array.
    class AIStagingServiceQueueableMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            // Return JSON so that TranscriptFormatter.formatTranscript returns:
            // "Test: Test Transcript from Dialpad"
            res.setBody('{"lines": [{"type": "transcript", "name": "Test", "content": "Test Transcript from Dialpad"}]}');
            return res;
        }
    }
    
    @isTest static void testAIStagingServiceQueueable() {
        // Create an eligible Task record.
        Task t = new Task(
            Subject = 'Test Task for AIStagingServiceQueueable',
            Status = 'Completed',
            Dialpad__CallId__c = 'Call123',
            Dialpad__Call_End_Time__c = System.now(),
            Transcript_Merged__c = false,
            Do_Not_Process__c = false
            // Add any additional required fields.
        );
        insert t;
        
        // Set the HTTP callout mock.
        Test.setMock(HttpCalloutMock.class, new AIStagingServiceQueueableMock());
        
        Test.startTest();
            System.enqueueJob(new AIStagingServiceQueueable(new List<Id>{ t.Id }));
        Test.stopTest();
        
        // Query for Task Transcript records.
        List<Task_Transcript__c> transcripts = [
            SELECT Transcript__c 
            FROM Task_Transcript__c 
            WHERE Task_ID_Text__c = :String.valueOf(t.Id)
        ];
        System.assert(transcripts.size() > 0, 'Expected at least one Task Transcript record.');
        // Expecting formatted transcript: "Test: Test Transcript from Dialpad"
        System.assertEquals('Test: Test Transcript from Dialpad', transcripts[0].Transcript__c);
        
        // Verify that the Task record was updated (checking for the transcript marker in Description).
        Task updatedTask = [SELECT Description FROM Task WHERE Id = :t.Id];
        System.assert(updatedTask.Description.contains('<!-- BEGIN_TRANSCRIPT -->'), 'Task Description should contain transcript marker.');
    }
}
