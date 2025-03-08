public with sharing class AIUtility {
    // The Named Credential endpoint for your OpenAI integration.
    private static final String OPENAI_ENDPOINT = 'callout:OpenAI_Integration/v1/chat/completions';

    // Synchronous method for performing the callout.
    public static String callOpenAI(String taskDescription) {
        System.debug('🔵 [AIUtility] Processing AI extraction for task description: ' + taskDescription);

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(OPENAI_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(60000); // 60 seconds timeout

        // Build JSON payload from the task description.
        req.setBody(constructRequestPayload(taskDescription));

        try {
            HttpResponse response = http.send(req);
            System.debug('🟢 OpenAI Response: ' + response.getBody());
            if (response.getStatusCode() == 200) {
                return response.getBody();
            } else {
                System.debug('❌ OpenAI callout failed with status code ' + response.getStatusCode());
                return null;
            }
        } catch (Exception e) {
            System.debug('❌ OpenAI Callout Failed: ' + e.getMessage());
            return null;
        }
    }

    private static String constructRequestPayload(String taskDescription) {
        System.debug('🔹 [AIUtility] Constructing request payload.');

        Map<String, Object> requestPayload = new Map<String, Object>();
        List<Map<String, String>> messages = new List<Map<String, String>>();

        messages.add(new Map<String, String>{
            'role' => 'system', 
            'content' =>
                'Extract software assets from the conversation. ' +
                'Respond ONLY in JSON format EXACTLY in the following structure, with no additional text:' +
                '\n{' +
                '\n  "assets": [' +
                '\n    {' +
                '\n      "name": "Software Name",' +
                '\n      "usageEndDate": "YYYY-MM-DD",' +
                '\n      "quantity": 1,' +
                '\n      "status": "Active",' +
                '\n      "isCompetitorProduct": true' +
                '\n    }' +
                '\n  ]' +
                '\n}' +
                '\nIf no asset is mentioned, return {"assets": []}.' +
                '\nEnsure dates are in YYYY-MM-DD format, and always use the first day of the month. ' +
                '\nFor relative dates like "next year", assume the conversation date is 2025-01-01.'
        });

        messages.add(new Map<String, String>{
            'role' => 'user', 
            'content' => taskDescription
        });

        requestPayload.put('messages', messages);
        requestPayload.put('model', 'gpt-4');

        return JSON.serialize(requestPayload);
    }
}