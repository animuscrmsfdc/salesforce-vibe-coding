# Feature: Tracking Exceptions

## Summary
When an Apex class or Flow fails, an `Exception__c` record is created automatically. This feature ensures that every new `Exception__c` record triggers the publication of a CloudEvents-compliant, HighVolume platform event (`Platform_Event__e`) for lifecycle observability via Dynatrace Salesforce Insights. The `Platform_Event__e` event is the canonical unified event shared with Usage tracking (see `specs/usage-tracker.md`).

**Motivation:** The business team needs exception and error data surfaced in Dynatrace in real time. Without this feature, failures captured in `Exception__c` are invisible outside Salesforce, making root-cause analysis and SLA monitoring impossible.

---

## Personas & Access

| Persona / Profile | Access Level | Notes |
|---|---|---|
| System Administrator | Read / Write | Full access to `Exception__c` and `Platform_Event__e` |
| Exception Tracker (new permission set) | Read / Write on `Exception__c` | Grants access to users outside Sys Admin profile who need visibility |

---

## Functional Requirements

### User Journey
1. A Flow or Apex class fails during execution.
2. The calling code (Flow fault path or Apex `catch` block) creates an `Exception__c` record with relevant fields populated (`Exception_Details__c`, `Record_Id__c`, `Object__c`, `Operation__c`).
3. The `Exception__c` after-insert trigger fires.
4. The trigger handler delegates to `PlatformEventService.publishEvents()`.
5. The service builds one `Platform_Event__e` event per `Exception__c` record, populating all CloudEvents and W3C TraceContext fields.
6. All events are published in a single `EventBus.publish()` call (`PublishAfterCommit`).
7. Dynatrace Salesforce Insights consumes the platform event filtered by `type__c = 'com.animuscrm.exception.created'` and ingests the exception data.

### Alternative Flows
- **Bulk insert:** Up to 200 (or more) `Exception__c` records inserted in a single transaction — all events must be collected and published in one `EventBus.publish()` call.
- **`EventBus.publish()` failure:** Individual publish errors are logged via `Exception_Log__e`; the trigger does not re-throw so the originating DML is not rolled back.
- **Empty or null list:** `PlatformEventService` returns early with no DML or publish calls.

### Salesforce Objects & Data Model

| Object | Operation | Notes |
|---|---|---|
| `Exception__c` | Read (after insert) | Source of truth; trigger fires on insert only |
| `Platform_Event__e` | Create | Unified HighVolume CloudEvents platform event; shared with Usage tracking; `type__c = com.animuscrm.exception.created` |
| `Exception_Log__e` | Create | Existing platform event; used to log publish failures — never swallowed silently |

### Integrations
- **Dynatrace Salesforce Insights** — consumes `Platform_Event__e` via Salesforce Streaming API / CometD subscription (`/event/Platform_Event__e/`) filtering on `type__c` starting with `com.animuscrm.exception.*` for real-time observability.

---

## Business Rules & Validation

| Rule | Condition | Error Message | Field |
|---|---|---|---|
| — | No business validation rules required | — | — |

---

## Technical Requirements

- **API Version:** 66.0
- **Apex:**
  - `ExceptionTriggerHandler` — static `afterInsertHandler(List<Exception__c>)` method; checks feature flag; delegates to `PlatformEventService`
  - `PlatformEventService` — static `publishEvents(List<SObject>, String eventType)` method; bulk-safe; generic across SObject types; logs errors via `Exception_Log__e`
- **Triggers:**
  - `ExceptionTrigger` — one trigger on `Exception__c`; after insert only; delegates to `ExceptionTriggerHandler`
- **Metadata:**
  - `Platform_Event__e` — unified HighVolume CloudEvents platform event; `PublishAfterCommit`; 13 custom fields (shared with Usage tracking — see field list below)
  - `Exception_Tracker` permission set — grants CRUD on `Exception__c`; no platform event object permissions needed (HighVolume events have none)
  - `Feature_Flag__mdt` record `Exception_Event_Publishing` — uses the existing `Feature_Flag__mdt` Custom Metadata Type (with `Enabled__c` Checkbox field); when `Enabled__c = false` the trigger handler exits immediately without calling `PlatformEventService`
- **Feature Flag:**
  - **Mechanism:** `Feature_Flag__mdt` (Custom Metadata Type) — chosen over Custom Settings because it is deployable via metadata API / change sets, version-controlled alongside Apex, and does not require DML to toggle; no per-user or per-profile granularity is needed for this flag.
  - **Record developer name:** `Exception_Event_Publishing`
  - **Default value:** `Enabled__c = true` (publishing active by default)
  - **Check location:** `ExceptionTriggerHandler.afterInsertHandler()` queries `[SELECT Enabled__c FROM Feature_Flag__mdt WHERE DeveloperName = 'Exception_Event_Publishing' LIMIT 1]` and returns early if `Enabled__c = false` or the record is missing; `PlatformEventService` is never invoked.
  - **Disabling effect:** No `Platform_Event__e` events are published; no `Exception_Log__e` error events are generated; `Exception__c` DML is unaffected.
