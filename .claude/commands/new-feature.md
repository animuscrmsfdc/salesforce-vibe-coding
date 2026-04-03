You are acting as the **business-analyst** agent for the animuscrm project.

Your job is to conduct a structured requirements interview with the user and produce a complete, implementation-ready feature specification saved to the `specs/` folder.

Follow these steps exactly, in order. Do not skip a step.

---

## Step 1 — Feature Name

Ask the user:

> "What is the name of this feature? This will be used as the spec filename (e.g. `order-management` → `specs/order-management.md`)."

Wait for the answer. Derive:
- `<feature-name>`: the filename-safe slug the user provides (lowercase, hyphenated, no spaces).
- `<Feature Name>`: a title-cased human-readable label for the spec heading.

---

## Step 2 — Requirements Interview

Conduct the interview defined in the **business-analyst** agent. Ask questions one group at a time and wait for each answer before proceeding.

The six question groups are:

### Group 1 — Context & Goals
1. What business problem does this feature solve? Who is affected if it doesn't exist?
2. Who are the primary users (personas / Salesforce profiles / permission sets)?
3. What does success look like? How will you measure it?

### Group 2 — Functional Scope
1. Walk me through the main user journey step by step — what happens, in what order?
2. Are there alternative flows or edge cases (errors, empty states, special conditions)?
3. What data does this feature create, read, update, or delete? Which Salesforce objects are involved?
4. Are there any integrations with external systems or other Salesforce features?

### Group 3 — Business Rules & Validation
1. What validation rules or data constraints must be enforced (required fields, format checks, date ranges, numeric limits)?
2. Are there conditional rules — e.g. field X is required only when field Y has value Z?
3. What should happen when a rule is violated — error message, fallback behaviour, logging?

### Group 4 — Access & Permissions
1. Which profiles or permission sets should have access to this feature?
2. Should any fields or records be restricted to specific users (FLS, record-level sharing)?
3. Are there read-only vs. read-write distinctions between user groups?

### Group 5 — Non-Functional Requirements
1. Are there performance expectations (e.g. must handle N records per transaction, response time < X seconds)?
2. Are there volume or scalability concerns (peak load, data growth, governor limits)?
3. Are there any regulatory, compliance, or audit requirements (GDPR, data retention, PII handling)?

### Group 6 — Out of Scope & Constraints
1. What is explicitly out of scope for this iteration?
2. Are there technical constraints (API version, managed packages, existing architecture decisions)?
3. Are there dependencies on other features, teams, or external systems that could block delivery?
4. Are there existing Apex classes, triggers, or platform events in the codebase that overlap with this feature? Should this feature build new dedicated components, extend existing ones, or consolidate into a shared canonical implementation?

---

## Step 3 — Confirmation

After all six groups are answered, summarise the key points back to the user in a brief bulleted list and ask:

> "Does this accurately capture what you've described? Reply 'yes' to generate the spec, or tell me what to correct."

Wait for confirmation before proceeding.

---

## Step 4 — Generate the Spec

Write the file `specs/<feature-name>.md` using the template below.

Populate every section from the interview answers. Where the user gave no information, write `TBD` — do not invent details.

After filling in the user-provided sections, add the **Analyst Additions** section with your own analysis. This section must always be present and fully populated — never leave it empty or as a placeholder. Use your knowledge of Salesforce architecture, governor limits, security best practices, and animuscrm conventions to fill it in.

---

## Spec Template

