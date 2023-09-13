/**
 * @description       : 
 * @author            : product@grax.com
 * @group             : 
 * @last modified on  : 09-13-2023
 * @last modified by  : product@grax.com
 * Modifications Log
 * Ver   Date         Author             Modification
 * 1.0   09-12-2023   product@grax.com   Initial Version
**/
public class GRAXSampleSynch extends GRAXEmbedAPIAccess{

    public string objectname{   
        get {
            if (!String.isBlank(objectname))
                return objectname;
            else {
                return 'Account';
            }
        }
        set {
            objectname=value;
        }
    }
    public string remoteobjectid {   
        get {
            if (!String.isBlank(remoteobjectid))
                return remoteobjectid;
            else {
                return '0018V00002bWhRkQAK';
            }
        }
        set {
            remoteobjectid=value;
        }
    }
    public string localobjectid {get;set;}
    public List<GRAXSynchFiles.filestruct> fileList {get;set;}
    
    public pageReference show(){
        GRAXSynchFiles synchHelper = new GRAXSynchFiles(this.objectname,this.remoteobjectid,this.localobjectid);
        fileList = synchHelper.SynchNow();
        return null;
    }
}