// File: AIStagingSaveController.cls
public with sharing class AIStagingSaveController {
    @AuraEnabled
    public static void saveComments(Id recordId, String newComments) {
        // Query the AI_Staging__c record by its Id
        List<AI_Staging__c> records = [
            SELECT Id, Comments__c 
            FROM AI_Staging__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        
        // Check if the record exists
        if (records.isEmpty()) {
            // Throw a clear error if no record is found
            throw new AuraHandledException('No AI Staging record found with ID: ' + recordId);
        }
        
        AI_Staging__c stagingRecord = records[0];
        stagingRecord.Comments__c = newComments;
        
        try {
            update stagingRecord;
            System.debug('✅ Successfully updated Comments__c for record: ' + recordId);
        } catch (Exception e) {
            System.debug('❌ Error saving comments: ' + e.getMessage());
            throw new AuraHandledException('Error saving comments: ' + e.getMessage());
        }
    }
}