# ProjectGetTranscript

## Overview
ProjectGetTranscript automates the retrieval of call transcripts from Dialpad and appends them to the corresponding Salesforce Task record. When a Dialpad call log is created, its Linked Task is updated in the background with the final transcript—triggering your AI review process.

## Components
- **Apex Classes:**
  - `DialpadTranscriptService.cls`: Performs an HTTP callout to retrieve the transcript from Dialpad and appends it to the Task’s Description.
  - `TranscriptRetryQueueable.cls`: Implements retry logic if the callout or Task update fails.
  - `ErrorLogHandler.cls`: Logs any errors into the custom object `Dialpad_Error_Log__c`.

- **Apex Trigger:**
  - `DialpadCallLogTrigger.trigger`: Automatically invokes the transcript retrieval process when a new Dialpad call log record is inserted.

- **Test Classes:**
  - `DialpadTranscriptServiceTest.cls`
  - `TranscriptRetryQueueableTest.cls`
  - `ErrorLogHandlerTest.cls`

## Setup Instructions
1. **Custom Label:**  
   Create a custom label named `Dialpad_API_Key` and set its value to:  
   `tM2kRUza5Q7uMM7cm7C9Z7j4jx82BqULvHG6VyXABDUnjckjdBCZWKf9cqK57JBKQDctUcKMw2SsAaTsLCwRpfKBCELsH8MMSAB6`

2. **Remote Site Settings:**  
   Add `https://dialpad.com` as a Remote Site.

3. **Deployment:**  
   Deploy the contents of this folder using Salesforce DX, change sets, or the Metadata API.

4. **Testing:**  
   Run all Apex tests to verify that:
   - The transcript is correctly retrieved and appended to the Task.
   - The retry mechanism works as expected.
   - Errors are logged in `Dialpad_Error_Log__c`.

## Process Flow
1. A Dialpad call is initiated, and a `Dialpad__Call_Log__c` record is created with:
   - `Dialpad__CallId__c`: The Dialpad call identifier.
   - `Dialpad__Linked_Task_ID__c`: The Salesforce Task record ID.
2. The `DialpadCallLogTrigger` fires and calls `DialpadTranscriptService.processTranscript`.
3. The service makes an HTTP GET callout to `https://dialpad.com/api/v2/transcripts/{callId}`.
4. On success, the transcript is appended (with a delimiter) to the Task’s `Description` field.
5. On failure, the `TranscriptRetryQueueable` retries the process, and errors are logged via `ErrorLogHandler`.

## Maintenance
Monitor the `Dialpad_Error_Log__c` object to review any callout or update failures.
