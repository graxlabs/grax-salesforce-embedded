Global with sharing class GRAXEmbedLWCHelper {
    public GRAXEmbedLWCHelper() {
    }

    @AuraEnabled(cacheable=true)
    public static GRAXLWCPayload loadLWCPaylod(String objectName, String fields, String objectId, Boolean enforceRowSecurity){
        GRAXLWCPayload lwcPayload = new GRAXLWCPayload(objectName, fields, objectId, enforceRowSecurity);
        return lwcPayload;
    }

    public class GRAXLWCPayload {
        @AuraEnabled
        public String apiPath {get;set;}
        public GRAXLWCPayload(String objectName, String fields, String objectId, Boolean enforceRowSecurity) {
            GRAXEmbedConfiguration__c gxs = GRAXEmbedConfiguration__c.getOrgDefaults();
            this.apiPath = gxs.GRAXApiUrl__c;
        }
    }
}