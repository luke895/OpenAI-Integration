public class DailyHealthScoreBatch implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext batchContext) {
        return Database.getQueryLocator('SELECT Id, WhoId FROM Task WHERE WhoId != NULL');
    }

    public void execute(Database.BatchableContext batchContext, List<Task> taskList) {
        Map<Id, Task> oldTasks = new Map<Id, Task>(); // No old records in batch
        TaskHandler.handleTaskChanges(TriggerOperation.AFTER_UPDATE, taskList, oldTasks);
    }

    public void finish(Database.BatchableContext batchContext) {
        System.debug('Batch Process Completed');
    }
}