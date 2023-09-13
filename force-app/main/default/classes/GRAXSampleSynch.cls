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

    public class filestruct{
        public string id {get;set;}
        public string name {get;set;}
        public long size {get;set;}
        public string url {get;set;}
        public string apiURL {get;set;}
        public string viewURL {get;set;}
        public Blob fileContents {get;set;}
    }

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
    public string rawData {get;set;}
    public string filelistRaw {get;set;}

    public Map<String, String> mapCDLToCD {get;set;}
    public List<Map<string, object>> resultsFileListUntyped {get;set;}
    public List<filestruct> fileList {get;set;}

    public pageReference show(){
        // mapCDLToCD = getCDLToCDMapping(this.objectname,this.remoteobjectid);
        fileList = getFileList(this.objectname,this.remoteobjectid);
        GRAXEmbedSettings.debugInfo(JSON.serialize(mapCDLToCD));
        return null;
    }

    private List<filestruct> getFileList(String objectname,String objectid){
        filelistRaw = loadFileList(objectname,objectid);
        Map<String, Object> fileResultsUntyped = (Map<String, Object>)JSON.deserializeUntyped(filelistRaw);
        List<object> fileMapList = (List<object>)fileResultsUntyped.get('files');
        fileList = new List<filestruct>();
        for (Object entry: fileMapList) {
            Map<String, Object>  record = (Map<String, Object>)entry;
            filestruct fileEntry = new filestruct(); 
            fileEntry.name = (String)record.get('name');
            fileEntry.url = (String)record.get('url');
            fileEntry.viewURL = (String)record.get('viewURL');
            fileEntry.apiURL = ((String)record.get('url')).replace('/web/','/api/v1/salesforce/fromAuth/');
            fileEntry.id = (String)record.get('id');
            fileEntry.size = (long)record.get('size');
            // fileEntry.fileContents = loadFile(fileEntry.apiURL);
            loadFile(fileEntry.apiURL);
            fileList.add(fileEntry);
            GRAXEmbedSettings.debugInfo('File Name: ' + fileEntry.name + ' Url: ' + fileEntry.url + ' Size: ' + fileEntry.size);
        }
        return fileList;
    }

    private Map<String, String> getCDLToCDMapping(String objectname,String objectid){
        LoadDataOptions loadOptions = new LoadDataOptions();
        loadOptions.childObject = 'ContentDocumentLink';
        string GRAXData = loadData(objectname,objectid,loadOptions);
        List<Object> resultsUntyped = (List<Object>)JSON.deserializeUntyped(GRAXData);
        Map<String, String> mCDLToCD = new Map<String, String>();
        // GRAXEmbedSettings.debugInfo(JSON.serialize(resultsUntyped));
        for (Object entry: resultsUntyped) {
            // https://apidocs.grax.io/#5672fdc3-496b-44c4-84c6-01deb366e750
            Map<String, Object> record = (Map<String, Object>)entry;
            Map<String, Object> recordFields = (Map<String, Object>)record.get('fields');
            // assemble the field definitions for this record
            GRAXEmbedSettings.debugInfo('Loading : ' + (String)record.get('id') + ' Id: ' + recordFields.get('ContentDocumentId'));
            // GRAXEmbedSettings.debugInfo(' Fields: ' + JSON.serializePretty(recordFields));
            mCDLToCD.put((String)record.get('id'),(String)recordFields.get('ContentDocumentId'));
        }
        return mCDLToCD;
    }


}