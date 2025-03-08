import { LightningElement, wire } from 'lwc';
import getTermsContent from '@salesforce/apex/TermsAndConditionsService.getTermsContent';

export default class TermsAndConditions extends LightningElement {
    termsContent;

    @wire(getTermsContent)
    wiredContent({ error, data }) {
        if (data) {
            const container = this.template.querySelector('div');
            if (container) {
                container.innerHTML = data; // Inject the HTML content dynamically
            }
            this.termsContent = data;
        } else if (error) {
            console.error('Error fetching Terms and Conditions:', error);
        }
    }
}
