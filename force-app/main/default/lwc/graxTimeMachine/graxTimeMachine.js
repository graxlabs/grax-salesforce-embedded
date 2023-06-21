import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import loadLWCPaylod from '@salesforce/apex/GRAXEmbedLWCHelper.loadLWCPaylod';
import TIME_ZONE  from '@salesforce/i18n/timeZone';

export default class graxEmbedded extends NavigationMixin(LightningElement) {
  @api flexipageRegionWidth;
  @api objectApiName;
  @api recordId;
 
  @api iFrameSize = 400;

  @api apiUrl;
  @track iFrameUrl='';

  @api additionalParams = '';
  @api recordsPerPage = 5;
  @api title;

  @track lwcPayload = null;

  async queryGRAX(){
    return await loadLWCPaylod({objectName:this.objectApiName,fields:'',objectId:this.recordId,enforceRowSecurity:false});
  }

  async connectedCallback() { 
    this.lwcPayload = await this.queryGRAX();
    this.iFrameUrl = `${this.lwcPayload.apiPath}/web/objects/${this.objectApiName}/records/${this.recordId}/latest/versions?embedded=true&${this.getParams()}`;
  }

  // Embedded Parameters
  getParams(){
    var paramFields = this.fields;
    var retVal = `autologin=true&includeFields=true&fields=${encodeURIComponent(paramFields)}`;
    if (this.title != "" && !this.title!=null && this.title!=undefined) {
      retVal+=`&title=${encodeURIComponent(this.title)}`;
    }
    if (this.recordsPerPage!=null && this.recordsPerPage > 0){
      retVal+=`&perPage=${this.recordsPerPage}`;
    }
    // If we add additional parameters we can still use existing LWC 
    if (this.additionalParams != "" && this.additionalParams!=null && this.additionalParams!=undefined) {
      retVal+='&' + this.additionalParams;
    }
    return retVal;
  }  
}