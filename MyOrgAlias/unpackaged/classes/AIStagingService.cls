public with sharing class AIStagingService {

    // Future method for asynchronous processing (kept for backward compatibility).
    @future(callout=true)
    public static void processTasksForAIStagingFuture(List<Id> taskIds) {
        System.debug('Future Method: Processing tasks for IDs: ' + taskIds);
        List<Task> tasks = [SELECT Id, Description FROM Task WHERE Id IN :taskIds];
        processTasksForAIStaging(tasks);
    }
    
    // NEW: Synchronous method that accepts a list of Task IDs.
    // This method is to be called from the queueable job.
    public static void processTasksForAIStaging(List<Id> taskIds) {
        List<Task> tasks = [SELECT Id, Description FROM Task WHERE Id IN :taskIds];
        processTasksForAIStaging(tasks);
    }
    
    // Processes a list of Task records.
    public static void processTasksForAIStaging(List<Task> tasks) {
        for (Task t : tasks) {
            processTaskForAIStaging(t);
        }
    }
    
    // Processes a single Task record.
    public static void processTaskForAIStaging(Task taskRecord) {
        System.debug('🔵 [AIStagingService] Processing AI extraction for Task: ' + taskRecord.Id);
        if (!isValidTask(taskRecord)) {
            System.debug('⚠️ [AIStagingService] Task is invalid or missing description.');
            return;
        }
        
        // Perform the callout to OpenAI.
        String aiResponse = AIUtility.callOpenAI(taskRecord.Description);
        if (aiResponse == null) {
            System.debug('❌ No AI response received.');
            return;
        }
        
        // Parse the response using our updated parser.
        List<Map<String, Object>> extractedAssets = AIResponseParser.parseAIResponse(aiResponse);
        System.debug('🟢 [AIStagingService] Extracted Assets: ' + JSON.serializePretty(extractedAssets));
        
        // Create AI Staging records (for review).
        createAIStagingRecords(taskRecord.Id, extractedAssets);
    }
    
    private static Boolean isValidTask(Task taskRecord) {
        return taskRecord != null && !String.isBlank(taskRecord.Description);
    }
    
    private static void createAIStagingRecords(Id taskId, List<Map<String, Object>> extractedAssets) {
        // Delete any existing pending staging records for this task to avoid duplicates.
        List<AI_Staging__c> existingRecords = [
            SELECT Id 
            FROM AI_Staging__c 
            WHERE Task_ID__c = :taskId 
              AND Review_Status__c = 'Pending Review'
        ];
        if (!existingRecords.isEmpty()) {
            delete existingRecords;
            System.debug('Deleted ' + existingRecords.size() + ' existing pending staging records for task ' + taskId);
        }
        
        if (extractedAssets.isEmpty()) {
            System.debug('⚠️ [AIStagingService] No assets extracted from AI response.');
            return;
        }
        
        List<AI_Staging__c> aiStagingRecords = new List<AI_Staging__c>();
        for (Map<String, Object> assetData : extractedAssets) {
            // Create a staging record for each asset.
            AI_Staging__c stagingRecord = mapAssetToStagingRecord(taskId, assetData);
            aiStagingRecords.add(stagingRecord);
        }
        
        if (!aiStagingRecords.isEmpty()) {
            insert aiStagingRecords;
            System.debug('✅ [AIStagingService] Inserted ' + aiStagingRecords.size() + ' AI Staging records.');
        }
    }
    
    // Maps asset data to an AI_Staging__c record.
    private static AI_Staging__c mapAssetToStagingRecord(Id taskId, Map<String, Object> assetData) {
        AI_Staging__c record = new AI_Staging__c();
        record.Task_ID__c = taskId;
        record.Name__c = (String) assetData.get('Name');
        record.Quantity__c = (Integer) assetData.get('Quantity');
        record.Usage_End_Date__c = parseDate(assetData.get('UsageEndDate'));
        record.Is_Competitor_Asset__c = assetData.get('IsCompetitorProduct') != null 
                                        ? (Boolean) assetData.get('IsCompetitorProduct') 
                                        : false;
        record.Review_Status__c = 'Pending Review';
        return record;
    }
    
    // --- Approval and Conversion Logic ---
    @AuraEnabled
    public static void approveRecord(Id recordId) {
        try {
            AI_Staging__c stagingRecord = [
                SELECT Id, Name__c, Quantity__c, Usage_End_Date__c, Is_Competitor_Asset__c, Task_ID__c, Review_Status__c 
                FROM AI_Staging__c 
                WHERE Id = :recordId 
                LIMIT 1
            ];
            stagingRecord.Review_Status__c = 'Approved';
            update stagingRecord;
            System.debug('✅ AI Staging Record Approved: ' + recordId);
            convertStagingToAsset(stagingRecord);
        } catch (Exception e) {
            System.debug('❌ Error approving record: ' + e.getMessage());
            throw new AuraHandledException('Error approving record: ' + e.getMessage());
        }
    }
    
    // Converts an approved staging record into an Asset record.
    private static void convertStagingToAsset(AI_Staging__c stagingRecord) {
        Asset newAsset = new Asset();
        newAsset.Name = stagingRecord.Name__c;
        newAsset.Quantity = stagingRecord.Quantity__c;
        newAsset.UsageEndDate = stagingRecord.Usage_End_Date__c;
        newAsset.IsCompetitorProduct = stagingRecord.Is_Competitor_Asset__c;
        Task relatedTask = [
            SELECT AccountId 
            FROM Task 
            WHERE Id = :stagingRecord.Task_ID__c 
            LIMIT 1
        ];
        newAsset.AccountId = relatedTask.AccountId;
        insert newAsset;
        System.debug('✅ Created Asset record with Id: ' + newAsset.Id);
    }
    // --- End Approval and Conversion Logic ---
    
    @AuraEnabled
    public static void rejectRecord(Id recordId) {
        try {
            AI_Staging__c record = [
                SELECT Id 
                FROM AI_Staging__c 
                WHERE Id = :recordId 
                LIMIT 1
            ];
            delete record;
            Database.emptyRecycleBin(new List<AI_Staging__c>{ record });
            System.debug('✅ Permanently deleted AI Staging Record (Rejected): ' + recordId);
        } catch (Exception e) {
            System.debug('❌ Error permanently deleting rejected record: ' + e.getMessage());
            throw new AuraHandledException('Error permanently deleting rejected record: ' + e.getMessage());
        }
    }
    
    // --- New Method to Filter Staging Records by Task ---
    @AuraEnabled(cacheable=true)
    public static List<AI_Staging__c> getAIStagingRecordsByTask(Id taskId) {
        try {
            return [
                SELECT Id, Name__c, Quantity__c, Usage_End_Date__c, Review_Status__c, Task_ID__c 
                FROM AI_Staging__c 
                WHERE Review_Status__c = 'Pending Review'
                  AND Task_ID__c = :taskId
                ORDER BY CreatedDate DESC 
                LIMIT 50
            ];
        } catch (Exception e) {
            System.debug('❌ [AIStagingService] Error fetching staged data for task ' + taskId + ': ' + e.getMessage());
            return new List<AI_Staging__c>();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<AI_Staging__c> getAIStagingRecords() {
        try {
            return [
                SELECT Id, Name__c, Quantity__c, Usage_End_Date__c, Review_Status__c, Task_ID__c 
                FROM AI_Staging__c 
                WHERE Review_Status__c = 'Pending Review'
                ORDER BY CreatedDate DESC 
                LIMIT 50
            ];
        } catch (Exception e) {
            System.debug('❌ [AIStagingService] Error fetching staged data: ' + e.getMessage());
            return new List<AI_Staging__c>();
        }
    }
    
    @AuraEnabled
    public static void sendToAIStaging(Id taskId, List<Map<String, Object>> extractedAssets) {
        createAIStagingRecords(taskId, extractedAssets);
    }
    
    // --- Utility Methods for Date Parsing ---
    private static Date parseDate(Object dateValue) {
        if (dateValue == null) {
            return null;
        }
        String rawDate = String.valueOf(dateValue).trim();
        if (String.isBlank(rawDate)) {
            return null;
        }
        try {
            return Date.valueOf(rawDate);
        } catch(Exception e) {
            System.debug('❌ [AIStagingService] Error converting date: ' + e.getMessage());
            return null;
        }
    }
}