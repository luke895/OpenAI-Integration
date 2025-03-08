trigger TaskAfterTrigger on Task (after insert, after update) {
    if (Trigger.isInsert) {
        MyTaskTriggerHandler.handleTaskInsert(Trigger.new);
    } else if (Trigger.isUpdate) {
        // Process only when the call has ended.
        List<Task> tasksToProcess = new List<Task>();
        for (Task t : Trigger.new) {
            Task oldTask = Trigger.oldMap.get(t.Id);
            // Ensure oldTask is not null before accessing its fields
            if (oldTask != null && oldTask.Dialpad__Call_End_Time__c == null &&
                t.Dialpad__Call_End_Time__c != null &&
                t.Status == 'Completed' &&
                t.Transcript_Merged__c != true &&
                t.Do_Not_Process__c != true) {
                tasksToProcess.add(t);
            }
        }
        if (!tasksToProcess.isEmpty()) {
            MyTaskTriggerHandler.handleTaskInsert(tasksToProcess);
        }
    }
}
