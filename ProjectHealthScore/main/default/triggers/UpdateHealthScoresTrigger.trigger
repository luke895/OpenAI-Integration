trigger UpdateHealthScoresTrigger on Task (after insert, after update, after delete) {
    TaskHandler.updateHealthScores(Trigger.new, Trigger.oldMap);
}
