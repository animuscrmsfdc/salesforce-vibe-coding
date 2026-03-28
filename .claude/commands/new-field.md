Create a new custom field on a Salesforce object: $ARGUMENTS

Expected format: <ObjectName__c> <FieldName__c> <FieldType> [options]

Supported field types: Text, LongTextArea, Number, Currency, Percent, Date, DateTime, Checkbox,
Lookup, MasterDetail, Picklist, MultiselectPicklist, Email, Phone, URL, AutoNumber, Formula

Steps:
1. Create the file at force-app/main/default/objects/<ObjectName__c>/fields/<FieldName__c>.field-meta.xml
2. Use the correct XML structure for the specified field type
3. Always include: label, description, required (false by default), trackHistory (false by default)
4. For Text fields: include length (default 255)
5. For Number/Currency/Percent fields: include precision and scale
6. For Lookup fields: include referenceTo and relationshipName
7. For Picklist fields: include a valueSet with the values provided; mark first value as default
8. For Formula fields: include formula and returnType
9. Show the deploy command after creation:
   sf project deploy start --metadata CustomField:<ObjectName__c>.<FieldName__c> --target-org animuscrm
