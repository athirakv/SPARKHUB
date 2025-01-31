import { LightningElement, track, wire } from 'lwc';
import getAvailableConfigs from '@salesforce/apex/CaseConfigController.getAvailableConfigs';
import addConfigsToCase from '@salesforce/apex/CaseConfigController.addConfigsToCase';

export default class AvailableConfigs extends LightningElement {
    @track availableConfigs;
    selectedConfigs = [];

    columns = [
        { label: 'Label', fieldName: 'Label__c', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Amount', fieldName: 'Amount__c', type: 'number' }
    ];

    @wire(getAvailableConfigs)
    wiredConfigs({ error, data }) {
        if (data) {
            alert(data);
            alert('data');
            console.log(data);

            this.availableConfigs = data;
        } else if (error) {
            console.error(error);
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedConfigs = selectedRows;
    }

    addSelectedConfigs() {
        
        addConfigsToCase({ selectedConfigs: this.selectedConfigs, caseId: this.recordId })
            .then(() => {
                
            })
            .catch(error => {
                console.error(error);
            });
        }
    }