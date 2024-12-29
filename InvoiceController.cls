public with sharing class InvoiceController {

    @AuraEnabled(cacheable=true)
    public static String fetchInvoiceData(
        String originRecordId,
        String account,
        String invoiceDate,
        String dueDate,
        String childRelationship,
        String descriptionField,
        String quantityField,
        String unitPriceField
    ){
        system.debug('originRecordId value: ' +originRecordId + 'account value: ' +account + 'invoiceDate value: ' +invoiceDate + 'dueDate value: ' +dueDate
        + 'childRelationship value: ' +childRelationship + 'descriptionField value: ' +descriptionField + 'quantityField value: ' +quantityField + 'unitPriceField value: ' +unitPriceField
        );
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        Schema.SObjectType token = Id.valueOf(originRecordId).getSObjectType();
        Schema.DescribeSObjectResult dr = token.getDescribe();

        String query = 'SELECT Id,' + account + ', ' + invoiceDate + ', ' + dueDate +' FROM ' + dr.getName() +'  WHERE Id = ' + '\'' +originRecordId+ '\'';
        system.debug(query);
        List<sObject> records= Database.query(query);
        System.debug(records);

        String childObj = (childRelationship == 'OpportunityLineItems') ? 'OpportunityLineItem' : 'OrderItem';
        String parentObjField = (childObj == 'OpportunityLineItem') ? 'OpportunityId' : 'OrderId';
        String query2 = 'SELECT Id, ' + descriptionField + ', ' + quantityField + ', ' + unitPriceField +', ' + parentObjField + ' FROM ' + childObj +'  WHERE ' + parentObjField + ' = ' + '\'' +originRecordId+ '\'';
        System.debug(query2);
        List<sObject> childRecords = Database.query(query2);
        System.debug(childRecords);

        List<String> parentFields = new List<String>();
        parentFields.add(account);
        parentFields.add(invoiceDate);
        parentFields.add(dueDate);
        System.debug('parentFields: ' +parentFields);

        List<String> childFields = new List<String>();
        childFields.add(parentObjField);
        childFields.add(descriptionField);
        childFields.add(quantityField);
        childFields.add(unitPriceField);
        System.debug('childFields: ' +childFields);

        

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        System.debug(globalDescribe);
        Schema.SObjectType parentObjSchema = globalDescribe.get(dr.getName());
        System.debug('parentObjSchema: ' +parentObjSchema);
        Map<String, Schema.SObjectField> pObjfields = parentObjSchema.getDescribe().fields.getMap();

        Schema.SObjectType childObjSchema = globalDescribe.get(childObj);
        System.debug('childObjSchema: ' +childObjSchema);
        Map<String, Schema.SObjectField> cObjfields = childObjSchema.getDescribe().fields.getMap();
        /*for(String fieldName : fields.keySet()){
            System.debug('Field: ' +fieldName);
            System.debug('value: ' +fields.get(fieldName));
        }*/

        Map<Id, List<Map<String,Object>>> lineItemsByOptyId = new Map<Id, List<Map<String,Object>>>();
        for(SObject li : childRecords){
            
            if(!lineItemsByOptyId.containsKey((Id)li.get(parentObjField))){
                lineItemsByOptyId.put((Id)li.get(parentObjField), new List<Map<String, Object>>());
            }

            Map<String, Object> childData = new Map<String,Object>();
            for(String field: childFields){
                childData.put(field.trim(), li.get(field.trim()));
            }
            lineItemsByOptyId.get((Id)li.get(parentObjField)).add(childData);
        }
        System.debug('test1: '+lineItemsByOptyId);

        List<Map<String,Object>> parentList = new List<Map<String,Object>>();
        for(SObject inv : records){
            Map<String,Object> parentData = new Map<String,Object>();
            for(String field: parentFields){
                parentData.put(field.trim(), inv.get(field.trim()));
            }
            if(lineItemsByOptyId.containsKey(inv.Id)){
                parentData.put('LineItems', lineItemsByOptyId.get(inv.Id));
            }
            else{
                parentData.put('LineItems', new List<Map<String,Object>>());
            }
            parentList.add(parentData);
        }
        System.debug('parentList: ' +parentList);

        Map<String, Object> response = new Map<String, Object>();
        response.put('Invoices', parentList);
        System.debug(JSON.serialize(response));
        

        return JSON.serialize(response);
    }


   @AuraEnabled
    public static String createInvoice(String invoiceJson){
        try{
            Map<String,Object> invoiceData = (Map<String,Object>) JSON.deserializeUntyped(invoiceJson);
            System.debug('invoiceData:' +invoiceData);
            /*Create invoice record
            Invoice__c invoice = new Invoice__c();
            invoice.Account__c = (String) invoiceData.get('account');
            System.debug('invoice date: ' +invoiceData.get('invoiceDate'));
            invoice.Invoice_Date__c = Date.valueOf(invoiceData.get('invoiceDate'));
            invoice.Due_Date__c = Date.valueOf((String)invoiceData.get('dueDate'));
            System.debug('Invoice: ' +invoice);
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
            System.debug('LineItems: ' +lineItemRecords);
            insert lineItemRecords;
            */

           
            List<Object> invoices = (List<Object>) invoiceData.get('Invoices');
                Invoice__c inv = new Invoice__c();
                Map<String, Object> firstInvoice = (Map<String, Object>) invoices[0];
                String accountId = (String) firstInvoice.get('AccountId');
                inv.Account__c = accountId;
                String invoiceDate = (String) firstInvoice.get('CloseDate');
                System.debug('AccountId1: ' + invoiceDate);
                inv.Invoice_Date__c = Date.valueOf(invoiceDate);
                String dueDate = (String) firstInvoice.get('Custom_date__c');
                System.debug('AccountId1: ' + dueDate);
                inv.Due_Date__c = Date.valueOf(dueDate);
                insert inv;

               List<Object> lineItems = (List<Object>) firstInvoice.get('LineItems');
                //System.debug('invoices1: ' +invoices1);
            //List<Map<String,Object>> lineItems = (List<Map<String,Object>>) firstInvoice.get('LineItems');
            System.debug('lineItems: ' +lineItems);
            List<Line_Item__c> lineItemRecords = new List<Line_Item__c>();
            for(Object lineItemData : lineItems){
                Map<String, Object> lineItem = (Map<String, Object>) lineItemData;
                Line_Item__c newlineItem = new Line_Item__c();
                newlineItem.Invoice__c = inv.Id;
                System.debug('lineItem.invoice__c: ' +newlineItem.invoice__c);
                newlineItem.Line_Description__c = (String) lineItem.get('Description');
                newlineItem.Quantity__c = Integer.valueOf(lineItem.get('Quantity').toString());
                newlineItem.Unit_Price__c = Decimal.valueOf(lineItem.get('UnitPrice').toString());

                lineItemRecords.add(newlineItem);
            }
            if(!lineItemRecords.isEmpty()){
                insert lineItemRecords;
            }
            return (String)inv.Id;
        }catch(Exception e){
            throw new AuraHandledException('Error creating invoice: ' +e.getMessage());
        }
        
    }
}
