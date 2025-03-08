public with sharing class TaskHandler {
    public static void handleTaskChanges(TriggerOperation operation, List<Task> taskList, Map<Id, Task> oldTasks) {
        if (!validatePermissions()) {
            return;
        }

        Set<Id> contactIds = extractContactIds(taskList, oldTasks, operation == TriggerOperation.AFTER_DELETE);
        if (contactIds.isEmpty()) {
            return;
        }

        updateHealthScores(contactIds);
    }

    private static Boolean validatePermissions() {
        return Schema.sObjectType.Contact.isAccessible() &&
               Schema.sObjectType.Contact.fields.Contact_Health_Score__c.isAccessible() &&
               Schema.sObjectType.Contact.isUpdateable() &&
               Schema.sObjectType.Account.isAccessible() &&
               Schema.sObjectType.Account.fields.Company_Health_Score__c.isAccessible() &&
               Schema.sObjectType.Account.isUpdateable() &&
               Schema.sObjectType.Task.isAccessible() &&
               Schema.sObjectType.Task.fields.CreatedDate.isAccessible() &&
               Schema.sObjectType.Task.fields.Interaction_Rating__c.isAccessible();
    }

    private static Set<Id> extractContactIds(List<Task> taskList, Map<Id, Task> oldTasks, Boolean isDelete) {
        Set<Id> contactIds = new Set<Id>();

        if (isDelete) {
            addValidContactIds(contactIds, oldTasks != null ? oldTasks.values() : new List<Task>());
        } else {
            addValidContactIds(contactIds, taskList);
        }

        return contactIds;
    }

    private static void addValidContactIds(Set<Id> contactIds, List<Task> tasks) {
        for (Task t : tasks) {
            if (t.WhoId != null && String.valueOf(t.WhoId).startsWith('003')) {
                contactIds.add(t.WhoId);
            }
        }
    }

    private static void updateHealthScores(Set<Id> contactIds) {
        Map<Id, Decimal> contactScores = calculateContactHealthScores(contactIds);
        updateContactHealthScores(contactScores);
        updateAccountHealthScores();
    }

    private static Map<Id, Decimal> calculateContactHealthScores(Set<Id> contactIds) {
        Map<Id, Decimal> contactScores = new Map<Id, Decimal>();

        if (!Schema.sObjectType.Task.isAccessible()) {
            return contactScores;
        }

        for (AggregateResult ar : [
            SELECT WhoId, MAX(CreatedDate) lastDate, AVG(Interaction_Rating__c) avgRating
            FROM Task
            WHERE WhoId IN :contactIds
            GROUP BY WhoId
        ]) {
            Id contactId = (Id) ar.get('WhoId');
            Decimal avgRating = (Decimal) ar.get('avgRating');
            Datetime lastInteractionDate = (Datetime) ar.get('lastDate');

            Decimal finalScore = applyDecay(avgRating, lastInteractionDate);
            contactScores.put(contactId, finalScore);
        }

        return contactScores;
    }

    private static Decimal applyDecay(Decimal avgScore, Datetime lastInteractionDate) {
        if (avgScore == null) {
            avgScore = 0;
        }
        if (lastInteractionDate == null) {
            System.debug('applyDecay: lastInteractionDate is null, returning avgScore: ' + avgScore);
            return avgScore;
        }
        Integer daysSinceLastInteraction = Datetime.now().date().daysBetween(lastInteractionDate.date());
        Decimal finalScore = avgScore;

        if (daysSinceLastInteraction > 60) {
            Integer decayPeriods = (daysSinceLastInteraction - 1) / 60;
            finalScore = Math.max(0, finalScore - (decayPeriods * 5));
        }

        return Math.max(0, Math.min(100, finalScore));
    }

    private static void updateContactHealthScores(Map<Id, Decimal> contactScores) {
        if (!Schema.sObjectType.Contact.isUpdateable()) {
            return;
        }

        List<Contact> contactsToUpdate = new List<Contact>();

        for (Id contactId : contactScores.keySet()) {
            Decimal healthScore = Math.max(0, Math.min(100, contactScores.get(contactId)));
            contactsToUpdate.add(new Contact(Id = contactId, Contact_Health_Score__c = healthScore));
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }

    // Updated method with null-check for the aggregated score.
    private static void updateAccountHealthScores() {
        if (!Schema.sObjectType.Account.isUpdateable()) {
            return;
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (AggregateResult ar : [
            SELECT AccountId, AVG(Contact_Health_Score__c) avgContactHealth
            FROM Contact
            WHERE AccountId != null
            GROUP BY AccountId
        ]) {
            Id accountId = (Id) ar.get('AccountId');
            // If avgContactHealth is null, default to 0.
            Decimal avgContactHealth = (Decimal) ar.get('avgContactHealth');
            if (avgContactHealth == null) {
                avgContactHealth = 0;
            }
            Decimal finalCompanyHealth = Math.max(0, Math.min(100, avgContactHealth));
            accountsToUpdate.add(new Account(Id = accountId, Company_Health_Score__c = finalCompanyHealth));
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    private static void updateAccountHealthScores_old() {
        // Original code (if needed for reference)
    }

    // End Health Score Methods

    // (Other methods remain unchanged)
}