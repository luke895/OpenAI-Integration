public with sharing class QuoteTriggerHandler {
    public static void populateTermsForNewQuotes(List<Quote> newQuotes) {
        System.debug('### Trigger started for Quotes: ' + newQuotes);

        // Ensure field update access
        if (!Schema.sObjectType.Quote.fields.Terms_And_Conditions__c.isUpdateable() || 
            !Schema.sObjectType.Quote.fields.Terms_and_Conditions_PDF__c.isUpdateable() ||
            !Schema.sObjectType.Quote.fields.Quote_Acceptance__c.isUpdateable()) {
            System.debug('### User does not have permission to update Terms and Conditions or Quote Acceptance.');
            return;
        }

        // Fetch Terms and Conditions from CMDT
        String termsContent = TermsAndConditionsService.getTermsContent();
        System.debug('### Retrieved Terms Content: ' + termsContent);

        // Convert HTML to Plain Text for PDF Output
        String plainTextTerms = termsContent.replaceAll('<br/>', '\n')
                                            .replaceAll('</p>', '\n')
                                            .replaceAll('<[^>]+>', ''); // Removes remaining HTML tags

        // Default Signature Block
        String signatureBlock = '\n\n'
            + 'Name:______________________________\n\n'
            + 'Date: _____________________________\n\n'
            + 'Signature: ________________________\n\n';

        // Assign formatted text to both fields
        for (Quote q : newQuotes) {
            if (q.Terms_and_Conditions__c == null) {
                q.Terms_and_Conditions__c = termsContent; // Rich Text
            }
            if (q.Terms_and_Conditions_PDF__c == null) {
                q.Terms_and_Conditions_PDF__c = plainTextTerms; // Plain Text for PDF
            }
            if (q.Quote_Acceptance__c == null) {
                q.Quote_Acceptance__c = signatureBlock; // Auto-populated signature section
            }
        }
    }
}