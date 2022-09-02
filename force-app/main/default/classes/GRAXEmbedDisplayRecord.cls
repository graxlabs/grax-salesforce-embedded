public with sharing class GRAXEmbedDisplayRecord {
    
    public Type dateTimeType { get; set; } 
    public GRAXEmbedSettings graxSettings  { get; set; } 
    public Map<String, String> prefixObjectMap { get; set; } 
    public String Sf{get;set;}
    public String Selectedobject { get; set; }  
    public String salesforceId  { get; set; }  
    public Map<String, Object> objectData { get; set; }   
    public String jsondata { get; set; } 
    public Map<String, String> fields { get; set; } 
    public List<Object> results { get; set; } 
    public string resultsJSON { get; set;}
    public List<Object> cases { get; set;}

    public Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> fieldDefinitions { get; set; } 
    public Map<String, Map<String,Object>> childObjects  { get; set; }
    public Map<String, Map<String, Map<String,GRAXEmbedSFMetaHelper.GRAXFieldDefinition>>> childObjectsFieldDef  { get; set; }

    public List<Object> primaryChildren { get; set; }   
    public Map<String,String> primaryChildrenMap { get; set; }  

    public string selectedform { get; set;}
    public string userId { get; set;}

    public GRAXEmbedDisplayRecord() {
        //https://grax-salesforce-embedded.us-east-2.jgaskagraxcom.dev.graxaws.com/web/objects/Account/records/0018V00002Q6mbSQAR/latest
        graxSettings = new GRAXEmbedSettings();
        this.setDefaults();
        this.getGRAXData();
        dateTimeType = Datetime.class;
        selectedform = 'client';
    }
  
    public List<SelectOption> getSelectedobjnames()
    {
        List<Schema.SObjectType> obj = Schema.getGlobalDescribe().Values();
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('--Select Object--','--Select Object--'));
        for(Schema.SObjectType st : obj)
        {
            if(Selectedobject == null || Selectedobject=='' )
            {       
                Selectedobject = st.getDescribe().getName();
            }
            options.add(new SelectOption(st.getDescribe().getName(),st.getDescribe().getName()));
        }
        return options;
    }
       
    public List<SelectOption> getSelectedobjFields()
    {
        SObjectType objTyp = Schema.getGlobalDescribe().get(Selectedobject);
        DescribeSObjectResult objDef = objTyp.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap();

        Set<String> fieldSet = fields.keySet();
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('--Select Object--','--Select Object--'));
        for(String s:fieldSet)
        {  
            SObjectField Sobjfields = fields.get(s);
            DescribeFieldResult selectedField = Sobjfields.getDescribe();                 
            options.add(new SelectOption(selectedField.getName(),selectedField.getName()));
        }
        return options;
    }

    public String getFieldValue(String fieldName){
        String returnValue = '';
        if (this.objectData.get(fieldName)!=null){
            returnValue = this.objectData.get(fieldName).toString();
        }
        return returnValue;
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
                System.debug('GRAX_DEBUG: Name Field: ' + fieldName + ' Field Value: ' + fieldDefMap.get(fieldName).fValue);
            }
        }
        return fieldDefMap;
    }

    public void setDefaults(){
        salesforceId = ApexPages.currentPage().getParameters().get('id');
        prefixObjectMap = GRAXEmbedSFMetaHelper.getPrefixToObjectMap();
        if (salesforceId=='' || salesforceId==null){
            Selectedobject = 'Account';
            String Query = 'SELECT Id FROM ' + Selectedobject + ' ORDER BY SystemModStamp DESC LIMIT 1';
            List<sObject> sobjList = Database.query(Query);
            salesforceId = sobjList[0].Id;
        }else{
            Selectedobject = prefixObjectMap.get(salesforceId.left(3));
        }
    }

    public PageReference getGRAXData() {
        GRAXEmbedAPIAccess apiAccess = new GRAXEmbedAPIAccess();
        if (salesforceId != ''){
            childObjects = new Map<String, Map<String,Object>>();
            jsondata = apiAccess.loadData(Selectedobject, salesforceId);
            fieldDefinitions = GRAXEmbedSFMetaHelper.getFieldTypes(Selectedobject);
            Integer counter = 0;
            results = (List<Object>) JSON.deserializeUntyped(jsondata);
            resultsJSON = JSON.serialize(results);
            for (Object obj: results) {
                Map<String, Object> a = (Map<String, Object>)obj;
                if (counter==0){
                    objectData = (Map<String, Object>)a.get('fields');
                    primaryChildren = (List<Object>)a.get('children');
                    primaryChildrenMap = new Map<String,String>();
                    for(Object o : primaryChildren){
                        Map<String, Object> fv = (Map<String, Object>)o;
                        primaryChildrenMap.put(fv.get('id').toString(), fv.get('object').toString());
                    }
                    fieldDefinitions = this.mergeValues(fieldDefinitions,objectData);
                } else {
                    Map<String, Object> childData = (Map<String, Object>)a.get('fields');
                    String id = childData.get('Id').toString();
                    // System.debug('GRAX_DEBUG: ' + JSON.serialize(childData));
                    if (primaryChildrenMap.get(id)!=null){
                        if (childObjects.keySet()!= null){
                            // System.debug('GRAX_DEBUG: Id: ' + id + ' Type: ' + primaryChildrenMap.get(id) + ' Contains Key: ' + childObjects.keySet().contains(primaryChildrenMap.get(id)));
                            if (!childObjects.keySet().contains(primaryChildrenMap.get(id))){
                                childObjects.put(primaryChildrenMap.get(id), new Map<String,Object>());
                            }
                        }else{
                            childObjects.put(primaryChildrenMap.get(id), new Map<String,Object>());
                        }
                        childObjects.get(primaryChildrenMap.get(id)).put(id,childData);
                    }
                }
                counter++;
            }
            this.mergeChildRecords();
            // System.debug('GRAX_DEBUG: response : ' + jsondata);
            // System.debug('GRAX_DEBUG: fields : ' + fields);
        } else {
            objectData = null;
        }
        return null;
    } 

    private void mergeChildRecords(){
        childObjectsFieldDef = new Map<String, Map<String, Map<String,GRAXEmbedSFMetaHelper.GRAXFieldDefinition>>>();
        for(String objectName : childObjects.keySet()){
            Map<String,Map<String,GRAXEmbedSFMetaHelper.GRAXFieldDefinition>> objectRecordList = new Map<String, Map<String,GRAXEmbedSFMetaHelper.GRAXFieldDefinition>>();
            for(String Id : childObjects.get(objectName).keySet()){
                Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> currentFieldDefinition = GRAXEmbedSFMetaHelper.getFieldTypes(objectName);
                Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> recordValues = mergeValues(currentFieldDefinition, (Map<String, Object>)childObjects.get(objectName).get(Id));
                objectRecordList.put(Id, recordValues);
                System.debug('GRAX_DEBUG: ' + objectName + ' ' + Id + ' Name: ' + recordValues.get('Name').fValue + ' Test: ' + objectRecordList.get(Id).get('Name').fValue);
            }
            childObjectsFieldDef.put(objectName, objectRecordList);
        }
    }


}
