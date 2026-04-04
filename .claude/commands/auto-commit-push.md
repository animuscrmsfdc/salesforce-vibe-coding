Stage all changes, commit with a user-provided message, and push to the remote feature branch.

Steps:

1. Collect the list of locally changed files (new, modified, deleted) by running:
   ```
   git diff --name-only
   git diff --cached --name-only
   git ls-files --others --exclude-standard
   ```
   Combine all three outputs into a single deduplicated list of file paths (unstaged changes, already-staged changes, and untracked files). These are the files about to be committed.

2. Run the find-weaknesses agent (as defined in `.claude/commands/find-weaknesses.md`), but **scope the analysis exclusively to the changed files identified in step 1** — do not scan the rest of the project. Only report findings for those files. Collect all findings.

3. Pre-process findings before scoring:
   - **Discard** any MEDIUM or LOW/INFO/other finding whose associated file path ends in `.md`. These do not count toward the score or the findings summary.
   - **Reclassify severity**: A finding is only CRITICAL if it has a real, demonstrable impact on code quality in production (e.g. security vulnerabilities, data loss risk, broken logic, missing sharing enforcement, SOQL injection, unhandled exceptions in critical paths). Purely informative findings, style suggestions, or documentation notes must be downgraded to HIGH or MEDIUM as appropriate — never left as CRITICAL.

   Calculate the **Tech Debt Score** (0–10) as a true weighted average across all remaining findings:
   - Assign a weight to each finding by severity: CRITICAL = 10, HIGH = 5, MEDIUM = 3, LOW/INFO/other = 1.
   - Formula: `score = sum(weight_i for every finding i) / totalFindings`
     where `totalFindings` is the count of ALL remaining findings regardless of severity.
   - If there are no findings at all, the score is 0.
   - Result is a decimal rounded to one decimal place.
   - Example: 1 CRITICAL + 2 HIGH + 4 MEDIUM + 3 LOW = 10 total findings → score = (10 + 5+5 + 3+3+3+3 + 1+1+1) / 10 = 35/10 = 3.5

4. Display a findings summary followed immediately by the Tech Debt Score in this format:

   **Findings Summary**

   Assign a sequential 4-digit number to every finding across all severities, ordered CRITICAL first, then HIGH, then MEDIUM. The number resets to 0001 for each severity group.

   If there are CRITICAL findings, list each one:
   ```
   [CRITICAL-0001] <file>:<line> — <description>
   [CRITICAL-0002] <file>:<line> — <description>
   ```
   If there are HIGH findings, list each one:
   ```
   [HIGH-0001] <file>:<line> — <description>
   [HIGH-0002] <file>:<line> — <description>
   ```
   If there are MEDIUM findings, list each one:
   ```
   [MEDIUM-0001] <file>:<line> — <description>
   [MEDIUM-0002] <file>:<line> — <description>
   ```
   If a severity bucket has no findings, omit that section entirely. If there are no findings at all across all severities, print `No issues found in changed files.`

   Then, immediately below the findings, display the score card:
   ```
   ┌──────────────────────────────────────────────┐
   │  Tech Debt Score: <score>/10                 │
   │  Critical: <n>  High: <n>  Medium: <n>  Other: <n>  Total: <n> │
   └──────────────────────────────────────────────┘
   ```

5. **If any CRITICAL findings exist (criticalCount > 0)**, cancel the operation automatically regardless of the score and display:
   ```
   Commit cancelled. 1 or more CRITICAL findings must be resolved before committing.
   ```
   Stop here — do not proceed with staging, committing, or pushing.

   **Otherwise, if the Tech Debt Score is greater than 7**, cancel the operation automatically and display:
   ```
   Commit cancelled. Tech Debt Score (<score>/10) exceeds the threshold of 7.
   Resolve the critical/high weaknesses reported above before committing.
   ```
   Stop here — do not proceed with staging, committing, or pushing.

6. **If the Tech Debt Score is 7 or below**, ask the user:
   "Tech Debt Score is <score>/10. Do you want to continue with the commit? (yes/no)"
   Wait for the user's response. If the user answers anything other than "yes", cancel the operation and stop.

7. Run `git status` to show the user what files will be staged.

8. Ask the user: "Enter your commit message:"
   Wait for the user's input before proceeding.

9. Stage only the files identified in step 1. Before staging, filter out any path that matches a sensitive-file pattern (`.env`, `*.key`, `*.pem`, `*.p12`, `*.pfx`, any filename containing `secret`, `credential`, or `token`). If any file is filtered out, display a warning listing the skipped paths. Stage the remaining files individually:
   ```
   git add <file1> <file2> ...
   ```
   Do not use `git add -A` — stage only the explicit file list from step 1 (minus filtered paths).

10. Commit with the message provided by the user:
    ```
    git commit -m "<user-provided message>

    Co-Authored-By: Claude Code <noreply@anthropic.com>"
    ```

11. Get the current branch name:
    ```
    git branch --show-current
    ```

12. Push to the remote, setting the upstream to the current branch:
    ```
    git push --set-upstream origin <current-branch>
    ```

13. Confirm success by showing the output of the push command. If the push fails, report the error and do not retry automatically.