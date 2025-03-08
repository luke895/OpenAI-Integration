import { LightningElement, api, track } from 'lwc';
import updateUserNotes from '@salesforce/apex/UserNotesController.updateUserNotes';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UserNotes extends LightningElement {
    // recordId should be the Id of the Task Transcript record
    @api recordId;
    @track userNotes = '';

    delayTimeout;

    handleNotesChange(event) {
        this.userNotes = event.target.value;
        // Debounce the update call (wait 500ms after user stops typing)
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.saveUserNotes();
        }, 500);
    }

    saveUserNotes() {
        updateUserNotes({ taskTranscriptId: this.recordId, userNotes: this.userNotes })
            .then(() => {
                // Optionally display a toast notification
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'User notes updated',
                    variant: 'success'
                }));
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error updating user notes',
                    message: error.body.message,
                    variant: 'error'
                }));
            });
    }
}
