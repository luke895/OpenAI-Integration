import { LightningElement, api, wire } from 'lwc';
import processComments from '@salesforce/apex/AICommentProcessor.processComments';
import updateSoftwareDiscussedField from '@salesforce/apex/TaskSoftwareController.updateSoftwareDiscussedField';
import { publish, MessageContext } from 'lightning/messageService';
import REFRESH_CHANNEL from '@salesforce/messageChannel/MyRefreshChips__c';

export default class AnalyzeComments extends LightningElement {
    @api recordId;
    
    @wire(MessageContext)
    messageContext;

    analyzeComments() {
        if (!this.recordId) {
            console.error('RecordId is not provided.');
            return;
        }
        processComments({ taskId: this.recordId })
            .then(result => {
                console.log('Process Comments Result:', result);
                // Expecting a semicolon-delimited string from Apex.
                const softwareFromComments = result
                    .split(';')
                    .map(s => s.trim())
                    .filter(s => s !== '');
                const updatedFieldValue = softwareFromComments.join(';');
                updateSoftwareDiscussedField({ taskId: this.recordId, softwareDiscussed: updatedFieldValue })
                    .then(() => {
                        console.log('Salesforce field updated successfully.');
                        // Publish a refresh message with the toggled chips array.
                        publish(this.messageContext, REFRESH_CHANNEL, {
                            recordId: this.recordId,
                            toggledChips: softwareFromComments
                        });
                    })
                    .catch(error => {
                        console.error('Error updating Salesforce field:', JSON.stringify(error));
                    });
            })
            .catch(error => {
                console.error('Error processing comments:', JSON.stringify(error));
            });
    }
}
