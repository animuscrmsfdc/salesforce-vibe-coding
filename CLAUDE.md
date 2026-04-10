# AnimusCRM — Salesforce Developer Org

## Project
- Org: Salesforce Developer Edition
- Project name: animuscrm
- Default package directory: force-app/main/default
- API Version: 66.0
- Login URL: https://login.salesforce.com

## CLI
- Use `sf` CLI (not `sfdx`) for all commands
- Authenticate: `sf org login web --alias dev-org`
- Default target org alias: `dev-org`
- Username: david@animuscrm.com
- Deploy: `sf project deploy start --source-dir force-app --target-org dev-org`
- Retrieve: `sf project retrieve start --source-dir force-app --target-org dev-org`

## Folder Structure
- Apex classes:        force-app/main/default/classes/
- Triggers:           force-app/main/default/triggers/
- Custom objects:     force-app/main/default/objects/
- Validation rules:   force-app/main/default/objects/<ObjectName>/validationRules/
- Platform events:    force-app/main/default/objects/ (suffix: __e)
- LWC components:     force-app/main/default/lwc/
- Flows:              force-app/main/default/flows/
- Permission sets:    force-app/main/default/permissionsets/
- Custom labels:      force-app/main/default/labels/

## Metadata Conventions
- Custom object API names: PascalCase + `__c` suffix (e.g. `SalesOrder__c`)
- Custom field API names: PascalCase + `__c` suffix (e.g. `TotalAmount__c`)
- Platform event API names: PascalCase + `__e` suffix (e.g. `OrderPlaced__e`)
- Validation rule names: Descriptive_Snake_Case (e.g. `Amount_Cannot_Be_Negative`)
- Always include a description on every metadata component
- Label and API name should always match (no abbreviations)

## Apex Coding Standards
- All classes must use `with sharing` unless explicitly justified
- All SOQL in AuraEnabled/Wire methods must use `WITH SECURITY_ENFORCED`
- No hardcoded IDs — use Custom Metadata or Custom Labels
- No MD5 for tokens — use SHA-256 minimum
- Triggers: one trigger per object, delegate logic to a handler class
- Bulkify all trigger and batch logic

## Security Rules (enforced)
- Never use `without sharing` unless in a service class with a documented reason
- Always call `Security.stripInaccessible()` or `WITH SECURITY_ENFORCED` in @AuraEnabled methods
- Validate all user inputs at system boundaries
- No `Database.query()` with string concatenation — use bind variables only

## Testing
- Minimum 90% code coverage for all Apex
- Use `@TestSetup` for shared test data
- Never use `SeeAllData=true`
- Run tests: `sf apex run test --target-org animuscrm --code-coverage`

## Git Branch Conventions
- Feature branches: `feature/<spec-slug>` where `<spec-slug>` matches the spec filename exactly (e.g. spec `specs/order-management.md` → branch `feature/order-management`)
- Hotfix branches: `hotfix/<short-description>` (e.g. `hotfix/fix-null-pointer`)
- This convention is used by `/deploy`, `/run-tests`, and `/auto-commit-push` to deterministically link a branch to its spec and `project_context.md` entry — no ambiguity, no prompting

## What NOT to Do
- Never hard-code Org IDs or record IDs
- Never write SOQL without a WHERE clause on large objects
- Never deploy directly to production — always go through change sets or CI
