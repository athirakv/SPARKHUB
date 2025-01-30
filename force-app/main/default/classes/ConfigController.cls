public with sharing class ConfigController {
    @AuraEnabled
    public static List<Config__c> getAvailableConfigs() {
        return [SELECT Id, Label__c, Type__c, Amount__c FROM Config__c];
    }

    @AuraEnabled
    public static List<Case_Config__c> getCaseConfigs(Id caseId) {
        return [SELECT Id, Label__c, Type__c, Amount__c FROM Case_Config__c WHERE Case__c = :caseId];
    }

    @AuraEnabled
    public static void addConfigsToCase(Id caseId, List<Id> configIds) {
        List<Case_Config__c> caseConfigs = new List<Case_Config__c>();
        for (Config__c config : [SELECT Id, Label__c, Type__c, Amount__c FROM Config__c WHERE Id IN :configIds]) {
            caseConfigs.add(new Case_Config__c(
                Label__c = config.Label__c,
                Type__c = config.Type__c,
                Amount__c = config.Amount__c,
                Case__c = caseId
            ));
        }
        insert caseConfigs;
    }

    @AuraEnabled
    public static void sendCaseData(Id caseId) {
        Case c = [SELECT Id, Status FROM Case WHERE Id = :caseId];
        List<Case_Config__c> caseConfigs = getCaseConfigs(caseId);

        List<Map<String, Object>> configsData = new List<Map<String, Object>>();
        for (Case_Config__c config : caseConfigs) {
            configsData.add(new Map<String, Object>{
                'label' => config.Label__c,
                'type' => config.Type__c,
                'amount' => config.Amount__c
            });
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://<your-requestcatcher-endpoint>');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{
            'caseId' => caseId,
            'status' => 'Closed',
            'caseConfigs' => configsData
        }));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Error: ' + res.getStatus());
        }
        c.Status = 'Closed';
        update c;
    }
}