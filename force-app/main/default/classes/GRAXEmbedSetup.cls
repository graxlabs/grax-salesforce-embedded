public with sharing class GRAXEmbedSetup {
    public String selectedGraxAppURL {get;set;}
    public String iFrameSrc {get;set;}
    public Boolean hasConfigurationAdminPermission {get; set;}
    public GRAXEmbedSetup() {
        hasConfigurationAdminPermission = false;
        GRAXEmbedSettings settings = new GRAXEmbedSettings();
        if (settings.IsConfigured()){
            this.hasConfigurationAdminPermission = settings.IsAdminUser();
            iFrameSrc = settings.AppURL + '/web?autologin=true';
            iFrameSrc = 'https://documentation.grax.io/docs';
            selectedGraxAppURL = settings.AppURL;
        }  
    }   
}

