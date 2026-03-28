Retrieve metadata from the animuscrm Salesforce org into the local project: $ARGUMENTS

If a specific component is provided in $ARGUMENTS, retrieve only that component.
If no argument is provided, retrieve the entire force-app source directory.

Steps:
1. If $ARGUMENTS is empty, run:
   sf project retrieve start --source-dir force-app --target-org animuscrm

2. If $ARGUMENTS contains a metadata type and name (e.g. "CustomObject:MyObj__c"), run:
   sf project retrieve start --metadata <value> --target-org animuscrm

3. After retrieval, list what changed:
   - New files created
   - Files modified
   - Note any unexpected changes that may need review
