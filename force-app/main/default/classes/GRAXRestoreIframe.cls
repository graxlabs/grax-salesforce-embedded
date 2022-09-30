/**
 * @description       : 
 * @author            : product@grax.com
 * @group             : 
 * @last modified on  : 09-30-2022
 * @last modified by  : product@grax.com
 * Modifications Log
 * Ver   Date         Author             Modification
 * 1.0   09-30-2022   product@grax.com   Initial Version
**/
public with sharing class GRAXRestoreIframe {
    public String iFrameSrc {get;set;}
    public String appUrl {get;set;}
    public GRAXRestoreIframe(ApexPages.standardController std) {
        GRAXEmbedSettings settings = new GRAXEmbedSettings();
        iFrameSrc = settings.appURL + '/web/restore/record/Account/' + ApexPages.currentPage().getParameters().get('id') + '?autologin=true&embedded=true';
        appUrl = settings.appURL;
    }
}
