public with sharing class GRAXEmbedSFMetaHelper {

    private static Map<String, Schema.DescribeSObjectResult> objectsFullDescribe {get; set;}

    public GRAXEmbedSFMetaHelper() {

    }

    // Get object field schema types from object definition.
    public static Map<String, GRAXFieldDefinition>  getFieldTypes(String objectName){
        Map<String, GRAXFieldDefinition> returnVal = new Map<String, GRAXFieldDefinition>();
        Map<String, Schema.DescribeFieldResult> fieldTypes = GRAXEmbedUtils.getDescribeFieldsResultForObject(objectName);
        if (fieldTypes != null){
            for(String fieldName : fieldTypes.keySet()) {
                returnVal.put(
                        fieldName,
                        GRAXEmbedSFMetaHelper.GetFieldDefinition(fieldTypes.get(fieldName))
                    );
                    
                if (returnVal.get(fieldName).isNameField && returnVal.get('Name') == null){
                    returnVal.put('Name', returnVal.get(fieldName));
                    System.debug('GRAX_DEBUG: ' + returnVal.get(fieldName) + ' Value: ' + returnVal.get(fieldName).fValue);
                }
            }
        }
        return returnVal;
    } 

    // Get object prefix map to lookup type based on 3 letter prefix
    public static Map<String, String> getPrefixToObjectMap(){
        Map<String, String> returnValues = new Map<String, String>();
        Map<String,Schema.SObjectType> globalSchema = Schema.getGlobalDescribe(); 
        List<Schema.SObjectType> sobjects = globalSchema.values();
        for(Schema.SObjectType objType : sobjects) {
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            returnValues.put(objDescribe.getKeyPrefix(), objDescribe.getName());
        }
        return returnValues;
    }

    public static GRAXFieldDefinition GetFieldDefinition(Schema.DescribeFieldResult fieldResult){
        GRAXFieldDefinition cSObjField = new GRAXFieldDefinition();
        Schema.DisplayType fieldDisplayType = fieldResult.getType();
        cSObjField.relationshipName = fieldResult.getRelationshipName();
        cSObjField.isPolymorphic = fieldResult.getReferenceTo().size() > 1;
        for(Schema.SObjectType reference : fieldResult.getReferenceTo()) {
            if (cSObjField.referenceTo.length()>0)
                cSObjField.referenceTo+=',';
            cSObjField.referenceTo += reference.getDescribe().getName();
        }
        cSObjField.fLabel = fieldResult.getLabel();
        cSObjField.fName = fieldResult.getName();
        if (cSObjField.fLabel == ''){
            cSObjField.fLabel=cSObjField.fName;
        }
        cSObjField.fType = String.ValueOf(fieldDisplayType);
        cSObjField.isRequired = false;
        cSObjField.isEditable = true;
        cSObjField.isNameField = fieldResult.isNameField();
        cSObjField.isHtmlFormatted = fieldResult.isHtmlFormatted();
        return cSObjField;
    }

    public class GRAXFieldDefinition {
        @AuraEnabled
        public String fName {get;set;}
        @AuraEnabled
        public String fLabel {get;set;}
        @AuraEnabled
        public String fValue {get;set;}
        @AuraEnabled
        public Datetime fValueDatetime {get;set;}
        @AuraEnabled
        public Datetime fValueUserDatetime {get;set;}
        @AuraEnabled
        public String fType {get;set;}
        @AuraEnabled
        public String errorMsg {get;set;}
        @AuraEnabled
        public Boolean isRequired {get;set;}
        @AuraEnabled
        public Boolean isRichText {get;set;}
        @AuraEnabled
        public Boolean isEditable {get;set;}
        @AuraEnabled
        public Boolean isVisibleOnEdit {get;set;}
        @AuraEnabled
        public Boolean isPolymorphic {get;set;}
        @AuraEnabled
        public Boolean isNameField {get; set;}
        @AuraEnabled
        public Boolean isHtmlFormatted {get; set;}
        @AuraEnabled
        public String relationshipName {get;set;}
        @AuraEnabled
        public String referenceTo {get;set;}
        @AuraEnabled
        public String uiDisplayValue {get;set;}

        public GRAXFieldDefinition() {
			isRequired = false;
			isRichText = false;
			isEditable = true;
			isVisibleOnEdit = true;
			isPolymorphic = false;
			isNameField = false;
            isHtmlFormatted = false;
            referenceTo='';
		}
    }
}
