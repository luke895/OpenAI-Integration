public with sharing class TaskHandler {
    private static final Decimal MAX_TASK_SCORE = 10; // Maximum interaction rating
    private static final Decimal DECAY_RATE = 0.1;   // Decay rate for older interactions

    public static void updateHealthScores(List<Task> tasks, Map<Id, Task> oldTasks) {
        // Step 1: Validate CRUD permissions
        validatePermissions();

        // Step 2: Calculate decayed scores for Contacts
        Map<Id, Decimal> contactScores = calculateDecayedContactScores(tasks);
        Map<Id, Decimal> contactTaskCounts = calculateTaskCounts(tasks);

        // Step 3: Update Contact Health Scores
        updateContactHealthScores(contactScores, contactTaskCounts);

        // Step 4: Update Account Health Scores
        updateAccountHealthScores(contactScores);
    }

    /**
     * Validates CRUD and FLS permissions for Contact and Account objects.
     */
    private static void validatePermissions() {
        if (!Schema.sObjectType.Contact.isAccessible() || !Schema.sObjectType.Contact.fields.Contact_Health_Score__c.isAccessible()) {
            throw new AuthorizationException('No access to Contact or Contact_Health_Score__c.');
        }

        if (!Schema.sObjectType.Account.isAccessible() || !Schema.sObjectType.Account.fields.Company_Health_Score__c.isAccessible()) {
            throw new AuthorizationException('No access to Account or Company_Health_Score__c.');
        }

        if (!Schema.sObjectType.Contact.isUpdateable()) {
            throw new AuthorizationException('You do not have permission to update Contacts.');
        }

        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new AuthorizationException('You do not have permission to update Accounts.');
        }
    }

    /**
     * Calculates decayed scores for Contacts based on Task Interaction Ratings.
     */
    private static Map<Id, Decimal> calculateDecayedContactScores(List<Task> tasks) {
        Map<Id, Decimal> contactScores = new Map<Id, Decimal>();

        for (Task t : tasks) {
            if (t.WhoId != null && String.valueOf(t.WhoId).startsWith('003')) { // Only process Contacts
                Decimal decayedRating = getDecayedRating(t.Interaction_Rating__c, t.CreatedDate);
                contactScores.put(t.WhoId, contactScores.getOrDefault(t.WhoId, 0) + decayedRating);
            }
        }

        return contactScores;
    }

    /**
     * Calculates the number of tasks associated with each Contact.
     */
    private static Map<Id, Decimal> calculateTaskCounts(List<Task> tasks) {
        Map<Id, Decimal> contactTaskCounts = new Map<Id, Decimal>();

        for (Task t : tasks) {
            if (t.WhoId != null && String.valueOf(t.WhoId).startsWith('003')) {
                contactTaskCounts.put(t.WhoId, contactTaskCounts.getOrDefault(t.WhoId, 0) + 1);
            }
        }

        return contactTaskCounts;
    }

    /**
     * Updates the Health Scores for Contacts based on decayed scores and task counts.
     */
    private static void updateContactHealthScores(Map<Id, Decimal> contactScores, Map<Id, Decimal> contactTaskCounts) {
        List<Contact> contactsToUpdate = new List<Contact>();

        for (Id contactId : contactScores.keySet()) {
            Decimal contactMaxScore = contactTaskCounts.get(contactId) * MAX_TASK_SCORE;
            Decimal healthPercentage = (contactScores.get(contactId) / contactMaxScore) * 100;

            contactsToUpdate.add(new Contact(Id = contactId, Contact_Health_Score__c = healthPercentage));
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }

    /**
     * Updates the Health Scores for Accounts based on the Health Scores of their related Contacts.
     */
    private static void updateAccountHealthScores(Map<Id, Decimal> contactScores) {
        Map<Id, Decimal> accountScores = new Map<Id, Decimal>();
        Map<Id, Decimal> accountContactCounts = new Map<Id, Decimal>();

        for (Contact c : [
            SELECT Id, AccountId, Contact_Health_Score__c 
            FROM Contact 
            WHERE Id IN :contactScores.keySet()
        ]) {
            if (c.AccountId != null) {
                accountScores.put(c.AccountId, accountScores.getOrDefault(c.AccountId, 0) + c.Contact_Health_Score__c);
                accountContactCounts.put(c.AccountId, accountContactCounts.getOrDefault(c.AccountId, 0) + 1);
            }
        }

        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId : accountScores.keySet()) {
            Decimal companyMaxScore = accountContactCounts.get(accountId) * 100;
            Decimal companyHealthPercentage = (accountScores.get(accountId) / companyMaxScore);

            accountsToUpdate.add(new Account(Id = accountId, Company_Health_Score__c = companyHealthPercentage));
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    /**
     * Calculates the decayed rating for a given Task based on the interaction age.
     */
    private static Decimal getDecayedRating(Decimal rating, Datetime createdDate) {
        if (rating == null || createdDate == null) {
            return 0;
        }
        Decimal ageInDays = Datetime.now().date().daysBetween(createdDate.date());
        return rating * Math.exp(-DECAY_RATE * ageInDays);
    }
}
