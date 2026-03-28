Deploy the current changes to the animuscrm Salesforce org: $ARGUMENTS

If a specific component is provided in $ARGUMENTS, deploy only that component.
If no argument is provided, deploy the entire force-app source directory.

Steps:
1. If $ARGUMENTS is empty, run:
   sf project deploy start --source-dir force-app --target-org animuscrm

2. If $ARGUMENTS contains a metadata type and name (e.g. "CustomObject:MyObj__c"), run:
   sf project deploy start --metadata <value> --target-org animuscrm

3. After deploy completes, run to confirm status:
   sf project deploy report

4. If there are errors:
   - Read each error message carefully
   - Identify the file and line number
   - Suggest the fix and apply it if straightforward
   - Re-run the deploy after fixing
