// File: ProjectGetTranscript/classes/DialpadTranscriptQueueable.cls
public class DialpadTranscriptQueueable implements Queueable, Database.AllowsCallouts {
    private String callId;
    private Id taskId;
    
    public DialpadTranscriptQueueable(String callId, Id taskId) {
        this.callId = callId;
        this.taskId = taskId;
    }
    
    public void execute(QueueableContext context) {
        // Invoke the transcript service asynchronously.
        DialpadTranscriptService.processTranscript(callId, taskId);
    }
}
