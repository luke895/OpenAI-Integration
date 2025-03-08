public with sharing class PopulateTermsAndConditions {
    @InvocableMethod
    public static void updateTerms(List<Id> quoteIds) {
        // Verify user has permission to update this field
        if (!Schema.sObjectType.Quote.fields.Terms_and_Conditions__c.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update Terms and Conditions.');
        }

        // Get the content from the Custom Metadata Type (CMDT)
        String termsContent = TermsAndConditionsService.getTermsContent();

        // Query Quotes and update the Terms and Conditions field
        List<Quote> quotesToUpdate = [SELECT Id FROM Quote WHERE Id IN :quoteIds];
        for (Quote q : quotesToUpdate) {
            q.Terms_and_Conditions__c = termsContent;
        }

        update quotesToUpdate;
    }
}