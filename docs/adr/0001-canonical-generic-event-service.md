# ADR-0001: Canonical Generic Event Service (Option B)

**Date**: 2026-04-03
**Status**: accepted
**Deciders**: David Sanchez
**Salesforce Area**: Apex | Integration

## Context

The animuscrm org needed real-time exception observability via Dynatrace Salesforce Insights, requiring a new platform event and an Apex service for `Exception__c` records. The existing `UsageEventService` already published `Platform_Usages__e` events following an identical CloudEvents 1.0 pattern. Implementing a dedicated `ExceptionEventService` would duplicate ~60 lines of logic and create a third platform event object for every future tracked SObject. The trigger → handler → service pattern was already established and stable.

## Decision

We replace `UsageEventService` with a single generic `PlatformEventService.publishEvents(List<SObject>, String eventType)` that publishes to a unified `Platform_Event__e` object. `UsageEventService` is retained as a deprecated shim delegating to `PlatformEventService`. A dedicated `Platform_Exceptions__e` is not created. `ExceptionTriggerHandler` uses `PlatformEventService` directly. Any future SObject tracking is added by registering a new trigger + handler pair — no new service or platform event object is needed.

## Alternatives Considered

### Option A: Dedicated ExceptionEventService + Platform_Exceptions__e
- **Pros**: Zero risk to existing `UsageEventService` and Dynatrace subscription; independently deployable; follows the established pattern with no refactoring
- **Cons**: Duplicates ~60 lines of identical publish logic; a new service + platform event required for every future tracked object; CloudEvents envelope logic diverges over time
- **Why not**: The duplication cost was certain and immediate; the independence benefit was marginal given the pattern is already proven

### Option C: Shared base class / virtual method inheritance
- **Pros**: Reusable without a type-cast; idiomatic OOP
- **Cons**: Apex single-inheritance limits flexibility; `abstract` / `virtual` methods add ceremony with no benefit when the publish logic is fully static; increases complexity without solving the core problem
- **Why not**: Static `publishEvents(List<SObject>)` achieves the same reuse without an inheritance hierarchy

## Consequences

### Positive
- Single place to maintain CloudEvents envelope logic (`PlatformEventService`)
- New SObject tracking requires only a trigger + handler — no new service or platform event
- `PlatformEventServiceTest` covers Usage and Exception scenarios in one class
- `data__c` truncation at 20,000 chars is enforced consistently for all types

### Negative
- `List<Usage__c>` requires an explicit `(List<SObject>)` cast at every call site — compile-time covariance is not available in Apex
- `UsageEventService` must be kept as a shim until `UsageEventServiceTest` is migrated to avoid a breaking change in test coverage
- `Platform_Usages__e` remains deployed but receives no new events post-refactor — orphaned object until cleaned up

### Risks
- **Dynatrace subscription break**: Dynatrace is subscribed to `/event/Platform_Usages__e/`. Deploying `UsageTriggerHandler` changes before Dynatrace reconfigures to `/event/Platform_Event__e/` will create a window of zero Usage observability. Mitigation: coordinate deployment of Wave 3 (`UsageTriggerHandler`) with the Dynatrace team; do not merge until they confirm the new subscription is live.
- **Truncated JSON**: `data__c` payload is truncated at 20,000 chars, producing syntactically invalid JSON. Dynatrace consumers must tolerate the `...[TRUNCATED]` suffix. Mitigation: document in open questions; confirm with Dynatrace team before GA.
