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
