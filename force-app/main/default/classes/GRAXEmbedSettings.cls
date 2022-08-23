public virtual with sharing class GRAXEmbedSettings {
    public GRAXEmbedConfiguration__c gxs {get; set;}
    public String ApiURL {get; set;}
    public String WebURL {get; set;}
    public String AppURL {get; set;}
    public Map<String, Id> Permissions {get; set;}

    public GRAXEmbedSettings(){
		this.gxs = GRAXEmbedConfiguration__c.getOrgDefaults();
        if (this.gxs.GRAXApiUrl__c!=''){
            this.AppURL = this.gxs.GRAXApiUrl__c;
            this.ApiURL = this.gxs.GRAXApiUrl__c + '/api';
            this.WebURL = this.gxs.GRAXApiUrl__c + '/web';
            this.Permissions = GRAXEmbedSettings.GetPermissionSets();
        }
    }

    public Boolean IsAdminUser(){
        return this.Permissions.keySet().contains('GRAX_Console_Admin_User');
    }

    public Boolean IsPowerUser(){
        return this.Permissions.keySet().contains('GRAX_Console_Power_User');
    }

    public Boolean IsStandardUser(){
        return this.Permissions.keySet().contains('GRAX_Console_Standard_User');
    }

    public Boolean IsConfigured(){
        return this.AppURL != null;
    }

    private static Map<String, Id> GetPermissionSets(){
        Map<String, Id> perms = new Map<String, Id>();
        List<PermissionSetAssignment> assigned = [SELECT PermissionSet.Id,PermissionSet.Name FROM PermissionSetAssignment WHERE IsActive = true AND PermissionSet.Name LIKE '%GRAX%' AND AssigneeId=:UserInfo.getUserID()];
        for(PermissionSetAssignment p : assigned){
            perms.put(p.PermissionSet.Name,p.PermissionSet.Id);
        }
        GRAXEmbedSettings.DebugInfo(perms.toString());
        return perms;
    }

    private static void DebugInfo(String value){
        System.debug('GRAX_DEBUG_INFO: ' + value);
    }
}