Deploy the current changes to the animuscrm Salesforce org: $ARGUMENTS

If a specific component is provided in $ARGUMENTS, deploy only that component.
If no argument is provided, deploy the entire force-app source directory.

Steps:
1. If $ARGUMENTS is empty, run:
   sf project deploy start --source-dir force-app --target-org animuscrm

2. If $ARGUMENTS contains a metadata type and name (e.g. "CustomObject:MyObj__c"), run:
   sf project deploy start --metadata <value> --target-org animuscrm

3. After deploy completes, run to confirm status:
   sf project deploy report

4. If there are errors:
   - Read each error message carefully
   - Identify the file and line number
   - Suggest the fix and apply it if straightforward
   - Re-run the deploy after fixing

5. **On successful deploy**, update `~/.claude/projects/-Users-david-sanchezcarmona-animuscrm/memory/project_context.md`:

   a. Detect the current branch:
      ```
      git branch --show-current
      ```

   b. **If the branch name starts with `hotfix/`:**
      - Extract the slug: everything after `hotfix/` (e.g. `hotfix/fix-null-pointer` → slug `fix-null-pointer`).
      - Under `### Hotfixes`, append:
        `- **<slug>** — deployed to dev-org on <today's date ISO 8601>.`
      - Check `### Shipped` for any entry whose spec path contains the slug as a substring. If found, append to that entry:
        `Hotfix applied: <slug> (<today's date ISO 8601>).`
      - If no Shipped entry matches the slug, add the hotfix entry under `### Hotfixes` only — do not prompt the user.

   c. **If the branch name starts with `feature/`:**
      - Extract the slug: everything after `feature/` (e.g. `feature/order-management` → slug `order-management`).
      - Find the entry under `### In Progress` whose spec path is `specs/<slug>.md`.
      - If found:
        - Remove it from `### In Progress`.
        - Append `Shipped: <today's date ISO 8601>.` to the entry and add it under `### Shipped`.
      - If not found (e.g. incremental deploy of an already-shipped feature), do nothing.

   d. **For any other branch pattern**, do nothing to the memory file.

   Do not update the memory file if the deploy failed.
