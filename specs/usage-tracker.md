# Feature: Usage Tracker via Platform Event

## Summary
When a `Usage__c` record is created or updated in Salesforce, a corresponding Platform Event (`Platform_Usages__e`) is published automatically. This event follows the [CloudEvents 1.0 specification](https://cloudevents.io/) and is consumed by the Dynatrace **Salesforce Insights** extension for observability and monitoring of internal Salesforce processes.

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

### 3. Platform Event — `Platform_Usages__e`

Follows the [CloudEvents 1.0 specification](https://cloudevents.io/) for interoperability with Dynatrace Salesforce Insights.

| Property | Value |
|---|---|
| Label | Platform Usages |
| Plural Label | Platform Usages |
| API Name | `Platform_Usages__e` |
| Event Type | HighVolume |
| Publish Behavior | `PublishAfterCommit` |
| Description | CloudEvents-compliant platform event for Usage record lifecycle observability via Dynatrace Salesforce Insights. HighVolume chosen to match org pattern and avoid StandardVolume daily limits. |

#### Fields

| Label | API Name | Type | Length | Notes |
|---|---|---|---|---|
| Data Content Type | `datacontenttype__c` | Text | 50 | CloudEvents: MIME type of `data__c` (e.g. `application/json`) |
| Data Schema | `dataschema__c` | Text | 255 | CloudEvents: URI identifying the schema of `data__c` |
| Event Data | `data__c` | Long Text Area | 32768 | CloudEvents: JSON-serialised snapshot of the full `Usage__c` record (`JSON.serialize(usage)`). Not a field-by-field mapping — the CloudEvents envelope fields (`type__c`, `subject__c`, etc.) carry the metadata; `data__c` carries the payload. |
| Event Time | `time__c` | DateTime | — | CloudEvents: timestamp of event occurrence (`System.now()`) |
| Event Type | `type__c` | Text | 255 | CloudEvents: e.g. `com.animuscrm.usage.created` / `com.animuscrm.usage.updated` |
| Parent ID | `parentid__c` | Text | 18 | ⚠️ Increased from 255 → 18 (Salesforce IDs are exactly 18 chars) |
| Source | `source__c` | Text | 255 | CloudEvents: URI identifying the event producer (e.g. Salesforce org URL) |
| Spec Version | `specversion__c` | Text | 20 | CloudEvents: always `1.0` |
| Subject | `subject__c` | Text | 255 | CloudEvents: the Usage record ID (`Usage__c.Id`) |
| Trace Flags | `traceflags__c` | Text | 8 | W3C TraceContext: 2-char hex sampling flags (e.g. `01`) — ⚠️ increased from 8 → sufficient; confirm with Dynatrace spec |
| Trace ID | `traceid__c` | Text | 32 | ⚠️ Increased from 255 → 32 (W3C TraceContext trace-id is exactly 32 hex chars) |
| Trace State | `tracestate__c` | Long Text Area | 1000 | W3C TraceContext: vendor-specific trace state |
| Trace Version | `version__c` | Text | 10 | W3C TraceContext: always `00` for current spec |

> **Field size improvements applied:** `parentid__c` reduced to 18 chars (exact Salesforce ID length), `traceid__c` reduced to 32 chars (exact W3C trace-id length). These save storage and prevent accidental garbage values. Confirm `traceflags__c` length with Dynatrace if values longer than 2 chars are expected.

---

## Apex Requirements

### Trigger — `UsageTrigger`
- Object: `Usage__c`
- Events: `after insert`, `after update`
- Pattern: Kevin O'Hara TriggerHandler framework — no business logic in the trigger body
- Delegate to: `UsageTriggerHandler`

### Handler Class — `UsageTriggerHandler`
- Extends `TriggerHandler`
- Overrides `afterInsert()` and `afterUpdate()`
- Calls `UsageEventService.publishEvents(List<Usage__c>)`

### Service Class — `UsageEventService`
- `public with sharing`
- Method: `public static void publishEvents(List<Usage__c> usages)`
- Responsibilities:
  1. Build a `List<Platform_Usages__e>` mapping fields from `Usage__c` to `Platform_Usages__e` by API name where they match
  2. Set CloudEvents mandatory fields: `specversion__c = '1.0'`, `time__c = System.now()`, `subject__c = usage.Id`, `type__c` based on trigger context (created vs updated)
  3. Call `EventBus.publish(events)` once (never inside a loop)
  4. Check each `Database.SaveResult` — log failures via `Exception_Log__e` platform event
  5. Wrap in `try/catch(Exception e)` — publish to `Exception_Log__e` on unexpected failure

### Error Handling
- Use the existing `Exception_Log__e` platform event already in this org for all error logging
- Never throw unhandled exceptions from the trigger context
- Failed publish results must be logged with the `Usage__c` record ID and error message

---

## Acceptance Criteria

### AC-1: Usage record created → event published
- Given a `Usage__c` record is inserted with valid fields
- When the transaction commits
- Then exactly one `Platform_Usages__e` event is published with `type__c = 'com.animuscrm.usage.created'`
- And `subject__c` equals the new record's 18-char ID
- And `specversion__c = '1.0'`
- And `time__c` is populated with the current timestamp

### AC-2: Usage record updated → event published
- Given an existing `Usage__c` record is updated
- When the transaction commits
- Then exactly one `Platform_Usages__e` event is published with `type__c = 'com.animuscrm.usage.updated'`
- And `subject__c` equals the updated record's ID

### AC-3: Bulk — 200 records
- Given 200 `Usage__c` records are inserted in a single transaction
- Then 200 `Platform_Usages__e` events are published in a single `EventBus.publish()` call
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
- `UsageTrigger`, `UsageTriggerHandler`, and `UsageEventService` each have ≥ 90% Apex code coverage
- Test class covers: insert, update, bulk (200), publish failure simulation

---

## Out of Scope

- Subscribing to `Platform_Usages__e` in Apex, Flow, or any other Salesforce component — consumption is handled entirely by Dynatrace externally
- Deletion of `Usage__c` records does not publish an event
- Replaying or reprocessing past platform events
- Custom UI (LWC or Visualforce) for the `Usage__c` object — standard Salesforce layouts only
- Data migration or backfilling of historical Usage records as events
- Integration with any system other than Dynatrace Salesforce Insights
- Assigning the `Usage_Manager` Permission Set to any profile other than System Administrator
- Direct editing of profile metadata files (e.g. `Admin.profile-meta.xml`) — use Permission Sets only
- Workflow rules, Process Builder, or Flow automation on `Usage__c`
- Reporting or dashboards on `Usage__c` data
