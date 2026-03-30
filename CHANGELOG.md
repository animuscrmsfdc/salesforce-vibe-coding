# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [0.2.0] - 2026-03-30

### Added
- `Usage__c` custom object with fields: `Account__c` (required lookup), `OrderProduct__c`, `Quantity__c`, `UsageStartDate__c`, `UsageEndDate__c`, `Status__c` (restricted picklist: New, Error, Processed)
- `Platform_Usages__e` HighVolume platform event with 13 CloudEvents 1.0 fields (`specversion__c`, `type__c`, `source__c`, `subject__c`, `time__c`, `datacontenttype__c`, `data__c`, `dataschema__c`, `parentid__c`, `traceid__c`, `tracestate__c`, `traceflags__c`, `version__c`)
- `UsageTrigger` — after insert/after update trigger on `Usage__c`
- `UsageTriggerHandler` — static switch-based handler following project trigger pattern
- `UsageEventService` — bulk-safe service class; publishes `Platform_Usages__e` CloudEvents on insert and update; errors logged to `Exception_Log__e`
- `UsageEventServiceTest` — Apex test class with ≥90% code coverage
- `Usage__c-Usage Layout` — two-column page layout covering all fields
- `Usage_Manager` permission set — grants CRUD on `Usage__c` with FLS for non-required fields
- `UsageStatus` global value set backing the `Status__c` picklist
- Validation rules: `EndDate_Must_Be_After_StartDate`, `Quantity_Must_Be_Positive`
- `specs/usage-tracker.md` — feature spec with acceptance criteria

### Changed
- `manifest/package.xml` — added `GlobalValueSet` and `Layout` metadata types

---

## [0.1.0] - 2026-03-28

### Added
- Initial metadata retrieval from AnimusCRM Salesforce Developer org
- 30 custom objects including: `Person__c`, `Location__c`, `Location_Tracing__c`, `People_Tracing__c`, `Project__c`, `Session__c`, `Speaker__c`, `Hotel__c`, `House__c`, `Bear__c`, `Camping_Item__c`, `Campsite__c`, `Employee__c`, `Fundraiser__c`, `Expense__c`
- 3 platform event objects: `Exception_Log__e`, `Notification__e`, `Order_Event__e`
- 4 custom metadata types: `Feature_Flag__mdt`, `Finance_Setting__mdt`, `Flow_Error_Email__mdt`, `GraphicsPackSettings__mdt`
- 1 external object: `Phone_Plan__x`
- 140 Apex classes covering controllers, trigger handlers, service classes, batch jobs, REST resources, and test classes
- 10 Apex triggers across core objects
- 21 LWC components
- Project tooling: ESLint, Prettier, Jest, Husky pre-commit hooks
- Claude Code configuration: `CLAUDE.md`, `.claude/settings.json`, custom slash commands, agents, and skills

### Security
- Identified SOQL injection risks in `CTPersonController` and `CTLocationController` (pending fix)
- Identified null pointer and sensitive field exposure in `ApexSecurityRest` REST endpoint (pending fix)
- Identified MD5 token generation in `CTPersonController.getToken()` — should be upgraded to SHA-256 (pending fix)
- Identified missing FLS/CRUD enforcement across multiple `@AuraEnabled` controllers (pending fix)
- Identified hardcoded portal account ID in `SiteRegisterController` (pending fix)
