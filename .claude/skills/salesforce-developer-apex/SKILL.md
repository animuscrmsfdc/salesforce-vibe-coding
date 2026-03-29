---
name: salesforce-developer-apex
description: Apex development skills for animuscrm — triggers (Kevin O'Hara framework), classes, platform event publishing, and security enforcement.
---

# Salesforce Developer Apex Skill — animuscrm

Covers Apex trigger development, class structure, and security enforcement patterns.

---

## Framework Mandate: Kevin O'Hara Trigger Pattern

**When asked to create or modify an Apex trigger, you MUST use the Kevin O'Hara trigger framework pattern. Never put business logic directly in a trigger body.**

Before writing any trigger code:
1. Check whether a `TriggerHandler` base class already exists in `force-app/main/default/classes/`
2. If it does not exist, ask the user whether to add it (reference: https://github.com/kevinohara80/sfdc-trigger-framework)
3. If it exists, extend it — do not create a second base class

---

## skill: create-apex-trigger-with-handler

**Trigger phrase:** "create a trigger" / "new trigger for"

### Rules
- **One trigger per object.** If a trigger already exists for the object, extend the existing handler — do not create a second trigger.
- Business logic goes in the handler class, never in the trigger body.
- Use `TriggerHandler.bypass('HandlerName')` and `TriggerHandler.clearBypass('HandlerName')` for recursion control and selective disabling — do not use custom static flags when the framework is present.

### Steps
1. Check for existing trigger on the object — warn and stop if one exists
2. Create `force-app/main/default/triggers/<Object>Trigger.trigger`
   - Include only the events specified (default: before insert, before update, after insert, after update)
   - Delegate immediately to handler: `new <Object>TriggerHandler().run();`
   - No logic in the trigger body
3. Create `force-app/main/default/triggers/<Object>Trigger.trigger-meta.xml`
   - `apiVersion`: 66.0, `status`: Active
4. Create `force-app/main/default/classes/<Object>TriggerHandler.cls`
   - Extends `TriggerHandler` base class if available
   - `public with sharing class`
   - Separate override methods per event: `beforeInsert`, `afterInsert`, `beforeUpdate`, `afterUpdate`, etc.
   - Access `Trigger.new`, `Trigger.old`, `Trigger.newMap`, `Trigger.oldMap` via inherited context
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
| `trigger-handler` | `with sharing` | Extends TriggerHandler, override methods per event |
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

### Pattern: Publish from a Trigger Handler
```apex
public with sharing class UsageTriggerHandler extends TriggerHandler {

    override protected void afterInsert() {
        publishUsageEvents((List<Usage__c>) Trigger.new);
    }

    override protected void afterUpdate() {
        publishUsageEvents((List<Usage__c>) Trigger.new);
    }

    private static void publishUsageEvents(List<Usage__c> usages) {
        List<Platform_Usages__e> events = new List<Platform_Usages__e>();

        for (Usage__c u : usages) {
            Platform_Usages__e evt = new Platform_Usages__e();
            // Map fields explicitly by API name
            evt.source__c      = u.Source__c;
            evt.type__c        = u.Type__c;
            evt.subject__c     = String.valueOf(u.Id);
            evt.time__c        = System.now();
            evt.specversion__c = '1.0';
            // ... map remaining fields
            events.add(evt);
        }

        List<Database.SaveResult> results = EventBus.publish(events);

        for (Integer i = 0; i < results.size(); i++) {
            if (!results.get(i).isSuccess()) {
                for (Database.Error err : results.get(i).getErrors()) {
                    // Log the failure — use your org's error logging pattern
                    System.debug(LoggingLevel.ERROR,
                        'Platform event publish failed for Usage ' +
                        usages.get(i).Id + ': ' + err.getMessage());
                }
            }
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
7. If the org has an `Exception_Log__e` platform event (this org does), use it for error logging:
   ```apex
   } catch (Exception e) {
       EventBus.publish(new Exception_Log__e(
           Message__c = e.getMessage(),
           Stack_Trace__c = e.getStackTraceString()
       ));
   }
   ```

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
