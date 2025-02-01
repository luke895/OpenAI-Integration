public with sharing class TaskSoftwareController {

    @AuraEnabled(cacheable=true)
    public static String getTaskSoftware(Id taskId) {
        Task task = [SELECT Software_Discussed__c FROM Task WHERE Id = :taskId LIMIT 1];
        return task.Software_Discussed__c;
    }

    @AuraEnabled
    public static void updateTaskSoftware(Id taskId, String softwareList) {
        Task task = [SELECT Id FROM Task WHERE Id = :taskId];
        task.Software_Discussed__c = softwareList; // Semicolon-separated list
        update task;
    }
}
