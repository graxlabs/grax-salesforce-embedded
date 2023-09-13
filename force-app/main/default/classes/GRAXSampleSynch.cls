/**
 * @description       : 
 * @author            : product@grax.com
 * @group             : 
 * @last modified on  : 09-12-2023
 * @last modified by  : product@grax.com
 * Modifications Log
 * Ver   Date         Author             Modification
 * 1.0   09-12-2023   product@grax.com   Initial Version
**/
public class GRAXSampleSynch extends GRAXEmbedAPIAccess{
    public string objectname{get;set;}
    public string objectid{get;set;}
    public string children{get;set;}
    public string GRAXData{get;set;}

    public pageReference show(){
        LoadDataOptions loadOptions = new LoadDataOptions();
        loadOptions.childObject = children;
        GRAXData = loadData(this.objectname,this.objectid,loadOptions);
        return null;
    }
}