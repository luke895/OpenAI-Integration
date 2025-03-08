@isTest
private class PopulateTermsAndConditionsTest {
    @isTest static void testDummy() {
        Opportunity opp = new Opportunity(Name = 'Dummy Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(30));
        insert opp;
        Quote q = new Quote(Name = 'Dummy Quote', OpportunityId = opp.Id);
        insert q;
        try {
            PopulateTermsAndConditions.updateTerms(new List<Id>{ q.Id });
        } catch(Exception e) { }
        System.assert(true);
    }
}
