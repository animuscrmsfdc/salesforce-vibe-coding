---
name: salesforce-test-overwatch
description: Test skills for animuscrm — Apex test execution, failure analysis, fix planning with approval gate, and test class authoring standards.
---

# Salesforce Test Overwatch Skill — animuscrm

Covers Apex test execution, analysis, fix planning, and test class authoring.

---

## skill: test-overwatch (5-step workflow)

**Trigger phrase:** "run tests and fix" / "test overwatch" / "analyse test failures"

This skill follows a strict 5-step process. **Do NOT implement any fixes until the user has explicitly accepted the plan in Step 5.**

### Step 1 — Execute Tests
Run all Apex tests with code coverage:
```bash
sf apex run test \
  --target-org dev-org \
  --test-level RunLocalTests \
  --code-coverage \
  --result-format json \
  --wait 30
```

### Step 2 — Summarise Results
Extract and present:
- Total tests: passed / failed / skipped
- For each failure: test class, method name, error message, stack trace
- Code coverage: list all classes below 90% threshold with their current %

### Step 3 — Analyse Failures
For each failing test, read both the test source and the production code it tests. Identify the root cause:
- Assertion mismatch — expected vs actual values differ
- Null pointer exception — missing test data setup or unguarded field access
- DML error — missing required field, sharing rule, or record type constraint
- Missing test data — @TestSetup not creating the records the method expects
- Governor limit — unbulkified code or too many SOQL/DML in a loop

### Step 4 — Build Fix Plan
Produce a structured remediation plan grouped by failing test:
```
Failing test: <TestClass>.<methodName>
Root cause: <one sentence>
Fix required in: <file path, line number>
Proposed change: <specific code change>
```

Also list all classes below 90% coverage with the missing test scenarios.

### Step 5 — User Approval Gate (CRITICAL)
Present the complete plan and wait. Offer three options:
1. Accept all fixes — implement everything as planned
2. Accept with modifications — user specifies changes before implementation begins
3. Reject — do not implement anything

**Do NOT begin implementing any fixes until the user has explicitly chosen option 1 or 2.**

---

## skill: write-test-class

**Trigger phrase:** "write tests for" / "add test coverage for"

### Standards
- `@IsTest` on the class
- `@TestSetup` for all shared test data — no duplicate data creation across methods
- Never use `@IsTest(SeeAllData=true)`
- Use `System.runAs()` for sharing-rule and permission-based scenarios
- Wrap governor-limit-sensitive code in `Test.startTest()` / `Test.stopTest()`
- One scenario per test method
- Use `System.assertEquals()`, `System.assertNotEquals()`, `System.assert()` — no bare truths

### Required Scenarios (cover all four for every class)
1. **Happy path** — valid input, assert the expected return value or record state
2. **Bulk** — 200 records to verify bulkification (no SOQL/DML inside loops)
3. **Negative** — invalid input or missing data; assert the expected exception with `try/catch` + `System.assert(false, 'Expected exception not thrown')`
4. **Boundary** — null input, empty lists, zero values, max field length

### Naming
- File: `<ClassName>Test.cls`
- Path: `force-app/main/default/classes/<ClassName>Test.cls`
- Meta: `force-app/main/default/classes/<ClassName>Test.cls-meta.xml` (apiVersion: 66.0, status: Active)

### Coverage Target
90% minimum. After writing the class, identify which branches or lines are not covered and add targeted test methods until the threshold is met.

### Run the new test class
```bash
sf apex run test \
  --class-names <ClassName>Test \
  --target-org dev-org \
  --code-coverage \
  --result-format human \
  --wait 20
```
