/**
 * GRAXEmbedSetup is the default GRAX Setup page 
*/
public with sharing class GRAXEmbedSetup {
    public String selectedGraxAppURL {get;set;}
    public String iFrameSrc {get;set;}
    public Boolean hasConfigurationAdminPermission {get; set;}
    public GRAXEmbedSetup() {
        hasConfigurationAdminPermission = false;
        GRAXEmbedSettings settings = new GRAXEmbedSettings();
        if (settings.isConfigured()){
            this.hasConfigurationAdminPermission = settings.isAdminUser();
            iFrameSrc = settings.appURL + '/web?autologin=true';
            iFrameSrc = 'https://documentation.grax.io/docs';
            selectedGraxAppURL = settings.appURL;
        }  
    }   
}

