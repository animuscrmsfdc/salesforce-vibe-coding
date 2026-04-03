---
name: architecture-decision-records
description: Capture architectural decisions made during Claude Code sessions as structured ADRs. Auto-detects decision moments, records context, alternatives considered, and rationale. Maintains an ADR log so future developers understand why the codebase is shaped the way it is. Tailored for Salesforce Apex / metadata projects.
origin: ECC
---

# Architecture Decision Records

Capture architectural decisions as they happen during coding sessions. Instead of decisions living only in Slack threads, PR comments, or someone's memory, this skill produces structured ADR documents that live alongside the code.

## When to Activate

- User explicitly says "let's record this decision" or "ADR this"
- User chooses between significant alternatives (trigger pattern, sharing model, event strategy, integration approach)
- User says "we decided to..." or "the reason we're doing X instead of Y is..."
- User asks "why did we choose X?" (read existing ADRs)
- During planning phases when architectural trade-offs are discussed

## ADR Format

Use the lightweight ADR format proposed by Michael Nygard, adapted for Salesforce development:

```markdown
# ADR-NNNN: [Decision Title]

**Date**: YYYY-MM-DD
**Status**: proposed | accepted | deprecated | superseded by ADR-NNNN
**Deciders**: [who was involved]
**Salesforce Area**: [Apex | Metadata | Integration | Security | Data Model | DevOps | Testing]

## Context

What is the issue that we're seeing that is motivating this decision or change?

[2-5 sentences describing the situation, constraints, governor limits, org configuration, or Salesforce-specific forces at play]

## Decision

What is the change that we're proposing and/or doing?

[1-3 sentences stating the decision clearly. Include the Apex class, object, or metadata component affected where relevant.]

## Alternatives Considered

### Alternative 1: [Name]
- **Pros**: [benefits]
- **Cons**: [drawbacks]
- **Why not**: [specific reason this was rejected — include governor limit impact, security implications, or maintainability concerns where applicable]

### Alternative 2: [Name]
- **Pros**: [benefits]
- **Cons**: [drawbacks]
- **Why not**: [specific reason this was rejected]

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive
- [benefit 1]
- [benefit 2]

### Negative
- [trade-off 1]
- [trade-off 2]

### Risks
- [risk and mitigation — call out governor limit risks, sharing model side effects, or deployment order dependencies]
```

## Workflow

### Capturing a New ADR

When a decision moment is detected:

1. **Initialize (first time only)** — if `docs/adr/` does not exist, ask the user for confirmation before creating the directory, a `README.md` seeded with the index table header (see ADR Index Format below), and a blank `template.md` for manual use. Do not create files without explicit consent.
2. **Identify the decision** — extract the core architectural choice being made
3. **Gather context** — what problem prompted this? What Salesforce constraints exist (governor limits, sharing model, deployment order)?
4. **Document alternatives** — what other options were considered? Why were they rejected?
5. **State consequences** — what are the trade-offs? What becomes easier/harder?
6. **Assign a number** — scan existing ADRs in `docs/adr/` and increment
7. **Confirm and write** — present the draft ADR to the user for review. Only write to `docs/adr/NNNN-decision-title.md` after explicit approval. If the user declines, discard the draft without writing any files.
8. **Update the index** — append to `docs/adr/README.md`

### Reading Existing ADRs

When a user asks "why did we choose X?":

1. Check if `docs/adr/` exists — if not, respond: "No ADRs found in this project. Would you like to start recording architectural decisions?"
2. If it exists, scan `docs/adr/README.md` index for relevant entries
3. Read matching ADR files and present the Context and Decision sections
4. If no match is found, respond: "No ADR found for that decision. Would you like to record one now?"

### ADR Directory Structure

```
docs/
└── adr/
    ├── README.md                              ← index of all ADRs
    ├── 0001-trigger-handler-pattern.md
    ├── 0002-platform-events-over-flows.md
    ├── 0003-custom-metadata-for-config.md
    └── template.md                            ← blank template for manual use
```

### ADR Index Format

```markdown
# Architecture Decision Records

| ADR | Title | Area | Status | Date |
|-----|-------|------|--------|------|
| [0001](0001-trigger-handler-pattern.md) | Static switch-based trigger handler pattern | Apex | accepted | 2026-01-15 |
| [0002](0002-platform-events-over-flows.md) | Platform Events over Process Builder for async processing | Integration | accepted | 2026-01-20 |
| [0003](0003-custom-metadata-for-config.md) | Custom Metadata over Custom Settings for feature flags | Data Model | accepted | 2026-02-01 |
```

