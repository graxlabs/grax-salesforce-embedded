global virtual with sharing class GRAXEmbedAPIAccess {
    private Integer refreshedTokenValidFor = 0;
    private Boolean isTokenRefreshed = false;
    private Long responseTimeMS;
    private String responseJSON;
    private String refreshedToken;
    private Boolean useSessionToCheckPermissions = true;
	private GRAXEmbedSettings gx = new GRAXEmbedSettings();
	private String externalAPIEndpointStatic;

    public String loadData(String objName, String recordId, String ChildObject){
        return loadData(objName, recordId, ChildObject, null);
    }

    public String loadData(String objName, String recordId, String ChildObject, String deleteSource){
        String returnValue = '';
        String responseBody = '';
		String fullAPIPath = gx.AppURL + '/app/objects/' + objName + '/records/' + recordId + '/latest/graph?includeFields=true&level=1';
        if (ChildObject!=null && ChildObject!=''){
            fullAPIPath += '&childObject=' + ChildObject;
        }

        if (deleteSource!=null){
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