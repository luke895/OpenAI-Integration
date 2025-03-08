// File: force-app/ProjectGetTranscript/classes/DialpadTranscriptServiceTest.cls
@isTest
private class DialpadTranscriptServiceTest {
    
    // HTTP callout mock for the service.
    class DialpadTranscriptServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            // Return JSON so that TranscriptFormatter.formatTranscript returns:
            // "Test: Raw transcript text for service"
            res.setBody('{"lines": [{"type": "transcript", "name": "Test", "content": "Raw transcript text for service"}]}');
            return res;
        }
    }
    
    @isTest static void testProcessTranscript() {
        // Create a dummy Task record with required fields.
        Task t = new Task(
            Subject = 'Test Task for DialpadTranscriptService',
            Status = 'Completed',
            ActivityDate = Date.today()
            // Add additional required fields if needed.
        );
        insert t;
        
        Test.setMock(HttpCalloutMock.class, new DialpadTranscriptServiceMock());
        
        Test.startTest();
            DialpadTranscriptService.processTranscript('TestCall789', t.Id);
        Test.stopTest();
        
        // Query for the inserted Task Transcript record.
        List<Task_Transcript__c> transcripts = [
            SELECT Transcript__c 
            FROM Task_Transcript__c 
            WHERE Task_ID_Text__c = :String.valueOf(t.Id) 
            LIMIT 1
        ];
        System.assert(transcripts.size() > 0, 'Expected a Task Transcript record to be inserted.');
        System.assert(transcripts[0].Transcript__c != null &&
                      transcripts[0].Transcript__c.contains('Test: Raw transcript text for service'),
                      'Expected transcript to contain "Test: Raw transcript text for service".');
        
        // Verify that the Task's Description was updated with the transcript.
        Task updatedTask = [SELECT Description FROM Task WHERE Id = :t.Id];
        System.assert(updatedTask.Description.contains('Test: Raw transcript text for service'),
                      'Task description should include the transcript.');
    }
}
