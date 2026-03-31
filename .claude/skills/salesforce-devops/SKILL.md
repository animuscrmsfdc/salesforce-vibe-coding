---
name: salesforce-devops
description: DevOps skills for animuscrm — package.xml sync rules, deployment, retrieval, and CI/CD pipeline reference.
---

# Salesforce DevOps Skill — animuscrm

Covers package.xml maintenance, deployment, retrieval, and CI/CD pipeline behaviour.

---

## Package.xml Sync Rule (MANDATORY)

**Whenever you create, rename, or delete any Salesforce metadata file in this project, you MUST update `manifest/package.xml` to stay in sync.**

This applies to every file change — objects, fields, classes, triggers, LWC components, flows, validation rules, permission sets, custom labels, platform events, and all other metadata types.

### 8 Rules for Editing package.xml

1. **Always read the current `package.xml` before making any modifications**
2. **Keep member entries alphabetically sorted** within each `<types>` block
3. **Keep `<types>` blocks alphabetically sorted** by their `<name>` element
4. **Insert new `<types>` blocks in the correct alphabetical position** when adding a new metadata type
5. **Remove an entire `<types>` block** when it has no remaining members
6. **Check for duplicates before adding** — never create duplicate member entries
7. **Keep `<version>` in sync with `sfdx-project.json`** — currently `66.0`
8. **When deleting a metadata file, remove its corresponding `<members>` entry** from package.xml

### Post-Edit Validation
After updating package.xml, confirm:
- Every metadata file under `force-app/main/default/` has a corresponding entry
- XML uses four-space indentation throughout
- Version element matches `sfdx-project.json` `sourceApiVersion`

---

## skill: deploy-and-verify

**Trigger phrase:** "deploy" / "push to org" / "deploy and verify"

### Steps
1. Update `manifest/package.xml` if any metadata was created or modified (see sync rules above)
2. Choose the deploy method:
   - **Source deploy** (most common):
     ```
     sf project deploy start --source-dir force-app --target-org dev-org --wait 30
     ```
   - **Specific component**:
     ```
     sf project deploy start --metadata <MetadataType>:<ComponentName> --target-org dev-org --wait 30
     ```
   - **Manifest deploy**:
     ```
     npm run deploy:manifest
     ```
   - **Validate only (no changes to org)**:
     ```
     npm run deploy:validate
     ```
3. Check the exit code — if non-zero, read every error message, identify the file and line, fix and re-deploy
4. Verify deployment status:
   ```
   sf project deploy report
   ```
5. If Apex classes or triggers were deployed, suggest running tests:
   ```
   npm run test:apex
   ```

### npm Script Reference
| Script | Command |
|--------|---------|
| `npm run deploy` | Full source deploy to dev-org |
| `npm run deploy:validate` | Check-only deploy with RunLocalTests |
| `npm run deploy:manifest` | Manifest-based deploy via package.xml |
| `npm run retrieve` | Retrieve all source from dev-org |
| `npm run test:apex` | Run local Apex tests with coverage |

### CI/CD Triggers (automatic — no manual action needed)
| Event | What runs |
|-------|-----------|
| Push to feature branch | Nothing (local hooks only) |
| Open/update a PR → main | `.github/workflows/validate-pr.yml` — check-only deploy + RunLocalTests |
| Merge PR → main | `.github/workflows/deploy-main.yml` — full deploy + RunLocalTests |
| Manual / nightly 06:00 UTC | `.github/workflows/run-tests.yml` — test run with coverage |

### GitHub Actions Secret Required
The CI workflows authenticate using `secrets.SFDX_AUTH_URL`. Generate and store it once:
```bash
sf org display --target-org dev-org --verbose --json
# Copy "sfdxAuthUrl" value → GitHub repo → Settings → Secrets → SFDX_AUTH_URL
```
