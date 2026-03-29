---
name: salesforce-admin
description: Declarative metadata skills for animuscrm — custom objects, fields, platform events, global value sets, validation rules, page layouts, list views, and profile/permission set FLS.
---

# Salesforce Admin Skill — animuscrm

Covers declarative metadata creation: custom objects, custom fields, platform events, validation rules, page layouts, and field-level security.

---

## skill: create-custom-object

**Trigger phrase:** "create a custom object" / "new object"

### Pre-Creation Checklist (confirm before writing any file)
- Is the object truly custom, or can a standard object be extended?
- What is the sharing model? (default: ReadWrite)
- What should the Name field be? (Text label or AutoNumber)
- Which profiles/permission sets need access?
- Which page layouts will include this object?

### Steps
1. Create `force-app/main/default/objects/<Name__c>/` folder
2. Create `<Name__c>.object-meta.xml` with:
   - `deploymentStatus`: Deployed
   - `sharingModel`: ReadWrite (unless specified otherwise)
   - `label`, `pluralLabel`
   - `nameField` (Text or AutoNumber as appropriate)
   - `description` — always required
3. Create `fields/` subfolder
4. Add `Description__c` (LongTextArea, 32768 chars) by default
5. Create `.field-meta.xml` for each requested field (see create-custom-field skill)
6. Naming conventions: PascalCase + `__c` suffix (e.g. `SalesOrder__c`)
7. Deploy command:
   ```
   sf project deploy start --metadata CustomObject:<Name__c> --target-org dev-org
   ```

---

## skill: create-custom-field

**Trigger phrase:** "add a field" / "new field on"

### Pre-Creation Checklist
- Is the field type appropriate for the data? (Text vs LongTextArea vs Number vs Picklist)
- Should it be required?
- For Lookup: what is the relationship name? What happens on delete (restrict vs cascade)?
- For Picklist: what are the values? Is there a global picklist to reuse?
- Which profiles/permission sets need Read or Edit access?
- Which page layout section should it appear in?

### Field Type Reference
| Requested | Salesforce XML type |
|-----------|-------------------|
| Text (≤255) | Text |
| Long text / rich text | LongTextArea / Html |
| Number / decimal | Number |
| Currency | Currency |
| Percent | Percent |
| Date | Date |
| Date + Time | DateTime |
| True/False | Checkbox |
| Lookup | Lookup |
| Master-Detail | MasterDetail |
| Dropdown | Picklist |
| Multi-select | MultiselectPicklist |
| Email | Email |
| Phone | Phone |
| URL | Url |
| Auto-increment | AutoNumber |
| Calculated | Formula |

### Steps
1. Create `force-app/main/default/objects/<ObjectName__c>/fields/<FieldName__c>.field-meta.xml`
2. Always include: `label`, `description`, `required` (false by default), `trackHistory` (false by default)
3. For Lookup: include `referenceTo` and `relationshipName`
4. For Picklist: include `valueSet` with all values; mark first as default
5. For Formula: include `formula` and `returnType`
6. Naming: PascalCase + `__c` (e.g. `TotalAmount__c`)
7. Deploy command:
   ```
   sf project deploy start --metadata CustomField:<ObjectName__c>.<FieldName__c> --target-org dev-org
   ```

---

## skill: create-platform-event

**Trigger phrase:** "create a platform event" / "new platform event"

### Pre-Creation Checklist
- Volume type: StandardVolume (default) or HighVolume (>100k events/day)?
- Publish behavior: PublishAfterCommit (default) or PublishImmediately?
- What are the payload fields and their types?
- Note: Lookup, MasterDetail, and Formula fields are NOT supported on platform events

### Steps
1. Create `force-app/main/default/objects/<Name__e>/` folder
2. Create `<Name__e>.object-meta.xml` with:
   - `eventType`: StandardVolume (or HighVolume if specified)
   - `publishBehavior`: PublishAfterCommit (or PublishImmediately if specified)
   - `label`, `pluralLabel`, `description`
   - `deploymentStatus`: Deployed
3. Create `fields/` subfolder with `.field-meta.xml` for each payload field
4. Naming: PascalCase + `__e` suffix (e.g. `OrderPlaced__e`)
5. Deploy command:
   ```
   sf project deploy start --metadata CustomObject:<Name__e> --target-org dev-org
   ```

---

## skill: create-validation-rule

**Trigger phrase:** "create a validation rule" / "add a validation rule"

### Steps
1. Create `force-app/main/default/objects/<ObjectName__c>/validationRules/<RuleName>.validationRule-meta.xml`
2. Include: `active` (true), `description`, `errorConditionFormula`, `errorMessage`
3. Include `errorDisplayField` if the error should highlight a specific field
4. Formula returns `true` when the record is **invalid** (i.e. when the error fires)
5. Rule names: Descriptive_Snake_Case (e.g. `Amount_Cannot_Be_Negative`)
6. Deploy command:
   ```
   sf project deploy start --metadata ValidationRule:<ObjectName__c>.<RuleName> --target-org dev-org
   ```

---

## skill: create-global-value-set

**Trigger phrase:** "create a global picklist" / "global value set" / "shared picklist"

Use this when a picklist field should share values with other objects (e.g. a `Status` field reused across multiple objects).

