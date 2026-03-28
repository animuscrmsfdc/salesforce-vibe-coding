Create a new Salesforce Platform Event object: $ARGUMENTS

Expected format: <EventName__e> [HighVolume] [PublishImmediately] with fields <Field1> <Type>, <Field2> <Type>, ...

Steps:
1. Create the folder at force-app/main/default/objects/<EventName__e>/
2. Create <EventName__e>.object-meta.xml with:
   - eventType: StandardVolume (use HighVolume if specified)
   - publishBehavior: PublishAfterCommit (use PublishImmediately if specified)
   - label, pluralLabel (derived from event name)
   - description always included
   - deploymentStatus: Deployed
3. Create a fields/ subfolder
4. Create a .field-meta.xml for each payload field specified
5. Common field types for platform events: Text, Number, DateTime, Checkbox, LongTextArea
6. Show the deploy command after creation:
   sf project deploy start --metadata CustomObject:<EventName__e> --target-org animuscrm

Note: Platform events do not support all field types. Avoid Lookup, MasterDetail, and Formula fields.
