# Feature: Usage Tracker via Platform Event

## Summary
When a `Usage__c` record is created or updated in Salesforce, a corresponding Platform Event (`Platform_Event__e`) is published automatically. This event follows the [CloudEvents 1.0 specification](https://cloudevents.io/) and is consumed by the Dynatrace **Salesforce Insights** extension for observability and monitoring of internal Salesforce processes.

**Motivation:** Provide real-time visibility into Usage record lifecycle events without polling the database, using a standards-compliant event payload that Dynatrace can ingest natively.

---

## Metadata Components

### 1. Global Value Set

| Label | API Name | Values |
|---|---|---|
| Usage Status | `UsageStatus` | `New` (default), `Error`, `Processed` |

---

### 2. Custom Object — `Usage__c`

| Property | Value |
|---|---|
| Label | Usage |
| Plural Label | Usages |
| API Name | `Usage__c` |
| Name Field | Auto Number — format `USG-{0000}` |
| Sharing Model | ReadWrite |
| Description | Tracks product or service usage records linked to an Account and Order Product. |

#### Custom Fields

| Label | API Name | Type | Required | Notes |
|---|---|---|---|---|
| Usage Start Date | `UsageStartDate__c` | Date | Yes | Start of the usage period |
| Usage End Date | `UsageEndDate__c` | Date | No | Must be ≥ Start Date (enforced by validation rule) |
| Quantity | `Quantity__c` | Number(18, 6) | Yes | 6 decimal positions; must be > 0 |
| Account | `Account__c` | Lookup → `Account` | Yes | Relationship name: `Usages` |
| Order Product | `OrderProduct__c` | Lookup → `OrderItem` | No | Relationship name: `Usages`; delete behaviour: Don't Allow |
| Status | `Status__c` | Picklist | Yes | References global value set `UsageStatus`; default: `New` |

#### Validation Rules

| Rule Name | Formula | Error Message | Display Field |
|---|---|---|---|
| `EndDate_Must_Be_After_StartDate` | `UsageEndDate__c < UsageStartDate__c` | End Date must be on or after Start Date. | `UsageEndDate__c` |
| `Quantity_Must_Be_Positive` | `Quantity__c <= 0` | Quantity must be greater than zero. | `Quantity__c` |

#### Page Layout — `Usage__c-Usage Layout`
Sections and field order:

- **Usage Information** (2 columns): Name, Status, Account, Order Product
- **Usage Period** (2 columns): Usage Start Date, Usage End Date
- **Quantity** (1 column): Quantity
- **System Information** (2 columns): Created By, Last Modified By

#### List View — `All`
Columns: Name, Account, Status, Quantity, Usage Start Date, Usage End Date

#### Access
Create a dedicated Permission Set `Usage_Manager` granting Read + Edit object access and field-level Read + Edit on all `Usage__c` fields. Assign the Permission Set to System Administrator via the UI post-deploy.

> **Note:** Direct profile metadata edits are avoided — deploying a full profile file via DX can silently remove unrelated permissions. Permission Set is the safe, recommended approach.

---

### 3. Platform Event — `Platform_Event__e` *(canonical, unified)*

> **Note:** `Platform_Usages__e` was the original platform event for this feature. It was replaced by `Platform_Event__e` as part of the Option B canonical service refactor and **deleted from the org**. See [Refactoring Notes](#refactoring-notes-option-b-migration) below.

Follows the [CloudEvents 1.0 specification](https://cloudevents.io/) for interoperability with Dynatrace Salesforce Insights. Shared with Exception tracking — `type__c` distinguishes the source object.

| Property | Value |
|---|---|
| Label | Platform Event |
| Plural Label | Platform Events |
| API Name | `Platform_Event__e` |
| Event Type | HighVolume |
| Publish Behavior | `PublishAfterCommit` |
| Description | Unified CloudEvents-compliant platform event for SObject lifecycle observability via Dynatrace Salesforce Insights. Covers Usage__c, Exception__c, and future tracked objects. |

#### Fields

| Label | API Name | Type | Length | Notes |
|---|---|---|---|---|
| Data Content Type | `datacontenttype__c` | Text | 50 | CloudEvents: MIME type of `data__c` (e.g. `application/json`) |
| Data Schema | `dataschema__c` | Text | 255 | CloudEvents: URI identifying the schema of `data__c` |
| Event Data | `data__c` | Long Text Area | 32768 | CloudEvents: JSON-serialised snapshot of the SObject record. Truncated at 20,000 chars with `...[TRUNCATED]` suffix. |
| Event Time | `time__c` | DateTime | — | CloudEvents: timestamp of event occurrence (`System.now()`) |
| Event Type | `type__c` | Text | 255 | CloudEvents: e.g. `com.animuscrm.usage.created` / `com.animuscrm.usage.updated` |
| Parent ID | `parentid__c` | Text | 18 | Salesforce parent record ID (18 chars exact) |
| Source | `source__c` | Text | 255 | CloudEvents: URI identifying the event producer — set to `System.URL.getOrgDomainUrl().toExternalForm()` |
| Spec Version | `specversion__c` | Text | 20 | CloudEvents: always `1.0` |
| Subject | `subject__c` | Text | 255 | CloudEvents: the SObject record ID |
| Trace Flags | `traceflags__c` | Text | 8 | W3C TraceContext: 2-char hex sampling flags — set by Dynatrace |
| Trace ID | `traceid__c` | Text | 32 | W3C TraceContext: 32-char hex trace ID — set by Dynatrace |
| Trace State | `tracestate__c` | Long Text Area | 1000 | W3C TraceContext: vendor-specific trace state |
| Trace Version | `version__c` | Text | 10 | W3C TraceContext: always `00` for current spec |

---

## Apex Requirements

### Trigger — `UsageTrigger`
- Object: `Usage__c`
- Events: `after insert`, `after update`
- Pattern: Static switch-based handler — `switch on Trigger.operationType` in the trigger body; no base class or framework dependency
- Delegate to: `UsageTriggerHandler`

### Handler Class — `UsageTriggerHandler`
- Plain `public with sharing` class; no base class
- Static methods: `afterInsertHandler(List<Usage__c>)` and `afterUpdateHandler(List<Usage__c>, Map<Id,Usage__c>)`; called directly from `UsageTrigger` via `switch on Trigger.operationType`
- Calls `PlatformEventService.publishEvents((List<SObject>) records, eventType)`

### Service Class — `PlatformEventService` (canonical generic service)
- `public with sharing`
- Method: `public static void publishEvents(List<SObject> records, String eventType)`
- Publishes to `Platform_Event__e` (unified CloudEvents event shared with Exception tracking)
- Responsibilities:
  1. Build a `List<Platform_Event__e>` from the SObject list — sets CloudEvents fields generically via `rec.Id` and `JSON.serialize(rec)`
  2. Truncate `data__c` payload at 20,000 chars appending `...[TRUNCATED]` to stay within the 32,768-char LongTextArea limit
  3. Call `EventBus.publish(events)` once (never inside a loop)
  4. Check each `Database.SaveResult` — log failures via `Exception_Log__e` platform event
  5. Wrap in `try/catch(Exception e)` — publish to `Exception_Log__e` on unexpected failure

### Deleted — `UsageEventService`
- Was retained as a compatibility shim delegating to `PlatformEventService`
- Deleted after test scenarios migrated to `PlatformEventServiceTest`

### Error Handling
- Use the existing `Exception_Log__e` platform event already in this org for all error logging
- Never throw unhandled exceptions from the trigger context
- Failed publish results must be logged with the `Usage__c` record ID and error message

---

## Acceptance Criteria

### AC-1: Usage record created → event published
- Given a `Usage__c` record is inserted with valid fields
- When the transaction commits
- Then exactly one `Platform_Event__e` event is published with `type__c = 'com.animuscrm.usage.created'`
- And `subject__c` equals the new record's 18-char ID
- And `specversion__c = '1.0'`
- And `time__c` is populated with the current timestamp

### AC-2: Usage record updated → event published
- Given an existing `Usage__c` record is updated
- When the transaction commits
- Then exactly one `Platform_Event__e` event is published with `type__c = 'com.animuscrm.usage.updated'`
- And `subject__c` equals the updated record's ID

### AC-3: Bulk — 200 records
- Given 200 `Usage__c` records are inserted in a single transaction
- Then 200 `Platform_Event__e` events are published in a single `EventBus.publish()` call
- And no governor limit exception is thrown

### AC-4: Publish failure is logged, not re-thrown
- Given `EventBus.publish()` returns a failed `SaveResult` for one or more events
- Then the failure is logged to `Exception_Log__e` with the affected record ID and error message
- And the transaction is not rolled back
- And no unhandled exception surfaces to the user

### AC-5: Validation rules enforced
- Given a `Usage__c` record is saved with `UsageEndDate__c` before `UsageStartDate__c`
- Then a validation error is shown on the `UsageEndDate__c` field
- Given a `Usage__c` record is saved with `Quantity__c <= 0`
- Then a validation error is shown on the `Quantity__c` field

### AC-6: Access control
- Given a user assigned the `Usage_Manager` Permission Set
- Then they can create, read, edit, and delete `Usage__c` records and see all fields

### AC-7: Test coverage ≥ 90%
- `UsageTrigger`, `UsageTriggerHandler`, and `PlatformEventService` each have ≥ 90% Apex code coverage
- Test class covers: insert, update, bulk (200), publish failure simulation

---

## Out of Scope

- Subscribing to `Platform_Event__e` in Apex, Flow, or any other Salesforce component — consumption is handled entirely by Dynatrace externally
- Deletion of `Usage__c` records does not publish an event
- Replaying or reprocessing past platform events
- Custom UI (LWC or Visualforce) for the `Usage__c` object — standard Salesforce layouts only
- Data migration or backfilling of historical Usage records as events
- Integration with any system other than Dynatrace Salesforce Insights
- Assigning the `Usage_Manager` Permission Set to any profile other than System Administrator
- Direct editing of profile metadata files (e.g. `Admin.profile-meta.xml`) — use Permission Sets only
- Workflow rules, Process Builder, or Flow automation on `Usage__c`
- Reporting or dashboards on `Usage__c` data

---

## Refactoring Notes (Option B Migration)

The original implementation used `UsageEventService` publishing to `Platform_Usages__e`. As of the Option B canonical service refactor:

- `UsageTriggerHandler` now calls `PlatformEventService.publishEvents((List<SObject>) records, eventType)`.
- Events are published to `Platform_Event__e` (unified CloudEvents event) instead of `Platform_Usages__e`.
- `UsageEventService` has been deleted; `UsageEventServiceTest` migrated into `PlatformEventServiceTest`.
- `Platform_Usages__e` has been **deleted from the org** via `destructiveChanges.xml`.
- **Dynatrace action required:** Update the Streaming API subscription from `/event/Platform_Usages__e/` to `/event/Platform_Event__e/`. Filter on `type__c` values `com.animuscrm.usage.created` and `com.animuscrm.usage.updated`.
