public with sharing class DailyHealthScoreScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DailyHealthScoreBatch());
    }
}
