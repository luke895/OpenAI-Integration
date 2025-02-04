import { LightningElement, api, track, wire } from 'lwc';
import getTaskSoftware from '@salesforce/apex/TaskSoftwareController.getTaskSoftware';
import updateSoftwareDiscussedField from '@salesforce/apex/TaskSoftwareController.updateSoftwareDiscussedField';
import { subscribe, MessageContext } from 'lightning/messageService';
import REFRESH_CHANNEL from '@salesforce/messageChannel/MyRefreshChips__c';

export default class MultiSelectChips extends LightningElement {
    @api recordId;
    @track options = [];
    @track newSoftware = '';
    subscription;

    // Default chip values (the complete set that should always be displayed)
    defaultValues = [
        'Revit',
        'AutoCAD',
        'Fusion 360',
        '3ds Max',
        'BlueBeam',
        'Microsoft',
        'Adobe Photoshop'
    ];

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.loadSoftware();
        this.subscribeToRefresh();
    }

    subscribeToRefresh() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, REFRESH_CHANNEL, (message) => {
                if (message && message.recordId === this.recordId) {
                    console.log('Received refresh message for record:', this.recordId);
                    // If the message includes toggledChips, update immediately;
                    // otherwise, reload the saved state.
                    if (message.toggledChips && Array.isArray(message.toggledChips)) {
                        this.updateOptionsWithToggledChips(message.toggledChips);
                    } else {
                        this.loadSoftware();
                    }
                }
            });
        }
    }

    // loadSoftware() retrieves the saved field value and builds the options array
    // as the union of the default values and any saved values.
    // Each chip is marked as selected if it is present in the saved values.
    loadSoftware() {
        if (this.recordId) {
            getTaskSoftware({ taskId: this.recordId })
                .then(result => {
                    let savedValues = [];
                    if (result && result.trim() !== '') {
                        savedValues = result.split(';').map(s => s.trim()).filter(s => s !== '');
                        savedValues = Array.from(new Set(savedValues));
                    }
                    // Combine defaultValues and savedValues (union)
                    // This ensures all default chips are displayed, plus any extra that were saved.
                    const unionValues = Array.from(new Set([...this.defaultValues, ...savedValues]));

                    // Build the options array:
                    // Mark each chip as selected if its value is in savedValues.
                    this.options = unionValues.map(val => ({
                        label: val,
                        value: val,
                        selected: savedValues.includes(val),
                        class: savedValues.includes(val) ? 'chip selected' : 'chip'
                    }));
                    console.log('Loaded chip options:', this.options);
                })
                .catch(error => {
                    console.error('Error retrieving task software:', error);
                    // On error, just use the default values, all unselected.
                    this.options = this.defaultValues.map(val => ({
                        label: val,
                        value: val,
                        selected: false,
                        class: 'chip'
                    }));
                });
        }
    }

    // This method is called when a refresh message comes from the AnalyzeComments component.
    // The payload contains toggledChips (an array of chip values that should be selected).
    updateOptionsWithToggledChips(toggledChips) {
        // Build the union of default values and the toggled ones
        const unionValues = Array.from(new Set([...this.defaultValues, ...toggledChips]));
        this.options = unionValues.map(val => ({
            label: val,
            value: val,
            // Mark as selected if it is in toggledChips
            selected: toggledChips.includes(val),
            class: toggledChips.includes(val) ? 'chip selected' : 'chip'
        }));
        console.log('Updated chip options from toggledChips:', this.options);
        // After updating the UI, update the Salesforce field.
        this.updateFieldAndRefresh();
    }

    handleChipClick(event) {
        const clickedValue = event.target.dataset.value;
        this.options = this.options.map(option => {
            if (option.value === clickedValue) {
                return { 
                    ...option, 
                    // Toggle the selected state
                    selected: !option.selected, 
                    class: !option.selected ? 'chip selected' : 'chip'
                };
            }
            return option;
        });
        this.updateFieldAndRefresh();
    }

    handleInputChange(event) {
        this.newSoftware = event.target.value;
    }

    handleKeyDown(event) {
        if (event.key === 'Enter') {
            this.addCustomChip();
        }
    }

    // When a new chip is added via the input, it is appended to the options list
    // and is initially unselected.
    addCustomChip() {
        const software = this.newSoftware.trim();
        if (software && !this.options.some(option => option.value.toLowerCase() === software.toLowerCase())) {
            this.options.push({
                label: software,
                value: software,
                selected: false,
                class: 'chip'
            });
            this.updateFieldAndRefresh();
        }
        this.newSoftware = '';
    }

    // updateFieldAndRefresh() updates the Salesforce field based on the currently selected chips.
    updateFieldAndRefresh() {
        const selectedValues = this.options
            .filter(option => option.selected)
            .map(option => option.value)
            .join(';');
        updateSoftwareDiscussedField({ taskId: this.recordId, softwareDiscussed: selectedValues })
            .then(() => {
                console.log('Task updated successfully via manual toggle.');
            })
            .catch(error => {
                console.error('Error updating task after toggle:', JSON.stringify(error));
            });
    }
}
