({
    subscribe : function(component) {
        // Subscribe to our custom platform event "CallInitiatedEvent__e"
        var empApi = component.find("empApi");
        var channel = "/event/CallInitiatedEvent__e";
        var replayId = -1; // get new events
        empApi.subscribe(channel, replayId, $A.getCallback(function(event) {
            // Retrieve Task Id from the event payload
            var taskId = event.data.payload.TaskId__c;
            // Navigate automatically to the Task record page in a new tab
            var navEvt = $A.get("e.force:navigateToSObject");
            if(navEvt){
                navEvt.setParams({
                    "recordId": taskId,
                    "slideDevName": "detail"
                });
                navEvt.fire();
            }
        })).then(function(subscription) {
            console.log('Subscribed to ' + channel);
        });
    }
})
