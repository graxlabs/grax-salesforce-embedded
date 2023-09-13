/**
 * @description       : This will synchronize files from remote ID to another. Which ever environment GRAX is connected to it will pull data into local IDs
 * @author            : product@grax.com
 * @group             : 
 * @last modified on  : 09-13-2023
 * @last modified by  : product@grax.com
 * Modifications Log
 * Ver   Date         Author             Modification
 * 1.0   09-13-2023   product@grax.com   Initial Version
**/
public class GRAXSynchFiles extends GRAXEmbedAPIAccess{
    public class filestruct{
        public string id {get;set;}
        public string name {get;set;}
        public long size {get;set;}
        public string url {get;set;}
        public string apiURL {get;set;}
        public string viewURL {get;set;}
        public Blob fileContents {get;set;}
        public Id NewContentDocumentId {get;set;}
    }
    public string filelistRaw {get;set;}
    public List<filestruct> fileList {get;set;}

    public id localparentid {get;set;}
    public id remoteparentid {get;set;}
    public String objectname {get;set;}
    
    public GRAXSynchFiles(String objectname, id remoteparentid,id localparentid) {
        this.objectname = objectname;
        this.localparentid = localparentid;
        this.remoteparentid = remoteparentid;
    }

    public List<filestruct> SynchNow(){
        if (Schema.sObjectType.ContentDocumentLink.isCreateable() && Schema.sObjectType.ContentVersion.isCreateable()){
            this.fileList = getFileList(this.objectname,this.remoteparentid);
            this.fileList = synchFiles(this.localparentid,fileList);
        }
        return this.fileList;
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
            fileList.add(fileEntry);
            GRAXEmbedSettings.debugInfo('File Name: ' + fileEntry.name + ' Url: ' + fileEntry.url + ' Size: ' + fileEntry.size);
        }
        return fileList;
    }

    private List<filestruct> synchFiles(id localparentid, List<filestruct> filesToProcess){
        List<ContentVersion> cvs = new List<ContentVersion>();
        for (filestruct fileEntry: filesToProcess) {
            Blob fileData = loadFile(fileEntry.apiURL);
            ContentVersion newFile = new ContentVersion();
            newFile.PathOnClient = fileEntry.name;
            newFile.Title = fileEntry.name;
            newFile.VersionData = fileData;
            GRAXEmbedSettings.debugInfo('Version Data Size: ' + newFile.VersionData.size());
            cvs.add(newFile);
        }
        if (cvs.size() > 0){
            integer counter = 0;
            List<Id> cdlist = new List<Id>();
            Database.SaveResult[] srList = Database.insert(cvs);
            for (Database.SaveResult sr : srList){
                cdlist.add(sr.getId());
                filesToProcess[counter].NewContentDocumentId=sr.getId();
                counter++;
            }
            ContentVersion[] insertedFiles = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cdlist];
            List<ContentDocumentLink> cdvList = new List<ContentDocumentLink>();
            for (ContentVersion cdv : insertedFiles){
                cdvList.add(new ContentDocumentLink(LinkedEntityId=localparentid, ContentDocumentId=cdv.ContentDocumentId));
            }
            insert cdvList;
        }
        return filesToProcess;
    }
}