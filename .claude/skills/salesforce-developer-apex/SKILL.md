---
name: salesforce-developer-apex
description: Apex development skills for animuscrm — triggers (static switch-based handler pattern), classes, platform event publishing, and security enforcement.
---

# Salesforce Developer Apex Skill — animuscrm

Covers Apex trigger development, class structure, and security enforcement patterns.

---

## Trigger Pattern — animuscrm Standard

**This project uses a static switch-based trigger handler pattern. All existing triggers follow this convention — new triggers MUST follow the same pattern for consistency.**

The pattern:
- Trigger body contains only a `switch on Trigger.operationType` block
- Each `when` branch calls a static method on the handler class
- No business logic in the trigger body
- No base class required

```apex
trigger UsageTrigger on Usage__c (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            UsageTriggerHandler.afterInsertHandler(Trigger.new);
        }
        when AFTER_UPDATE {
            UsageTriggerHandler.afterUpdateHandler(Trigger.new, Trigger.oldMap);
        }
    }
}
```

> Note: The Kevin O'Hara TriggerHandler framework is NOT used in this project. Do not add a TriggerHandler base class unless the user explicitly requests a full migration of all existing triggers to that pattern.

---

## skill: create-apex-trigger-with-handler

**Trigger phrase:** "create a trigger" / "new trigger for"

### Rules
- **One trigger per object.** If a trigger already exists for the object, extend the existing handler class — do not create a second trigger.
- Business logic goes in the handler class, never in the trigger body.
- For recursion control, use a static Boolean flag on the handler class (no base class is present in this project).

### Steps
1. Check `force-app/main/default/triggers/` — warn and stop if a trigger for this object already exists
2. Create `force-app/main/default/triggers/<Object>Trigger.trigger`
   - Use `switch on Trigger.operationType` with only the required events
   - Each branch calls a static method on the handler: `<Object>TriggerHandler.afterInsertHandler(Trigger.new)`
   - No logic in the trigger body
3. Create `force-app/main/default/triggers/<Object>Trigger.trigger-meta.xml`
   - `apiVersion`: 66.0, `status`: Active
4. Create `force-app/main/default/classes/<Object>TriggerHandler.cls`
   - `public with sharing class` — no base class
   - Public static methods per event: `afterInsertHandler(List<SObject> newRecords)`, `afterUpdateHandler(List<SObject> newRecords, Map<Id,SObject> oldMap)`, etc.
   - Delegate to a service class for business logic — keep handler methods as thin dispatchers
5. Create `force-app/main/default/classes/<Object>TriggerHandler.cls-meta.xml`
6. Deploy command:
   ```
   sf project deploy start --metadata ApexTrigger:<Object>Trigger,ApexClass:<Object>TriggerHandler --target-org dev-org
   ```

---

## skill: create-apex-class

**Trigger phrase:** "create an Apex class" / "new service class" / "new controller"

### Class Types and Templates

| Type | Sharing | Key Pattern |
|------|---------|-------------|
| `controller` | `with sharing` | `@AuraEnabled` methods, `Security.stripInaccessible()` on results |
| `service` | `with sharing` | Static methods, `WITH SECURITY_ENFORCED` on all SOQL |
| `trigger-handler` | `with sharing` | Public static methods per event, delegates to service class |
| `batch` | `global` | Implements `Database.Batchable<SObject>`, start/execute/finish |
| `schedulable` | `global` | Implements `Schedulable`, execute(SchedulableContext sc) |
| `queueable` | `public` | Implements `Queueable`, execute(QueueableContext ctx) |
| `test` | `@IsTest` | @TestSetup, no SeeAllData=true, 90%+ coverage target |

### Naming Conventions
- Handler classes: `<ObjectName>TriggerHandler.cls`
- Service classes: `<Domain>Service.cls`
- Controller classes: `<Feature>Controller.cls`
- Test classes: `<ClassName>Test.cls`

### Steps
1. Create `force-app/main/default/classes/<ClassName>.cls` with correct template
2. Create `force-app/main/default/classes/<ClassName>.cls-meta.xml` (apiVersion: 66.0, status: Active)
3. Deploy command:
   ```
   sf project deploy start --metadata ApexClass:<ClassName> --target-org dev-org
   ```

---

## skill: publish-platform-event

**Trigger phrase:** "publish a platform event" / "fire a platform event" / "push to platform event"

Use this pattern whenever Apex needs to publish a Platform Event — from a trigger handler, service class, or batch job.

