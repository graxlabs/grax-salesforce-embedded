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

    public class LoadDataOptions {
        public String childObject;
        public String deleteSource;
        public Integer level;
    }

    /**
     * Use this method to load child data that is archived, deleted, or both.
     * <p>
     *
     * @param  objName  Salesforce Object Name (ex Account)
     * @param  recordID Salesforce Object Id (ex. 0018V00002Q6mbSQAR)
     * @param  ChildObject If you only want the child object returned from the parent object (ex Opportunity)
     * @param  deleteSource salesforce, grax, any (deleted salesforce OR grax)
     * @param  level integer identifying the level children should reside in
     * @return JSON document from calling the <A href="https://apidocs.grax.io/#3711333e-e5d3-4555-8ca1-b4e6ce7141db">GRAX Graph API</a>
     */
    public String loadData(String parentObject, String recordID, LoadDataOptions options){
        String returnValue = '';
        String responseBody = '';
		String fullAPIPath = gx.AppURL + '/app/objects/' + parentObject + '/records/' + recordID + '/latest/graph?includeFields=true';
        if (!String.isEmpty(options.childObject)){
            fullAPIPath += '&childObject=' + options.childObject;
        }

        if (!String.isEmpty(options.deleteSource)){
            fullAPIPath += '&deleteSource=' + options.deleteSource;
        }

        if (options.level != null) {
            fullAPIPath += '&level=' + options.level;
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