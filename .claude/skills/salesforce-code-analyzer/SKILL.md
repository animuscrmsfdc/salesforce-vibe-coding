---
name: salesforce-code-analyzer
description: Static analysis skills for animuscrm — run PMD via Salesforce Code Analyzer, interpret violations, prioritise fixes, and enforce rules in CI.
---

# Salesforce Code Analyzer Skill — animuscrm

Covers running PMD static analysis, interpreting results, and managing the ruleset.

---

## skill: scan (default workflow)

**Trigger phrase:** "run code analyzer" / "run pmd" / "scan for violations" / "static analysis"

### Step 1 — Run the scan

If no specific target is provided, scan all Apex classes and triggers:

```bash
sf scanner run \
  --target "force-app/main/default/classes,force-app/main/default/triggers" \
  --engine pmd \
  --pmdconfig pmd-ruleset.xml \
  --format table \
  --normalize-severity
```

If a specific file or folder is provided as an argument, scan only that target:
```bash
sf scanner run \
  --target "<target>" \
  --engine pmd \
  --pmdconfig pmd-ruleset.xml \
  --format table \
  --normalize-severity
```

### Step 2 — Summarise results

Group violations by severity and category:

```
Severity 1 (High):   X violations
Severity 2 (Medium): X violations
Severity 3 (Low):    X violations

By category:
  Security:       X
  Performance:    X
  Error Prone:    X
  Best Practices: X
```

List each violation with: file path, line number, rule name, description.

### Step 3 — Prioritise

Focus on Severity 1 (High) violations first:
- `ApexSharingViolations` — missing `with sharing` / `without sharing`
- `ApexSOQLInjection` — dynamic SOQL with unsanitised input
- `ApexCRUDViolation` — missing FLS/CRUD enforcement
- `AvoidHardCodedId` — hardcoded record/org IDs
- `AvoidSoqlInLoops` — SOQL inside a for loop
- `AvoidDmlStatementsInLoops` — DML inside a for loop

### Step 4 — Fix plan (with approval gate)

For each High violation, propose a specific fix:
```
Violation: <RuleName> in <file>:<line>
Issue: <one sentence>
Fix: <specific code change>
```

Present the plan and wait for user approval before implementing any changes.

---

## skill: scan-security-only

**Trigger phrase:** "scan for security issues" / "security analysis"

```bash
sf scanner run \
  --target "force-app/main/default/classes,force-app/main/default/triggers" \
  --engine pmd \
  --category "Security" \
  --format table \
  --normalize-severity
```

---

## skill: scan-single-file

**Trigger phrase:** "scan <ClassName>" / "analyze <ClassName>"

```bash
sf scanner run \
  --target "force-app/main/default/classes/<ClassName>.cls" \
  --engine pmd \
  --pmdconfig pmd-ruleset.xml \
  --format table \
  --normalize-severity
```

---

## Ruleset reference

The project ruleset is at `pmd-ruleset.xml` in the project root.

### Enforced rules (CI blocks on Severity ≤ 2)

| Rule | Category | Why |
|---|---|---|
| ApexSharingViolations | Security | Missing sharing model allows data leaks |
| ApexSOQLInjection | Security | String-concatenated queries allow injection |
| ApexCRUDViolation | Security | Missing FLS/CRUD enforcement |
| ApexDangerousMethods | Security | Unsafe crypto/exec patterns |
| ApexInsecureEndpoint | Security | HTTP instead of HTTPS |
| AvoidSoqlInLoops | Performance | Governor limit risk |
| AvoidDmlStatementsInLoops | Performance | Governor limit risk |
| AvoidHardCodedId | Error Prone | Breaks across environments |
| EmptyCatchBlock | Error Prone | Swallows exceptions silently |
| AvoidLogicInTrigger | Best Practices | Logic must live in handler classes |

### Excluded rules (too noisy)

| Rule | Reason |
|---|---|
| AvoidDebugStatements | Dev-time debugging is acceptable |
| ApexAssertionsShouldIncludeMessage | Existing test baseline doesn't follow this |
| QueueableWithoutFinalizer | Informational only |