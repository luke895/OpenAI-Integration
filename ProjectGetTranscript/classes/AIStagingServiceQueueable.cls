public class AIStagingServiceQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> taskIds;
    
    public AIStagingServiceQueueable(List<Id> taskIds) {
        this.taskIds = taskIds;
    }
    
    public void execute(QueueableContext context) {
        System.debug('🔵 [AIStagingServiceQueueable] Processing AI call for Task IDs: ' + taskIds);
        
        // STEP 1: Query eligible Tasks to create transcript records.
        List<Task> tasksForInsert = [
            SELECT Id, Description, Dialpad__CallId__c, Dialpad__Call_End_Time__c, Status,
                   Transcript_Merged__c, Do_Not_Process__c
            FROM Task 
            WHERE Id IN :taskIds 
              AND Status = 'Completed'
              AND Dialpad__CallId__c != null
              AND (Transcript_Merged__c = false OR Transcript_Merged__c = null)
              AND (Do_Not_Process__c = false OR Do_Not_Process__c = null)
        ];
        System.debug('🔎 [Queueable] Retrieved Tasks for Transcript Insertion: ' + tasksForInsert);
        
        List<Task_Transcript__c> transcriptsToInsert = new List<Task_Transcript__c>();
        for (Task t : tasksForInsert) {
            // Double-check that no transcript already exists.
            Integer existingTranscripts = [
                SELECT COUNT() FROM Task_Transcript__c WHERE Task_ID_Text__c = :t.Id
            ];
            if (existingTranscripts > 0) {
                System.debug('⚠️ [Queueable] Task ' + t.Id + ' already has a transcript. Skipping insertion.');
                continue;
            }
            System.debug('🔹 [Queueable] Processing Task for Transcript Insertion: ' + t.Id);
            String transcriptContent = getDialpadTranscript(t.Dialpad__CallId__c);
            if (String.isBlank(transcriptContent)) {
                System.debug('⚠️ [Queueable] No transcript found for Call ID: ' + t.Dialpad__CallId__c);
                continue;
            }
            transcriptsToInsert.add(new Task_Transcript__c(
                Task_ID_Text__c = String.valueOf(t.Id),
                Transcript__c = transcriptContent
            ));
        }
        
        if (!transcriptsToInsert.isEmpty()) {
            System.debug('✅ [Queueable] Inserting Task Transcript records: ' + transcriptsToInsert);
            insert transcriptsToInsert;
            System.debug('✅ [Queueable] Inserted ' + transcriptsToInsert.size() + ' Task Transcript records.');
        } else {
            System.debug('⚠️ [Queueable] No new transcript records to insert.');
        }
        
        // STEP 2: Merge Transcript Content and User Notes into Task Description.
        List<Task> tasksToUpdate = [SELECT Id, Description FROM Task WHERE Id IN :taskIds];
        
        // Build a map from Task Id (as String) to its corresponding transcript record.
        List<String> taskIdStrs = new List<String>();
        for (Id tid : taskIds) {
            taskIdStrs.add(String.valueOf(tid));
        }
        Map<String, Task_Transcript__c> transcriptMap = new Map<String, Task_Transcript__c>();
        for (Task_Transcript__c tt : [
            SELECT Id, Task_ID_Text__c, Transcript__c, User_Notes__c
            FROM Task_Transcript__c 
            WHERE Task_ID_Text__c IN :taskIdStrs
        ]) {
            transcriptMap.put(tt.Task_ID_Text__c, tt);
        }
        
        // Define markers for the user notes and transcript portions.
        String beginUserNotesMarker = '<!-- BEGIN_USER_NOTES -->';
        String endUserNotesMarker   = '<!-- END_USER_NOTES -->';
        String beginTranscriptMarker = '<!-- BEGIN_TRANSCRIPT -->';
        String endTranscriptMarker   = '<!-- END_TRANSCRIPT -->';
        
        List<Task> finalTasksToUpdate = new List<Task>();
        for (Task t : tasksToUpdate) {
            String taskIdStr = String.valueOf(t.Id);
            if (!transcriptMap.containsKey(taskIdStr)) {
                continue;
            }
            Task_Transcript__c transcriptRec = transcriptMap.get(taskIdStr);
            String transcriptText = transcriptRec.Transcript__c;
            
            // Use the saved User Notes from the Task Transcript record (if available)
            String userNotes = (transcriptRec.User_Notes__c != null) ? transcriptRec.User_Notes__c : '';
            
            // Optionally, if you want to retain any existing text in the Task Description that is not marked,
            // you could extract it here. For now, we will override with the userNotes field.
            
            // Build the merged description.
            String newDescription = '';
            newDescription += beginUserNotesMarker + '\n';
            newDescription += userNotes + '\n';
            newDescription += endUserNotesMarker + '\n\n';
            newDescription += beginTranscriptMarker + '\n';
            newDescription += transcriptText + '\n';
            newDescription += endTranscriptMarker;
            
            // Update the Task fields.
            t.Description = newDescription;
            t.Transcript_Merged__c = true;
            t.Do_Not_Process__c = true;
            finalTasksToUpdate.add(t);
            System.debug('🔹 [Queueable] New Description for Task ' + t.Id + ': ' + t.Description);
        }
        
        if (!finalTasksToUpdate.isEmpty()) {
            update finalTasksToUpdate;
            System.debug('✅ [Queueable] Updated Task descriptions with merged user notes and transcript.');
        }
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
                // If the API returns a direct transcript:
                if (responseBody.containsKey('transcript')) {
                    String transcript = (String) responseBody.get('transcript');
                    System.debug('✅ getDialpadTranscript: Transcript Found: ' + transcript);
                    return transcript;
                } else if (responseBody.containsKey('lines')) {
                    List<Object> lines = (List<Object>) responseBody.get('lines');
                    List<String> transcriptLines = new List<String>();
                    for (Object lineObj : lines) {
                        Map<String, Object> line = (Map<String, Object>) lineObj;
                        // Check for transcript lines.
                        if (line.containsKey('type') &&
                            String.valueOf(line.get('type')).toLowerCase() == 'transcript' &&
                            line.containsKey('content')) {
                            // Prepend the speaker’s name if available.
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
