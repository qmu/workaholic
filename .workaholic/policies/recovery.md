---
title: Recovery Policy
description: Data backup schedules, retention policies, disaster recovery procedures, and RTO/RPO targets
category: developer
modified_at: 2026-03-10T00:00:00+00:00
commit_hash: f76bde2
---

[English](recovery.md) | [Japanese](recovery_ja.md)

# Recovery Policy

This document describes the backup, recovery, and data restoration practices observed in the Workaholic repository. As a git-versioned project with no database or persistent services, recovery relies entirely on git history and GitHub's infrastructure. The repository now contains two plugins -- drivin for ticket-driven development and trippin for AI-oriented exploration -- each contributing distinct recovery mechanisms.

## Data Persistence

### Version Control as Primary Storage

All project data including markdown documents, JSON configuration, shell scripts, and git configuration is versioned in git. Every change is captured as an atomic commit, providing a complete audit trail and the ability to restore any previous state via git checkout or git revert. The repository contains all configuration in text files with no binary dependencies. (git version control system, `.git/config`)

### Remote Repository Backup

The repository is hosted on GitHub at git@github.com:qmu/workaholic.git, providing remote backup of the entire project history. Pull requests and branch pushes create additional redundancy through GitHub's infrastructure. The remote repository serves as the authoritative backup, with local clones providing working copies. (`.git/config` remote.origin.url field, GitHub remote hosting)

### Ticket Archival System

Completed tickets are archived to `.workaholic/tickets/archive/<branch>/` rather than deleted. This preserves the full history of all change requests, including their final reports and implementation details. The archive-ticket skill implements the archival workflow by moving tickets from `todo/` to `archive/<branch>/`, committing the change, and updating ticket frontmatter with commit hash and category. The archive workflow is atomic: move ticket, stage all changes, commit via commit skill, update frontmatter, and amend the commit. (`plugins/drivin/skills/archive-ticket/sh/archive.sh`)

### Abandoned Ticket Preservation

Tickets that cannot be implemented are moved to `.workaholic/tickets/abandoned/` with failure analysis, preventing data loss and preserving decision context. The drive-approval skill provides an "Abandon" option that generates a failure analysis and moves the ticket to the abandoned directory. This ensures that even failed work is documented for future reference. (`plugins/drivin/skills/drive-approval/SKILL.md`, `.workaholic/tickets/abandoned/`)

### Branch-Based State Snapshots

The repository uses timestamped topic branches following the pattern `<prefix>-YYYYMMdd-HHmmss` for all feature work. Each branch represents a recoverable snapshot of work in progress. Multiple branches exist simultaneously providing redundancy and the ability to recover from branch-specific issues. The branching skill creates these timestamped branches automatically. (`plugins/drivin/skills/branching/sh/create.sh`)

### Trip Artifact Versioning

The trippin plugin preserves all collaborative design artifacts using a versioned append-only pattern. Each revision creates a new numbered file (direction-v1.md, direction-v2.md, etc.) rather than overwriting previous versions. Artifacts are stored in `.workaholic/.trips/<trip-name>/` with subdirectories for directions, models, and designs. This ensures the full collaborative review history is preserved as a sequence of committed versions, enabling recovery of any intermediate design state. (`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`, `plugins/trippin/skills/trip-protocol/SKILL.md`)

### Worktree-Based Session Isolation

The trippin plugin isolates each exploration session in a dedicated git worktree at `.worktrees/<trip-name>/` with a branch named `trip/<trip-name>`. This prevents trip work from interfering with the main working tree and provides a clean recovery boundary: if a trip session fails, the worktree can be removed without affecting the primary checkout. The ensure-worktree script validates that neither the worktree nor the branch already exists before creation, preventing accidental overwrites. (`plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh`)

## Backup Strategy

### Git History as Continuous Backup

Git's commit history serves as a continuous, atomic backup mechanism. Each commit represents a restorable checkpoint with full content and metadata. The repository contains all commits from initial development through current work, demonstrating a complete restoration path. Every commit uses strict mode shell scripts and multi-section commit messages with Description, Changes, Test Planning, and Release Preparation sections. (`plugins/drivin/skills/commit/sh/commit.sh`)

### Commit-per-Step Traceability in Trips

The trippin plugin enforces a commit-per-step rule where every discrete workflow step produces a git commit on the trip branch. This creates a fine-grained commit history that traces the entire collaborative process, including each direction draft, review, revision, and consensus confirmation. The trip-commit script produces structured commit messages in the format `trip(<agent>): <step>` with the phase documented in the body, providing a recoverable record of each agent's contribution. (`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)

