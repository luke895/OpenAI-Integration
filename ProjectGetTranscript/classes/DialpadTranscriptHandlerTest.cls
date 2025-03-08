@isTest
private class DialpadTranscriptHandlerTest {
    
    @isTest static void testHandleWebhookSuccess() {
        // Run as current user for proper permissions.
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            // ✅ Step 1: Create a Task
            Task t = new Task(
                Subject = 'Dialpad Call - Outbound / 1 min',  // Simulates a real call subject.
                Status = 'Completed',
                Description = 'Old Description',
                ActivityDate = Date.today()
            );
            insert t;
            
            // ✅ Step 2: Create a Dialpad__Call_Log__c entry with the correct linked Task ID
            String testCallId = 'TestCall123';
            Dialpad__Call_Log__c callLog = new Dialpad__Call_Log__c(
                Dialpad__CallId__c = testCallId,
                Dialpad__Linked_Task_ID__c = t.Id
            );
            insert callLog;

            // ✅ Step 3: Prepare a valid JSON payload
            Map<String, Object> payload = new Map<String, Object>{
                'call_id' => testCallId,
                'transcription_text' => 'New Transcript Text'
            };
            String requestBody = JSON.serialize(payload);
            
            // ✅ Step 4: Set up the REST request and response
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/dialpad/transcript';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(requestBody);
            RestContext.request = req;
            
            RestResponse res = new RestResponse();
            RestContext.response = res;
            
            // ✅ Step 5: Execute the test
            Test.startTest();
                DialpadTranscriptHandler.handleWebhook();
            Test.stopTest();
            
            // ✅ Step 6: Verify response status and body
            System.assertEquals(200, RestContext.response.statusCode, 'Expected status code 200.');
            System.assertEquals('Success', RestContext.response.responseBody.toString(), 'Expected response body "Success".');
            
            // ✅ Step 7: Verify that the Task was updated correctly
            Task updatedTask = [SELECT Subject, Description FROM Task WHERE Id = :t.Id];
            System.assert(updatedTask.Subject.startsWith('Processed by AI - '), 'Subject should be updated with prefix.');
            System.assertEquals('New Transcript Text', updatedTask.Description, 'Description should be updated with transcript text.');
        }
    }
    
    @isTest static void testHandleWebhookInvalidPayload() {
        // ✅ Prepare a payload missing call_id.
        Map<String, Object> payload = new Map<String, Object>{
            'transcription_text' => 'Some Transcript'
        };
        String requestBody = JSON.serialize(payload);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/dialpad/transcript';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
            DialpadTranscriptHandler.handleWebhook();
        Test.stopTest();
        
        // ✅ Verify the error response
        System.assertEquals(400, RestContext.response.statusCode, 'Expected status code 400 for invalid payload.');
    }
}
