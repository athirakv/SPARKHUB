import { LightningElement, wire, api } from 'lwc';
import getAvailableConfigs from '@salesforce/apex/ConfigController.getAvailableConfigs';
import addConfigsToCase from '@salesforce/apex/ConfigController.addConfigsToCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AvailableConfigs extends LightningElement {
    @api recordId; // Case ID
    configs = [];
    selectedConfigIds = [];

    @wire(getAvailableConfigs)
    wiredConfigs({ error, data }) {
        if (data) {
            this.configs = data.map(config => ({ ...config, selected: false }));
        } else if (error) {
            console.error(error);
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedConfigIds = selectedRows.map(row => row.Id);
    }

    handleAddConfigs() {
        if (this.selectedConfigIds.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No configs selected.',
                    variant: 'error'
                })
            );
            return;
        }

        addConfigsToCase({ caseId: this.recordId, configIds: this.selectedConfigIds })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Configs added successfully.',
                        variant: 'success'
                    })
                );
                this.selectedConfigIds = [];
            })
            .catch(error => {
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