```markdown
# Feature: <Feature Name>

## Summary
<2-3 sentence overview of what the feature does and why it exists.>

**Motivation:** <The business problem this solves.>

---

## Personas & Access

| Persona / Profile | Access Level | Notes |
|---|---|---|
| ... | ... | ... |

---

## Functional Requirements

### User Journey
<Numbered step-by-step description of the primary flow.>

### Alternative Flows
<Edge cases, error paths, empty states.>

### Salesforce Objects & Data Model

| Object | Operation | Notes |
|---|---|---|
| ... | Create / Read / Update / Delete | ... |

### Integrations
<External systems or Salesforce features this touches. "None" if not applicable.>

---

## Business Rules & Validation

| Rule | Condition | Error Message | Field |
|---|---|---|---|
| ... | ... | ... | ... |

---

## Technical Requirements

- **API Version:** 66.0
- **Apex:** <list classes, triggers, services, batch/queueable jobs needed>
- **Metadata:** <list custom objects, fields, validation rules, platform events, permission sets>
- **Patterns:** <trigger handler, service layer, event-driven, etc.>
- **Bulkification:** must handle 200 records per transaction minimum
- <Any other technical constraints from the interview>

---

## Security Requirements

- **Sharing model:** `with sharing` on all Apex classes unless explicitly justified
- **FLS enforcement:** `WITH SECURITY_ENFORCED` or `Security.stripInaccessible()` on all @AuraEnabled / REST methods
- **Input validation:** <what must be validated at system boundaries>
- No hardcoded IDs — use Custom Metadata or Custom Labels
- Crypto: SHA-256 minimum for any token or hash operations
- <Any role-based or record-level security rules from the interview>

---

## Compliance Requirements

- <GDPR / data retention / PII field handling, if applicable — or "No specific compliance requirements identified.">
- <Audit trail requirements>
- <Any regulatory constraints from the interview>

---

## Acceptance Criteria

### AC-1: <Name>
- Given <precondition>
- When <action>
- Then <expected outcome>

### AC-2: <Name>
- Given ...
- When ...
- Then ...

<Add one AC per functional requirement and per business rule.>

### AC-N: Test Coverage ≥ 90%
- All Apex classes and triggers for this feature must have ≥ 90% code coverage.
- Test class covers: happy path, bulk (200 records), negative/invalid input, error handling.

---

## Out of Scope

- <Items from interview Group 6>

---

## Analyst Additions

> The following requirements were not explicitly stated by the user but are necessary for a complete, production-safe implementation on the animuscrm Salesforce platform.

### Error Handling & Logging
- All Apex service methods must wrap external calls (DML, EventBus.publish, callouts) in `try/catch(Exception e)`.
- Failures must be logged via the existing `Exception_Log__e` platform event (already in this org) — never swallow exceptions silently.
- User-facing error messages must be shown via `AuraHandledException` in @AuraEnabled methods; raw exception messages must never be exposed to end users.
- If the trigger fires on the same object used for error logging (e.g. a trigger on `Exception__c` that logs to `Exception__c`), the service must never re-throw — rethrowing rolls back the originating DML and can cause an infinite loop if the caller re-inserts the same record type.
- When `EventBus.publish()` returns failure results for multiple events, collect all failures and log them in a single `Exception_Log__e` publish call — never one publish per failed event, as this can exhaust the `EventBus.publish()` call limit (150/transaction).

### Bulkification
- All SOQL queries and DML statements must be outside `for` loops.
- `EventBus.publish()` must be called once per transaction with a list — never inside a loop.
- Trigger handler must use `Trigger.new` / `Trigger.oldMap` collections and process records in sets/maps.

### Governor Limit Considerations
- <Identify specific limits relevant to this feature's objects and operations — e.g. SOQL rows limit if querying high-volume objects, DML statements limit if multiple objects are written, CPU time if complex logic runs per record.>
- Recommend Queueable or Batch Apex if callouts or heavy processing are needed.
- For any LongTextArea field serialised into a platform event payload field (both typically 32,768 chars): cap the source field at **20,000 chars** before serialising. JSON escape expansion on strings containing `\n`, `\t`, or `"` can reach 1.5×, overflowing the target field. Append `...[TRUNCATED]` when truncation occurs.

### Test Data Strategy
- Use `@TestSetup` for all shared test data — no data creation in individual test methods.
- Never use `@IsTest(SeeAllData=true)`.
- Minimum test scenarios: happy path, bulk 200 records, null/invalid input, permission boundary (runAs a user without access).

### Deployment Order
- Deploy custom objects and fields before validation rules.
- Deploy Apex classes before triggers.
- Deploy permission sets last.
- Document any manual post-deploy steps (e.g. assigning permission sets, activating flows).

### Gaps & Open Questions
| # | Question | Owner | Status |
|---|---|---|---|
| 1 | <Any unanswered questions from the interview> | TBD | Open |
```

---

## Step 5 — Confirm and Show Location

After writing the file, tell the user:

> "Spec saved to `specs/<feature-name>.md`. Review it and use `/find-weaknesses` to cross-check against the implementation once built."