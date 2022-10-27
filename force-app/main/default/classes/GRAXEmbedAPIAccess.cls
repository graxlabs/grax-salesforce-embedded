/**
 * GRAXEmbedAPIAccess is an extensible Salesforce wrapper class to call the <A href="https://apidocs.grax.io/#3711333e-e5d3-4555-8ca1-b4e6ce7141db">GRAX Graph API</a>
*/
global virtual with sharing class GRAXEmbedAPIAccess {
    private Integer refreshedTokenValidFor = 0;
    private Boolean isTokenRefreshed = false;
    private Long responseTimeMS;
    private String responseJSON;
    private String refreshedToken;
    private Boolean useSessionToCheckPermissions = true;
	private GRAXEmbedSettings gx = new GRAXEmbedSettings();
	private String externalAPIEndpointStatic;

    /**
     * Call this method to load the parent object and/or children using the GRAX graph API. This will load ALL data in the graph for the parent.
     * <p>
     *
     * @param  objName  Salesforce Object Name (ex Account)
     * @param  recordId Salesforce Object Id (ex. 0018V00002Q6mbSQAR)
     * @param  ChildObject If you only want the child object returned from the parent object (ex Opportunity)
     * @return JSON document from calling the <A href="https://apidocs.grax.io/#3711333e-e5d3-4555-8ca1-b4e6ce7141db">GRAX Graph API</a>
     */
    public String loadData(String objName, String recordId, String ChildObject){
        return loadData(objName, recordId, ChildObject, null);
    }

    /**
     * Use this method to load child data that is archived, deleted, or both.
     * <p>
     *
     * @param  objName  Salesforce Object Name (ex Account)
     * @param  recordID Salesforce Object Id (ex. 0018V00002Q6mbSQAR)
     * @param  ChildObject If you only want the child object returned from the parent object (ex Opportunity)
     * @param  deleteSource salesforce, grax, any (deleted salesforce OR grax)
     * @return JSON document from calling the <A href="https://apidocs.grax.io/#3711333e-e5d3-4555-8ca1-b4e6ce7141db">GRAX Graph API</a>
     */

    public String loadData(String parentObject, String recordID, String childObject, String deleteSource){
        String returnValue = '';
        String responseBody = '';
		String fullAPIPath = gx.AppURL + '/app/objects/' + parentObject + '/records/' + recordID + '/latest/graph?includeFields=true&level=1';
        if (!String.isEmpty(childObject)){
            fullAPIPath += '&childObject=' + childObject;
        }

        if (!String.isEmpty(deleteSource)){
            fullAPIPath += '&deleteSource=' + deleteSource;
        }

        if (!Test.isRunningTest()){
            try{
                GRAXEmbedSettings.debugInfo('fullAPIPath:' + fullAPIPath);
                Long beforeAPICall = Datetime.now().getTime();
                HttpResponse res = this.apiCallOut('GET',fullAPIPath,'',false);
                responseTimeMS = Datetime.now().getTime() - beforeAPICall; // Milliseconds
                responseBody = res.getBody();
                // responseJSON = GRAXLWCHelper.filterRecordAccess(objName,responseBody,filterFields.split(','),enforceRowSecurity,limitFields);
                returnValue = responseBody;
                GRAXEmbedSettings.debugInfo('LoadData Finished ' + responseTimeMS + ' MS');
            } catch (Exception ex) {
                GRAXEmbedSettings.debugInfo('error calling GRAX API : '  + ex.getMessage());
                GRAXEmbedSettings.debugInfo('responseBody: ' + responseBody);
                GRAXEmbedSettings.debugInfo('fullAPIPath: ' + fullAPIPath);
            }
        }
        return returnValue;
    }

    private HttpResponse apiCallOut(String httpMethod, String endpoint, String parameters, Boolean isRetry){
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setTimeout(120000);
		req.setMethod(httpMethod);
		req.setHeader('Authorization', 'Bearer');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('licensetoken', gx.LicenseToken);
		req.setHeader('authorizationToken', gx.ApiToken);
		req.setHeader('x-api-key', gx.GatewayToken);
		req.setEndpoint(endpoint);
		if (parameters != ''){
			req.setBody(parameters);
		}
		http call = new http();
		HttpResponse res = call.send(req);
		GRAXEmbedSettings.debugInfo('Status Code: ' + res.getStatusCode());
		if (res.getStatusCode() == 500){
			GRAXEmbedSettings.debugInfo('APEX Request failed: Endpoint "' + endpoint + '" ' + res.getBody());
		}
		return res;
	}
}