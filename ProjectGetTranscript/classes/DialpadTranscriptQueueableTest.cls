// File: force-app/ProjectGetTranscript/classes/DialpadTranscriptQueueableTest.cls
@isTest
private class DialpadTranscriptQueueableTest {
    
    // HTTP callout mock for the queueable.
    class DialpadTranscriptQueueableMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            // Return JSON so that TranscriptFormatter.formatTranscript returns:
            // "Test: Raw transcript text"
            res.setBody('{"lines": [{"type": "transcript", "name": "Test", "content": "Raw transcript text"}]}');
            return res;
        }
    }
    
    @isTest static void testExecute() {
        // Create a dummy Task record.
        Task t = new Task(
            Subject = 'Test Task for DialpadTranscriptQueueable',
            Status = 'Completed'
            // Add additional required fields if needed.
        );
        insert t;
        
        Test.setMock(HttpCalloutMock.class, new DialpadTranscriptQueueableMock());
        
        Test.startTest();
            DialpadTranscriptQueueable job = new DialpadTranscriptQueueable('TestCall456', t.Id);
            job.execute(null);
        Test.stopTest();
        
        // Query for the inserted Task Transcript record.
        List<Task_Transcript__c> transcripts = [
            SELECT Transcript__c 
            FROM Task_Transcript__c 
            WHERE Task_ID_Text__c = :String.valueOf(t.Id)
        ];
        System.assert(transcripts.size() > 0, 'Expected a Task Transcript record to be inserted.');
        System.assert(transcripts[0].Transcript__c != null &&
                      transcripts[0].Transcript__c.contains('Test: Raw transcript text'),
                      'Expected transcript to contain "Test: Raw transcript text".');
    }
}
