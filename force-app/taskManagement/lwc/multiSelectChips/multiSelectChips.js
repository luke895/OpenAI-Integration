import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import SOFTWARE_FIELD from '@salesforce/schema/Task.Software_Discussed__c';

export default class MultiSelectChips extends LightningElement {
    @api recordId; // The ID of the Task record
    @track options = [
        { label: 'AutoCAD', value: 'AutoCAD', selected: false, class: 'chip' },
        { label: 'Revit', value: 'Revit', selected: false, class: 'chip' },
        { label: 'Fusion 360', value: 'Fusion 360', selected: false, class: 'chip' },
        { label: '3ds Max', value: '3ds Max', selected: false, class: 'chip' }
    ];
    @track newSoftware = ''; // Stores the custom input value

    // Fetch the existing value from the Salesforce record
    @wire(getRecord, { recordId: '$recordId', fields: [SOFTWARE_FIELD] })
    wiredRecord({ data }) {
        if (data) {
            const selectedValues = data.fields.Software_Discussed__c.value || '';
            this.options = this.options.map(option => ({
                ...option,
                selected: selectedValues.includes(option.value),
                class: selectedValues.includes(option.value) ? 'chip selected' : 'chip'
            }));
        }
    }

    // Toggle chip selection
    handleChipClick(event) {
        const clickedValue = event.target.dataset.value;

        this.options = this.options.map(option => {
            if (option.value === clickedValue) {
                const isSelected = !option.selected;
                return {
                    ...option,
                    selected: isSelected,
                    class: isSelected ? 'chip selected' : 'chip'
                };
            }
            return option;
        });

        this.updateSalesforceField();
    }

    // Handle input changes for the custom software
    handleInputChange(event) {
        this.newSoftware = event.target.value;
    }

    // Handle the "Enter" keypress
    handleKeyDown(event) {
        if (event.key === 'Enter' && this.newSoftware.trim()) {
            this.addCustomSoftware();
        }
    }

    // Add a new custom software as a pill
    addCustomSoftware() {
        // Prevent duplicates
        const existing = this.options.find(
            option => option.value.toLowerCase() === this.newSoftware.toLowerCase()
        );

        if (!existing) {
            const newOption = {
                label: this.newSoftware,
                value: this.newSoftware,
                selected: true,
                class: 'chip selected'
            };
            this.options = [...this.options, newOption];
        }

        this.newSoftware = ''; // Clear the input
        this.updateSalesforceField();
    }

    // Update the Salesforce field with selected values
    updateSalesforceField() {
        const selectedValues = this.options
            .filter(option => option.selected)
            .map(option => option.value)
            .join(';');

        const fields = { Id: this.recordId, [SOFTWARE_FIELD.fieldApiName]: selectedValues };
        updateRecord({ fields })
            .then(() => console.log('Record updated successfully'))
            .catch(error => console.error('Error updating record:', error));
    }
}
