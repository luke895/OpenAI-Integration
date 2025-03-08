public with sharing class AIResponseParser {

    public static List<Map<String, Object>> parseAIResponse(String aiTextResponse) {
        System.debug('🔵 [AIResponseParser] Processing AI Response: ' + aiTextResponse);
        List<Map<String, Object>> extractedAssets = new List<Map<String, Object>>();
        
        if (String.isBlank(aiTextResponse)) {
            System.debug('❌ AI Response is empty.');
            return extractedAssets;
        }
        
        try {
            // Deserialize the overall response
            Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(aiTextResponse);
            
            // Look for the "choices" key
            if (parsedResponse.containsKey('choices')) {
                List<Object> choices = (List<Object>) parsedResponse.get('choices');
                if (!choices.isEmpty()) {
                    // Get the first choice and its message
                    Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
                    if (firstChoice.containsKey('message')) {
                        Map<String, Object> message = (Map<String, Object>) firstChoice.get('message');
                        String content = (String) message.get('content');
                        if (!String.isBlank(content)) {
                            // Deserialize the content which should contain the "assets" key
                            Map<String, Object> contentData = (Map<String, Object>) JSON.deserializeUntyped(content);
                            if (contentData.containsKey('assets')) {
                                List<Object> assets = (List<Object>) contentData.get('assets');
                                if (assets.isEmpty()) {
                                    System.debug('⚠️ [AIResponseParser] No assets found in content.');
                                }
                                for (Object assetObj : assets) {
                                    Map<String, Object> asset = (Map<String, Object>) assetObj;
                                    Map<String, Object> formattedAsset = new Map<String, Object>();
                                    formattedAsset.put('Name', extractProductName(asset));
                                    formattedAsset.put('Quantity', extractQuantity(asset));
                                    formattedAsset.put('IsCompetitorProduct', extractIsCompetitorProduct(asset));
                                    formattedAsset.put('UsageEndDate', extractUsageEndDate(asset));
                                    extractedAssets.add(formattedAsset);
                                }
                            } else {
                                System.debug('⚠️ [AIResponseParser] Expected "assets" key not found in content.');
                            }
                        } else {
                            System.debug('⚠️ [AIResponseParser] Message content is empty.');
                        }
                    } else {
                        System.debug('⚠️ [AIResponseParser] "message" key not found in first choice.');
                    }
                } else {
                    System.debug('⚠️ [AIResponseParser] No choices found.');
                }
            } else {
                System.debug('⚠️ [AIResponseParser] Expected "choices" key not found.');
            }
        } catch (Exception e) {
            System.debug('❌ [AIResponseParser] Error parsing AI response: ' + e.getMessage());
        }
        
        return extractedAssets;
    }

    private static String extractProductName(Map<String, Object> asset) {
        if (asset.containsKey('name') && asset.get('name') != null) {
            return String.valueOf(asset.get('name'));
        }
        return 'Unknown';
    }

    private static Integer extractQuantity(Map<String, Object> asset) {
        if (asset.containsKey('quantity') && asset.get('quantity') != null) {
            try {
                return Integer.valueOf(asset.get('quantity'));
            } catch (Exception e) {
                System.debug('⚠️ [AIResponseParser] Invalid quantity format. Defaulting to 1.');
            }
        }
        return 1;
    }

    private static Boolean extractIsCompetitorProduct(Map<String, Object> asset) {
        if (asset.containsKey('isCompetitorProduct') && asset.get('isCompetitorProduct') != null) {
            return Boolean.valueOf(asset.get('isCompetitorProduct'));
        }
        return false;
    }

    private static String extractUsageEndDate(Map<String, Object> asset) {
        if (asset.containsKey('usageEndDate') && asset.get('usageEndDate') != null) {
            return String.valueOf(asset.get('usageEndDate'));
        }
        return null;
    }
}