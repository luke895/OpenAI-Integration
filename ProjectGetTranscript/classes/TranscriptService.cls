public with sharing class TranscriptService {
    /**
     * Retrieves the transcript record linked to the given Task (via Task_ID_Text__c)
     * and merges its Transcript__c field into the Task's description.
     * @param t The Task record.
     * @return The merged description.
     */
    public static String mergeTranscriptIntoDescription(Task t) {
        List<Task_Transcript__c> transcripts = [
            SELECT Id, Transcript__c 
            FROM Task_Transcript__c 
            WHERE Task_ID_Text__c = :String.valueOf(t.Id)
            LIMIT 1
        ];
        if (transcripts.isEmpty()) {
            return t.Description;
        }
        String transcript = transcripts[0].Transcript__c;
        // Use the merge method to append the transcript (after a delimiter) to the existing description.
        return TranscriptFormatter.mergeDescriptions(t.Description, transcript);
    }
}
