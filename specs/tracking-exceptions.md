# Feature: Tracking Exceptions

## Summary
When an Apex class or Flow fails, an `Exception__c` record is created automatically. This feature ensures that every new `Exception__c` record triggers the publication of a CloudEvents-compliant, HighVolume platform event (`Platform_Exceptions__e`) for lifecycle observability via Dynatrace Salesforce Insights.

**Motivation:** The business team needs exception and error data surfaced in Dynatrace in real time. Without this feature, failures captured in `Exception__c` are invisible outside Salesforce, making root-cause analysis and SLA monitoring impossible.

---

## Personas & Access

| Persona / Profile | Access Level | Notes |
|---|---|---|
| System Administrator | Read / Write | Full access to `Exception__c` and `Platform_Exceptions__e` |
| Exception Tracker (new permission set) | Read / Write on `Exception__c` | Grants access to users outside Sys Admin profile who need visibility |

---

## Functional Requirements

### User Journey
1. A Flow or Apex class fails during execution.
2. The calling code (Flow fault path or Apex `catch` block) creates an `Exception__c` record with relevant fields populated (`Exception_Details__c`, `Record_Id__c`, `Object__c`, `Operation__c`).
3. The `Exception__c` after-insert trigger fires.
4. The trigger handler delegates to `ExceptionEventService.publishEvents()`.
5. The service builds one `Platform_Exceptions__e` event per `Exception__c` record, populating all CloudEvents and W3C TraceContext fields.
6. All events are published in a single `EventBus.publish()` call (`PublishAfterCommit`).
7. Dynatrace Salesforce Insights consumes the platform event and ingests the exception data.

### Alternative Flows
- **Bulk insert:** Up to 200 (or more) `Exception__c` records inserted in a single transaction — all events must be collected and published in one `EventBus.publish()` call.
- **`EventBus.publish()` failure:** Individual publish errors are logged via `Exception_Log__e`; the trigger does not re-throw so the originating DML is not rolled back.
- **Empty or null list:** `ExceptionEventService` returns early with no DML or publish calls.

### Salesforce Objects & Data Model

| Object | Operation | Notes |
|---|---|---|
| `Exception__c` | Read (after insert) | Source of truth; trigger fires on insert only |
| `Platform_Exceptions__e` | Create | New HighVolume platform event; CloudEvents-compliant; mirrors `Platform_Usages__e` field structure |
| `Exception_Log__e` | Create | Existing platform event; used to log publish failures — never swallowed silently |

### Integrations
- **Dynatrace Salesforce Insights** — consumes `Platform_Exceptions__e` via Salesforce Streaming API / CometD subscription for real-time observability.

---

## Business Rules & Validation

| Rule | Condition | Error Message | Field |
|---|---|---|---|
| — | No business validation rules required | — | — |

---

## Technical Requirements

- **API Version:** 66.0
- **Apex:**
  - `ExceptionTriggerHandler` — static `afterInsertHandler(List<Exception__c>)` method; delegates to service
  - `ExceptionEventService` — static `publishEvents(List<Exception__c>, String eventType)` method; bulk-safe; logs errors via `Exception_Log__e`
- **Triggers:**
  - `ExceptionTrigger` — one trigger on `Exception__c`; after insert only; delegates to `ExceptionTriggerHandler`
- **Metadata:**
  - `Platform_Exceptions__e` — new HighVolume platform event; `PublishAfterCommit`; 13 custom fields mirroring `Platform_Usages__e` (see field list below)
  - `Exception_Tracker` permission set — grants CRUD on `Exception__c` and Read on `Platform_Exceptions__e`
- **Patterns:** Trigger → Handler → Service (same pattern as `UsageTrigger` / `UsageTriggerHandler` / `UsageEventService`)
- **Bulkification:** Must handle 200+ records per transaction; all events collected before single `EventBus.publish()` call
- **CloudEvents fields on `Platform_Exceptions__e`** (mirror `Platform_Usages__e`):
  `specversion__c`, `type__c`, `source__c`, `subject__c`, `time__c`, `datacontenttype__c`, `data__c`, `dataschema__c`, `parentid__c`, `traceid__c`, `traceflags__c`, `tracestate__c`, `version__c`
