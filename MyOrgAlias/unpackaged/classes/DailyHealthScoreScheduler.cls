public with sharing class DailyHealthScoreScheduler implements Schedulable {
    
    public void execute(SchedulableContext schedulableContext) {
        Database.executeBatch(new DailyHealthScoreBatch());
    }
}