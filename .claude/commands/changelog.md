Update CHANGELOG.md with a new entry for recent changes: $ARGUMENTS

## How to use
- No argument: drafts an entry from the current git diff / untracked files
- Version argument (e.g. `1.1.0`): uses that version number
- Type argument (e.g. `patch`, `minor`, `major`): bumps the last version accordingly
- Description argument: uses it as a hint for the entry summary

## Steps

1. Read the current CHANGELOG.md to find the latest version number
2. Determine the new version:
   - If $ARGUMENTS contains a version number, use it
   - If $ARGUMENTS says "patch": increment patch (1.0.0 → 1.0.1)
   - If $ARGUMENTS says "minor": increment minor (1.0.0 → 1.1.0)
   - If $ARGUMENTS says "major": increment major (1.0.0 → 2.0.0)
   - If no argument: default to patch bump
3. Inspect what changed by running:
   `git diff --name-only` for modified files
   `git status --short` for new/untracked files
4. Categorise each changed file into the correct section:
   - **Added**: new objects, fields, classes, LWC components, flows, permission sets, triggers
   - **Changed**: updates to existing validation rules, Apex logic, field properties, LWC behaviour
   - **Fixed**: bug fixes, security patches (e.g. replaced MD5, added FLS enforcement)
   - **Security**: any fix that addresses a security vulnerability — always call this out separately
   - **Removed**: deleted components, deprecated code removed
5. Write entries in plain English, not file names. Good: "Added Invoice__c custom object with Amount and Status fields". Bad: "Modified Invoice__c.object-meta.xml".
6. Insert the new dated entry under `## [Unreleased]` in CHANGELOG.md, above the previous release
7. Show the git tag command to run when ready to release:
   `git tag -a v<version> -m "<one-line summary>" && git push origin v<version>`

## Format to follow
```
## [X.Y.Z] - YYYY-MM-DD
### Added
- ...
### Changed
- ...
### Fixed
- ...
### Security
- ...
### Removed
- ...
```
Omit any section that has no entries.
