// File: ProjectGetTranscript/classes/triggers/DialpadCallLogTrigger.trigger
trigger DialpadCallLogTrigger on Dialpad__Call_Log__c (after insert) {
    for (Dialpad__Call_Log__c logRec : Trigger.new) {
        // Make sure the record has both a Dialpad Call Id and a Linked Task Id.
        if (!String.isBlank(logRec.Dialpad__CallId__c) && logRec.Dialpad__Linked_Task_ID__c != null) {
            System.enqueueJob(new DialpadTranscriptQueueable(
                logRec.Dialpad__CallId__c, 
                logRec.Dialpad__Linked_Task_ID__c
            ));
        }
    }
}