- **Event type value:** `com.animuscrm.exception.created`

---

## Security Requirements

- **Sharing model:** `with sharing` on `ExceptionEventService` and `ExceptionTriggerHandler`
- **FLS enforcement:** No `@AuraEnabled` or REST methods in this feature — FLS enforcement via trigger context is sufficient
- **Input validation:** No user-supplied inputs at system boundaries; `Exception__c` records are created programmatically by trusted Apex/Flow
- No hardcoded IDs — use Custom Metadata or Custom Labels if org-specific values are needed
- Crypto: not applicable to this feature
- `Exception_Log__e` must never be published with raw stack traces exposed in user-facing messages (internal logging only)

---

## Compliance Requirements

- No specific compliance requirements identified.
- **Audit trail:** `Exception__c` records serve as the durable audit trail; `Platform_Exceptions__e` is the real-time signal (HighVolume events are not stored in Salesforce).

---

## Acceptance Criteria

### AC-1: Platform event published on single insert
- Given one `Exception__c` record is inserted
- When the after-insert trigger fires
- Then exactly one `Platform_Exceptions__e` event is published with `type__c = 'com.animuscrm.exception.created'`, `subject__c` = the `Exception__c` Id, and `data__c` containing the JSON-serialised record

### AC-2: Platform event published on bulk insert
- Given 200 `Exception__c` records are inserted in a single transaction
- When the after-insert trigger fires
- Then exactly 200 `Platform_Exceptions__e` events are published in a single `EventBus.publish()` call (not inside a loop)

### AC-3: Publish failure is logged, not re-thrown
- Given `EventBus.publish()` returns a failure result for one or more events
- When the service processes the results
- Then each failure is logged via `Exception_Log__e` and the transaction is not rolled back

### AC-4: Empty list is handled gracefully
- Given `ExceptionEventService.publishEvents()` is called with a null or empty list
- When the method executes
- Then no DML or `EventBus.publish()` calls are made and no exception is thrown

### AC-5: CloudEvents envelope fields are populated
- Given a `Platform_Exceptions__e` event is published
- When inspected
- Then `specversion__c = '1.0'`, `source__c` equals the org domain URL, `datacontenttype__c = 'application/json'`, and `time__c` is set to publish time

### AC-6: Permission set grants correct access
- Given a user assigned the `Exception_Tracker` permission set (non-Sys Admin)
- When they attempt to create an `Exception__c` record
- Then the record is created successfully and the platform event fires

### AC-N: Test Coverage ≥ 90%
- All Apex classes and triggers for this feature must have ≥ 90% code coverage.
- Test class covers: happy path (single record), bulk (200 records), null/empty input, `EventBus.publish()` failure path, `runAs` a user with `Exception_Tracker` permission set only.

---

## Out of Scope

- Mechanism by which `Exception__c` records are created (Flow fault paths, Apex catch blocks) — this is pre-existing behaviour.
- Consuming or processing `Platform_Exceptions__e` within Salesforce (e.g. via a trigger or Flow on the event) — Dynatrace is the consumer.
- UI changes to the `Exception__c` record page.
- Refactoring `UsageEventService` / `UsageTriggerHandler` into a shared generic service — see open question below.

---

## Analyst Additions

> The following requirements were not explicitly stated by the user but are necessary for a complete, production-safe implementation on the animuscrm Salesforce platform.

### Error Handling & Logging
- `ExceptionEventService` must wrap `EventBus.publish()` in `try/catch(Exception e)`.
- Failures must be logged via `Exception_Log__e` (already in this org) — never swallowed silently.
- The service must never throw; throwing inside an after-insert trigger handler rolls back the originating DML and could cause an infinite loop if the catch block re-inserts an `Exception__c`.
- Raw stack traces must not be surfaced to end users; they go to `Exception_Log__e.Exception_Details__c` only.