### Multi-Contributor Commit Attribution

The commit skill automatically appends Co-Authored-By trailer to all commits, ensuring proper attribution even when Claude assists with implementation. This preserves contribution history for recovery context and audit trails. Every commit message includes "Co-Authored-By: Claude <noreply@anthropic.com>" in the body. (`plugins/drivin/skills/commit/sh/commit.sh` lines 95-97)

### CI Validation Before Merge

GitHub Actions workflow validates all changes before merge to main branch, preventing invalid state from entering the primary branch. The validate-plugins workflow runs on push and pull request events, checking JSON validity, required fields, file existence, and plugin-directory consistency. The workflow uses a glob pattern (`plugins/*/.claude-plugin/plugin.json`) that automatically covers both drivin and trippin plugins, ensuring validation scales with the marketplace. Validation failures block merge, ensuring the main branch remains in a known-good state. (`.github/workflows/validate-plugins.yml`)

### Automated Release Artifacts

The release workflow creates GitHub releases with version tags and release notes, providing named recovery points at each version increment. Releases are triggered on push to main branch when marketplace version changes. The workflow extracts release notes from `.workaholic/release-notes/` directory or falls back to git log, creates a GitHub release with version tag, and marks it as latest. (`.github/workflows/release.yml`)

### Release Note Generation

Generated release notes are stored in `.workaholic/release-notes/` directory before creating GitHub releases. The write-release-note skill produces concise release notes from story files, which are then used by the release workflow. This ensures release documentation is versioned and recoverable alongside code. (`plugins/drivin/skills/write-release-note/SKILL.md`, `.github/workflows/release.yml` lines 62-86)

## Migration Procedures

### Configuration File Validation

JSON configuration files including marketplace.json and plugin.json are validated on every push via CI workflow. The validation checks JSON syntax, required fields like name and version, and file references. Invalid configuration prevents merge, ensuring the repository remains in a valid state. The workflow uses jq for JSON parsing and validation. The validation now covers multiple plugins (drivin and trippin) through glob-based file discovery. (`.github/workflows/validate-plugins.yml` lines 22-59)

### Frontmatter Schema Enforcement

Ticket files require YAML frontmatter with specific schema including created_at in ISO 8601 format, author as email address, type as one of enhancement/bugfix/refactoring/housekeeping, layer as YAML array with UX/Domain/Infrastructure/DB/Config values, and effort as one of 0.1h/0.25h/0.5h/1h/2h/4h or empty. A post-write hook validates ticket frontmatter format after every Write or Edit operation. Validation failures block the write operation with exit code 2, preventing invalid ticket data from being committed. The validation also rejects anthropic.com emails requiring actual user git email. (`plugins/drivin/hooks/validate-ticket.sh`, `plugins/drivin/hooks/hooks.json`)

### Skill File Integrity Check

CI workflow verifies that all skill files referenced in plugin.json exist, preventing broken skill references. The check runs on every push and pull request, extracting skill paths from plugin.json and verifying file existence. Missing skill files cause CI failure. (`.github/workflows/validate-plugins.yml` lines 61-79)

### Marketplace-Directory Consistency Check

CI workflow validates that all plugins listed in marketplace.json have corresponding directories in plugins/, preventing configuration drift. The check compares plugin names from marketplace.json against actual plugin directories using jq and ls. Missing directories cause CI failure. (`.github/workflows/validate-plugins.yml` lines 81-102)

### Version Synchronization Across Plugins

Version numbers must be kept in sync across three files: `.claude-plugin/marketplace.json` root version, `plugins/drivin/.claude-plugin/plugin.json`, and `plugins/trippin/.claude-plugin/plugin.json`. Version bumps update all files simultaneously to maintain consistency. While the CI workflow validates individual plugin.json files, cross-file version consistency is enforced by the release workflow convention documented in CLAUDE.md. (`.claude-plugin/marketplace.json`, `plugins/drivin/.claude-plugin/plugin.json`, `plugins/trippin/.claude-plugin/plugin.json`, `CLAUDE.md` version management section)

## Recovery Plan

### Error Recovery Through Script Safety

