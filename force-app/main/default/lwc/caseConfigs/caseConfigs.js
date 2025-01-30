import { LightningElement, wire, api } from 'lwc';
import getCaseConfigs from '@salesforce/apex/ConfigController.getCaseConfigs';
import sendCaseData from '@salesforce/apex/ConfigController.sendCaseData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseConfigs extends LightningElement {
    @api recordId; // Case ID
    caseConfigs = [];
    isSendDisabled = false;

    @wire(getCaseConfigs, { caseId: '$recordId' })
    wiredCaseConfigs({ error, data }) {
        if (data) {
            this.caseConfigs = data;
        } else if (error) {
            console.error(error);
        }
    }

    handleSend() {
        this.isSendDisabled = true;
        sendCaseData({ caseId: this.recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Data sent successfully. Case is now closed.',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.isSendDisabled = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                console.error(error);
            });
    }
}