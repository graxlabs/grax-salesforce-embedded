public virtual with sharing class GRAXEmbedSettings {
    public GRAXEmbedConfiguration__c gxs {get; set;}
    public String ApiURL {get; set;}
    public String WebURL {get; set;}

    public GRAXEmbedSettings(){
		this.gxs = GRAXEmbedConfiguration__c.getOrgDefaults();
        if (this.gxs.GRAXApiUrl__c!=''){
            this.ApiURL = this.gxs.GRAXApiUrl__c + '/graxproxy/api';
            this.WebURL = this.gxs.GRAXApiUrl__c + '/web';
        }
    }
}