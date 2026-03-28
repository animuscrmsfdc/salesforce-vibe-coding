Create a new Salesforce custom object with the following specification: $ARGUMENTS

Steps to follow:
1. Create the object folder at force-app/main/default/objects/<ObjectName__c>/
2. Create <ObjectName__c>.object-meta.xml with:
   - deploymentStatus: Deployed
   - sharingModel: ReadWrite (default unless specified)
   - label, pluralLabel, nameField (AutoNumber or Text as appropriate)
   - description always included
3. Create a fields/ subfolder inside the object folder
4. Add a Description__c field (LongTextArea, 32768 chars) by default
5. Create a .field-meta.xml file for each field specified in the arguments
6. Show the deploy command after creating all files:
   sf project deploy start --metadata CustomObject:<ObjectName__c> --target-org animuscrm
