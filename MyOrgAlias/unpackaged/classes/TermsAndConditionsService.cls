public with sharing class TermsAndConditionsService {
    @AuraEnabled(cacheable=true)
    public static String getTermsContent() {
        try {
            // Ensure CMDT and field access
            if (!Schema.sObjectType.Terms_And_Conditions__mdt.isAccessible()) {
                throw new SecurityException('User does not have permission to access Terms and Conditions metadata.');
            }

            // Fetch the Terms and Conditions record
            List<Terms_And_Conditions__mdt> termsList = [
                SELECT Content__c FROM Terms_And_Conditions__mdt LIMIT 1
            ];

            if (termsList.isEmpty()) {
                return 'No Terms and Conditions found.';
            }

            // Replace line breaks with HTML <br/> tags for correct Rich Text Area formatting
            String formattedTerms = termsList[0].Content__c.replaceAll('\n', '<br/>');

            return formattedTerms;
        } catch (Exception e) {
            System.debug('Error retrieving Terms and Conditions: ' + e.getMessage());
            return 'Default Terms and Conditions - error loading content.';
        }
    }
}