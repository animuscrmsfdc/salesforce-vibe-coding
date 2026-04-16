# AnimusCRM — Salesforce Developer Org

## Project
- Org: Salesforce Developer Edition
- Project name: animuscrm
- Default package directory: force-app/main/default
- API Version: 66.0
- Login URL: https://login.salesforce.com

## CLI
- Default target org alias: `dev-org`
- Username: david@animuscrm.com
- Deploy: `sf project deploy start --source-dir force-app --target-org dev-org`
- Retrieve: `sf project retrieve start --source-dir force-app --target-org dev-org`

## Metadata Conventions
- Custom object API names: PascalCase + `__c` suffix (e.g. `SalesOrder__c`)
- Custom field API names: PascalCase + `__c` suffix (e.g. `TotalAmount__c`)
- Platform event API names: PascalCase + `__e` suffix (e.g. `OrderPlaced__e`)
- Validation rule names: Descriptive_Snake_Case (e.g. `Amount_Cannot_Be_Negative`)
- Always include a description on every metadata component
- Label and API name must match (no abbreviations)

## Apex Coding Standards
- All SOQL in @AuraEnabled/Wire methods must use `WITH SECURITY_ENFORCED`
- Always call `Security.stripInaccessible()` or `WITH SECURITY_ENFORCED` in @AuraEnabled methods
- Triggers: one trigger per object, delegate logic to a handler class
- Bulkify all trigger and batch logic

## Testing
- Minimum 90% code coverage for all Apex
- Use `@TestSetup` for shared test data
- Never use `SeeAllData=true`
- Run tests: `sf apex run test --target-org animuscrm --code-coverage`

## Git Branch Conventions
- Feature branches: `feature/<spec-slug>` where `<spec-slug>` matches the spec filename exactly (e.g. spec `specs/order-management.md` → branch `feature/order-management`)
- Hotfix branches: `hotfix/<short-description>`
- Used by `/deploy`, `/run-tests`, and `/auto-commit-push` to link branch to spec — no prompting
