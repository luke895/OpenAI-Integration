public with sharing class TaskTriggerHandler {
    public static void processTasks(List<Task> tasks) {
        for (Task task : tasks) {
            AIStagingService.processTaskForAIStaging(task);
        }
    }
}