All shell scripts use strict mode with undefined variable detection and error exit, preventing partial execution from leaving the system in an inconsistent state. If a script fails, it stops immediately rather than continuing with incorrect data. The drivin plugin uses `set -eu` (POSIX sh) across its 21 shell scripts, while the trippin plugin uses `set -euo pipefail` (bash) across its 3 shell scripts, providing consistent safety guarantees across both plugins. (`plugins/drivin/skills/*/sh/*.sh`, `plugins/drivin/hooks/*.sh`, `plugins/trippin/skills/*/sh/*.sh`)

### Pre-Commit Validation Gates

The validate-writer-output skill checks that expected output files exist and are non-empty before updating README index files. This prevents broken documentation links from being introduced. The skill returns JSON with per-file status and overall pass/fail, allowing the caller to abort before committing. (`plugins/drivin/skills/validate-writer-output/sh/validate.sh`)

### Manual Approval Gate

The drive command requires explicit developer approval before committing each ticket's implementation. The drive-approval skill presents an approval dialog with selectable options including Approve, Approve and stop, and Abandon. The approval prompt must include the ticket title and overview, enforced by a requirement that presenting an approval prompt with missing or placeholder values is a failure condition. This ensures the developer always has sufficient context to make an informed approval decision, serving as a pre-commit recovery mechanism. (`plugins/drivin/commands/drive.md`, `plugins/drivin/skills/drive-approval/SKILL.md`)

### Detached HEAD Protection

The commit skill verifies the repository is on a named branch before allowing commits, preventing accidental commits in detached HEAD state. The pre-flight check runs git branch --show-current and exits with error if empty. This prevents orphaned commits that would be difficult to recover. (`plugins/drivin/skills/commit/sh/commit.sh` lines 43-48)

### Staged Change Verification

The commit skill checks if anything is staged before creating a commit, preventing empty commits and alerting the developer to unexpected working tree state. If no changes are staged, it prints a warning and exits successfully, allowing the developer to investigate with git status. (`plugins/drivin/skills/commit/sh/commit.sh` lines 70-77)

### Atomic Archive Workflow

The archive-ticket skill implements an atomic workflow that moves the ticket, stages all changes, commits via the commit skill with --skip-staging flag, updates frontmatter with commit hash and category, and amends the commit. This ensures ticket archival is all-or-nothing with no partial state. (`plugins/drivin/skills/archive-ticket/sh/archive.sh`)

### Worktree Pre-Creation Validation

The trippin plugin validates preconditions before creating a worktree: it verifies the current directory is inside a git repository, checks that the worktree does not already exist, and confirms the target branch does not already exist. These guards prevent accidental overwrites and ensure each trip starts from a clean state. (`plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh`)

### Trip Name Validation

The trip initialization script validates that trip names follow a strict lowercase alphanumeric with hyphens pattern (no leading or trailing hyphens), and rejects names where a trip directory already exists. This prevents filesystem conflicts and ensures consistent, recoverable directory structures. (`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`)

### No-Change Commit Guard in Trips

The trip-commit script checks for uncommitted changes (staged, unstaged, and untracked) before attempting a commit. If no changes are detected, it returns a JSON response indicating no commit was made rather than failing, preventing unnecessary commits and providing clear feedback to the calling agent. (`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)

## Observations

Git versioning provides complete project history with restoration capability via standard git commands. Ticket archival preserves all change request history in branch-specific directories. Shell script safety with strict mode prevents partial failures across 24 scripts in both plugins. Multiple validation gates including CI, hooks, and manual approval prevent broken state from being committed. The project's pure-file architecture with no databases or services means recovery is as simple as cloning the repository. Timestamped topic branches provide recoverable snapshots of work in progress. Multi-section commit messages with Description, Changes, Test Planning, and Release Preparation sections provide detailed recovery context. The trippin plugin adds worktree isolation and commit-per-step traceability as additional recovery mechanisms, ensuring exploration sessions are recoverable independently of the main working tree. The versioned append-only artifact pattern in trips preserves the full collaborative review history across all design iterations.

## Gaps

Not observed: No formal backup verification or restore testing procedures beyond manual git operations. Not observed: No documented recovery procedures for common failure scenarios like corrupted repository, lost commits, or GitHub outage. Not observed: No branch protection rules visible in the repository which may be configured on GitHub web interface. Not observed: No automated integrity checks beyond CI validation. Not observed: No RTO Recovery Time Objective or RPO Recovery Point Objective targets defined, as the project architecture may not require them. Not observed: No backup of GitHub-specific metadata like issues, pull request comments, or project boards. Not observed: No disaster recovery runbook or incident response procedures. Not observed: No worktree cleanup automation for completed or abandoned trip sessions.