### Bulkification
- All events must be collected in a `List<Platform_Exceptions__e>` before the single `EventBus.publish()` call.
- `EventBus.publish()` must never be called inside a `for` loop.
- Trigger handler must use `Trigger.new` collections; no SOQL inside the trigger or handler.

### Governor Limit Considerations
- **`EventBus.publish()` limit:** 150 `EventBus.publish()` calls per transaction. This feature uses one call per transaction — no risk even at high volume.
- **Platform event message size:** `data__c` is a LongTextArea (32,768 chars). `JSON.serialize(exception__c)` on a record with large `Exception_Details__c` could approach this limit. Consider truncating `Exception_Details__c` to a safe length (e.g. 10,000 chars) before serialising.
- **DML rows limit (10,000):** If the `Exception_Log__e` fallback fires for every failed event in a 200-record bulk insert, this could generate up to 200 additional `EventBus.publish()` calls in the error loop — refactor the `logError` path to batch errors into a single `Exception_Log__e` publish where possible.

### Test Data Strategy
- Use `@TestSetup` for all shared test data — no data creation in individual test methods.
- Never use `@IsTest(SeeAllData=true)`.
- Minimum test scenarios: happy path (1 record), bulk (200 records), null input, `EventBus.publish()` failure (mock via `Test.startTest()` / `Test.stopTest()`), `runAs` user with `Exception_Tracker` permission set only.
- Use `Test.getEventBus().deliver()` to validate event publication in unit tests.

### Deployment Order
1. Deploy `Platform_Exceptions__e` object and all 13 fields.
2. Deploy `ExceptionEventService` and `ExceptionTriggerHandler` Apex classes.
3. Deploy `ExceptionTrigger`.
4. Deploy `Exception_Tracker` permission set.
5. **Manual post-deploy:** Assign `Exception_Tracker` permission set to relevant non-Sys-Admin users.

### Architecture Decision: Dedicated vs. Canonical Generic Service

**Option A — Dedicated classes (recommended for this iteration)**
- New `ExceptionTriggerHandler`, `ExceptionEventService`, `Platform_Exceptions__e` following the exact same pattern as `UsageTriggerHandler` / `UsageEventService` / `Platform_Usages__e`.
- **Pros:** Zero risk to existing Usage tracking; independently deployable and testable; follows the established pattern with no refactoring.
- **Cons:** Code duplication; as more objects are onboarded (e.g. `Lead__c`, `Contact`) the pattern will need to be repeated each time.

**Option B — Canonical generic service (future iteration)**
- Refactor `UsageEventService` into a generic `SObjectEventService` that accepts any `SObject` list + event type string, and publish to a single unified `Platform_Event__e` object.
- **Pros:** Single point of maintenance; no duplication; easier to add new objects.
- **Cons:** Requires refactoring existing tested production code; the unified platform event schema must be generic enough for all objects (losing object-specific field typing); Dynatrace subscription configuration must change; higher delivery risk.

**Recommendation:** Implement Option A now. Open a separate technical debt story for the Option B canonicalization once both Usage and Exception patterns are stable and Dynatrace integration is validated end-to-end.

### Gaps & Open Questions

| # | Question | Owner | Status |
|---|---|---|---|
| 1 | Should `Platform_Exceptions__e` include all 13 fields from `Platform_Usages__e` (incl. W3C TraceContext fields `traceid__c`, `traceflags__c`, `tracestate__c`, `version__c`)? Or are TraceContext fields only populated by Dynatrace and can be omitted from the Apex service? | David / Dynatrace team | Open |
| 2 | `ExceptionEventService` must truncate `Exception_Details__c` to **20,000 chars** before serialising to `data__c`. JSON escape expansion (up to 1.5×) on stack traces means the full 32,768-char value can overflow the 32,768-char `data__c` field. Append `...[TRUNCATED]` when truncation occurs. | David | Resolved |
| 3 | Is `Exception__c` after-update also in scope (e.g. if an exception record is enriched later)? The interview confirmed after-insert only — confirm this is correct. | David | Open |
| 4 | When should the Option B canonical generic service refactor be scheduled relative to this delivery? | David / Tech Lead | Open |
