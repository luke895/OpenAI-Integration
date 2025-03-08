public with sharing class DialpadTranscriptService {
    /**
     * Retrieves the transcript for a Dialpad call, stores it in a Task Transcript record,
     * and then updates the Task description.
     *
     * @param callId The Dialpad call Id.
     * @param taskId The Task record Id to update.
     */
    public static void processTranscript(String callId, Id taskId) {
        System.debug('Processing transcript for callId: ' + callId + ' and taskId: ' + taskId);
        
        // Build the endpoint URL using your Named Credential (Dialpad_NC).
        String endpoint = 'callout:Dialpad_NC/api/v2/transcripts/' + callId;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(60000);
        
        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
        } catch (Exception e) {
            System.debug('Error making callout: ' + e.getMessage());
            return;
        }
        
        if (res.getStatusCode() == 200) {
            String rawTranscript = res.getBody();
            System.debug('Raw Transcript retrieved: ' + rawTranscript);
            
            // Format the transcript.
            String formattedTranscript = TranscriptFormatter.formatTranscript(rawTranscript);
            System.debug('Formatted Transcript: ' + formattedTranscript);
            
            // Create a separate Task Transcript record.
            Task_Transcript__c transcriptRec = new Task_Transcript__c(
                Task_ID_Text__c = String.valueOf(taskId),
                Transcript__c = formattedTranscript
            );
            insert transcriptRec;
            System.debug('Inserted Task Transcript record with Id: ' + transcriptRec.Id);
            
            // Retrieve the Task and merge its description with the new transcript.
            Task t = [SELECT Id, Description FROM Task WHERE Id = :taskId LIMIT 1];
            t.Description = TranscriptFormatter.mergeDescriptions(t.Description, formattedTranscript);
            update t;
            System.debug('Updated Task description with transcript.');
        } else {
            System.debug('Callout failed with status code: ' + res.getStatusCode());
        }
    }
}