### Steps
1. Create `force-app/main/default/globalValueSets/<ValueSetName>.globalValueSet-meta.xml`
2. XML structure:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <GlobalValueSet xmlns="http://soap.sforce.com/2006/04/metadata">
       <customValue>
           <fullName>Value1</fullName>
           <default>true</default>
           <label>Value1</label>
       </customValue>
       <customValue>
           <fullName>Value2</fullName>
           <default>false</default>
           <label>Value2</label>
       </customValue>
       <description>Description of what this value set is used for</description>
       <masterLabel>Value Set Label</masterLabel>
       <sorted>false</sorted>
   </GlobalValueSet>
   ```
3. To reference it in a field (instead of inline values), use `valueSetName` in the field-meta.xml:
   ```xml
   <valueSet>
       <restricted>true</restricted>
       <valueSetName>GlobalValueSetAPIName</valueSetName>
   </valueSet>
   ```
4. Naming: PascalCase, no suffix (e.g. `UsageStatus`, `OrderStatus`)
5. Add `GlobalValueSet` entry to `manifest/package.xml`
6. Deploy command:
   ```
   sf project deploy start --metadata GlobalValueSet:<ValueSetName> --target-org dev-org
   ```

---

## skill: create-page-layout

**Trigger phrase:** "add to page layout" / "create page layout" / "update layout"

### Steps
1. File path: `force-app/main/default/objects/<ObjectName__c>/layouts/<ObjectName__c>-<LayoutName>.layout-meta.xml`
   - Default layout name is typically `<ObjectName__c> Layout`
   - Example: `Usage__c-Usage Layout.layout-meta.xml`
2. Key XML structure:
   - `<layoutSections>` — group fields into sections with 1 or 2 columns
   - `<layoutColumns>` → `<layoutItems>` — each item is a field, blank, or separator
   - Required fields must appear in the layout
   - Use `<behavior>Edit</behavior>` for editable fields, `<behavior>Readonly</behavior>` for read-only
3. Always include the Name field in the first section
4. Group related fields together (dates together, lookups together, etc.)
5. Add `Layout` entry to `manifest/package.xml`
6. Deploy command:
   ```
   sf project deploy start --metadata Layout:"<ObjectName__c>-<LayoutName>" --target-org dev-org
   ```

---

## skill: create-list-view

**Trigger phrase:** "create a list view" / "add list view" / "default list view"

### Steps
1. File path: `force-app/main/default/objects/<ObjectName__c>/listViews/<ListViewName>.listView-meta.xml`
   - Standard names: `All` (all records), `Recent` (recently viewed)
2. Key XML structure:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <ListView xmlns="http://soap.sforce.com/2006/04/metadata">
       <fullName>All</fullName>
       <columns>NAME</columns>
       <columns>Field1__c</columns>
       <columns>Field2__c</columns>
       <filterScope>Everything</filterScope>
       <label>All</label>
   </ListView>
   ```
3. `<filterScope>` options: `Everything`, `Mine`, `Queue`, `Delegated`, `MyTerritory`
4. To add filter criteria, include `<filters>` with `<field>`, `<operation>`, `<value>`
5. Always create at least the `All` list view for new custom objects
6. Add `ListView` entry to `manifest/package.xml`
7. Deploy command:
   ```
   sf project deploy start --metadata ListView:<ObjectName__c>.<ListViewName> --target-org dev-org
   ```

---

## skill: grant-profile-fls-access

**Trigger phrase:** "grant access to profile" / "add FLS to profile" / "grant System Administrator access"

### Important
Never edit a full profile file — they are enormous and org-specific. Use **Permission Sets** for new access grants wherever possible. Only edit a profile file when the spec explicitly requires it (e.g. System Administrator access to a new object).

### Steps for Permission Set (preferred)
1. File path: `force-app/main/default/permissionsets/<Name>.permissionset-meta.xml`
2. Add `<objectPermissions>` block for the object:
   ```xml
   <objectPermissions>
       <allowCreate>true</allowCreate>
       <allowDelete>true</allowDelete>
       <allowEdit>true</allowEdit>
       <allowRead>true</allowRead>
       <modifyAllRecords>false</modifyAllRecords>
       <object>Usage__c</object>
       <viewAllRecords>false</viewAllRecords>
   </objectPermissions>
   ```
3. Add `<fieldPermissions>` block for each field that needs access:
   ```xml
   <fieldPermissions>
       <editable>true</editable>
       <field>Usage__c.Status__c</field>
       <readable>true</readable>
   </fieldPermissions>
   ```
4. Deploy command:
   ```
   sf project deploy start --metadata PermissionSet:<Name> --target-org dev-org
   ```

### Steps for Profile (only when explicitly required)
1. Retrieve the profile first — never edit from scratch:
   ```
   sf project retrieve start --metadata Profile:Admin --target-org dev-org
   ```
2. Add `<objectPermissions>` and `<fieldPermissions>` entries (same structure as above)
3. Deploy command:
   ```
   sf project deploy start --metadata Profile:Admin --target-org dev-org
   ```

### Post-Grant Verification
- Confirm the object appears in the App Launcher or navigation for the target profile
- Confirm each field is visible and editable as expected
- Confirm the list view is accessible

---

## Post-Creation Verification
- Confirm global value sets are deployed before any field that references them
- Confirm field-level security is set for all relevant profiles/permission sets
- Confirm field is added to the correct page layout and section
- Confirm a list view exists for every new custom object
- For picklists: confirm all required values are present
- For lookups: confirm relationship name does not conflict with existing relationships
- For platform events: confirm publishBehavior matches the use case (transactional vs fire-and-forget)
