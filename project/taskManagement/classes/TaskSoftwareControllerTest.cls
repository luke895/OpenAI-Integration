// File: project/taskManagement/classes/TaskSoftwareControllerTest.cls
@isTest
private class TaskSoftwareControllerTest {
    
    @isTest static void testGetTaskSoftware() {
        // Create a Task record with a known value for Software_Discussed__c.
        Task t = new Task(
            Subject = 'Test Task',
            ActivityDate = Date.today(),
            Software_Discussed__c = 'Test Software'
            // Populate any additional required fields.
        );
        insert t;
        
        // Retrieve the software discussed value using the controller.
        String result = TaskSoftwareController.getTaskSoftware(t.Id);
        System.assertEquals('Test Software', result, 'The returned Software Discussed value should match the test value.');
    }
    
    @isTest static void testUpdateSoftwareDiscussedField() {
        // Create a Task record with an initial value.
        Task t = new Task(
            Subject = 'Test Task',
            ActivityDate = Date.today(),
            Software_Discussed__c = 'Initial Software'
            // Populate any additional required fields.
        );
        insert t;
        
        // Update the Software_Discussed__c field via the controller.
        TaskSoftwareController.updateSoftwareDiscussedField(t.Id, 'Updated Software');
        
        // Query the Task record to verify the field was updated.
        t = [SELECT Software_Discussed__c FROM Task WHERE Id = :t.Id];
        System.assertEquals('Updated Software', t.Software_Discussed__c, 'Software Discussed field should be updated.');
    }
}
