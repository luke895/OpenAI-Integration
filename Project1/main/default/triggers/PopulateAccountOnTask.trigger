trigger PopulateAccountOnTask on Task (before insert, before update) {
    PopulateAccountOnTaskHandler.populateAccountName(Trigger.new);
}
//Forcing change detection