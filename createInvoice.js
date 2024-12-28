import { LightningElement, track, api } from 'lwc';
import fetchInvoiceData from '@salesforce/apex/InvoiceController.fetchInvoiceData';
import createInvoice from '@salesforce/apex/InvoiceController.createInvoice';

export default class CreateInvoice extends LightningElement {
    parameters = []
    @track invoiceData =[]
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

    connectedCallback(){

        
        const urlParams = new URLSearchParams(window.location.search);
        console.log(urlParams)
        this.originRecordId = urlParams.get('c__origin_record')
        const account = urlParams.get('c__account')
        const invoiceDate = urlParams.get('c__invoice_date')
        const dueDate = urlParams.get('c__invoice_due_date')
        this.childRelationship = urlParams.get('c__child_relationship_name')
        this.lineItemDescriptionField = urlParams.get('c__line_item_description')
        console.log(this.lineItemDescriptionField)
        this.lineItemQuantityField = urlParams.get('c__line_item_quantity')
        console.log(this.lineItemQuantityField)
        this.lineItemUnitPriceField = urlParams.get('c__line_item_unit_price')
        console.log(this.lineItemUnitPriceField)

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
            originRecordId:this.originRecordId, invoiceDate:this.invoiceDate,dueDate:this.dueDate, childRelationship:this.childRelationship,
            descriptionField: this.lineItemDescriptionField, quantityField:this.lineItemQuantityField, unitPriceField:this.lineItemUnitPriceField
            }).then((data)=>{
                this.lineItems = data;
                this.isLoading = false;
            }).catch((error)=>{
                console.error('Error fetching data: ' +error);
                this.isLoading = false;
            });

            this.invoiceData = {
                account,
                invoiceDate,
                dueDate
            };
        
    }

    async handleCreateInvoice(){
        try{
            const result = await createInvoice({
                invoiceData : this.invoiceData,
                lineItems : this.lineItems,
            });
            alert('Invoice created Successfully: ' +result);
        } catch(error){
            console.error('Error creating Invoice: ' +error);
        }
    }

}