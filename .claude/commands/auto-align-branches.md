Fetch all remote changes and update both main and the current feature branch locally, keeping the VS Code workspace in sync.

Steps:

1. Get the current branch name so we can return to it after updating main:
   ```
   git branch --show-current
   ```

2. Fetch all remote changes (does not modify any local branch):
   ```
   git fetch origin
   ```

3. Switch to main and pull the latest:
   ```
   git checkout main
   git pull origin main
   ```

4. Switch back to the original feature branch and pull it:
   ```
   git checkout <current-branch>
   git pull origin <current-branch>
   ```

5. Report the result: show the current branch name and confirm both branches are up to date. If any step fails (e.g. pull conflict, non-existent remote branch), report the error clearly and stop — do not attempt automatic merges or rebases.
