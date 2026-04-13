import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

const actions = [
    { label: 'View', name: 'view' },
];

const columns = [  
    { label: 'Name', fieldName: 'Name' },
    { label: 'Email', fieldName: 'Email' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    }, 
];

export default class Lwc_for_flows extends NavigationMixin(LightningElement) {

    @api contacts;
    columns = columns;
   
    handleRowAction( event ) {

        const row = event.detail.row;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                objectApiName: 'Contact',
                actionName: 'view'
            }
        });

    }

}