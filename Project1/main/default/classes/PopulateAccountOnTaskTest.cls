public with sharing class PopulateAccountOnTaskHandler {
    public static void populateAccountName(List<Task> tasks) {
        // Check permissions for the required objects and fields
        if (!hasRequiredPermissions()) {
            return; // Exit if the user lacks necessary permissions
        }

        // Get the Contact ID to Account Name mapping
        Map<Id, String> contactAccountMap = getContactAccountMap(tasks);

        // Update the Task records with the associated Account Name
        updateTasksWithAccountName(tasks, contactAccountMap);
    }

    /**
     * Check if the user has the required CRUD and FLS permissions.
     */
    private static Boolean hasRequiredPermissions() {
        return Schema.sObjectType.Contact.isAccessible() &&
               Schema.sObjectType.Contact.fields.AccountId.isAccessible() &&
               Schema.sObjectType.Task.fields.Associated_Account_Name__c.isUpdateable();
    }

    /**
     * Get a map of Contact IDs to their associated Account Names.
     */
    private static Map<Id, String> getContactAccountMap(List<Task> tasks) {
        Set<Id> contactIds = new Set<Id>();

        // Collect Contact IDs from the Task's WhoId field
        for (Task t : tasks) {
            if (t.WhoId != null && String.valueOf(t.WhoId).startsWith('003')) { // "003" is the prefix for Contact IDs
                contactIds.add(t.WhoId);
            }
        }

        Map<Id, String> contactAccountMap = new Map<Id, String>();

        // Query Contacts and their related Accounts only if we have IDs to process
        if (!contactIds.isEmpty() && Schema.sObjectType.Contact.isAccessible() && Schema.sObjectType.Contact.fields.AccountId.isAccessible()) {
            for (Contact c : [
                SELECT Id, Account.Name
                FROM Contact
                WHERE Id IN :contactIds
            ]) {
                if (c.Account != null) {
                    contactAccountMap.put(c.Id, c.Account.Name);
                }
            }
        }

        return contactAccountMap;
    }

    /**
     * Populate the Associated_Account_Name__c field on Task records.
     */
    private static void updateTasksWithAccountName(List<Task> tasks, Map<Id, String> contactAccountMap) {
        for (Task t : tasks) {
            if (t.WhoId != null && contactAccountMap.containsKey(t.WhoId)) {
                t.Associated_Account_Name__c = contactAccountMap.get(t.WhoId);
            }
        }
    }
}
//Forcing change detection