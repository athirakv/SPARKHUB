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