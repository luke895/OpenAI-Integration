public with sharing class DailyHealthScoreBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Task]);
    }

    public void execute(Database.BatchableContext bc, List<Task> scope) {
        TaskHandler.updateHealthScores(scope, null);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Daily batch completed.');
    }
}
