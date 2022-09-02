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
        String returnValue = '';
        String responseBody = '';
		String fullAPIPath = gx.AppURL + '/app/objects/' + objName + '/records/' + recordId + '/latest/graph?includeFields=true&level=1';
        if (ChildObject!=null && ChildObject!=''){
            fullAPIPath += '&childObject=' + ChildObject;
        }
		system.debug('GRAX_DEBUG: fullAPIPath:' + fullAPIPath);
        if (!Test.isRunningTest()){
            try{
                Long beforeAPICall = Datetime.now().getTime();
                HttpResponse res = this.apiCallOut('GET',fullAPIPath,'',false);
                responseTimeMS = Datetime.now().getTime() - beforeAPICall; // Milliseconds
                responseBody = res.getBody();
                // responseJSON = GRAXLWCHelper.filterRecordAccess(objName,responseBody,filterFields.split(','),enforceRowSecurity,limitFields);
                returnValue = responseBody;
            } catch (Exception ex) {
                system.debug('error calling GRAX API : '  + ex.getMessage());
                system.debug('responseBody: ' + responseBody);
                system.debug('fullAPIPath: ' + fullAPIPath);
            }
        }
		system.debug('GRAX_DEBUG: LoadData Finished ' + responseTimeMS + ' MS');
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
		system.debug('GRAX_DEBUG: Status Code: ' + res.getStatusCode());
		if (res.getStatusCode() == 500){
			system.debug('APEX Request failed: Endpoint "' + endpoint + '" ' + res.getBody());
		}
		return res;
	}
}