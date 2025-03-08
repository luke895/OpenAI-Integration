trigger TaskBeforeTrigger on Task (before update) {
    for (Task t : Trigger.new) {
        Task oldT = Trigger.oldMap.get(t.Id);
        // Ensure oldT is not null before accessing its fields
        if (oldT != null && oldT.Transcript_Merged__c == true && t.Description != oldT.Description) {
            System.debug('Reverting Description update on Task ' + t.Id + ' as transcript is merged.');
            t.Description = oldT.Description;
        }
    }
}