## Decision Detection Signals

Watch for these patterns in conversation that indicate an architectural decision:

**Explicit signals**
- "Let's go with X"
- "We should use X instead of Y"
- "The trade-off is worth it because..."
- "Record this as an ADR"

**Implicit signals** (suggest recording an ADR — do not auto-create without user confirmation)
- Choosing between trigger handler patterns
- Selecting a sharing model (`with sharing` vs `inherited sharing` vs service-layer `without sharing`)
- Deciding between Platform Events, Change Data Capture, Flows, or Process Builder for async automation
- Choosing Custom Metadata vs Custom Settings vs Custom Labels for configuration
- Picking an integration pattern (REST callout vs Platform Events vs MuleSoft)
- Making a SOQL security enforcement choice (`WITH SECURITY_ENFORCED` vs `Security.stripInaccessible()`)
- Deciding on a batch vs queueable vs future method approach
- Selecting a test data strategy (`@TestSetup` vs factories vs static data)
- Branching / deployment strategy choices (scratch orgs, sandboxes, CI pipeline)

## Salesforce-Specific Decision Categories

| Category | Salesforce Examples |
|----------|-------------------|
| **Apex patterns** | Trigger handler pattern, service/selector/domain layers, bulkification approach |
| **Async processing** | Batch Apex vs Queueable vs Future vs Platform Events vs Flows |
| **Automation layer** | Flow vs Apex trigger vs Workflow (deprecated) vs Process Builder (deprecated) |
| **Configuration storage** | Custom Metadata vs Custom Settings vs Custom Labels vs Hierarchy Settings |
| **Security enforcement** | `WITH SECURITY_ENFORCED` vs `Security.stripInaccessible()`, sharing model per class |
| **Integration** | REST callouts vs Platform Events vs Named Credentials vs MuleSoft |
| **Data modeling** | Junction objects, polymorphic lookups, External Objects, Big Objects |
| **UI layer** | LWC vs Aura vs Visualforce vs Flow Screens |
| **Testing** | Test data factories vs `@TestSetup`, mock strategies, coverage thresholds |
| **DevOps** | Package development vs org development, scratch org workflow, CI/CD tooling |
| **API versioning** | When to bump API version, which components to include in a deployment |

## What Makes a Good ADR

### Do
- **Be specific** — "Use static switch-based handler in `ExceptionTriggerHandler`" not "use a handler class"
- **Reference Salesforce constraints** — governor limits, sharing considerations, deployment order dependencies
- **Record the why** — the rationale matters more than the what
- **Include rejected alternatives** — future developers need to know what was considered (e.g., why Flows were rejected)
- **State consequences honestly** — every decision has trade-offs
- **Keep it short** — an ADR should be readable in 2 minutes
- **Use present tense** — "We use X" not "We will use X"
- **Name affected components** — reference the Apex class, object API name, or metadata component

### Don't
- Record trivial decisions — field label wording or minor formatting choices don't need ADRs
- Write essays — if the context section exceeds 10 lines, it's too long
- Omit alternatives — "we just picked it" is not a valid rationale
- Backfill without marking it — if recording a past decision, note the original date
- Let ADRs go stale — superseded decisions should reference their replacement
- Assume Salesforce defaults are obvious — document why a non-default sharing model or CRUD bypass was chosen

## ADR Lifecycle

```
proposed → accepted → [deprecated | superseded by ADR-NNNN]
```

- **proposed**: decision is under discussion, not yet committed
- **accepted**: decision is in effect and being followed
- **deprecated**: decision is no longer relevant (e.g., feature removed, Process Builder retired)
- **superseded**: a newer ADR replaces this one (always link the replacement)

## Integration with Other Skills

- **salesforce-developer-apex**: when establishing a new Apex pattern (trigger handler, service layer), suggest creating an ADR
- **salesforce-admin**: when choosing between declarative automation options, suggest creating an ADR
- **salesforce-devops**: when selecting a deployment or branching strategy, suggest creating an ADR
- **find-weaknesses**: security or architecture findings that require a structural fix may warrant an ADR to capture the decision