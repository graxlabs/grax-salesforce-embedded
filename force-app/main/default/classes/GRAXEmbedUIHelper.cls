/**
 * GRAXEmbedUIHelper is the main class for rendering data from GRAX that is merged with Salesforce Metadata Field definitions. Please see sample usage in existing UI samples.
*/
public with sharing class GRAXEmbedUIHelper {
    // internal
    private static GRAXEmbedSettings settings = new GRAXEmbedSettings();
    private static Map<String, String> objectPrefixMap = GRAXEmbedSFMetaHelper.getPrefixToObjectMap();


    public Map<String, Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition>> recordFieldDefs { get; private set; }
    // parent object info
    public String parentObjectName { get; private set; }
    public String parentRecordID { get; private set; }

    // Pass in delete source if you only want to display Deleted=salesforce or Archived=grax 
    public GRAXEmbedUIHelper(String parentID, String parentObjectName) {
        if (String.isEmpty(parentID)) {
            throw new IllegalArgumentException('parent record ID cannot be null in GRAXEmbedUIHelper');
        }
        this.parentRecordID = parentID;

        if (String.isEmpty(parentObjectName)) {
            throw new IllegalArgumentException('parent object name cannot be null in GRAXEmbedUIHelper');
        }
        this.parentObjectName = parentObjectName;
    }

    public class PopulateFilters {
        public String deleteSource { get; set; }
        // TODO: public Set<String> fieldNames { get; set; }
        public Set<String> replaceReferencesWithNames { get; set; }
    }

    public Map<String, Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition>> Populate(String childObject, PopulateFilters filters) {
        // childObject is a required filter
        if (String.isEmpty(childObject)) {
            throw new IllegalArgumentException('child object name cannot be null in Populate');
        }
        
        // Map of record ids to a map of field names to field definitions
        Map<String, Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition>> recordFieldDefsTemp = new Map<String, Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition>>();

        // Field definitions for this base object
        Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> objectFieldDefs = GRAXEmbedSFMetaHelper.getFieldTypes(childObject);

        // load data from the api
        GRAXEmbedAPIAccess apiAccess = new GRAXEmbedAPIAccess();
        String response = apiAccess.loadData(this.parentObjectName, this.parentRecordID, childObject, filters.deleteSource);
        List<Object> results = (List<Object>)JSON.deserializeUntyped(response);
        for (Object entry: results) {
            // https://apidocs.grax.io/#5672fdc3-496b-44c4-84c6-01deb366e750
            Map<String, Object> record = (Map<String, Object>)entry;
            Map<String, Object> recordFields = (Map<String, Object>)record.get('fields');
            // assemble the field definitions for this record
            recordFieldDefsTemp.put((String)record.get('id'), mergeValues(objectFieldDefs, recordFields));
        }

        // replace all chosen reference fields with the name of related record
        // this will break if the record referred to by a field is deleted from salesforce
        for (String fieldName : filters.replaceReferencesWithNames) {
            // Track the referenced object for use in query
            String referencedObject = '';
            // Assemble a list of all referenced records
            Set<String> relatedRecordIDs = new Set<String>();
            for (String recordID : recordFieldDefsTemp.keySet()) {
                // This first get is protected by being in a keySet loop
                GRAXEmbedSFMetaHelper.GRAXFieldDefinition fieldDef = recordFieldDefsTemp.get(recordID).get(fieldName);
                // if not a reference field, there is no referenced record to look for
                if (fieldDef?.referenceTo != null) {
                    // Keeping track of only a single object name may be susceptible to change in schema
                    // if an org is able to change the object referred to by a field. Older versions may contain
                    // different "referred to" objects than new ones, and that will lead to omission 
                    // of names from the table based on whichever object is "last seen" in this loop.
                    referencedObject = fieldDef.referenceTo;
                    relatedRecordIDs.add(fieldDef.fValue);
                }
            }
            // Get the names for all referenced records from salesforce
            Map<String, String> nameMap = new Map<String, String>();
            if (relatedRecordIDs.size() > 0) {
                String query = String.format('SELECT Id, Name FROM {0} WHERE Id IN :relatedRecordIDs', new List<String>{referencedObject});
                GRAXEmbedSettings.debugInfo('query: '+ fieldName);
                List<sObject> sobjList = Database.query(query);
                for (sObject obj : sobjList) {
                    nameMap.put(obj.Id, (String)obj.get('Name'));
                }
            }
            // Overwrite the labels for all impacted fields
            for (String recordID : recordFieldDefsTemp.keySet()) {
                // This first get is protected by being in a keySet loop
                GRAXEmbedSFMetaHelper.GRAXFieldDefinition fieldDef = recordFieldDefsTemp.get(recordID).get(fieldName);
                // if not a reference field, there is no referenced record to look for
                if (fieldDef?.referenceTo != null) {
                    fieldDef.uiDisplayValue = nameMap.get(fieldDef.fValue);
                    recordFieldDefsTemp.get(recordID).put(fieldName, fieldDef);
                }
            }
        }

        // after all processing and decoration, update the actual record property to prevent blips/stutters
        return recordFieldDefsTemp;
    }

    public static String webappURL() {
        return settings.webURL;
    }

    private static String getRelationshipName(String fieldName){
        String queryFieldName = fieldName;
        if (fieldName.endsWith('Id'))
            queryFieldName = queryFieldName.left(queryFieldName.length()-2);
        else if (fieldName.endsWith('__c'))
            queryFieldName = queryFieldName.replace('__c', '__r');
        return queryFieldName;
    }

    // data in objData that do not exist in fieldDefMap cannot exist in output
    private static Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> mergeValues(Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> fieldDefMap, Map<String, Object> objData){
        // create a separate map of new definitions so that we don't modify inputs
        Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> mergedFields = new Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition>();
        for (String fieldName : fieldDefMap.keySet()) {
            GRAXEmbedSFMetaHelper.GRAXFieldDefinition def = fieldDefMap.get(fieldName);
            mergedFields.put(fieldName, new GRAXEmbedSFMetaHelper.GRAXFieldDefinition(def));
        }

        // merge field definitions into the new map created above
        String nameValue = '';
        String nameLabel = '';
        for(String fieldName : mergedFields.keySet()){
            if (objData.containsKey(fieldName)){
                mergedFields.get(fieldName).fValue = objData.get(fieldName).toString();
                if (mergedFields.get(fieldName).fType=='DATETIME'){
                    mergedFields.get(fieldName).fValueDatetime = (DateTime)JSON.deserialize('"' + mergedFields.get(fieldName).fValue + '"', DateTime.class);
                    TimeZone tz = UserInfo.getTimeZone();
                    Double offset = tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
                    mergedFields.get(fieldName).fValueUserDatetime = mergedFields.get(fieldName).fValueDatetime + offset;
                }
            } else {    
                mergedFields.get(fieldName).fValue = '';
                mergedFields.get(fieldName).fValueDatetime = null;
            }

            if (mergedFields.get(fieldName).isNameField){
                if (mergedFields.get(fieldName).fValue!=null && mergedFields.get(fieldName).fValue!=''){
                    nameValue = mergedFields.get(fieldName).fValue;
                    nameLabel = mergedFields.get(fieldName).fLabel;
                }else{
                    mergedFields.get(fieldName).fValue=nameValue;
                    mergedFields.get(fieldName).fLabel=nameLabel;
                }
            }
        }
        return mergedFields;
    }
}
