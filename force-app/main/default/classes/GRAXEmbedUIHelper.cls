public with sharing class GRAXEmbedUIHelper {
    public String salesforceObject { get; set; } 
    public String salesforceId  { get; set; } 
    public GRAXEmbedSettings graxSettings  { get; set; } 

    public Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> fieldDefinitions { get; set; } 
    public Map<String, Map<String,Object>> childObjects  { get; set; }
    public Map<String, Map<String, Map<String,GRAXEmbedSFMetaHelper.GRAXFieldDefinition>>> childObjectsFieldDef  { get; set; }
    public Map<String, String> prefixObjectMap { get; set; } 
     
    public Map<String, Object> objectData { get; set; }   
    public String jsondata { get; set; } 
    public Map<String, String> fields { get; set; } 
    public List<Object> results { get; set; } 
    public string resultsJSON { get; set;}
    public List<Object> cases { get; set;}

    public GRAXEmbedUIHelper(String LimitChildObjects) {
        this(LimitChildObjects, null);
    }

    public GRAXEmbedUIHelper(String LimitChildObjects, List<String> MapNamesToIds) {
        this(LimitChildObjects, MapNamesToIds, ApexPages.currentPage().getParameters().get('id'));
    }

    public GRAXEmbedUIHelper(String LimitChildObjects, List<String> MapNamesToIds, String CurrentParentId) {
        graxSettings = new GRAXEmbedSettings();
        salesforceId = GRAXEmbedUIHelper.convertId(CurrentParentId);
        prefixObjectMap = GRAXEmbedSFMetaHelper.getPrefixToObjectMap();
        salesforceObject = GetObjectFromId(salesforceId);
        this.getGRAXData(LimitChildObjects);
        if (MapNamesToIds!=null){
            this.MapNameToIdFields(LimitChildObjects,MapNamesToIds);
        }
    }

    private static String GetRelationshipName(String fieldName){
        String QueryFieldName = fieldName;
        if (fieldName.endsWith('Id'))
            QueryFieldName = fieldName.left(fieldName.length()-2);
        else if (fieldName.endsWith('__c'))
            QueryFieldName = fieldName.replace('__c', '__r');
        return QueryFieldName;
    }

    private void MapNameToIdFields(String ChildObjectName, String[] MapNamesToIds){
        if (MapNamesToIds!=null && ChildObjectName != null){
            if (fieldDefinitions==null){
                fieldDefinitions = GRAXEmbedSFMetaHelper.getFieldTypes(ChildObjectName);
            }
            String Query = '';
            for(String fieldName : MapNamesToIds){
                if (fieldDefinitions.containsKey(fieldName)){
                    if (fieldDefinitions.get(fieldName).referenceTo!=null){
                        if (Query!='') 
                            Query += ',';
                        Query += GRAXEmbedUIHelper.GetRelationshipName(fieldName) + '.Name';
                        Query += ',' + fieldName;
                    }
                }
            }
            Set<String> IdList = childObjectsFieldDef.get(ChildObjectName).keySet();
            if (Query!=''){
                Query = 'SELECT Id, ' + Query + ' FROM ' + ChildObjectName + ' WHERE Id IN: IdList';
                //GRAXEmbedSettings.debugInfo('Child Query : ' + Query);
                //GRAXEmbedSettings.debugInfo('ID List : ' + IdList);
                List<sObject> sobjList = Database.query(Query);
                GRAXEmbedSettings.debugInfo('sobjList: ' + sobjList);
                for(sObject obj : sobjList){
                    for(String fieldName : MapNamesToIds){
                        if (fieldDefinitions.get(fieldName).referenceTo!=null){
                            childObjectsFieldDef.get(ChildObjectName).get(obj.Id).get(fieldName).uiDisplayValue = obj.getSObject(GetRelationshipName(fieldName)).get('Name').toString();
                            //GRAXEmbedSettings.debugInfo('obj : ' + obj.Id + ' Name: ' + childObjectsFieldDef.get(ChildObjectName).get(obj.Id).get(fieldName).uiDisplayValue);
                        }
                    }
                }
            }
        }
    }

    public String GetObjectFromId(String salesforceId){
        return prefixObjectMap.get(salesforceId.left(3));
    }

    public static String convertId(String idSalesforce){
        // Salesforce Classic uses 15 but GRAX requires 18
        if(idSalesforce.length() == 18){
            return idSalesforce;
        } else {
            String suffix = '';
            String idOut= '';
            String InChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345';
            for(Integer i = 0; i<3; i++){
                Integer flags = 0;
                for(Integer j = 0; j<5; j++){
                    String c = idSalesforce.substring(i*5+j, i*5+j+1);
                    if((c.compareTo('A')>=0) && (c.compareTo('Z')<=0)){
                        flags += 1 << j;
                    }
                }
                suffix = suffix + InChars.substring(flags, flags+1);
            }
            idOut = idSalesforce + suffix;
            GRAXEmbedSettings.debugInfo('Id Output 15: ' + idSalesforce);
            GRAXEmbedSettings.debugInfo('Id Output 18: ' + idOut);
            return idOut;
        }
    }

    public PageReference getGRAXData(String ChildObject) {
        GRAXEmbedAPIAccess apiAccess = new GRAXEmbedAPIAccess();
        if (salesforceId != ''){
            childObjects = new Map<String, Map<String,Object>>();
            jsondata = apiAccess.loadData(salesforceObject, salesforceId, ChildObject);
            results = (List<Object>) JSON.deserializeUntyped(jsondata);
            resultsJSON = JSON.serialize(results);
            for (Object obj: results) {
                Map<String, Object> a = (Map<String, Object>)obj;
                Map<String, Object> childData = (Map<String, Object>)a.get('fields');
                String id = childData.get('Id').toString();
                if (salesforceId == id){
                    fieldDefinitions = GRAXEmbedSFMetaHelper.getFieldTypes(GetObjectFromId(salesforceId));
                    objectData = (Map<String, Object>)a.get('fields');
                    fieldDefinitions = this.mergeValues(fieldDefinitions,objectData);
                } else {
                    if (!childObjects.keySet().contains(GetObjectFromId(id))){
                        childObjects.put(GetObjectFromId(id), new Map<String,Object>());
                    }
                    childObjects.get(GetObjectFromId(id)).put(id,childData);
                }
            }
            this.mergeChildRecords();
            // GRAXEmbedSettings.debugInfo('response : ' + jsondata);
            // GRAXEmbedSettings.debugInfo('fields : ' + fields);
        } else {
            objectData = null;
        }
        return null;
    } 

    public Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> mergeValues(Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> fieldDefMap, Map<String, Object> objData){
        String nameValue = '';
        String nameLabel = '';
        for(String fieldName : fieldDefMap.keySet()){
            if (objData.containsKey(fieldName)){
                fieldDefMap.get(fieldName).fValue = objData.get(fieldName).toString();
                if (fieldDefMap.get(fieldName).fType=='DATETIME'){
                    fieldDefMap.get(fieldName).fValueDatetime = (DateTime)JSON.deserialize('"' + fieldDefMap.get(fieldName).fValue + '"', DateTime.class);
                    TimeZone tz = UserInfo.getTimeZone();
                    Double offset = tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
                    fieldDefMap.get(fieldName).fValueUserDatetime = fieldDefMap.get(fieldName).fValueDatetime + offset;
                }
            } else {    
                fieldDefMap.get(fieldName).fValue = '';
                fieldDefMap.get(fieldName).fValueDatetime = null;
            }

            if (fieldDefMap.get(fieldName).isNameField){
                if (fieldDefMap.get(fieldName).fValue!=null && fieldDefMap.get(fieldName).fValue!=''){
                    nameValue = fieldDefMap.get(fieldName).fValue;
                    nameLabel = fieldDefMap.get(fieldName).fLabel;
                }else{
                    fieldDefMap.get(fieldName).fValue=nameValue;
                    fieldDefMap.get(fieldName).fLabel=nameLabel;
                }
                GRAXEmbedSettings.debugInfo('Name Field: ' + fieldName + ' Field Value: ' + fieldDefMap.get(fieldName).fValue);
            }
        }
        return fieldDefMap;
    }

    private void mergeChildRecords(){
        childObjectsFieldDef = new Map<String, Map<String, Map<String,GRAXEmbedSFMetaHelper.GRAXFieldDefinition>>>();
        GRAXEmbedSettings.debugInfo('keySet Size: ' + childObjects.keySet().size());
        for(String objectName : childObjects.keySet()){
            Map<String,Map<String,GRAXEmbedSFMetaHelper.GRAXFieldDefinition>> objectRecordList = new Map<String, Map<String,GRAXEmbedSFMetaHelper.GRAXFieldDefinition>>();
            for(String Id : childObjects.get(objectName).keySet()){
                Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> currentFieldDefinition = GRAXEmbedSFMetaHelper.getFieldTypes(objectName);
                Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> recordValues = mergeValues(currentFieldDefinition, (Map<String, Object>)childObjects.get(objectName).get(Id));
                objectRecordList.put(Id, recordValues);
                // GRAXEmbedSettings.debugInfo('' + objectName + ' ' + Id + ' Name: ' + recordValues.get('Name').fValue + ' Test: ' + objectRecordList.get(Id).get('Name').fValue);
            }
            childObjectsFieldDef.put(objectName, objectRecordList);
        }
    }
}
