Run Apex tests in the animuscrm org and report coverage: $ARGUMENTS

If a class name is provided in $ARGUMENTS, run only that test class.
If no argument is provided, run all tests.

Steps:
1. If $ARGUMENTS is empty, run all tests:
   sf apex run test --target-org animuscrm --code-coverage --result-format human --wait 10

2. If $ARGUMENTS contains a class name, run only that class:
   sf apex run test --class-names <ClassName> --target-org animuscrm --code-coverage --result-format human --wait 10

3. After results are available:
   - List all failing tests with their error messages
   - List all classes below 90% code coverage
   - For each failing test, suggest what the likely cause is
   - For each under-covered class, suggest what test scenarios are missing

4. **If all tests passed AND all classes are at ≥ 90% coverage**, update `~/.claude/projects/-Users-david-sanchezcarmona-animuscrm/memory/project_context.md`:
   - Get the current branch: `git branch --show-current`
   - If the branch starts with `feature/`, extract the slug (everything after `feature/`).
   - Find the entry under `### In Progress` whose spec path is `specs/<slug>.md`.
   - If found and the entry does not already contain a "Tested" note, append `Tested (≥90% coverage): <today's date ISO 8601>.` to that entry — on the same line, after any existing notes.
   - If the branch is not `feature/*`, or the slug matches a `### Shipped` entry (regression run), or no match is found — do nothing.
