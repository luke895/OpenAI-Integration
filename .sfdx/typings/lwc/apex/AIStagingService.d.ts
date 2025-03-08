declare module "@salesforce/apex/AIStagingService.approveRecord" {
  export default function approveRecord(param: {recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/AIStagingService.rejectRecord" {
  export default function rejectRecord(param: {recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/AIStagingService.getAIStagingRecordsByTask" {
  export default function getAIStagingRecordsByTask(param: {taskId: any}): Promise<any>;
}
declare module "@salesforce/apex/AIStagingService.getAIStagingRecords" {
  export default function getAIStagingRecords(): Promise<any>;
}
declare module "@salesforce/apex/AIStagingService.sendToAIStaging" {
  export default function sendToAIStaging(param: {taskId: any, extractedAssets: any}): Promise<any>;
}
