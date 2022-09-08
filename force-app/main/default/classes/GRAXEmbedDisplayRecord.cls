/**
 * Helper Class for UI page simply calling GRAXEmbedUIHelper
*/
public with sharing class GRAXEmbedDisplayRecord {
    public GRAXEmbedUIHelper graxUIHelper { get; set; }
    public GRAXEmbedDisplayRecord() {
        graxUIHelper = new GRAXEmbedUIHelper(null);
    }    
}
