/**
 * Helper Class for UI page simply calling GRAXEmbedUIHelper
*/
public with sharing class GRAXEmbedDisplayOppList {
    
    public GRAXEmbedUIHelper graxUIHelper { get; set; }
    public Integer numberofRecords  { get; set; }
    public GRAXEmbedDisplayOppList(ApexPages.standardController std) {
        // Only return Opportunity records
        // Lookup Name for AccountId
        numberofRecords = 0;
        graxUIHelper = new GRAXEmbedUIHelper('Opportunity',new List<String>{'AccountId'}, ApexPages.currentPage().getParameters().get('id'), 'any');
        if (graxUIHelper.childObjectsFieldDef!=null){
            Map<String, Map<String,GRAXEmbedSFMetaHelper.GRAXFieldDefinition>> mapChildObjectVar = graxUIHelper.childObjectsFieldDef.get('Opportunity');
            if (mapChildObjectVar!=null){
                numberofRecords = mapChildObjectVar.size();
            }
        }
    }
}
