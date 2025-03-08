// File: force-app/ProjectGetTranscript/classes/UserNotesController.cls
public with sharing class UserNotesController {
    
    @AuraEnabled
    public static void updateUserNotes(String taskId, String userNotes) {
        System.debug('>>> updateUserNotes called for Task Id: ' + taskId + ' with notes: ' + userNotes);
        
        // Check if taskId is null or empty and throw an error early.
        if (String.isBlank(taskId)) {
            throw new AuraHandledException('Task Id cannot be null or empty.');
        }
        
        // Query the Task Transcript record using a LIKE match on Task_ID_Text__c.
        List<Task_Transcript__c> ttList = [
            SELECT Id, User_Notes__c, Transcript__c 
            FROM Task_Transcript__c 
            WHERE Task_ID_Text__c LIKE :('%' + taskId + '%')
            LIMIT 1
        ];
        
        if (ttList.isEmpty()) {
            // If no record is found, throw an exception so the LWC can display an error.
            throw new AuraHandledException('Task Transcript record not found for Task Id: ' + taskId);
        }
        
        Task_Transcript__c tt = ttList[0];
        tt.User_Notes__c = userNotes;
        update tt;
        System.debug('>>> Updated Task_Transcript__c with user notes.');
        
        // Define markers for the user notes and transcript sections.
        String beginUserNotesMarker = '<!-- BEGIN_USER_NOTES -->';
        String endUserNotesMarker   = '<!-- END_USER_NOTES -->';
        String beginTranscriptMarker = '<!-- BEGIN_TRANSCRIPT -->';
        String endTranscriptMarker   = '<!-- END_TRANSCRIPT -->';
        
        // Retrieve the transcript text from the Task Transcript record.
        String transcriptText = (tt.Transcript__c == null) ? '' : tt.Transcript__c;
        
        // Construct the merged description.
        String mergedDescription = 
            beginUserNotesMarker + '\n' +
            userNotes + '\n' +
            endUserNotesMarker + '\n\n' +
            beginTranscriptMarker + '\n' +
            transcriptText + '\n' +
            endTranscriptMarker;
            
        // Query the Task record.
        Task t = [SELECT Id, Description FROM Task WHERE Id = :taskId LIMIT 1];
        t.Description = mergedDescription;
        update t;
        System.debug('>>> Updated Task ' + t.Id + ' Description to: ' + t.Description);
    }
    
    /**
     * Retrieves the transcript from Dialpad for the given Call ID.
     */
    private String getDialpadTranscript(String callId) {
        if (String.isBlank(callId)) {
            System.debug('❌ getDialpadTranscript: Call ID is empty, skipping.');
            return null;
        }
        System.debug('🔵 getDialpadTranscript: Fetching transcript for Call ID: ' + callId);
        String apiEndpoint = 'transcripts/' + callId;
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Dialpad_NC/' + apiEndpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
            System.debug('🔵 getDialpadTranscript: API Response Status: ' + res.getStatusCode());
            System.debug('🔵 getDialpadTranscript: API Response Body: ' + res.getBody());
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                // If a direct transcript is returned:
                if (responseBody.containsKey('transcript')) {
                    String transcript = (String) responseBody.get('transcript');
                    System.debug('✅ getDialpadTranscript: Transcript Found: ' + transcript);
                    return transcript;
                } else if (responseBody.containsKey('lines')) {
                    List<Object> lines = (List<Object>) responseBody.get('lines');
                    List<String> transcriptLines = new List<String>();
                    for (Object lineObj : lines) {
                        Map<String, Object> line = (Map<String, Object>) lineObj;
                        // Only include lines of type "transcript"
                        if (line.containsKey('type') &&
                            String.valueOf(line.get('type')).toLowerCase() == 'transcript' &&
                            line.containsKey('content')) {
                            String prefix = '';
                            if (line.containsKey('name')) {
                                prefix = String.valueOf(line.get('name')) + ': ';
                            }
                            transcriptLines.add(prefix + String.valueOf(line.get('content')));
                        }
                    }
                    String transcript = String.join(transcriptLines, '\n');
                    if (!String.isBlank(transcript)) {
                        System.debug('✅ getDialpadTranscript: Transcript extracted from lines: ' + transcript);
                        return transcript;
                    }
                }
                System.debug('⚠️ getDialpadTranscript: No transcript found in API response.');
                return null;
            } else if (res.getStatusCode() == 400) {
                System.debug('⏳ getDialpadTranscript: Call is still active. Exiting processing.');
                return null;
            }
            System.debug('❌ getDialpadTranscript: API Call Failed. Status: ' + res.getStatusCode() + ' Response: ' + res.getBody());
            return null;
        } catch (Exception e) {
            System.debug('❌ getDialpadTranscript: API Call Exception: ' + e.getMessage());
            return null;
        }
    }
}
