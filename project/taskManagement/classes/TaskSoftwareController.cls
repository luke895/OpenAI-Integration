public with sharing class TaskSoftwareController {
    @AuraEnabled(cacheable=true)
    public static String getTaskSoftware(Id taskId) {
        // Validate read access for the Software_Discussed__c field.
        if (!Schema.sObjectType.Task.fields.Software_Discussed__c.isAccessible()) {
            throw new AuraHandledException('You do not have access to the Software Discussed field.');
        }
        
        // Query the Task record for the field value.
        Task t = [SELECT Software_Discussed__c FROM Task WHERE Id = :taskId LIMIT 1];
        return t.Software_Discussed__c;
    }

    @AuraEnabled
    public static void updateSoftwareDiscussedField(Id taskId, String softwareDiscussed) {
        // Validate update access on the Software_Discussed__c field.
        if (!Schema.sObjectType.Task.fields.Software_Discussed__c.isUpdateable()) {
            throw new AuraHandledException('You do not have update access to the Software Discussed field.');
        }
        
        // Query the Task record.
        Task taskRecord = [SELECT Id, Software_Discussed__c FROM Task WHERE Id = :taskId LIMIT 1];
        
        // Update the field and perform the DML operation.
        taskRecord.Software_Discussed__c = softwareDiscussed;
        update taskRecord;
    }
}
