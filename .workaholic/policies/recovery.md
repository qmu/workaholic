---
title: Recovery Policy
description: Backup, disaster recovery, and data restoration practices
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](recovery.md) | [Japanese](recovery_ja.md)

# 1. Recovery Policy

This document describes the backup, recovery, and data restoration practices observed in the Workaholic repository. As a git-versioned project with no database or persistent services, recovery relies entirely on git history and GitHub's infrastructure.

## 2. Version Control as Backup

### 2-1. Git History

[Explicit] All project data (markdown documents, JSON configuration, shell scripts) is versioned in git. Every change is captured as an atomic commit, providing a complete audit trail and the ability to restore any previous state via `git checkout` or `git revert`.

### 2-2. Remote Backup

[Explicit] The repository is hosted on GitHub (`https://github.com/qmu/workaholic`), providing remote backup of the entire project history. Pull requests and branch pushes create additional redundancy through GitHub's infrastructure.

### 2-3. Ticket Archival

[Explicit] Completed tickets are archived to `.workaholic/tickets/archive/<branch>/` rather than deleted. This preserves the full history of all change requests, including their final reports and implementation details.

## 3. Error Recovery

### 3-1. Shell Script Safety

[Explicit] All shell scripts use `set -eu` (strict mode with undefined variable and error exit), which prevents partial execution from leaving the system in an inconsistent state. If a script fails, it stops immediately rather than continuing with incorrect data.

### 3-2. Validation Before Update

[Explicit] The `validate-writer-output` skill checks that expected output files exist and are non-empty before updating README index files. This prevents broken documentation links from being introduced.

### 3-3. Approval Gate

[Explicit] The `/drive` command requires explicit developer approval before committing each ticket's implementation. This allows the developer to reject changes before they enter the git history, serving as a pre-commit recovery mechanism.

### 3-4. Abandon Option

[Explicit] During `/drive`, the "Abandon" option allows a developer to skip a ticket that cannot be implemented, generating a failure analysis and moving the ticket to the abandoned directory. This provides graceful recovery from implementation failures.

## 4. Data Restoration

Not observed. No explicit data restoration procedures are documented beyond git's built-in capabilities. No database migrations, seed data, or backup scripts exist (none are needed for this project type).

## 5. Disaster Recovery

Not observed. No formal disaster recovery plan exists. Recovery would rely on cloning the repository from GitHub, which contains the complete project state.

## 6. Observations

- [Explicit] Git versioning provides complete project history with restoration capability.
- [Explicit] Ticket archival preserves all change request history.
- [Explicit] Shell script safety (`set -eu`) prevents partial failures.
- [Explicit] Validation gates prevent broken documentation from being committed.
- [Inferred] The project's pure-file architecture (no databases, no services) means recovery is as simple as cloning the repository, making formal disaster recovery planning unnecessary.

## 7. Gaps

- Not observed: No formal backup verification or restore testing.
- Not observed: No documented recovery procedures for common failure scenarios.
- Not observed: No branch protection rules visible in the repository (may be configured on GitHub).
- Not observed: No automated integrity checks beyond CI validation.
