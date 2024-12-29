import { LightningElement, track, api } from 'lwc';
import fetchInvoiceData from '@salesforce/apex/InvoiceController.fetchInvoiceData';
import createInvoice from '@salesforce/apex/InvoiceController.createInvoice';

export default class CreateInvoice extends LightningElement {
    parameters = []
    @track invoiceData
    @track lineItems = []
    isLoading = true

    @api originRecordId
    @api lineItemDescriptionField
    @api account
    @api invoiceDate
    @api dueDate
    @api childRelationship
    @api lineItemQuantityField
    @api lineItemUnitPriceField

    @track showJSON = false
    @track jsonString = ''

    connectedCallback(){

        
        const urlParams = new URLSearchParams(window.location.search);
        this.originRecordId = urlParams.get('c__origin_record')
        console.log('this.originRecordId: ' +this.originRecordId)
        this.account = urlParams.get('c__account')
        console.log('this.account: ' +this.account)
        this.invoiceDate = urlParams.get('c__invoice_date')
        this.dueDate = urlParams.get('c__invoice_due_date')
        this.childRelationship = urlParams.get('c__child_relationship_name')
        this.lineItemDescriptionField = urlParams.get('c__line_item_description')
        this.lineItemQuantityField = urlParams.get('c__line_item_quantity')
        this.lineItemUnitPriceField = urlParams.get('c__line_item_unit_price')

        this.parameters = [
            {name:'origin_record', value: urlParams.get('c__origin_record')},
            {name:'account', value: urlParams.get('c__account')},
            {name:'invoice_date', value: urlParams.get('c__invoice_date') },
            {name:'invoice_due_date', value: urlParams.get('c__invoice_due_date')},
            {name:'child_relationship_name', value: urlParams.get('c__child_relationship_name')},
            {name:'line_item_description', value: urlParams.get('c__line_item_description')},
            {name:'line_item_quantity', value: urlParams.get('c__line_item_quantity')},
            {name:'line_item_unit_price', value: urlParams.get('c__line_item_unit_price')}
        ]

        /*
        //Invoice data
        this.invoiceData = {
            originRecordId,
            account,
            invoiceDate,
            dueDate,
            childRelationship
        };

        //Line items data
        */

        fetchInvoiceData({
            originRecordId:this.originRecordId, account:this.account, invoiceDate:this.invoiceDate,dueDate:this.dueDate, childRelationship:this.childRelationship,
            descriptionField: this.lineItemDescriptionField, quantityField:this.lineItemQuantityField, unitPriceField:this.lineItemUnitPriceField
            }).then((data)=>{
                this.invoiceData = JSON.stringify(JSON.parse(data), null, 2);
                this.isLoading = false;
            }).catch((error)=>{
                console.error('Error fetching data: ' +error);
                this.isLoading = false;
            });

            /*this.invoiceData = {
                account,
                invoiceDate,
                dueDate
            };*/

            //this.handleCreateInvoice()
        
    }


    clickHandler(){
        this.showJSON = true
        this.jsonString = this.lineItems
        console.log()
    }

    handleBack(){
        this.showJSON = false
    }

    handleCreateInvoice(){
        console.log('hi')
        createInvoice({invoiceJson: this.invoiceData})
        .then((result)=>{
            window.location.href = `/lightning/r/Invoice__c/${result}/view`;
        })
        .catch((error)=>{
            console.error('Error creating invoice: ' + error);
        })
    }

}
