/**
 * Helper Class for UI page simply calling GRAXEmbedUIHelper
*/
public with sharing class GRAXEmbedDisplayRecord {
    public String urlBase { get; private set; }

    public String parentObjectName { get; private set; }
    public Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition> parentRecordData { get; private set; }

    public Map<String, Map<String, Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition>>> childrenData { get; private set; }

    public GRAXEmbedDisplayRecord() {
        this.urlBase = GRAXEmbedUIHelper.webappURL();
        // initialize presentation data to avoid nulls
        this.parentRecordData = new Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition>();
        this.childrenData = new Map<String, Map<String, Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition>>>();

        // Get query parameters
        String parentRecordID = ApexPages.currentPage().getParameters().get('id');
        this.parentObjectName = Id.valueOf(parentRecordID).getSobjectType().getDescribe().getName();

        // A new helper instance, linked to the parent record, to be reused for each API call.
        GRAXEmbedUIHelper helper = new GRAXEmbedUIHelper(parentRecordID);

        // Control Variables for the below
        GRAXEmbedUIHelper.Filters filters = new GRAXEmbedUIHelper.Filters();
        filters.level = 0; // Get the parent record itself

        // Query for parent record fields with any delete source.
        Map<String, Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition>> parentRecords = helper.Populate(this.parentObjectName, filters);
        this.parentRecordData = parentRecords.get(parentRecordID);

        // Load the child records data
        Set<String> childObjects = helper.ListChildObjects(1);
        for (String childObject : childObjects) {
            GRAXEmbedUIHelper.Filters childFilter = new GRAXEmbedUIHelper.Filters();
            childFilter.level = 1;
            this.childrenData.put(childObject, helper.Populate(childObject, childFilter));
        }
    }    
}