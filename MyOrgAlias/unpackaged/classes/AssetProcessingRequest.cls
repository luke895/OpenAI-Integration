public with sharing class AssetProcessingRequest {
    public Id accountId;
    public List<AssetData> extractedAssets;
    public Map<String, Asset> existingAssets;

    public AssetProcessingRequest(Id accountId, List<AssetData> extractedAssets, Map<String, Asset> existingAssets) {
        this.accountId = accountId;
        this.extractedAssets = extractedAssets;
        this.existingAssets = existingAssets;
    }
}