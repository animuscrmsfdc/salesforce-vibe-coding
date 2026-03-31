# AnimusCRM — Salesforce Developer Org

A Salesforce DX project for the AnimusCRM developer org, configured for AI-assisted development with Claude Code. The project includes Salesforce metadata, Apex code, and a full Claude Code configuration (skills, agents, commands) that accelerates Salesforce development workflows.

---

## 1. Usage Tracker Feature

The **Usage Tracker** provides real-time observability of `Usage__c` record lifecycle events in Salesforce. When a Usage record is created or updated, a CloudEvents 1.0-compliant platform event (`Platform_Usages__e`) is automatically published and consumed by the **Dynatrace Salesforce Insights** extension for monitoring.

**Motivation:** Eliminate database polling for Usage activity. Deliver a standards-compliant event payload that Dynatrace can ingest natively over CometD, giving operations teams real-time visibility into Usage record changes without additional infrastructure.

### Key Components

| Component | Type | Purpose |
|---|---|---|
| `Usage__c` | Custom Object | Tracks product/service usage records linked to an Account and Order Product |
| `Platform_Usages__e` | Platform Event (HighVolume) | CloudEvents 1.0 envelope published on every Usage insert/update |
| `UsageTrigger` | Apex Trigger | Fires `after insert` and `after update` on `Usage__c` |
| `UsageTriggerHandler` | Apex Class | Dispatches trigger events to the service layer |
| `UsageEventService` | Apex Class | Bulk-safe event publisher; logs errors to `Exception_Log__e` |
| `UsageEventServiceTest` | Apex Test Class | ≥90% coverage for trigger, handler, and service |
| `Usage_Manager` | Permission Set | Grants CRUD on `Usage__c`; assign to System Administrator post-deploy |
| `UsageStatus` | Global Value Set | Shared picklist backing `Status__c` (New, Error, Processed) |

### Event Payload

