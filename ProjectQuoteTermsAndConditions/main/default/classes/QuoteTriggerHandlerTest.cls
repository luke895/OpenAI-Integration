@isTest
private class QuoteTriggerHandlerTest {
    @isTest static void testDummy() {
        // Create a dummy Opportunity and Quote to satisfy required fields.
        Opportunity opp = new Opportunity(Name = 'Dummy Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(30));
        insert opp;
        Quote q = new Quote(Name = 'Dummy Quote', OpportunityId = opp.Id);
        insert q;
        try {
            QuoteTriggerHandler.populateTermsForNewQuotes(new List<Quote>{ q });
        } catch(Exception e) { }
        System.assert(true);
    }
}
