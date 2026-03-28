Create a new Salesforce validation rule: $ARGUMENTS

Expected format: <ObjectName__c> <RuleName> "<error formula>" "<error message>" [field: <FieldName>]

Steps:
1. Create the file at:
   force-app/main/default/objects/<ObjectName__c>/validationRules/<RuleName>.validationRule-meta.xml
2. Use this XML structure:
   - active: true
   - description: derived from rule name and error message
   - errorConditionFormula: the formula provided (must be valid Salesforce formula syntax)
   - errorMessage: the error message provided
   - errorDisplayField: if a field name is provided, set it; otherwise omit the element
3. Rule name must follow Descriptive_Snake_Case convention
4. Formula should return true when the record is INVALID (i.e. when the error should fire)
5. Show the deploy command after creation:
   sf project deploy start --metadata ValidationRule:<ObjectName__c>.<RuleName> --target-org animuscrm
