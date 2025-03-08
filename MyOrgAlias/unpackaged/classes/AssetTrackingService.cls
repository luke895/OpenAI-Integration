public with sharing class AssetTrackingService {
    public static void processTaskForAssets(Task taskRecord) {
        System.debug('🔵 [AssetTrackingService] Processing task: ' + taskRecord.Id);

        if (!isValidTask(taskRecord)) {
            return;
        }

        String aiResponse = AIUtility.callOpenAI(taskRecord.Description);
        if (aiResponse == null) {
            System.debug('❌ No AI response received.');
            return;
        }

        List<Map<String, Object>> extractedAssets = AIResponseParser.parseAIResponse(aiResponse);
        System.debug('🟢 Extracted Assets: ' + JSON.serializePretty(extractedAssets));

        // ✅ Send extracted data to AI Staging
        AIStagingService.sendToAIStaging(taskRecord.Id, extractedAssets);
    }

    private static Boolean isValidTask(Task taskRecord) {
        return taskRecord != null && !String.isBlank(taskRecord.Description);
    }
}