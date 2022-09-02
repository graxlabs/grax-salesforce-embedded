public with sharing class GRAXEmbedUtils {
    public GRAXEmbedUtils() {

    }
    static final Integer currentPackageMajorVersion = 3;
	static final Integer currentPackageMinorVersion = 22;
	public static Object encryptedStringMask = '********';

	public static Set<String> archivedObjects2QueryAllRows = new Set<String>{'Event', 'Task'};
	public static Map<String, Set<String>> objectFieldsMapToExclude = new Map<String, Set<String>>{
		'Account' => new Set<String>{'ChannelProgramName', 'ChannelProgramLevelName', 'BillingAddress', 'ShippingAddress', 'PhotoUrl', 'PersonIndividualId'},
		'Case' => new Set<String>{'Comments'},
		'Campaign' => new Set<String>{'TotalLandingPageViews'},
		'Contact' => new Set<String>{'IndividualId', 'MailingAddress', 'OtherAddress'},
		'Lead' => new Set<String>{'Address'},
		'Quote' => new Set<String>{'AdditionalAddress', 'QuoteToAddress', 'ShippingAddress'},
		'WorkOrder' => new Set<String>{'IsGeneratedFromMaintenancePlan'},
		'User' => new Set<String>{'Address'}
	};
	public static Set<String> asyncObjects2ProcessByGRAX = new Set<String>{'Attachment', 'ContentVersion', 'EventLogFile'};
	public static List<String> defaultAuditDatetimeFields = new List<String>{'SystemModstamp', 'LastModifiedDate', 'CreatedDate'};

	private static Map<String, Schema.SObjectType> globalDescribe;
	private static Map<String, Schema.DescribeSObjectResult> objectsFullDescribe {get; set;}
	private static Map<String, Map<String, Schema.DescribeFieldResult>> fieldsDescribeByObject;

	private static void loadGlobalDescribe(){
		if(globalDescribe == null){
			globalDescribe = Schema.getGlobalDescribe();
		}
	}

	private static void loadObjectDescribe(String objName){
		if(objectsFullDescribe == null){
			objectsFullDescribe = new Map<String, Schema.DescribeSObjectResult>();
		}

		if(!objectsFullDescribe.containsKey(objName) && sObjectExists(objName)){
			objectsFullDescribe.put(objName, globalDescribe.get(objName).getDescribe());
		}
	}

	private static void loadObjectAndFieldsDescribe(String objName){
		if(fieldsDescribeByObject == null){
			fieldsDescribeByObject = new Map<String, Map<String, Schema.DescribeFieldResult>>();
		}

		if(!fieldsDescribeByObject.containsKey(objName) && sObjectExists(objName)){
			Schema.DescribeSObjectResult objDesc = getObjectDescribe(objName);

			Map<String, Schema.DescribeFieldResult> fieldsDescribe = new Map<String, Schema.DescribeFieldResult>();

			// Get the describe of each field of the object
			Map<String, Schema.SObjectField> objDescFieldsMap = objDesc.fields.getMap();
			for(String fieldAPIName: objDescFieldsMap.keySet()){
				Schema.DescribeFieldResult fldDescRes = objDescFieldsMap.get(fieldAPIName).getDescribe();
				fieldsDescribe.put(fldDescRes.getName(), fldDescRes);
			}
			fieldsDescribeByObject.put(objDesc.getName(), fieldsDescribe);
		}
	}

	public static Set<String> getAllSObjectAPINames() {
		loadGlobalDescribe();

		return globalDescribe.keySet();
	}

	public static Boolean sObjectExists( String objName ){
		loadGlobalDescribe();

		return globalDescribe.containsKey( objName );
	}

	public static Schema.SObjectType getSObjectType(String objName) {
		loadGlobalDescribe();

		return globalDescribe.get(objName);
	}

	public static Schema.DescribeSObjectResult getObjectDescribe(String objName){
		loadObjectDescribe(objName);

		return objectsFullDescribe.get(objName);
	}

	// This method does not store in the transaction cache the retrieved Object's Describe
	public static Schema.DescribeSObjectResult getObjectDescribe(String objName, Boolean clearCache){
		Schema.DescribeSObjectResult result = getObjectDescribe(objName);
		if(clearCache){
			objectsFullDescribe.remove(objName);
		}
		return result;
	}

	public static Map<String, Schema.DescribeFieldResult> getDescribeFieldsResultForObject(String objName){
		loadObjectAndFieldsDescribe(objName);
		return fieldsDescribeByObject.get(objName);
	}

	public static Schema.DescribeFieldResult getFieldDescribeFromSObjectField(Schema.SObjectField sObjFld){
		return sObjFld.getDescribe();
	}

	private static Map<String, Schema.DescribeFieldResult> nameFieldDescVsObjectNameMap = new Map<String, Schema.DescribeFieldResult>();

	public static Schema.DescribeFieldResult getNameFieldDescForObject(String objName){
		if(nameFieldDescVsObjectNameMap.containsKey(objName)) {
			return nameFieldDescVsObjectNameMap.get(objName);
		}

		Schema.DescribeFieldResult result;

		if( sObjectExists(objName) ){
			// Get the Name field defined for each object
			for(Schema.DescribeFieldResult fieldDesc : getDescribeFieldsResultForObject(objName).values()){
				if(fieldDesc.isNameField()){
					result = fieldDesc;
					break;
				}
			}
		}

		nameFieldDescVsObjectNameMap.put(objName, result);

		return result;
	}

	public static String getObjectNameFromSObjectType(Schema.SObjectType sObjT){
		String objName = '';

		loadGlobalDescribe();

		for(Schema.SObjectType objSObjType : globalDescribe.values()){
			if(sObjT == objSObjType){
				objName = sObjT.getDescribe().getName();
				break;
			}
		}

		return objName;
	}

	public static SObject createObjectInstance(String objName, Id recordId, Boolean loadDefaultValues){
		SObject result = getSObjectType(objName).newSObject(recordId);

		if(loadDefaultValues){
			result = getSObjectType(objName).newSObject(recordId, true);
		}

		return result;
	}

	public static String CleanFieldLabel(Schema.DescribeFieldResult sField, Boolean escapeForVF){
		String fieldLabel = CleanFieldLabel(sField, escapeForVF, true);

		return fieldLabel;
	}

	public static String CleanFieldLabel(Schema.DescribeFieldResult sField, Boolean escapeForVF, Boolean removeIDWordFromLabel){
		String fieldLabel = sField.getLabel();

		if(removeIDWordFromLabel && !sField.isCustom() && sField.getType().name() == 'REFERENCE' && fieldLabel.endsWith(' ID')){
			fieldLabel = fieldLabel.removeEnd(' ID');
		}

		if(escapeForVF){
			fieldLabel = fieldLabel.escapeHtml4();
		}

		return fieldLabel;
	}

	public static List<String> polymorphicDefaultIncludedObjects = new List<String>{'Task', 'Event', 'Attachment', 'Note', 'ContentVersion', 'ContentDocumentLink', 'SocialPost'};
	public static List<String> polymorphicDefaultIncludedFields = new List<String>{'OwnerId', 'LastModifiedId', 'CreatedById'};
	public static Map<String, String> singleRelationshipPolymorphicFieldsByObjectName = new Map<String, String>{'SocialPost' => 'ParentId'};

	public static Boolean isPolymorphicAvailableToGetReference(String objName, Schema.DescribeFieldResult fieldDesc) {
		loadObjectAndFieldsDescribe(objName);

		if(!polymorphicDefaultIncludedObjects.contains(objName) && !polymorphicDefaultIncludedFields.contains(fieldDesc.name)) {
			return false;
		}

		return true;
	}

	public static String getReferenceField(String objName, Schema.DescribeFieldResult fieldDesc) {
		loadObjectAndFieldsDescribe(objName);

		// Check if this field is accessible for the current User
		if(fieldDesc <> null) {

			// If the current field is a reference field, get the Name field of the related object to be used in the search
			if(fieldDesc.getType().name().equalsIgnoreCase('REFERENCE')) {

				String nameField = 'Name';

				if(fieldDesc.getReferenceTo().size() == 1 && (!singleRelationshipPolymorphicFieldsByObjectName.containsKey(objName) || singleRelationshipPolymorphicFieldsByObjectName.get(objName) <> fieldDesc.getName())) {
					nameField = '';

					// Get the Name field defined for this related object
					String relObjName = getObjectNameFromSObjectType(fieldDesc.getReferenceTo()[0]);
					Schema.DescribeSObjectResult relObjDescribe = getObjectDescribe(relObjName);

					// Get the Name field of the related object
					Schema.DescribeFieldResult relNameFieldDesc = getNameFieldDescForObject(relObjName);

					if(relObjDescribe <> null && relNameFieldDesc<>null){
						nameField = relNameFieldDesc.getName();
					}
				} else if(!isPolymorphicAvailableToGetReference(objName, fieldDesc)) {
					nameField = '';
				}

				String relationName = fieldDesc.getRelationshipName();

				if(String.isNotBlank(relationName) && nameField <> '') {
					return relationName + '.' + nameField;
				}
			}

		}

		return null;
	}

	public static List<String> getReferenceFields(String objName) {
		loadObjectAndFieldsDescribe(objName);

		List<String> referenceFields = new List<String>();

		Map<String, Schema.DescribeFieldResult> fieldsDesc = fieldsDescribeByObject.get(objName);

		if(fieldsDesc == null) return referenceFields;

		for(String fieldName : fieldsDesc.keySet()) {
			Schema.DescribeFieldResult fieldDesc = fieldsDesc.get(fieldName);

			String referenceField = getReferenceField(objName, fieldDesc);

			if(referenceField <> null) {
				referenceFields.add(referenceField);
			}
		}

		return referenceFields;
	}

	public static List<String> getGraxFields(String objName) {
		List<String> graxFields = new List<String>();

		if(objName == null) return graxFields;

		for(String refField: getReferenceFields(objName)) {
			graxFields.add(getGraxFieldFromReference(refField));
		}

		return graxFields;
	}

	public static String getGraxFieldFromReference(String refField) {
		if(refField <> null) {
			return 'grax_' + String.valueOf(refField).replaceAll('\\.', '_');
		}

		return null;
	}

	public static Map<String, String> getReferenceFieldsMap(String objName) {
		Map<String,String> result = new Map<String,String>();

		if(fieldsDescribeByObject <> null && objName <> null) {
			Map<String, Schema.DescribeFieldResult> fieldsDesc = fieldsDescribeByObject.get(objName);

			for(String fieldName : fieldsDesc.keySet()) {
				Schema.DescribeFieldResult fieldDesc = fieldsDesc.get(fieldName);

				// If the current field is a reference field add it to the Map
				if(fieldDesc.getType().name().equalsIgnoreCase('REFERENCE')){
					result.put(fieldDesc.getName(), String.valueOf(fieldDesc.getReferenceTo()).replace('(','').replace(')',''));
				}
			}
		}

		return result;
	}

	public static Object parseSObjectFieldValue(SObject sobj, String refField){
		Object fieldValue;

		// Split the field by '.' and traverse the object relationship
		List<String> objFields = refField.split('\\.');
		SObject dynObj = sobj;
		for(Integer i = 0; i < objFields.size() - 1; i++){
			if(dynObj <> null){
				dynObj = dynObj.getSObject(objFields[i]);
			}
		}

		// Get the Field Name to retrieve
		String relatedObjField = objFields[objFields.size()-1];

		// Retrieve the value of the field
		if(dynObj <> null){
			fieldValue = dynObj.get(relatedObjField);
		}

		return fieldValue;
	}

	private static Integer userTimeZoneOffsetMinutes;

	// Method to calculate the running User's Time Zone Offset, in minutes
	public static Integer getUserTimeZoneOffsetMinutes(){
		if(userTimeZoneOffsetMinutes == null){
			userTimeZoneOffsetMinutes = UserInfo.getTimeZone().getOffset(System.now()) / 60000;
		}
		return userTimeZoneOffsetMinutes;
	}

	// Description: Cast the value passing by parameter to the specified Field Type.
	public static Object castGenericObjectToType(Object objValue, String fieldType, Boolean isSavingRecord, Boolean isSavingFromGrax){
		Object result = objValue;

		if(objValue <> null){
			String obj = String.valueOf(objValue);

			if(String.isBlank(obj)){
				result = null;
			}else{
				if((new Set<String>{'time', 'datetime', 'date'}).contains(fieldType.toLowerCase())){
					if(fieldType.equalsIgnoreCase('time')){
						// The assumption is that TIME values will be in this format '16:45:47.000Z'
						// Add the time portion to it, so it is treated as a Datetime
						obj = '2000-01-01T' + obj;
					}

					if( obj.length() > 19 && obj.contains('T')){
						//Bad format 2016-07-29T16:45:47.000Z . Reformat to 2016-07-29 16:45:47
						obj = obj.replace('T', ' ').subString(0, 19);
					}

					if(fieldType.equalsIgnoreCase('datetime') || fieldType.equalsIgnoreCase('time')){
						if(isSavingRecord){
							// Used when saving a record
							if(isSavingFromGrax){
								result = (Object)Datetime.valueOfGMT(obj);
							}else{
								result = (Object)Datetime.valueOf(obj);
							}
						}else{
							// Used when displaying a record
							result = (Object)(Datetime.valueOfGMT(obj).addMinutes(getUserTimeZoneOffsetMinutes()));
						}
					}else if(fieldType.equalsIgnoreCase('date')){
						//YEAR-MONTH-DAY - Used when displaying a record
						result = (Object)Date.valueOf(obj);
					}

					if(fieldType.equalsIgnoreCase('time')){
						// This value was already transformed to a Datetime, extract the Time portion of it
						result = (Object)(((Datetime)result).timeGMT());
					}
				}else if((new Set<String>{'integer', 'double', 'currency', 'long', 'percent', 'decimal'}).contains(fieldType.toLowerCase())){
					// Replace all the Thousands, and, Decimals, Separators, set based on the current running User's Locale, with the format expected by the Salesforce's Database
					obj = obj.replace(GRAXEmbedUtils.getCurrentUserThousandsSeparator(), '').replace(GRAXEmbedUtils.getCurrentUserDecimalsSeparator(), '.');

					if(fieldType.equalsIgnoreCase('integer')){
						result = (Object)Integer.valueOf(obj);
					}else if(fieldType.equalsIgnoreCase('double') || fieldType.equalsIgnoreCase('currency') || fieldType.equalsIgnoreCase('percent')){
						result = (Object)Double.valueOf(obj);
					}else if(fieldType.equalsIgnoreCase('long')){
						result = (Object)Long.valueOf(obj);
					}else if(fieldType.equalsIgnoreCase('decimal')){
						result = (Object)Decimal.valueOf(obj);
					}
				}else if(fieldType.equalsIgnoreCase('boolean')){
					result = (Object)Boolean.valueOf(obj);
				}else{
					result = obj;
				}
			}
		}

		return result;
	}

	public static Object castGenericObjectToType(Object objValue, String fieldType, Boolean isSavingRecord){
		Object result = castGenericObjectToType(objValue, fieldType, isSavingRecord, false);

		return result;
	}

	public static Boolean idExist(String sid) {
		try {
			Id recordId = Id.valueOf(sid);

			String soql = 'SELECT count() FROM ' + recordId.getSObjectType() + ' WHERE Id = :recordId';

			return Database.countQuery(soql) == 1;
		} catch (Exception e) {}

		return false;
	}

	public static Boolean isPersonAccountEnabled() {
		return getDescribeFieldsResultForObject('Account').containsKey('IsPersonAccount');
	}

	public static String getPageParameter(Pagereference page, String paramName) {
		String paramValue;

		try {
			paramValue = page.getParameters().get(paramName);
		} catch(Exception e) {}

		return paramValue;
	}

	public static String getPageParameter(String paramName) {
		return getPageParameter(Apexpages.currentPage(), paramName);
	}

	public static SObject getSObjectById(Id sId) {
		String sObjectName = getSObjectNameById(sId);

		return getSObjectById(sId, sObjectName);
	}

	public static SObject getSObjectById(Id sId, String sObjectName) {
		loadObjectAndFieldsDescribe(sObjectName);

		String sObjectFields = String.join(new List<String>(getDescribeFieldsResultForObject(sObjectName).keySet()), ', ');

		return Database.query('SELECT ' + sObjectFields + ' FROM ' + sObjectName + ' WHERE Id = :sId LIMIT 1');
	}

	public static String getSObjectNameById(Id sId) {
		return sId.getSObjectType().getDescribe().getName();
	}

	public static String getSObjectNameFromList(List<SObject> sObjects){
		String sObjectName;

		// Get the SObject Type, assuming that all the inserted records, belong to the same SObject Type
		for(SObject obj : sObjects){
			sObjectName = String.valueOf(obj.getSObjectType());
			break;
		}

		return sObjectName;
	}

	public static List<List<Object>> splitList(List<Object> listToSplit, Integer chunkMax) {
		List<List<Object>> chunks = new List<List<Object>>();

		Integer lastIndex = listToSplit.size() - 1;

		Integer ci = 0;
		List<Object> chunk = new List<Object>();
		for (Integer f = 0; f <= lastIndex; f++) {
			chunk.add(listToSplit[f]);
			ci++;

			if(ci == chunkMax || f == lastIndex) {
				chunks.add(chunk);
				chunk = new List<Object>();
				ci = 0;
			}
		}

		return chunks;
	}

	public static String generate20UniqueKey() {
		// The following line was commented out to prevent the Execution Unique Key having special characters like "/", "+", "="
		//return EncodingUtil.base64Encode(Crypto.generateAesKey(256)).right(20);
		return generateRandomString(20);
	}

	public static String generateRandomString(Integer len){
		final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
		Integer baseCharactersLength = chars.length();
		String randStr = '';
		while (randStr.length() < len){
			Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), baseCharactersLength);
			randStr += chars.substring(idx, idx+1);
		}

		return randStr;
	}

	private static String namespace;

	private static void loadNamespace() {
		if(namespace == null) {
			try {
				if(String.valueOf(GRAXEmbedUtils.class).contains('.')){
					namespace = String.valueOf(GRAXEmbedUtils.class).split('\\.', 2)[0];
				}
			} catch(Exception e) {
				namespace = '';
			}
		}
	}

	public static String getPureNameSpace(){
		loadNamespace();

		return namespace;
	}

	public static String getNameSpacePrefix() {
		loadNamespace();

		return String.isNotBlank(namespace) ? namespace + '__' : '';
	}

	public static String getPackageVersion() {
		Boolean isValidPackageEnv = getIsValidPackageEnv();

		if(getPureNameSpace() <> null) {
			System.Version v = Test.isRunningTest() || !isValidPackageEnv ? new System.Version(currentPackageMajorVersion, currentPackageMinorVersion) : System.requestVersion();
			String versionString = v.major() + '.' + v.minor();

			if (v.patch() <> null) {
				versionString += '.' + v.patch();
			}

			return versionString;
		}

		return null;
	}

	public static Boolean getIsValidPackageEnv(){
		Boolean result = true;
		try{
			String currentPackageId = System.Packaging.getCurrentPackageId();
			UserInfo.isCurrentUserLicensedForPackage(currentPackageId);
		}catch(Exception e){
			result = false;
			// A TypeException is thrown if packageID is an invalid type.
			// A SystemException is thrown if packageID is the ID of an unlocked or unmanaged package, or if the contextual user doesn’t have a license to the managed package.
		}

		return result;
	}

	private static String externalAPIEndpointStatic;

	public static String getExternalAPIEndpoint(){
		String result = externalAPIEndpointStatic;

		if(String.isBlank(result)){
			for(Organization org : [SELECT InstanceName FROM Organization LIMIT 1]){
				if(org != null && org.InstanceName != null) {
					result = 'https://' + org.InstanceName.toLowerCase() + '.salesforce.com';
					break;
				}
			}

			if(String.isBlank(result)){
				String uid = UserInfo.getUserId();
				String sid = UserInfo.getSessionId();
				String oid = UserInfo.getOrganizationId();
				String base = Url.getSalesforceBaseUrl().toExternalForm();

				//use getSalesforceBaseUrl within batches and schedules (not Visualforce), and fix inconsistent protocol
				if (sid == null) return base.replaceFirst('http:', 'https:');

				//within test context use url class, else derive from identity response
				PageReference api = new PageReference('/id/' + oid + '/' + uid + '?access_token=' + sid);
				String content = Test.isRunningTest() ? '{"urls":{"profile":"' + base + '"}}' : api.getContent().toString();
				Url profile = new Url(content.substringBetween('"profile":"', '"'));
				result = profile.getProtocol() + '://' + profile.getHost();
			}

			externalAPIEndpointStatic = result;
		}

		return result;
	}


	private static Map<String, Map<String, Object>> recordFieldCache = new Map<String, Map<String, Object>>();

	public static void putRecordFieldCache(String sid, String field, Object value) {
		if(!recordFieldCache.containsKey(sid)) {
			recordFieldCache.put(sid, new Map<String, Object>());
		}

		recordFieldCache.get(sid).put(field, value);
	}

	public static Boolean existRecordFieldCache(String sid, String field) {
		return recordFieldCache.containsKey(sid) && recordFieldCache.get(sid).containsKey(field);
	}

	public static Object getRecordFieldCache(String sid, String field) {
		if(existRecordFieldCache(sid, field)) {
			return recordFieldCache.get(sid).get(field);
		}

		return null;
	}

	public static Boolean alreadyCheckedRecordFieldCache(String sid) {
		return recordFieldCache.containsKey(sid);
	}

	/*
	* BEGIN Base62 encode / decode code
	* This is used to convert salesforce Ids to Integers and back for chunking
	*
	* This code ported from python here: https://gist.github.com/adyliu/4494223
	*/

	private static String basedigits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

	public static Long base62decode(String s) {
		Long ret = 0;
		Long mult = 1;

		String[] chars = s.split('');

		String[] charsReversed = new List<String>();

		for(Integer i = chars.size()-1; i>=0; i--) {
			charsReversed.add(chars.get(i));
		}

		for (String c: charsReversed) {
			Integer index = basedigits.indexOf(c);
			system.assert(index > -1, 'bad character');
			ret += mult*index;
			mult *= 62;
		}

		return ret;
	}

	public static String base62encode(Long num) {
		system.assert(num >= 0, 'expected positive number');
		if (num == 0) {
			return '0';
		}

		List<String> retList = new List<String>();

		String[] basedigitsArr = basedigits.split('');

		while (num != 0) {
			Integer cIndex = (Integer)Math.Mod(num, 62);
			retList.add(basedigitsArr[cIndex]);
			num = (num/62);
		}

		List<String> retListReversed = new List<String>();
		for(Integer i = retList.size()-1; i>=0; i--) {
			retListReversed.add(retList.get(i));
		}

		return String.join(retListReversed, '');
	}

	/*
	* END Base62 encode / decode code
	*/


	/*
	* removes leading zeros from a passed string of numbers or returns NULL when not all numeric characters
	*
	* Source: https://www.interactiveties.com/blog/2011/apex-drop-leading-zeros.php#.VMv5Ml7F9sA
	*/
	public static String drop_leading_zeros(String passedValue) {
		String return_string = null; //return string for passing back
		if (passedValue != null) { //if the passed value is not null
			return_string = passedValue.trim(); //trim the whitespace from the start and end of the value
			Pattern valid_characters = Pattern.compile('([0-9]+)'); //only numbers
			Matcher check_chars = valid_characters.matcher(return_string); //compare the string to the set of valid characters
			if (check_chars.matches()) { //if we have a somewhat valid number
				if (return_string.startsWith('0') && return_string.length() > 1) { //if the string begins with a 0 and the length is greater than 1
					boolean keepChecking = true; //create a boolean variable
					while (keepChecking) { //if boolean is true
						if (return_string.startsWith('0') && return_string.length() > 1) { //if the string begins with 0 and there is more than 1 character
							return_string = return_string.substring(1); //drop the first character
						} else { //either the string doesn't begin with 0 or the length is less than or equal to 1
							keepChecking = false; //stop the loop
						}
					}
				}
				if (return_string == '0') { //if the resulting string is now a single '0'
					return_string = null; //set the string to null
				}
			} else { //otherwise the value passed was not valid
				return_string = null; //set the string to null
			}
		}
		return return_string; //pass back a value
	}

	public static String prefixStringWithZeros(String sInput, Integer totalLength) {
		String sOutput = '';

		if (sInput != null) {
			sOutput = sInput+'';
		}

		//prepend with however many zeros we need to get up to total length
		Integer zerosToAdd = (totalLength - sOutput.length());
		if (zerosToAdd > 0) {
			for (Integer i=0; i<zerosToAdd; i++) {
				sOutput = '0'+sOutput;
			}
		}

		return sOutput;
	}

	public static String prefixLongWithZeros(Long lngInput, Integer totalLength) {
		String sOutput = '';

		if (lngInput != null) {
			sOutput = lngInput+'';
		}

		//prepend with however many zeros we need to get up to total length
		Integer zerosToAdd = (totalLength - sOutput.length());
		if (zerosToAdd > 0) {
			for (Integer i=0; i<zerosToAdd; i++) {
				sOutput = '0'+sOutput;
			}
		}

		return sOutput;
	}

	public static long numericDistance(Id firstId, Id secondId) {
		long firstNumericId = numericId(firstId);
		long secondNumericId = numericId(secondId);
		return secondNumericId - firstNumericId;
	}

	public static long numericId(Id input) {
		return numericId((string)input);
	}

	public static long numericId(string input) {

		string idAsString = (string)input;
		if(idAsString.length() > 15) {
			// Drop the case checking suffix for the last 3 characters of an 18 char ID.
			idAsString = idAsString.substring(0, 15);
		}

		long returnValue = 0;
		long multiplier = 1;

		for(integer i = idAsString.length(); i > 1; i--) {
			// The character being converted
			string idChar = idAsString.substring(i-1, i);
			// The index of the character being converted
			long value = basedigits.indexOf(idChar);

			returnValue = returnValue + ( value * multiplier );
			multiplier = multiplier * 62;
		}

		return returnValue;
	}

	public static Boolean isSalesforceChatterEnabled(){
		Boolean result = ConnectApi.Organization.getSettings().features.chatter;

		return result;
	}

	private static Boolean isTagsSettingEnabled;

	public static Boolean isSalesforceTagsEnabled(){
		if(isTagsSettingEnabled == null){
			isTagsSettingEnabled = [SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName = 'TagDefinition' LIMIT 1].size() > 0;
		}

		return isTagsSettingEnabled;
	}

	public static Boolean isQuerySortableField(String objectName, String fieldAPIName){
		List<FieldDefinition> fieldDefinitions = [SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = : objectName AND QualifiedApiName = : fieldAPIName AND IsApiSortable = true];

		return fieldDefinitions.size() > 0;
	}

	// Methods to obtain the Thousands, and, Decimals Separator defined for the current running User (based on the assigned Locale)
	private static String currentUserThousandsSeparator;
	private static String currentUserDecimalsSeparator;

	public static String getCurrentUserThousandsSeparator(){
		if(currentUserThousandsSeparator == null){
			getCurrentUserNumericSeparators();
		}

		return currentUserThousandsSeparator;
	}

	public static String getCurrentUserDecimalsSeparator(){
		if(currentUserDecimalsSeparator == null){
			getCurrentUserNumericSeparators();
		}

		return currentUserDecimalsSeparator;
	}

	private static void getCurrentUserNumericSeparators(){
		Decimal value = 1000.15;

		String formattedValue = value.format();

		currentUserThousandsSeparator = formattedValue.substring(1,2);
		currentUserThousandsSeparator = currentUserThousandsSeparator.isNumeric() ? '' : currentUserThousandsSeparator;

		currentUserDecimalsSeparator = formattedValue.right(3).substring(0, 1);
	}

	// Description: Cast a specific field value to be concatened in the where condition of a dynamic SOQL query string.
	public static String castFieldValueForDynamicSOQL(String objectName, String fieldName, Object fieldValue){
		String result = escapeSpecialCharactersForSOQL(String.valueOf(fieldValue));

		Set<String> stringFieldTypes = new Set<String>{'STRING', 'EMAIL', 'ID', 'REFERENCE', 'PHONE', 'PICKLIST', 'TEXTAREA', 'URL'};

		String fieldType = GRAXEmbedUtils.getDescribeFieldsResultForObject(objectName).get(fieldName).getType().name();

		if(stringFieldTypes.contains(fieldType)){
			result = '\'' + result + '\'';
		}

		if( fieldType == 'DATE' || fieldType == 'DATETIME'){
			// If Date or Datetime, we need to return a formatted datetime as follows yyyy-MM-ddTHH:mm:ssZ
			DateTime dt = (DateTime) fieldValue;
			result = dt.formatGMT('yyyy-MM-dd') + 'T' + dt.formatGMT('HH:mm:ss') + 'Z';
		}

		return result;
	}

	// Description: Escape the special characters from a value entered by the User to avoid errors in a SOQL query.
	public static String escapeSpecialCharactersForSOQL(String str){
		Set<String> specialCharacters = new Set<String>{'\\', '%', '_'};

		return escapeSpecialCharacters(str, specialCharacters);
	}

	// Description: Escape the special characters from a value entered by the User to avoid errors in a SOSL query.
	public static String escapeSpecialCharactersForSOSL(String str){
		Set<String> specialCharacters = new Set<String>{'?', '&', '|', '!', '{', '}', '[', ']', '(', ')', '^', '~', '*', ':', '\\', '"', '+', '-'};

		return escapeSpecialCharacters(str, specialCharacters);
	}

	// Description: Generic method to escape a list of special characters from a given string value.
	private static String escapeSpecialCharacters(String str, Set<String> specialCharacters){
		String result = str;

		if(result == null){
			result = '';
		}

		if(result <> null && result <> ''){
			for(String specialChar : specialCharacters){
				result = result.replace(specialChar, '\\' + specialChar);
			}
		}

		result = String.escapeSingleQuotes(result);

		return result;
	}
}
