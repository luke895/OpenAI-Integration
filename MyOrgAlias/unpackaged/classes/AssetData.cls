public with sharing class AssetData {
    public String name;
    public Integer quantity;
    public Boolean isCompetitorProduct;
    public Date usageEndDate;

    public AssetData(Map<String, String> assetInfo) {
        this.name = assetInfo.containsKey('name') ? assetInfo.get('name') : 'Unknown Asset';
        this.quantity = assetInfo.containsKey('quantity') ? Integer.valueOf(assetInfo.get('quantity')) : 1;
        this.isCompetitorProduct = assetInfo.containsKey('IsCompetitorProduct') ? Boolean.valueOf(assetInfo.get('IsCompetitorProduct')) : false;
        this.usageEndDate = assetInfo.containsKey('UsageEndDate') ? Date.valueOf(assetInfo.get('UsageEndDate')) : null;
    }
}