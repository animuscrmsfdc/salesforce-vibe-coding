# AnimusCRM — Salesforce Developer Org

A Salesforce DX project for the AnimusCRM developer org, configured for AI-assisted development with Claude Code. The project includes Salesforce metadata, Apex code, and a full Claude Code configuration (skills, agents, commands) that accelerates Salesforce development workflows.

---

## 1. Usage Tracker Feature

The **Usage Tracker** provides real-time observability of `Usage__c` record lifecycle events in Salesforce. When a Usage record is created or updated, a CloudEvents 1.0-compliant platform event (`Platform_Event__e`) is automatically published and consumed by the **Dynatrace Salesforce Insights** extension for monitoring.

**Motivation:** Eliminate database polling for Usage activity. Deliver a standards-compliant event payload that Dynatrace can ingest natively over CometD, giving operations teams real-time visibility into Usage record changes without additional infrastructure.

### Key Components

| Component | Type | Purpose |
|---|---|---|
| `Usage__c` | Custom Object | Tracks product/service usage records linked to an Account and Order Product |
| `Platform_Event__e` | Platform Event (HighVolume) | Canonical CloudEvents 1.0 envelope published on every Usage insert/update and Exception insert |
| `UsageTrigger` | Apex Trigger | Fires `after insert` and `after update` on `Usage__c` |
| `UsageTriggerHandler` | Apex Class | Dispatches trigger events to `PlatformEventService` |
| `PlatformEventService` | Apex Class | Canonical bulk-safe event publisher for all SObject types; logs errors to `Exception_Log__e` |
| `PlatformEventServiceTest` | Apex Test Class | ≥90% coverage for all triggers, handlers, and the service layer |
| `Usage_Manager` | Permission Set | Grants CRUD on `Usage__c`; assign to System Administrator post-deploy |
| `UsageStatus` | Global Value Set | Shared picklist backing `Status__c` (New, Error, Processed) |

### Event Payload

