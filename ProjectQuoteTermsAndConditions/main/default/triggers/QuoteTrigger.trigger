trigger QuoteTrigger on Quote (before insert) {
    QuoteTriggerHandler.populateTermsForNewQuotes(Trigger.new);
}
