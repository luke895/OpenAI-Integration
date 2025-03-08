// File: force-app/ProjectHealthScore/main/default/classes/DailyHealthScoreSchedulerTest.cls
@isTest
private class DailyHealthScoreSchedulerTest {
    @isTest static void testDailyHealthScoreScheduler() {
        DailyHealthScoreScheduler sched = new DailyHealthScoreScheduler();
        Test.startTest();
            sched.execute(null);
        Test.stopTest();
        // If no exception is thrown, the test passes.
        System.assert(true, 'Scheduler executed without errors.');
    }
}
