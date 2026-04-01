Run Salesforce Code Analyzer (PMD) static analysis on the animuscrm project: $ARGUMENTS

If a specific class name or path is provided in $ARGUMENTS, scan only that target.
If no argument is provided, scan all Apex classes and triggers.

Steps:

1. Determine the target:
   - If $ARGUMENTS is empty: target = "force-app/main/default/classes,force-app/main/default/triggers"
   - If $ARGUMENTS contains a class name (e.g. "AccountController"): target = "force-app/main/default/classes/AccountController.cls"
   - If $ARGUMENTS contains a path: use it directly

2. Run the scan:
   sf scanner run \
     --target "<target>" \
     --engine pmd \
     --pmdconfig pmd-ruleset.xml \
     --format table \
     --normalize-severity

3. Summarise the output:
   - Total violations found
   - Breakdown by severity: High (1) / Medium (2) / Low (3)
   - Breakdown by category: Security / Performance / Error Prone / Best Practices
   - List each violation: file, line, rule, description

4. Prioritise and explain:
   - Lead with Severity 1 (High) violations — these block CI
   - For each High violation, explain what the risk is in one sentence
   - For each Medium violation, explain briefly
   - Skip Low violations unless asked

5. Propose fixes for High violations:
   - Read the affected file
   - Propose a specific code change for each violation
   - Wait for user approval before making any changes