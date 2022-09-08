/**
 * Helper method for UI page simply calling GRAXEmbedUIHelper
*/
public with sharing class GRAXEmbedDisplayOppList {
    
    public GRAXEmbedUIHelper graxUIHelper { get; set; }
    public Integer numberofRecords  { get; set; }
    public GRAXEmbedDisplayOppList(ApexPages.standardController std) {
        // Only return Opportunity records
        // Lookup Name for AccountId
        graxUIHelper = new GRAXEmbedUIHelper('Opportunity',new List<String>{'AccountId'});
        numberofRecords = graxUIHelper.childObjectsFieldDef.get('Opportunity').size();
    }
}
