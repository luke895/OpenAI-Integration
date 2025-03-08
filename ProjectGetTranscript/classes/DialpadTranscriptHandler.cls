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

            if (callId == null || transcript == null) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Invalid payload received');
                return;
            }

            // Locate the related Task in Salesforce
            List<Task> tasksToUpdate = [SELECT Id, Description FROM Task WHERE Subject LIKE :('%' + callId + '%') LIMIT 1];

            if (!tasksToUpdate.isEmpty()) {
                Task taskToUpdate = tasksToUpdate[0];
                taskToUpdate.Description = transcript;
                taskToUpdate.Subject = 'Processed by AI - ' + taskToUpdate.Subject;
                update taskToUpdate;
            }

            res.statusCode = 200;
            res.responseBody = Blob.valueOf('Success');
        } catch (Exception e) {
            System.debug('Error processing Dialpad transcript: ' + e.getMessage());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error processing request');
        }
    }
}