public with sharing class AssetProcessingHelper {
    public static void processAssets(AssetProcessingRequest request) {
        if (request == null || request.extractedAssets.isEmpty()) {
            System.debug('No extracted assets to process.');
            return;
        }

        // Validate Object Permissions
        if (!Schema.sObjectType.Asset.isAccessible() || !Schema.sObjectType.Asset.isCreateable() || !Schema.sObjectType.Asset.isUpdateable()) {
            System.debug('Insufficient permissions to access or modify Asset records.');
            return;
        }

        List<Asset> assetsToInsert = new List<Asset>();
        List<Asset> assetsToUpdate = new List<Asset>();

        for (AssetData assetData : request.extractedAssets) {
            if (request.existingAssets.containsKey(assetData.name)) {
                Asset existingAsset = request.existingAssets.get(assetData.name);
                updateAsset(existingAsset, assetData);
                assetsToUpdate.add(existingAsset);
            } else {
                assetsToInsert.add(createNewAsset(assetData));
            }
        }

        performDML(assetsToInsert, assetsToUpdate);
    }

    private static void updateAsset(Asset asset, AssetData assetData) {
        // Validate Field-Level Security (FLS) Before Updating
        if (!Schema.sObjectType.Asset.fields.Quantity.isUpdateable() ||
            !Schema.sObjectType.Asset.fields.IsCompetitorProduct.isUpdateable() ||
            !Schema.sObjectType.Asset.fields.UsageEndDate.isUpdateable()) {
            System.debug('Insufficient field-level security permissions to update Asset fields.');
            return;
        }

        asset.Quantity = assetData.quantity;
        asset.IsCompetitorProduct = assetData.isCompetitorProduct;
        asset.UsageEndDate = assetData.usageEndDate;
    }

    private static Asset createNewAsset(AssetData assetData) {
        // Validate Field-Level Security (FLS) Before Inserting
        if (!Schema.sObjectType.Asset.fields.Name.isCreateable() ||
            !Schema.sObjectType.Asset.fields.Quantity.isCreateable() ||
            !Schema.sObjectType.Asset.fields.IsCompetitorProduct.isCreateable() ||
            !Schema.sObjectType.Asset.fields.UsageEndDate.isCreateable()) {
            System.debug('Insufficient field-level security permissions to create Asset fields.');
            return null;
        }

        return new Asset(
            Name = assetData.name,
            Quantity = assetData.quantity,
            IsCompetitorProduct = assetData.isCompetitorProduct,
            UsageEndDate = assetData.usageEndDate
        );
    }

    private static void performDML(List<Asset> assetsToInsert, List<Asset> assetsToUpdate) {
        if (!assetsToInsert.isEmpty()) {
            insert assetsToInsert;
            System.debug('Inserted ' + assetsToInsert.size() + ' new Assets.');
        }
        if (!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
            System.debug('Updated ' + assetsToUpdate.size() + ' existing Assets.');
        }
    }
}