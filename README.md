# Salesforce DX Project: Case and Config Management 
User Story

As a Consultant, I want to manage "Available Configs" and "Case Configs" directly from the Case detail page to streamline the process of adding and activating configurations without leaving the Case page.

Requirements Breakdown
Objects
1. Config__c
   - Fields:
     - Label (Text, Unique)
     - Type (Text)
     - Amount (Number)

2. Case_Config__c
   - Fields:
     - Label (Text, Unique)
     - Type (Text)
     - Amount (Number)
     - Case (Lookup to Case object)
Components
1. Available Configs
   - Displays all Config__c records.
   - Allows selection of multiple records and adds them to Case_Config__c.
   - Prevents duplicate entries for the same Case.

2. Case Configs
   - Displays added Case_Config__c records for the current Case.
   - Includes a "Send" button:
     - Updates Case status to "Closed."
     - Sends a POST request with Case and Config data.
     - Handles responses from the external system.
Optional Features
- Sorting by columns.
- Pagination for large datasets (>200 records).
Tasks and Deliverables
Tasks
1. Create SFDX Project
   - Set up metadata structure.

2. Define Objects and Fields
   - Create Config__c and Case_Config__c objects.

3. Develop Apex Classes
   - Controller for LWC components.
   - Helper methods for DML and external API requests.

4. Build LWC Components
   - AvailableConfigs component.
   - CaseConfigs component.

5. Integrate UI and Backend
   - Implement SLDS for styling.
   - Ensure real-time updates.

6. Write Tests
   - Apex tests with 85%+ coverage.

7. Documentation
   - ReadMe with detailed tasks, feedback, and usage instructions.
Code
Apex Classes
ConfigController
Handles SOQL queries and DML operations for Config__c and Case_Config__c objects.

public with sharing class CaseConfigController {
    @AuraEnabled(cacheable=true)
    public static List<Config__c> getAvailableConfigs() {
        system.debug('inside');
        return [SELECT Id, Label__c, Type__c, Amount__c FROM Config__c];
        
    }

    @AuraEnabled
    public static void addConfigsToCase(List<Config__c> selectedConfigs, Id caseId) {
        List<Case_Config__c> caseConfigsToInsert = new List<Case_Config__c>();

        for (Config__c config : selectedConfigs) {
            caseConfigsToInsert.add(new Case_Config__c(
                label__c = config.Label__c,
                type__c = config.Type__c,
                amount__c = config.Amount__c,
                Case__c = caseId
            ));
        }
        
        insert caseConfigsToInsert;
    }

    @AuraEnabled
    public static void sendCaseStatus(Id caseId, List<Case_Config__c> caseConfigs) {
        
        Case caseRecord = [SELECT Id, Status FROM Case WHERE Id = :caseId LIMIT 1];
        caseRecord.Status = 'Closed';
        update caseRecord;
       List<Map<String, Object>> caseConfigList = new List<Map<String, Object>>();
        for (Case_Config__c caseConfig : caseConfigs) {
            caseConfigList.add(new Map<String, Object>{
                'label' => caseConfig.Label__c,
                'type' => caseConfig.Type__c,
                'amount' => caseConfig.Amount__c
            });
        }

        String jsonRequest = JSON.serialize(new Map<String, Object>{
            'caseId' => caseId,
            'status' => 'Closed',
            'caseConfigs' => caseConfigList
        });
      
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://requestcatcher.com/');
        request.setMethod('POST');
        request.setBody(jsonRequest);
        request.setHeader('Content-Type', 'application/json');

        HttpResponse response = http.send(request);
        if (response.getStatusCode() != 200) {
            
            throw new AuraHandledException('Error sending request: ' + response.getBody());
        }
    }
}

Testing and Deployment
### Test Cases
1. Verify that available configs are displayed.
2. Test adding configs to a Case.
3. Validate API integration and error handling.
4. Ensure 85%+ test coverage.

### Deployment
1. Use SFDX commands to deploy metadata.
   ```
   sfdx force:source:push
   ```
2. Commit code regularly using Git.

Lightning Web Components (LWC)

AvailableConfigs.html

<template>
    <lightning-card title="Available Configs">
        <template if:true={availableConfigs}>
            <lightning-datatable
                data={availableConfigs}
                columns={columns}
                key-field="id"
                onrowselection={handleRowSelection}>
            </lightning-datatable>
        </template>
        <lightning-button label="Add" onclick={addSelectedConfigs}></lightning-button>
    </lightning-card>
</template>

AvailableConfigs.js
Handles the display and selection of available configs, and enables the user to add selected configs to the current Case.

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

CaseConfigs.js
Displays the added configs for the current Case and includes a Send button to send the data to an external system.

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


![image](https://github.com/user-attachments/assets/20c2d12a-a5cf-4643-ab93-63d447e07f4a)


 

 

 

