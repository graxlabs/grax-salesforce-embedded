/**
 * Helper Class for UI page simply calling GRAXEmbedUIHelper
*/
public with sharing class GRAXEmbedDisplayOppList {

    public String urlBase { get; private set; }

    public String objectName { get; private set; }
    public Integer recordCount { get; private set; }
    public Map<String, Map<String, GRAXEmbedSFMetaHelper.GRAXFieldDefinition>> recordData { get; private set; }
    
    public GRAXEmbedDisplayOppList(ApexPages.standardController std) {
        this.urlBase = GRAXEmbedUIHelper.webappURL();

        // Get the id of the parent record from the page containing the list.
        String parentID = std.getRecord().Id;

        // A new helper instance, linked to the parent record, to be reused for each API call.
        GRAXEmbedUIHelper helper = new GRAXEmbedUIHelper(parentID);

        // Control Variables for the below
        this.objectName = 'Opportunity';

        GRAXEmbedUIHelper.Filters filters = new GRAXEmbedUIHelper.Filters();
        filters.deleteSource = 'any';
        filters.replaceReferencesWithNames = new Set<String>{'AccountId'};
        filters.level = 1; // Get opportunities that are direct children of the account

        // Query for Opportunity records with any delete source. Replace the account id field with the name of the related account.
        this.recordData = helper.Populate(this.objectName, filters);
        this.recordCount = this.recordData.size();
    }
}
