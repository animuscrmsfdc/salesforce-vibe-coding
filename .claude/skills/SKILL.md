# Salesforce Development Skills

This file defines reusable skill definitions for the animuscrm project.
Reference these when asking Claude to perform structured, repeatable tasks.

---

## skill: create-custom-object

**Trigger phrase:** "create a custom object" / "new object"

**Steps:**
1. Create `force-app/main/default/objects/<Name__c>/` folder
2. Create `<Name__c>.object-meta.xml` with sharingModel, nameField, label, pluralLabel, description, deploymentStatus: Deployed
3. Create `fields/` subfolder
4. Add `Description__c` LongTextArea field by default
5. Create field meta files for each requested field
6. Output deploy command: `sf project deploy start --metadata CustomObject:<Name__c> --target-org dev-org`

---

## skill: create-platform-event

**Trigger phrase:** "create a platform event" / "new platform event"

**Steps:**
1. Create `force-app/main/default/objects/<Name__e>/` folder
2. Create `<Name__e>.object-meta.xml` with eventType, publishBehavior, label, description, deploymentStatus: Deployed
3. Create `fields/` subfolder with payload field meta files
4. Output deploy command: `sf project deploy start --metadata CustomObject:<Name__e> --target-org dev-org`

---

## skill: create-apex-trigger-with-handler

**Trigger phrase:** "create a trigger" / "new trigger for"

**Steps:**
1. Check if a trigger for this object already exists — warn if so
2. Create `force-app/main/default/triggers/<Object>Trigger.trigger` — delegate only, no logic in the trigger body
3. Create `<Object>Trigger.trigger-meta.xml`
4. Create `force-app/main/default/classes/<Object>TriggerHandler.cls` — with sharing, separate methods per event, recursion guard
5. Create `<Object>TriggerHandler.cls-meta.xml`
6. Output deploy command for both components

---

## skill: enforce-security

**Trigger phrase:** "add security to" / "secure this class"

**Steps:**
1. Read the target Apex class
2. Add `WITH SECURITY_ENFORCED` to all SOQL queries in `@AuraEnabled` methods, OR use `Security.stripInaccessible(AccessType.READABLE, results)` before returning
3. Check all DML operations — add `isCreateable()` / `isUpdateable()` / `isDeletable()` guards as appropriate
4. Confirm class uses `with sharing`
5. Report any remaining issues

---

## skill: write-test-class

**Trigger phrase:** "write tests for" / "add test coverage for"

**Steps:**
1. Read the target class fully
2. Identify all methods and branches
3. Create `<ClassName>Test.cls` with `@TestSetup`, bulk test (200 records), positive, negative, and boundary scenarios
4. Achieve 90%+ coverage target
5. Output run command: `sf apex run test --class-names <ClassName>Test --target-org dev-org --code-coverage --result-format human --wait 10`

---

## skill: deploy-and-verify

**Trigger phrase:** "deploy" / "push to org"

**Steps:**
1. Run `sf project deploy start` with appropriate `--metadata` or `--source-dir` flags targeting `dev-org`
2. Check exit code — if non-zero, read errors and fix
3. Run `sf project deploy report` to confirm success
4. If tests were affected, suggest running `/run-tests`
