public virtual with sharing class GRAXEmbedSettings {
    public GRAXEmbedConfiguration__c gxs {get; set;}
    public String apiURL {get; set;}
    public String webURL {get; set;}
    public String appURL {get; set;}

    public String gatewayToken {get; set;}
    public String licenseToken {get; set;}
    public String apiToken {get; set;}

    public Map<String, Id> Permissions {get; set;}

    public GRAXEmbedSettings(){
		this.gxs = GRAXEmbedConfiguration__c.getOrgDefaults();
        if (this.gxs.GRAXApiUrl__c!=''){
            this.appURL = this.gxs.GRAXApiUrl__c;
            this.apiURL = this.gxs.GRAXApiUrl__c + '/api';
            this.webURL = this.gxs.GRAXApiUrl__c + '/web';
            this.gatewayToken = this.gxs.GatewayToken__c;
            this.licenseToken = this.gxs.LicenseToken__c;
            this.apiToken = this.gxs.ApiToken__c;
            this.permissions = GRAXEmbedSettings.getPermissionSets();
        }
    }

    public Boolean isAdminUser(){
        return this.Permissions.keySet().contains('GRAX_Console_Admin_User');
    }

    public Boolean isPowerUser(){
        return this.Permissions.keySet().contains('GRAX_Console_Power_User');
    }

    public Boolean isStandardUser(){
        return this.Permissions.keySet().contains('GRAX_Console_Standard_User');
    }

    public Boolean isConfigured(){
        return this.AppURL != null;
    }

    private static Map<String, Id> getPermissionSets(){
        Map<String, Id> perms = new Map<String, Id>();
        List<PermissionSetAssignment> assigned = [SELECT PermissionSet.Id,PermissionSet.Name FROM PermissionSetAssignment WHERE IsActive = true AND PermissionSet.Name LIKE '%GRAX%' AND AssigneeId=:UserInfo.getUserID()];
        for(PermissionSetAssignment p : assigned){
            perms.put(p.PermissionSet.Name,p.PermissionSet.Id);
        }
        GRAXEmbedSettings.DebugInfo(perms.toString());
        return perms;
    }

    private static void debugInfo(String value){
        System.debug('GRAX_DEBUG_INFO: ' + value);
    }
}