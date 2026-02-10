---
title: Recovery Policy
description: Data backup schedules, retention policies, disaster recovery procedures, and RTO/RPO targets
category: developer
modified_at: 2026-02-09T04:52:30+0000
commit_hash: d627919
---

[English](recovery.md) | [Japanese](recovery_ja.md)

# Recovery Policy

This document describes the backup, recovery, and data restoration practices observed in the Workaholic repository. As a git-versioned project with no database or persistent services, recovery relies entirely on git history and GitHub's infrastructure.

## Data Persistence

### Version Control as Primary Storage

All project data (markdown documents, JSON configuration, shell scripts) is versioned in git. Every change is captured as an atomic commit, providing a complete audit trail and the ability to restore any previous state via `git checkout` or `git revert`. (git version control system)

### Remote Repository Backup

The repository is hosted on GitHub at `git@github.com:qmu/workaholic.git`, providing remote backup of the entire project history. Pull requests and branch pushes create additional redundancy through GitHub's infrastructure. (`.git/config`, GitHub remote hosting)

### Ticket Archival System

Completed tickets are archived to `.workaholic/tickets/archive/<branch>/` rather than deleted. This preserves the full history of all change requests, including their final reports and implementation details. The archive-ticket skill (`plugins/core/skills/archive-ticket/sh/archive.sh`) implements the archival workflow by moving tickets from `todo/` to `archive/<branch>/`, committing the change, and updating ticket frontmatter with commit hash and category. (`plugins/core/skills/archive-ticket/sh/archive.sh`)

### Abandoned Ticket Preservation

Tickets that cannot be implemented are moved to `.workaholic/tickets/abandoned/` with failure analysis, preventing data loss and preserving decision context. The drive-approval skill provides an "Abandon" option that generates a failure analysis and moves the ticket to the abandoned directory. (`plugins/core/skills/drive-approval/SKILL.md`, `.workaholic/tickets/abandoned/`)

## Backup Strategy

### Git History as Continuous Backup

Git's commit history serves as a continuous, atomic backup mechanism. Each commit represents a restorable checkpoint. The repository contains 20+ commits in recent history, demonstrating frequent backup points. (git commit history)

### Branch-Based Redundancy

Multiple branches exist simultaneously (main, drive-*, feat-*), providing redundancy and the ability to recover from branch-specific issues. The manage-branch skill creates timestamped topic branches with the pattern `<prefix>-YYYYMMdd-HHmmss`. (`plugins/core/skills/manage-branch/sh/create.sh`)

### CI Validation Before Merge

GitHub Actions workflow validates all changes before merge to main branch, preventing invalid state from entering the primary branch. The validate-plugins workflow runs on push and pull request events, checking JSON validity and file existence. (`.github/workflows/validate-plugins.yml`)

### Automated Release Artifacts

The release workflow creates GitHub releases with version tags and release notes, providing named recovery points. Releases are triggered on push to main branch when marketplace version increments. (`.github/workflows/release.yml`)

## Migration Procedures

### Configuration File Validation

JSON configuration files (`marketplace.json`, `plugin.json`) are validated on every push via CI workflow. The validation checks JSON syntax, required fields (name, version), and file references. Invalid configuration prevents merge, ensuring the repository remains in a valid state. (`.github/workflows/validate-plugins.yml` lines 22-59)

### Frontmatter Schema Enforcement

Ticket files require YAML frontmatter with specific schema (created_at, author, type, layer, effort). A post-write hook validates ticket frontmatter format after every Write or Edit operation. Validation failures block the write operation with exit code 2, preventing invalid ticket data from being committed. (`plugins/core/hooks/validate-ticket.sh`, `plugins/core/hooks/hooks.json`)

### Skill File Integrity Check

CI workflow verifies that all skill files referenced in plugin.json exist, preventing broken skill references. The check runs on every push and pull request. (`.github/workflows/validate-plugins.yml` lines 61-79)

## Recovery Plan

### Error Recovery Through Script Safety

All shell scripts use `set -eu` (strict mode with undefined variable and error exit), preventing partial execution from leaving the system in an inconsistent state. If a script fails, it stops immediately rather than continuing with incorrect data. (19 shell scripts in `plugins/core/skills/*/sh/*.sh` and `plugins/core/hooks/*.sh`)

### Pre-Commit Validation Gates

The validate-writer-output skill checks that expected output files exist and are non-empty before updating README index files. This prevents broken documentation links from being introduced. The skill returns JSON with per-file status and overall pass/fail. (`plugins/core/skills/validate-writer-output/sh/validate.sh`)

### Manual Approval Gate

The `/drive` command requires explicit developer approval before committing each ticket's implementation. The drive-approval skill presents an approval dialog with selectable options: "Approve", "Approve and stop", "Other" (for feedback), and "Abandon". This allows the developer to reject changes before they enter the git history, serving as a pre-commit recovery mechanism. (`plugins/core/commands/drive.md` lines 48-71, `plugins/core/skills/drive-approval/SKILL.md`)

### Detached HEAD Protection

The commit skill verifies the repository is on a named branch before allowing commits, preventing accidental commits in detached HEAD state. The pre-flight check runs `git branch --show-current` and exits with error if empty. (`plugins/core/skills/commit/sh/commit.sh` lines 42-46)

### Marketplace-Directory Consistency Check

CI workflow validates that all plugins listed in marketplace.json have corresponding directories, preventing configuration drift. The check compares plugin names from marketplace.json against actual plugin directories. (`.github/workflows/validate-plugins.yml` lines 81-102)

## Observations

Git versioning provides complete project history with restoration capability via standard git commands. Ticket archival preserves all change request history in branch-specific directories. Shell script safety (`set -eu`) prevents partial failures across 19+ scripts. Multiple validation gates (CI, hooks, approval) prevent broken state from being committed. The project's pure-file architecture (no databases, no services) means recovery is as simple as cloning the repository.

## Gaps

Not observed: No formal backup verification or restore testing procedures beyond manual git operations. Not observed: No documented recovery procedures for common failure scenarios (corrupted repository, lost commits, GitHub outage). Not observed: No branch protection rules visible in the repository (may be configured on GitHub web interface). Not observed: No automated integrity checks beyond CI validation. Not observed: No RTO (Recovery Time Objective) or RPO (Recovery Point Objective) targets defined, as the project architecture may not require them.
