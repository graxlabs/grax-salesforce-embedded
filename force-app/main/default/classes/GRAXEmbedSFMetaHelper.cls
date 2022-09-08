/**
 * GRAXEmbedSFMetaHelper is the wrapper class for merging Salesforce Metadata with GRAX data.
*/
public with sharing class GRAXEmbedSFMetaHelper {

    private static Map<String, Schema.SObjectType> globalDescribe;
	private static Map<String, Map<String, Schema.DescribeFieldResult>> fieldsDescribeByObject;
	private static Map<String, Schema.DescribeSObjectResult> objectsFullDescribe {get; set;}

    public GRAXEmbedSFMetaHelper() {

    }

    // Get object field schema types from object definition.
    public static Map<String, GRAXFieldDefinition>  getFieldTypes(String objectName){
        Map<String, GRAXFieldDefinition> returnVal = new Map<String, GRAXFieldDefinition>();
        Map<String, Schema.DescribeFieldResult> fieldTypes = GRAXEmbedSFMetaHelper.getDescribeFieldsResultForObject(objectName);
        if (fieldTypes != null){
            for(String fieldName : fieldTypes.keySet()) {
                returnVal.put(
                        fieldName,
                        GRAXEmbedSFMetaHelper.GetFieldDefinition(fieldTypes.get(fieldName))
                    );
                    
                if (returnVal.get(fieldName).isNameField && returnVal.get('Name') == null){
                    returnVal.put('Name', returnVal.get(fieldName));
                    GRAXEmbedSettings.debugInfo('' + returnVal.get(fieldName) + ' Value: ' + returnVal.get(fieldName).fValue);
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

    public static Map<String, Schema.DescribeFieldResult> getDescribeFieldsResultForObject(String objName){
		loadObjectAndFieldsDescribe(objName);
		return fieldsDescribeByObject.get(objName);
	}

	private static void loadGlobalDescribe(){
		if(globalDescribe == null){
			globalDescribe = Schema.getGlobalDescribe();
		}
	}

	public static Boolean sObjectExists( String objName ){
		loadGlobalDescribe();

		return globalDescribe.containsKey( objName );
	}

	private static void loadObjectDescribe(String objName){
		if(objectsFullDescribe == null){
			objectsFullDescribe = new Map<String, Schema.DescribeSObjectResult>();
		}

		if(!objectsFullDescribe.containsKey(objName) && sObjectExists(objName)){
			objectsFullDescribe.put(objName, globalDescribe.get(objName).getDescribe());
		}
	}

	private static void loadObjectAndFieldsDescribe(String objName){
		if(fieldsDescribeByObject == null){
			fieldsDescribeByObject = new Map<String, Map<String, Schema.DescribeFieldResult>>();
		}

		if(!fieldsDescribeByObject.containsKey(objName) && sObjectExists(objName)){
			Schema.DescribeSObjectResult objDesc = getObjectDescribe(objName);

			Map<String, Schema.DescribeFieldResult> fieldsDescribe = new Map<String, Schema.DescribeFieldResult>();

			// Get the describe of each field of the object
			Map<String, Schema.SObjectField> objDescFieldsMap = objDesc.fields.getMap();
			for(String fieldAPIName: objDescFieldsMap.keySet()){
				Schema.DescribeFieldResult fldDescRes = objDescFieldsMap.get(fieldAPIName).getDescribe();
				fieldsDescribe.put(fldDescRes.getName(), fldDescRes);
			}
			fieldsDescribeByObject.put(objDesc.getName(), fieldsDescribe);
		}
	}

	public static Schema.DescribeSObjectResult getObjectDescribe(String objName){
		loadObjectDescribe(objName);

		return objectsFullDescribe.get(objName);
	}

	// This method does not store in the transaction cache the retrieved Object's Describe
	public static Schema.DescribeSObjectResult getObjectDescribe(String objName, Boolean clearCache){
		Schema.DescribeSObjectResult result = getObjectDescribe(objName);
		if(clearCache){
			objectsFullDescribe.remove(objName);
		}
		return result;
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
