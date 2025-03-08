public class MyTaskTriggerHandler {
    /**
     * Handles Task events (both insert and update) by enqueuing eligible Tasks for processing.
     */
    public static void handleTaskInsert(List<Task> newTasks) {
        System.debug('🔵 [TaskTriggerHandler] Processing new Tasks...');
        
        // Re-query tasks by IDs to get the latest field values.
        Set<Id> taskIdsFromTrigger = new Set<Id>();
        for (Task t : newTasks) {
            taskIdsFromTrigger.add(t.Id);
        }
        
        List<Task> tasks = [
            SELECT Id, Transcript_Merged__c, Do_Not_Process__c, Status, Dialpad__Call_End_Time__c, Dialpad__CallId__c
            FROM Task 
            WHERE Id IN :taskIdsFromTrigger
        ];
        
        List<Id> idsToEnqueue = new List<Id>();
        for (Task t : tasks) {
            System.debug('🔹 [TaskTriggerHandler] Evaluating Task: ' + t.Id +
                         ' | Transcript_Merged__c: ' + t.Transcript_Merged__c +
                         ' | Do_Not_Process__c: ' + t.Do_Not_Process__c);
                         
            if (t.Status != 'Completed' || t.Dialpad__Call_End_Time__c == null) {
                System.debug('⏳ [TaskTriggerHandler] Skipping Task ' + t.Id + ' because the call is still ongoing.');
                continue;
            }
            
            if (t.Transcript_Merged__c == true || t.Do_Not_Process__c == true) {
                System.debug('⚠️ [TaskTriggerHandler] Task ' + t.Id + ' is already processed. Skipping.');
                continue;
            }
            
            // Prevent duplicate processing if a transcript record already exists.
            Integer existingTranscripts = [
                SELECT COUNT() FROM Task_Transcript__c WHERE Task_ID_Text__c = :t.Id
            ];
            if (existingTranscripts > 0) {
                System.debug('⚠️ [TaskTriggerHandler] Task ' + t.Id + ' already has a transcript. Skipping.');
                continue;
            }
            
            idsToEnqueue.add(t.Id);
        }
        
        if (!idsToEnqueue.isEmpty()) {
            System.enqueueJob(new AIStagingServiceQueueable(idsToEnqueue));
            System.debug('✅ [TaskTriggerHandler] Enqueued AI Processing Queue for Task IDs: ' + idsToEnqueue);
        }
    }
}