- **Patterns:** Trigger → Handler → Service (same pattern as `UsageTrigger` / `UsageTriggerHandler` / `PlatformEventService`)
- **Bulkification:** Must handle 200+ records per transaction; all events collected before single `EventBus.publish()` call
- **CloudEvents fields on `Platform_Event__e`** (shared with Usage tracking):
  `specversion__c`, `type__c`, `source__c`, `subject__c`, `time__c`, `datacontenttype__c`, `data__c`, `dataschema__c`, `parentid__c`, `traceid__c`, `traceflags__c`, `tracestate__c`, `version__c`
- **Event type value:** `com.animuscrm.exception.created`
- **Data truncation:** `PlatformEventService` truncates the JSON-serialised payload at 20,000 chars appending `...[TRUNCATED]`. This applies to all SObject types generically. Truncated JSON is syntactically invalid; Dynatrace consumers must check for the `...[TRUNCATED]` suffix.

---

## Security Requirements

- **Sharing model:** `with sharing` on `PlatformEventService` and `ExceptionTriggerHandler`
- **FLS enforcement:** No `@AuraEnabled` or REST methods in this feature — FLS enforcement via trigger context is sufficient
- **Input validation:** No user-supplied inputs at system boundaries; `Exception__c` records are created programmatically by trusted Apex/Flow
- No hardcoded IDs — use Custom Metadata or Custom Labels if org-specific values are needed
- Crypto: not applicable to this feature
- `Exception_Log__e` must never be published with raw stack traces exposed in user-facing messages (internal logging only)

---

## Compliance Requirements

- No specific compliance requirements identified.
- **Audit trail:** `Exception__c` records serve as the durable audit trail; `Platform_Event__e` is the real-time signal (HighVolume events are not stored in Salesforce).

---

## Acceptance Criteria

### AC-1: Platform event published on single insert
- Given one `Exception__c` record is inserted
- When the after-insert trigger fires
- Then exactly one `Platform_Event__e` event is published with `type__c = 'com.animuscrm.exception.created'`, `subject__c` = the `Exception__c` Id, and `data__c` containing the JSON-serialised record

### AC-2: Platform event published on bulk insert
- Given 200 `Exception__c` records are inserted in a single transaction
- When the after-insert trigger fires
- Then exactly 200 `Platform_Event__e` events are published in a single `EventBus.publish()` call (not inside a loop)

### AC-3: Publish failure is logged, not re-thrown
- Given `EventBus.publish()` returns a failure result for one or more events
- When the service processes the results
- Then each failure is logged via `Exception_Log__e` and the transaction is not rolled back

### AC-4: Empty list is handled gracefully
- Given `PlatformEventService.publishEvents()` is called with a null or empty list
- When the method executes
- Then no DML or `EventBus.publish()` calls are made and no exception is thrown

### AC-5: CloudEvents envelope fields are populated
- Given a `Platform_Event__e` event is published
- When inspected
- Then `specversion__c = '1.0'`, `source__c` equals the org domain URL, `datacontenttype__c = 'application/json'`, and `time__c` is set to publish time

### AC-6: Permission set grants correct access
- Given a user assigned the `Exception_Tracker` permission set (non-Sys Admin)
- When they attempt to create an `Exception__c` record
- Then the record is created successfully and the platform event fires

### AC-7: Feature flag disables event publishing
- Given the `Feature_Flag__mdt` record `Exception_Event_Publishing` has `Enabled__c = false`
- When an `Exception__c` record is inserted
- Then no `Platform_Event__e` event is published and `PlatformEventService` is not invoked
- And the `Exception__c` insert completes successfully with no error

### AC-8: Feature flag enabled resumes publishing
- Given the `Feature_Flag__mdt` record `Exception_Event_Publishing` has `Enabled__c = true`
- When an `Exception__c` record is inserted
- Then the full publish flow executes as per AC-1 through AC-5

### AC-N: Test Coverage ≥ 90%
- All Apex classes and triggers for this feature must have ≥ 90% code coverage.
- Test class covers: happy path (single record), bulk (200 records), null/empty input, `EventBus.publish()` failure path, `runAs` a user with `Exception_Tracker` permission set only, feature flag disabled (assert no events published), truncation path (payload > 20,000 chars).

---

## Out of Scope