### Rules
- Always use `EventBus.publish()` — never use `insert` for platform events
- Always check `Database.SaveResult` after publishing — a publish can fail silently without the check
- Use `try/catch` to handle unexpected exceptions and log them
- Field mapping between source SObject and the event must be explicit — no dynamic field assignment
- This pattern fires `after insert` or `after update` — never `before` context (records need IDs)

### Pattern: Publish from a Service Class (animuscrm pattern)
```apex
public with sharing class UsageEventService {

    public static void publishEvents(List<Usage__c> usages, String eventType) {
        List<Platform_Usages__e> events = new List<Platform_Usages__e>();

        for (Usage__c u : usages) {
            Platform_Usages__e evt = new Platform_Usages__e();
            // CloudEvents envelope fields
            evt.specversion__c    = '1.0';
            evt.type__c           = eventType; // e.g. 'com.animuscrm.usage.created'
            evt.source__c         = URL.getOrgDomainUrl().toExternalForm();
            evt.subject__c        = u.Id;
            evt.time__c           = System.now();
            evt.datacontenttype__c = 'application/json';
            // Payload: JSON-serialise the Usage record
            evt.data__c           = JSON.serialize(u);
            events.add(evt);
        }

        try {
            List<Database.SaveResult> results = EventBus.publish(events);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results.get(i).isSuccess()) {
                    for (Database.Error err : results.get(i).getErrors()) {
                        // Log using this org's Exception_Log__e fields
                        EventBus.publish(new Exception_Log__e(
                            Object__c          = 'Usage__c',
                            Operation__c       = 'PublishPlatformEvent',
                            Record_Id__c       = usages.get(i).Id,
                            Exception_Details__c = err.getStatusCode() + ': ' + err.getMessage()
                        ));
                    }
                }
            }
        } catch (Exception e) {
            EventBus.publish(new Exception_Log__e(
                Object__c          = 'Usage__c',
                Operation__c       = 'PublishPlatformEvent',
                Record_Id__c       = null,
                Exception_Details__c = e.getMessage() + '\n' + e.getStackTraceString()
            ));
        }
    }
}
```

### Steps
1. Determine which trigger events should publish (typically `after insert`, `after update`)
2. Create the mapping list: for each source record, instantiate the `__e` SObject and assign fields explicitly
3. Call `EventBus.publish(eventList)` and capture the `List<Database.SaveResult>`
4. Iterate results — log any `isSuccess() == false` entries with the record ID and error message
5. Wrap the entire method in `try/catch(Exception e)` and log unexpected failures
6. Never put `EventBus.publish()` inside a loop — always bulk-collect events first, publish once
7. This org's `Exception_Log__e` has these fields — always use these exact API names:
   - `Object__c` (Text 80) — the SObject being processed
   - `Operation__c` (Text 250) — the operation name (e.g. `'PublishPlatformEvent'`)
   - `Record_Id__c` (Text 18) — the affected record's ID
   - `Exception_Details__c` (LongTextArea 32768) — full error message and stack trace

### Governor Limit Notes
- `EventBus.publish()` counts against DML statement limits (150 per transaction)
- Each published event counts against platform event daily limits (varies by org edition)
- Bulk-publish in one call — never call `EventBus.publish()` inside a for loop

---

## skill: enforce-security

**Trigger phrase:** "add security to" / "secure this class" / "fix security issues"

### Steps
1. Read the target Apex class in full
2. For every SOQL query in `@AuraEnabled`, `@RemoteAction`, or `@RestResource` methods:
   - Add `WITH SECURITY_ENFORCED` to the query, OR
   - Use `Security.stripInaccessible(AccessType.READABLE, results)` before returning
3. For every DML operation (`insert`, `update`, `delete`, `upsert`):
   - Add `Schema.sObjectType.<Object>.isCreateable()` before insert/upsert
   - Add `Schema.sObjectType.<Object>.isUpdateable()` before update/upsert
   - Add `Schema.sObjectType.<Object>.isDeletable()` before delete
4. Confirm the class declaration uses `with sharing`
5. Confirm no `Database.query()` uses string concatenation — replace with bind variables
6. Report any remaining issues that require manual review

### Security Checklist
- [ ] `with sharing` on class declaration
- [ ] `WITH SECURITY_ENFORCED` or `stripInaccessible()` on all exposed SOQL
- [ ] DML guards (`isCreateable`, `isUpdateable`, `isDeletable`) in place
- [ ] No hardcoded IDs (15 or 18 char strings starting with 00D, 001, 003, etc.)
- [ ] No MD5 for tokens — use `Crypto.generateDigest('SHA-256', ...)` minimum
- [ ] No string concatenation in `Database.query()` calls
- [ ] Null checks before accessing related object fields (`.Lookup__r.Field__c`)
