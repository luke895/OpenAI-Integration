// File: force-app/ProjectQuoteTermsAndConditions/main/default/triggers/QuoteTriggerTest.cls
@isTest
private class QuoteTriggerTest {
    @isTest static void testQuoteTriggerBeforeInsert() {
        // Create a test Quote with null fields to simulate a new Quote.
        Quote q = new Quote(
            Name = 'Test Quote',
            Terms_and_Conditions__c = null,
            Terms_And_Conditions_PDF__c = null,
            Quote_Acceptance__c = null
            // Populate other required fields if necessary.
        );
        insert q;
        
        // Query the Quote record.
        Quote updatedQ = [SELECT Terms_and_Conditions__c, Terms_And_Conditions_PDF__c, Quote_Acceptance__c FROM Quote WHERE Id = :q.Id];
        System.assertNotEquals(null, updatedQ.Terms_and_Conditions__c, 'Terms and Conditions should be populated.');
        System.assertNotEquals(null, updatedQ.Terms_And_Conditions_PDF__c, 'PDF Terms should be populated.');
        System.assertNotEquals(null, updatedQ.Quote_Acceptance__c, 'Quote Acceptance should be populated.');
    }
}
