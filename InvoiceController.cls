public with sharing class InvoiceController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> fetchInvoiceData(
        String originRecordId,
        String invoiceDate,
        String dueDate,
        String childRelationship,
        String descriptionField,
        String quantityField,
        String unitPriceField
    ){
        system.debug('descriptionField value: ' +descriptionField);
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        Schema.SObjectType token = Id.valueOf(originRecordId).getSObjectType();
        Schema.DescribeSObjectResult dr = token.getDescribe();

        String fieldToQuery = (dr.getName() == 'Opportunity') ? 'OpportunityId' : 'OrderId';

        
            //String query = 'SELECT ' + descriptionField + ', ' +quantityField + ', ' + unitpriceField +' FROM ' + childRelationship +' WHERE ' + fieldToQuery + ' = :' +originRecordId;
            String query = 'SELECT Id, (SELECT ' + descriptionField + ', ' +quantityField + ', ' + unitpriceField +' FROM ' + childRelationship +') FROM '+ dr.getName() +'  WHERE Id = ' + '\'' +originRecordId+ '\'';
            System.debug(query);
            List<sObject> records= Database.query(query);

            if(dr.getName() == 'Opportunity'){
                for(sObject record1: records){
                    for(sObject record2: record1.getSObjects('OpportunityLineItems')){
                        Map<String,Object> lineItem= new Map<String,Object>();
                        lineItem.put('description', (String)record2.get(descriptionField));
                        lineItem.put('quantity', (Decimal) record2.get(quantityField));
                        lineItem.put('unitPrice', (Decimal) record2.get(unitPriceField));
                        lineItem.put('amount', ((Decimal)record2.get(quantityField) * (Decimal)record2.get(unitPriceField)));
                        lineItems.add(lineItem);
                    }

                    
                }
            }
            else{
                for(sObject record3: records){
                    for(sObject record4: record3.getSObjects('OrderLineItems')){
                        Map<String,Object> lineItem= new Map<String,Object>();
                        lineItem.put('description', (String)record4.get(descriptionField));
                        lineItem.put('quantity', (Decimal) record4.get(quantityField));
                        lineItem.put('unitPrice', (Decimal) record4.get(unitPriceField));
                        lineItem.put('amount', ((Decimal)record4.get(quantityField) * (Decimal)record4.get(unitPriceField)));
                        lineItems.add(lineItem);
                    }
                    
                }
            }
            
        system.debug(lineItems);
        return lineItems;
    }


    @Auraenabled(cacheable=true)
    public static String createInvoice(Map<String,Object> invoiceData, List<Map<String,Object>> lineItems){
        try{
            //Create invoice record
            Invoice__c invoice = new Invoice__c();
            invoice.Account__c = (String) invoiceData.get('account');
            invoice.Invoice_Date__c = Date.valueof((String)invoiceData.get('invoiceDate'));
            invoice.Due_Date__c = Date.valueOf((String)invoiceData.get('dueDate'));
            insert invoice;

            //Create Line items
            List<Line_Item__c> lineItemRecords = new List<Line_Item__c>();
            for(Map<String,Object> item :lineItems){
                Line_Item__c lineItem = new Line_Item__c();
                lineItem.Invoice__c = invoice.Id;
                lineItem.Line_Description__c = (String) item.get('description');
                lineItem.Quantity__c = (Decimal) item.get('quantity');
                lineItem.Unit_Price__c = (Decimal) item.get('unit price');
                lineItemRecords.add(lineItem);
            }
            insert lineItemRecords;

            return invoice.Id;
        }catch(Exception e){
            throw new AuraHandledException('Error creating invoice: ' +e.getMessage());
        }
        
    }
}