Each `Platform_Event__e` event follows the [CloudEvents 1.0 specification](https://cloudevents.io/) with W3C TraceContext fields for distributed tracing:

| Field | Value |
|---|---|
| `specversion__c` | `1.0` |
| `type__c` | `com.animuscrm.usage.created` or `com.animuscrm.usage.updated` |
| `source__c` | Salesforce org domain URL |
| `subject__c` | `Usage__c` record ID (18 chars) |
| `time__c` | Transaction timestamp (`System.now()`) |
| `datacontenttype__c` | `application/json` |
| `data__c` | JSON-serialised snapshot of the full `Usage__c` record (truncated at 20,000 chars) |
| `traceid__c` | W3C TraceContext trace ID (32 hex chars) |

> Events are HighVolume (`PublishAfterCommit`). They are consumed externally by Dynatrace over CometD and cannot be queried inside Salesforce.

Full specification: [specs/usage-tracker.md](specs/usage-tracker.md)

---

## 2. Exception Tracker Feature

The **Exception Tracker** provides real-time observability of `Exception__c` record lifecycle events. When an `Exception__c` record is inserted (by a Flow fault path or Apex `catch` block), a CloudEvents-compliant `Platform_Event__e` event is published for consumption by Dynatrace Salesforce Insights.

**Motivation:** Surface Apex and Flow failures in Dynatrace in real time, enabling root-cause analysis and SLA monitoring without manual log review.

### Key Components

| Component | Type | Purpose |
|---|---|---|
| `Exception__c` | Custom Object | Durable audit record of Apex/Flow failures |
| `ExceptionTrigger` | Apex Trigger | Fires `after insert` on `Exception__c` |
| `ExceptionTriggerHandler` | Apex Class | Checks `Feature_Flag__mdt` before delegating to `PlatformEventService` |
| `PlatformEventService` | Apex Class | Shared with Usage Tracker — publishes `Platform_Event__e` for any SObject type |
| `Exception_Tracker` | Permission Set | Grants CRUD on `Exception__c` for non-Sys-Admin users |
| `Feature_Flag__mdt` | Custom Metadata Type | Controls feature toggles; record `Exception_Event_Publishing` gates event publishing |

### Feature Flag

Event publishing is controlled by the `Feature_Flag__mdt` record `Exception_Event_Publishing` (`Enabled__c = true` by default). When `Enabled__c = false`, `ExceptionTriggerHandler` exits immediately without calling `PlatformEventService`. The flag is deployable via metadata API — no DML required to toggle it.

Full specification: [specs/tracking-exceptions.md](specs/tracking-exceptions.md)

---

## 3. Canonical Platform Event (`Platform_Event__e`)

`Platform_Event__e` is the **single unified** HighVolume platform event for all SObject observability in this org. It replaces the deprecated `Platform_Usages__e` object (deleted in v0.3.0). All tracked objects — Usage, Exception, and future additions — publish to this one event type, distinguished by the `type__c` field.

| `type__c` value | Source |
|---|---|
| `com.animuscrm.usage.created` | `UsageTrigger` / `UsageTriggerHandler` |
| `com.animuscrm.usage.updated` | `UsageTrigger` / `UsageTriggerHandler` |
| `com.animuscrm.exception.created` | `ExceptionTrigger` / `ExceptionTriggerHandler` |

Dynatrace subscribes to `/event/Platform_Event__e/` and filters on `type__c` to route events to the correct dashboard. **`Platform_Usages__e` has been deleted** — Dynatrace must be reconfigured to the new subscription path.

---

## 4. Claude Code Configuration

This project is configured for AI-assisted Salesforce development using [Claude Code](https://claude.ai/code). The `.claude/` folder contains instructions, skills, agents, and commands that give Claude deep context about the project.

### Folder and File Reference

| Path | Type | Purpose |
|---|---|---|
| [CLAUDE.md](CLAUDE.md) | Project instructions | Org alias, API version, folder structure, coding standards, security rules, testing requirements. Loaded automatically by Claude Code in every session. |
| [CLAUDE.local.md](CLAUDE.local.md) | Local overrides (gitignored) | Personal org aliases, sandbox credentials, and local notes. Never committed. |
| [.claude/settings.json](.claude/settings.json) | Claude Code settings | Allowed/denied tools, environment variables (`SF_TARGET_ORG`), and a pre-tool-use hook that blocks edits on the `main` branch. |
| [.claude/settings.local.json](.claude/settings.local.json) | Local settings (gitignored) | Machine-specific tool permissions that override the shared settings. |
| [.claude/skills/SKILL.md](.claude/skills/SKILL.md) | Skills index | Master index of all skill folders with trigger phrases and a summary of each specialisation. |
| [.claude/skills/salesforce-admin/SKILL.md](.claude/skills/salesforce-admin/SKILL.md) | Admin skill | Step-by-step instructions for custom objects, fields, platform events, validation rules, global value sets, page layouts, list views, and permission sets. |
| [.claude/skills/salesforce-developer-apex/SKILL.md](.claude/skills/salesforce-developer-apex/SKILL.md) | Apex skill | Trigger handler pattern, Apex class templates, platform event publishing pattern, and security enforcement checklist. |
| [.claude/skills/salesforce-devops/SKILL.md](.claude/skills/salesforce-devops/SKILL.md) | DevOps skill | `package.xml` sync rules, deploy/retrieve commands, npm scripts, and CI/CD pipeline reference. |
| [.claude/skills/salesforce-test-overwatch/SKILL.md](.claude/skills/salesforce-test-overwatch/SKILL.md) | Test skill | 5-step test-and-fix workflow with approval gate, test class authoring standards, and coverage targets. |
| [.claude/skills/salesforce-code-analyzer/SKILL.md](.claude/skills/salesforce-code-analyzer/SKILL.md) | Code Analyzer skill | Run PMD via Salesforce Code Analyzer, interpret violations, prioritise fixes, and enforce rules in CI. |
| [.claude/skills/architecture-decision-records/SKILL.md](.claude/skills/architecture-decision-records/SKILL.md) | ADR skill | Capture architectural decisions as structured ADRs in `docs/adr/`; auto-detects decision moments during coding sessions. |
| [.claude/agents/salesforce-security-reviewer.md](.claude/agents/salesforce-security-reviewer.md) | Agent | Reviews Apex code for SOQL injection, missing FLS/CRUD, insecure crypto, hardcoded IDs, and sharing violations. |
| [.claude/agents/metadata-generator.md](.claude/agents/metadata-generator.md) | Agent | Generates Salesforce metadata files (objects, fields, layouts) from a natural-language description. |
| [.claude/agents/apex-test-writer.md](.claude/agents/apex-test-writer.md) | Agent | Writes Apex test classes to ≥90% coverage following project standards. |
| [.claude/agents/find-weaknesses.md](.claude/agents/find-weaknesses.md) | Agent | Full weakness review across functional, security, coding standards, and performance dimensions; presents a prioritised report before touching any code. |
| [.claude/agents/business-analyst.md](.claude/agents/business-analyst.md) | Agent | Conducts a structured requirements interview and produces a complete, implementation-ready feature spec. Always invoked via `/new-feature`. |
| [.claude/commands/new-object.md](.claude/commands/new-object.md) | Slash command | `/new-object <spec>` — creates a custom object with fields and deploys. |
| [.claude/commands/new-field.md](.claude/commands/new-field.md) | Slash command | `/new-field <spec>` — adds a field to an existing object. |
| [.claude/commands/new-validation-rule.md](.claude/commands/new-validation-rule.md) | Slash command | `/new-validation-rule <spec>` — creates a validation rule. |
| [.claude/commands/new-platform-event.md](.claude/commands/new-platform-event.md) | Slash command | `/new-platform-event <spec>` — creates a platform event object with fields. |
| [.claude/commands/new-apex-class.md](.claude/commands/new-apex-class.md) | Slash command | `/new-apex-class <spec>` — creates an Apex class from a template. |
| [.claude/commands/new-trigger.md](.claude/commands/new-trigger.md) | Slash command | `/new-trigger <spec>` — creates a trigger + handler following project conventions. |
| [.claude/commands/new-feature.md](.claude/commands/new-feature.md) | Slash command | `/new-feature` — launches the business-analyst agent to elicit and document feature requirements. |
| [.claude/commands/deploy.md](.claude/commands/deploy.md) | Slash command | `/deploy` — runs the full source deploy to `dev-org`. |
| [.claude/commands/retrieve.md](.claude/commands/retrieve.md) | Slash command | `/retrieve` — retrieves all metadata from `dev-org`. |
| [.claude/commands/run-tests.md](.claude/commands/run-tests.md) | Slash command | `/run-tests` — runs all Apex tests with code coverage. |
| [.claude/commands/scan.md](.claude/commands/scan.md) | Slash command | `/scan` — runs Salesforce Code Analyzer (PMD) static analysis on the project. |
| [.claude/commands/find-weaknesses.md](.claude/commands/find-weaknesses.md) | Slash command | `/find-weaknesses` — launches the find-weaknesses agent for a full project review. |
| [.claude/commands/auto-commit-push.md](.claude/commands/auto-commit-push.md) | Slash command | `/auto-commit-push` — scans changed files for weaknesses, calculates a Tech Debt Score, gates the commit if score > 7 or CRITICAL issues exist, then stages, commits, and pushes. |
| [.claude/commands/auto-align-branches.md](.claude/commands/auto-align-branches.md) | Slash command | `/auto-align-branches` — fetches remote changes and updates both `main` and the current feature branch. |
| [.claude/commands/changelog.md](.claude/commands/changelog.md) | Slash command | `/changelog` — updates CHANGELOG.md with the latest commits. |

---

## 5. Skills Reference for Salesforce Professionals

Each skill folder contains a `SKILL.md` with step-by-step instructions that Claude follows automatically when it detects a matching trigger phrase in your prompt.

| Skill | Trigger Phrases | Value for Salesforce Professionals |
|---|---|---|
| **salesforce-admin** | "create a custom object", "add a field", "new platform event", "create a validation rule", "global picklist", "add to page layout", "grant access to profile" | Eliminates manual XML authoring for declarative metadata. Generates correctly structured object, field, layout, and permission set files with all required properties populated, following org naming conventions. |
| **salesforce-developer-apex** | "create a trigger", "new service class", "publish a platform event", "secure this class" | Enforces the project's static switch-based trigger pattern, generates bulkified service classes, applies `with sharing` and FLS checks automatically, and wires up CloudEvents-compliant platform event publishing with error logging. |
| **salesforce-devops** | "deploy", "push to org", "update package.xml", "deploy and verify" | Keeps `package.xml` in sync with every file change, runs the correct `sf` CLI deploy command, checks for errors, and documents CI/CD pipeline behaviour (GitHub Actions workflows for PR validation and main-branch deployment). |
| **salesforce-test-overwatch** | "run tests and fix", "write tests for", "add test coverage", "test overwatch" | Runs Apex tests, diagnoses failures by reading both test and production code, presents a structured fix plan with an approval gate before touching any code, and writes test classes with `@TestSetup`, bulk scenarios, and negative cases. |
| **salesforce-code-analyzer** | "run code analyzer", "run pmd", "scan for violations", "static analysis" | Runs PMD via the `sf scanner` CLI against the project ruleset, groups violations by severity and category, and presents a prioritised fix plan with an approval gate before any changes are made. |
| **architecture-decision-records** | "record this decision", "ADR this", "why did we choose X?", "let's record a decision" | Captures architectural decisions as structured ADRs in `docs/adr/`, recording context, alternatives considered, and consequences so future developers understand why the codebase is shaped the way it is. |

---

## 6. Getting Started

### Prerequisites

- [Salesforce CLI (`sf`)](https://developer.salesforce.com/tools/salesforcecli) v2+
- [VS Code](https://code.visualstudio.com/) with the [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)
- [Node.js](https://nodejs.org/) v18+ (for ESLint, Prettier, Jest, and npm scripts)
- [Claude Code](https://claude.ai/code) (for AI-assisted development)
- Git

### Clone and Open in VS Code

```bash
# Clone the repository
git clone https://github.com/animuscrmsfdc/animuscrm.git
cd animuscrm

# Install Node.js dependencies (ESLint, Prettier, Jest, Husky)
npm install

# Open in VS Code
code .
```

### Connect to Your Salesforce Org

```bash
# Authenticate to your dev org
sf org login web --alias dev-org

# Verify the connection
sf org display --target-org dev-org
```

### Deploy to Your Org

```bash
# Deploy all source
sf project deploy start --source-dir force-app --target-org dev-org --wait 30

# Assign permission sets to your user
sf org assign permset --name Usage_Manager --target-org dev-org
sf org assign permset --name Exception_Tracker --target-org dev-org
```

### Run Apex Tests

```bash
sf apex run test \
  --target-org dev-org \
  --test-level RunLocalTests \
  --code-coverage \
  --result-format human \
  --wait 30
```

### Useful npm Scripts

| Script | What it does |
|---|---|
| `npm run deploy` | Full source deploy to dev-org |
| `npm run deploy:validate` | Check-only deploy (no changes applied) |
| `npm run deploy:manifest` | Deploy using `manifest/package.xml` |
| `npm run retrieve` | Retrieve all metadata from dev-org |
| `npm run test:apex` | Run all Apex tests with coverage |
| `npm run lint` | Run ESLint on LWC components |

---

## 7. Repository Status and Licensing

### Current Status

| Version | Date | Status |
|---|---|---|
| 0.3.0 | 2026-04-03 | Exception Tracker deployed; canonical `Platform_Event__e` replaces `Platform_Usages__e`; `PlatformEventService` replaces `UsageEventService` |
| 0.2.0 | 2026-03-30 | Beta — Usage Tracker deployed and verified in dev org connected to Dynatrace SRG tenant |
| 0.1.0 | 2026-03-28 | Initial — full metadata retrieved from AnimusCRM Salesforce Developer org |

**Known issues (pending fix):**
- SOQL injection risks in `CTPersonController` and `CTLocationController`
- Missing FLS/CRUD enforcement in multiple `@AuraEnabled` controllers
- MD5 token generation in `CTPersonController.getToken()` — should use SHA-256
- Hardcoded portal account ID in `SiteRegisterController`

**Open questions (GA blockers):**
- Dynatrace JSON truncation handling: does Dynatrace require valid JSON or can it handle the `...[TRUNCATED]` suffix in `data__c`? Deadline: 2026-04-10. See [specs/tracking-exceptions.md](specs/tracking-exceptions.md).

See [CHANGELOG.md](CHANGELOG.md) for the full release history.

### Architecture Decision Records

Key architectural decisions are documented in [docs/adr/](docs/adr/):

| ADR | Decision |
|---|---|
| [0001](docs/adr/0001-canonical-generic-event-service.md) | Canonical generic `PlatformEventService` + unified `Platform_Event__e` over dedicated per-object services and events |

### CI/CD

| Trigger | Workflow | What runs |
|---|---|---|
| Pull request to `main` | `validate-pr.yml` | Check-only deploy + RunLocalTests |
| Merge to `main` | `deploy-main.yml` | Full deploy + RunLocalTests |
| Nightly (06:00 UTC) | `run-tests.yml` | Apex test run with coverage report |

### Licensing

This project is under MIT license.