Each `Platform_Usages__e` event follows the [CloudEvents 1.0 specification](https://cloudevents.io/) with W3C TraceContext fields for distributed tracing:

| Field | Value |
|---|---|
| `specversion__c` | `1.0` |
| `type__c` | `com.animuscrm.usage.created` or `com.animuscrm.usage.updated` |
| `source__c` | Salesforce org domain URL |
| `subject__c` | `Usage__c` record ID (18 chars) |
| `time__c` | Transaction timestamp (`System.now()`) |
| `data__c` | JSON-serialised snapshot of the full `Usage__c` record |
| `traceid__c` | W3C TraceContext trace ID (32 hex chars) |

> Events are HighVolume (`PublishAfterCommit`). They are consumed externally by Dynatrace over CometD and cannot be queried inside Salesforce.

Full specification: [specs/usage-tracker.md](specs/usage-tracker.md)

---

## 2. Claude Code Configuration

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
| [.claude/agents/salesforce-security-reviewer.md](.claude/agents/salesforce-security-reviewer.md) | Agent | Reviews Apex code for SOQL injection, missing FLS/CRUD, insecure crypto, hardcoded IDs, and sharing violations. |
| [.claude/agents/metadata-generator.md](.claude/agents/metadata-generator.md) | Agent | Generates Salesforce metadata files (objects, fields, layouts) from a natural-language description. |
| [.claude/agents/apex-test-writer.md](.claude/agents/apex-test-writer.md) | Agent | Writes Apex test classes to ≥90% coverage following project standards. |
| [.claude/commands/new-object.md](.claude/commands/new-object.md) | Slash command | `/new-object <spec>` — creates a custom object with fields and deploys. |
| [.claude/commands/new-field.md](.claude/commands/new-field.md) | Slash command | `/new-field <spec>` — adds a field to an existing object. |
| [.claude/commands/new-validation-rule.md](.claude/commands/new-validation-rule.md) | Slash command | `/new-validation-rule <spec>` — creates a validation rule. |
| [.claude/commands/new-platform-event.md](.claude/commands/new-platform-event.md) | Slash command | `/new-platform-event <spec>` — creates a platform event object with fields. |
| [.claude/commands/new-apex-class.md](.claude/commands/new-apex-class.md) | Slash command | `/new-apex-class <spec>` — creates an Apex class from a template. |
| [.claude/commands/new-trigger.md](.claude/commands/new-trigger.md) | Slash command | `/new-trigger <spec>` — creates a trigger + handler following project conventions. |
| [.claude/commands/deploy.md](.claude/commands/deploy.md) | Slash command | `/deploy` — runs the full source deploy to `dev-org`. |
| [.claude/commands/retrieve.md](.claude/commands/retrieve.md) | Slash command | `/retrieve` — retrieves all metadata from `dev-org`. |
| [.claude/commands/run-tests.md](.claude/commands/run-tests.md) | Slash command | `/run-tests` — runs all Apex tests with code coverage. |
| [.claude/commands/changelog.md](.claude/commands/changelog.md) | Slash command | `/changelog` — updates CHANGELOG.md with the latest commits. |

---

## 3. Skills Reference for Salesforce Professionals

Each skill folder contains a `SKILL.md` with step-by-step instructions that Claude follows automatically when it detects a matching trigger phrase in your prompt.

| Skill | Trigger Phrases | Value for Salesforce Professionals |
|---|---|---|
| **salesforce-admin** | "create a custom object", "add a field", "new platform event", "create a validation rule", "global picklist", "add to page layout", "grant access to profile" | Eliminates manual XML authoring for declarative metadata. Generates correctly structured object, field, layout, and permission set files with all required properties populated, following org naming conventions. |
| **salesforce-developer-apex** | "create a trigger", "new service class", "publish a platform event", "secure this class" | Enforces the project's static switch-based trigger pattern, generates bulkified service classes, applies `with sharing` and FLS checks automatically, and wires up CloudEvents-compliant platform event publishing with error logging. |
| **salesforce-devops** | "deploy", "push to org", "update package.xml", "deploy and verify" | Keeps `package.xml` in sync with every file change, runs the correct `sf` CLI deploy command, checks for errors, and documents CI/CD pipeline behaviour (GitHub Actions workflows for PR validation and main-branch deployment). |
| **salesforce-test-overwatch** | "run tests and fix", "write tests for", "add test coverage", "test overwatch" | Runs Apex tests, diagnoses failures by reading both test and production code, presents a structured fix plan with an approval gate before touching any code, and writes test classes with `@TestSetup`, bulk scenarios, and negative cases. |

---

## 4. Getting Started

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

# Assign the Usage Manager permission set to your user
sf org assign permset --name Usage_Manager --target-org dev-org
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

## 5. Repository Status and Licensing

### Current Status

| Version | Date | Status |
|---|---|---|
| 0.2.0 | 2026-03-30 | Beta — Usage Tracker deployed and verified in dev org connected to Dynatrace SRG tenant |
| 0.1.0 | 2026-03-28 | Initial — full metadata retrieved from AnimusCRM Salesforce Developer org |

**Known issues (pending fix):**
- SOQL injection risks in `CTPersonController` and `CTLocationController`
- Missing FLS/CRUD enforcement in multiple `@AuraEnabled` controllers
- MD5 token generation in `CTPersonController.getToken()` — should use SHA-256
- Hardcoded portal account ID in `SiteRegisterController`

See [CHANGELOG.md](CHANGELOG.md) for the full release history.

### CI/CD

| Trigger | Workflow | What runs |
|---|---|---|
| Pull request to `main` | `validate-pr.yml` | Check-only deploy + RunLocalTests |
| Merge to `main` | `deploy-main.yml` | Full deploy + RunLocalTests |
| Nightly (06:00 UTC) | `run-tests.yml` | Apex test run with coverage report |

### Licensing

This project is private. All Salesforce metadata, Apex code, and Claude Code configuration are proprietary to AnimusCRM. Not licensed for redistribution.