- Mechanism by which `Exception__c` records are created (Flow fault paths, Apex catch blocks) — this is pre-existing behaviour.
- Consuming or processing `Platform_Event__e` within Salesforce (e.g. via a trigger or Flow on the event) — Dynatrace is the consumer.
- UI changes to the `Exception__c` record page.

---

## Architecture Decision: Option B — Canonical Generic Service (Implemented)

Option B has been implemented. `PlatformEventService` is the canonical generic service for all platform event publishing. A dedicated `ExceptionEventService` and `Platform_Exceptions__e` were not created.

**Implemented approach:**
- `PlatformEventService.publishEvents(List<SObject>, String eventType)` is the single publish entry point for all tracked objects.
- `Platform_Event__e` is the unified platform event used by both Usage tracking and Exception tracking.
- `UsageEventService` has been deleted; test scenarios migrated into `PlatformEventServiceTest`.

**Trade-offs accepted:**
- Truncated JSON in `data__c` is syntactically invalid — Dynatrace consumers must handle the `...[TRUNCATED]` suffix.
- Dynatrace must reconfigure its Streaming API subscription from `/event/Platform_Usages__e/` to `/event/Platform_Event__e/` with `type__c` filtering. **Do not deploy the `UsageTriggerHandler` changes until Dynatrace confirms the new subscription is active.**

**Option A (dedicated classes)** was not implemented. A canonical generic service story covering Option A is no longer relevant.

---

## Analyst Additions

> The following requirements were not explicitly stated by the user but are necessary for a complete, production-safe implementation on the animuscrm Salesforce platform.

### Error Handling & Logging
- `PlatformEventService` wraps `EventBus.publish()` in `try/catch(Exception e)`.
- Failures are logged via `Exception_Log__e` (already in this org) — never swallowed silently.
- The service never throws; throwing inside an after-insert trigger handler rolls back the originating DML and could cause an infinite loop if the catch block re-inserts an `Exception__c`.
- Raw stack traces are not surfaced to end users; they go to `Exception_Log__e.Exception_Details__c` only.

### Bulkification
- All events are collected in a `List<Platform_Event__e>` before the single `EventBus.publish()` call.
- `EventBus.publish()` is never called inside a `for` loop.
- Trigger handler uses `Trigger.new` collections; no SOQL inside the trigger or handler (feature flag query in handler is exempt — Custom Metadata queries are platform-cached).

### Governor Limit Considerations
- **`EventBus.publish()` limit:** 150 `EventBus.publish()` calls per transaction. This feature uses one call per transaction — no risk even at high volume.
- **Platform event message size:** `data__c` is a LongTextArea (32,768 chars). `PlatformEventService` truncates the serialised JSON at 20,000 chars, leaving ample headroom for JSON escape overhead.
- **DML rows limit (10,000):** Error logging publishes one `Exception_Log__e` per failed event. In the worst case (200 failures), this is 200 additional `EventBus.publish()` calls in the error loop — within the 150-call-per-transaction limit only if errors are batched. Current implementation logs individually; this is acceptable for expected failure rates.

### Test Data Strategy
- `@TestSetup` for all shared test data — no data creation in individual test methods.
- Never use `@IsTest(SeeAllData=true)`.
- Minimum test scenarios: happy path (1 record), bulk (200 records), null input, truncation path (payload > 20,000 chars), `runAs` user with `Exception_Tracker` permission set only, feature flag disabled (assert insert completes successfully).

### Deployment Order
1. Deploy `Platform_Event__e` object and all 13 fields.
2. Deploy `Feature_Flag__mdt` record `Exception_Event_Publishing` (with `Enabled__c = true`).
3. Deploy `PlatformEventService` Apex class.
4. **Coordinate with Dynatrace** to update Streaming API subscription to `/event/Platform_Event__e/`.
5. Deploy `UsageTriggerHandler` (updated to call `PlatformEventService`).
6. Deploy `ExceptionTriggerHandler` and `ExceptionTrigger`.
7. Deploy `Exception_Tracker` permission set.
8. **Manual post-deploy:** Assign `Exception_Tracker` permission set to relevant non-Sys-Admin users.

### Gaps & Open Questions

| # | Question | Owner | Status |
|---|---|---|---|
| 1 | Should `Platform_Event__e` TraceContext fields (`traceid__c`, `traceflags__c`, `tracestate__c`, `version__c`) be populated by Apex or only by Dynatrace? | David / Dynatrace team | Open |
| 2 | `PlatformEventService` truncates serialised JSON at 20,000 chars; truncated payload is invalid JSON. Does Dynatrace require valid JSON or can it handle the `...[TRUNCATED]` suffix? | David / Dynatrace team | Open |
| 3 | Is `Exception__c` after-update also in scope (e.g. if an exception record is enriched later)? The interview confirmed after-insert only — confirm this is correct. | David | Open |
