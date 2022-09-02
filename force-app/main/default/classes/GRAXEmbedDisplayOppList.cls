public with sharing class GRAXEmbedDisplayOppList {
    
    public GRAXEmbedUIHelper graxUIHelper { get; set; }
    public Integer numberofRecords  { get; set; }
    public GRAXEmbedDisplayOppList(ApexPages.standardController std) {
        // Only return Opportunity records
        graxUIHelper = new GRAXEmbedUIHelper('Opportunity');
        numberofRecords = graxUIHelper.childObjectsFieldDef.get('Opportunity').size();
        //childObject
    }
}
