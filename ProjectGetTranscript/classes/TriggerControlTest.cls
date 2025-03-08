// File: force-app/ProjectGetTranscript/classes/TriggerControlTest.cls
@isTest
private class TriggerControlTest {
    @isTest static void testProcessedTaskIds() {
        // Clear the static set first.
        TriggerControl.processedTaskIds.clear();
        Id fakeId = '005000000000001';
        TriggerControl.processedTaskIds.add(fakeId);
        System.assert(TriggerControl.processedTaskIds.contains(fakeId), 'The static set should contain the added ID.');
    }
}
