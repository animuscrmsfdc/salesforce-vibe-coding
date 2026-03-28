import { LightningElement, wire } from "lwc";
import getHouses from "@salesforce/apex/HouseService.getRecords";

export default class HousingMap extends LightningElement {
    mapMarkers;
    error;
  
    @wire(getHouses)
    wiredHouses({ error, data }) {
        if (data) {
    // We are using Javascript Map function to transform the
      this.mapMarkers = data.map((element) => {
        return {
          location: {
            Street: element.Address__c,
            City: element.City__c,
            State: element.State__c
          },
          title: element.Name,
          description: element.Price__c,
          icon: 'custom:custom26',
        };
      });
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.mapMarkers = undefined;
    }
  }
}