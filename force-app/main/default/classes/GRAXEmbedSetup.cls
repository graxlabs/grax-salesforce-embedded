public with sharing class GRAXEmbedSetup {
    public String selectedGraxAppURL {get;set;}
    public String iFrameSrc {get;set;}
    public Boolean hasConfigurationAdminPermission {get; set;}
    public GRAXEmbedSetup() {
        hasConfigurationAdminPermission = false;
        GRAXEmbedConfiguration__c gxs = GRAXEmbedConfiguration__c.getOrgDefaults();
        if (gxs.GRAXApiUrl__c!=null){
            this.hasConfigurationAdminPermission = true;
            iFrameSrc = gxs.GRAXApiUrl__c + '/web?autologin=true';
            iFrameSrc = 'https://documentation.grax.io/docs';
            selectedGraxAppURL = gxs.GRAXApiUrl__c;
        }  
    }   
}

