@RestResource(urlMapping='/dialpad/transcript')
global with sharing class DialpadTranscriptHandler {
    @HttpPost
    global static void handleWebhook() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Read incoming JSON data
            String requestBody = req.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            // Extract necessary fields
            String callId = (String) payload.get('call_id');
            String transcript = (String) payload.get('transcription_text');

            if (String.isBlank(callId) || String.isBlank(transcript)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Invalid payload received');
                return;
            }

            System.debug('🔵 [DialpadTranscriptHandler] Processing transcript for Call ID: ' + callId);

            // ✅ Step 1: Get the Task ID from Dialpad__Call_Log__c
            Dialpad__Call_Log__c callLog = [
                SELECT Dialpad__Linked_Task_ID__c 
                FROM Dialpad__Call_Log__c 
                WHERE Dialpad__CallId__c = :callId
                LIMIT 1
            ];

            if (callLog == null || String.isBlank(callLog.Dialpad__Linked_Task_ID__c)) {
                System.debug('⚠️ [DialpadTranscriptHandler] No Task found for Call ID: ' + callId);
                res.statusCode = 404;
                res.responseBody = Blob.valueOf('No Task found for Call ID');
                return;
            }

            Id taskId = callLog.Dialpad__Linked_Task_ID__c;
            System.debug('✅ [DialpadTranscriptHandler] Found Task ID: ' + taskId);

            // ✅ Step 2: Query the Task record
            Task taskToUpdate = [SELECT Id, Description, Subject FROM Task WHERE Id = :taskId LIMIT 1];

            // ✅ Step 3: Update the Task record
            taskToUpdate.Description = transcript;
            taskToUpdate.Subject = 'Processed by AI - ' + taskToUpdate.Subject;
            update taskToUpdate;

            System.debug('✅ [DialpadTranscriptHandler] Task updated successfully.');

            res.statusCode = 200;
            res.responseBody = Blob.valueOf('Success');
        } catch (Exception e) {
            System.debug('❌ [DialpadTranscriptHandler] Error processing Dialpad transcript: ' + e.getMessage());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error processing request');
        }
    }
}
