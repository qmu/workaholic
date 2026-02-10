---
title: Delivery Policy
description: CI/CD pipeline, release process, and deployment practices
category: developer
modified_at: 2026-02-09T04:52:24+09:00
commit_hash: d627919
---

[English](delivery.md) | [Japanese](delivery_ja.md)

# Delivery Policy

This document describes the continuous integration, delivery, and release practices observed in the Workaholic repository. Delivery is automated through GitHub Actions workflows and plugin commands. The repository follows a ticket-driven development workflow where implementation work flows through structured stages from specification to release.

## CI/CD Pipeline

### Plugin Validation Workflow

The `validate-plugins.yml` workflow runs on every push and pull request to `main` (`on: push/pull_request: branches: [main]`). It executes four validation steps on `ubuntu-latest` with Node.js 20:

1. **Marketplace JSON validation**: Validates `.claude-plugin/marketplace.json` is syntactically correct JSON using `jq empty` (step: "Validate marketplace.json")
2. **Plugin metadata validation**: Validates each `plugin.json` contains required fields (`name`, `version`) using `jq -r` extraction and null checks (step: "Validate plugin.json files")
3. **Skill file existence check**: Verifies that all skill files referenced in `plugin.json` exist on disk using `jq -r '.skills[]?.path'` and file existence tests (step: "Check skill files exist")
4. **Plugin directory consistency**: Ensures every plugin listed in `marketplace.json` has a corresponding directory in `plugins/` (step: "Validate marketplace plugins match directories")

The validation uses shell scripts with `jq` for JSON parsing. Any validation failure causes the workflow to exit with code 1.

### CI Environment

CI runs on `ubuntu-latest` (`runs-on: ubuntu-latest`) with Node.js 20 (`uses: actions/setup-node@v4 with: node-version: '20'`). The environment uses standard Unix tools (`jq`, `awk`, `grep`, shell scripting) for validation and does not compile or build artifacts.

### No Build Step

No build or compilation step exists. The repository contains markdown configuration files, shell scripts, and JSON metadata. Validation ensures structural integrity without transformation or bundling.

## Build Process

### No Artifact Generation

Not observed. As a Claude Code plugin, Workaholic does not produce compiled artifacts. The source files are the distributable assets.

### Dependency Management

Not observed. No `package.json`, `requirements.txt`, or dependency manifests exist. The plugin depends only on GitHub CLI (`gh`) and standard Unix tools available in the CI environment.

## Deployment Strategy

### Distribution via GitHub Release

Deployment occurs through GitHub Release creation. Users install the plugin by referencing the marketplace repository, not by downloading packaged artifacts. The "deployment target" is the GitHub Release, which makes the version discoverable.

### Release Workflow Trigger

The `release.yml` workflow triggers on push to `main` or manual dispatch (`on: push: branches: [main], workflow_dispatch`). It runs on `ubuntu-latest` with `permissions: contents: write`.

### Release Creation Logic

The workflow compares the version in `.claude-plugin/marketplace.json` against the latest GitHub Release tag:

1. **Extract current version**: Uses `grep` and `cut` to extract the `version` field from `marketplace.json` (step: "Get current version")
2. **Get latest release**: Uses `gh release view --json tagName` to retrieve the latest release tag, strips `v` prefix (step: "Get latest release version")
3. **Compare versions**: If current version differs from latest (or no release exists), sets `needed=true` (step: "Check if release needed")
4. **Extract release notes**: Looks for generated release notes in `.workaholic/release-notes/` (most recent by modification time using `ls -t`). If none exist, falls back to `git log` since the last tag (step: "Extract release notes")
5. **Create release**: Runs `gh release create "v{version}" --title "v{version}" --notes-file /tmp/release_notes.txt --latest` (step: "Create GitHub Release")

The workflow skips release creation if the version has not changed.

### No Staging Environment

Not observed. No staging, preview, or pre-production environment exists. All changes merge directly to `main` and become part of the next release.

## Release Process

### Version Management

Two version files must remain synchronized:

- `.claude-plugin/marketplace.json` - root `version` field and `plugins[].version` entries
- `plugins/core/.claude-plugin/plugin.json` - plugin `version` field

The `/release` command (`.claude/commands/release.md`) handles version synchronization. It accepts `major`, `minor`, or `patch` (default) as argument, increments the version semantically, and updates all version fields.

### Release Command Workflow

The `/release` command follows this sequence:

1. Read current version from `.claude-plugin/marketplace.json`
2. Increment version based on argument (default: `patch`)
3. Update `version` field in `.claude-plugin/marketplace.json`
4. Update `version` field in `plugins/core/.claude-plugin/plugin.json`
5. Update plugin version entries in the `plugins` array within `marketplace.json`
6. Sync documentation by reading `plugins/core/commands/sync-work.md` and following its instructions
7. Commit with message `Release v{new_version}`
8. Push to remote

The release command uses semantic versioning (e.g., `1.0.33`).

### Automated Release Notes

The release workflow prefers generated release notes from `.workaholic/release-notes/<branch-name>.md` over git log extraction. The `release-note-writer` subagent (`plugins/core/agents/release-note-writer.md` referenced in `story-writer.md`) generates release notes during PR creation via the `/report` command.

Release note generation happens at PR creation time, not at release time. The workflow consumes pre-generated notes if available.

### Manual Version Bump Required

Version bumping is manual (developer runs `/release` command) rather than automated. The GitHub workflow detects version changes but does not create them. This prevents accidental releases from unintentional version changes.

## Branch Strategy

### Branch Naming Convention

Development branches follow these patterns:

- `drive-<YYYYMMDD>-<HHMMSS>` - ticket-driven development branches
- `trip-<YYYYMMDD>-<HHMMSS>` - alternative branch type (not explicitly documented)

The base branch is `main`. All pull requests target `main`.

### PR Creation Workflow

The `/report` command (referenced in `plugins/core/commands/report.md`) orchestrates PR creation:

1. Bump version following CLAUDE.md Version Management (patch increment)
2. Invoke `story-writer` subagent (`subagent_type: "core:story-writer"`, `model: "opus"`)
3. Display PR URL from story-writer result

The `story-writer` subagent (`plugins/core/agents/story-writer.md`) generates branch story, commits it, invokes `pr-creator` subagent in parallel with `release-note-writer`, and outputs the PR URL.

### PR Creation Script

The `plugins/core/skills/create-pr/sh/create-or-update.sh` script handles PR operations:

1. Strip YAML frontmatter from `.workaholic/stories/<branch-name>.md` using `awk`
2. Check if PR exists using `gh pr list --head "$BRANCH"`
3. If PR does not exist: create with `gh pr create --title "$TITLE" --body-file /tmp/pr-body.md`
4. If PR exists: update via GitHub REST API using `gh api repos/{REPO}/pulls/{NUMBER} --method PATCH`

The script uses REST API for updates to avoid GraphQL Projects deprecation errors (comment in script: `# Update existing PR via REST API (avoids GraphQL Projects deprecation error)`).

### Ticket-Driven Workflow

The `/drive` command implements tickets from `.workaholic/tickets/todo/` sequentially. For each ticket:

1. Implement changes according to ticket specification
2. Request user approval with selectable options
3. Update ticket frontmatter with effort and Final Report
4. Archive ticket to `.workaholic/tickets/archive/<branch>/` using `archive-ticket` skill
5. Commit using structured message format (from `commit` skill referenced in `archive-ticket/SKILL.md`)

The `/drive` command commits each ticket individually, creating a commit per implemented ticket.

## Artifact Promotion Flow

### No Multi-Environment Promotion

Not observed. No artifact promotion across environments (dev → staging → production) exists. Source files in `main` branch are the canonical version.

### Version as Promotion Gate

Version increment serves as the promotion gate. Merging to `main` with an incremented version triggers release creation. The release workflow acts as the final promotion step.

## Observations

- CI validation focuses on structural integrity (valid JSON, required fields, file existence) rather than behavioral testing or type checking
- Release process is semi-automated: developer bumps version via `/release`, GitHub workflow creates release on merge
- Version files require manual synchronization via command rather than deriving from single source of truth
- Release notes are generated at PR creation time (via `/report`) and consumed at release time by GitHub workflow
- PR creation and update use different mechanisms (CLI vs REST API) to avoid deprecated GraphQL endpoints
- Each ticket implementation creates a separate commit during `/drive`, enabling granular change tracking
- Branch story generation invokes 6 subagents in parallel (4 for story content, 2 for PR operations) using Task tool
- The `/scan` command invokes 17 documentation agents in parallel (all with `model: "sonnet"`) to update `.workaholic/` documentation
- Documentation generation is decoupled from code changes and triggered explicitly via `/scan`

## Gaps

- Not observed: No staging or preview environment for testing plugin changes before release
- Not observed: No canary or gradual rollout mechanism for new versions
- Not observed: No automated rollback capability if a release introduces issues
- Not observed: No changelog validation to ensure changelog is updated before release
- Not observed: No automated dependency scanning or security vulnerability checks in CI
- Not observed: No performance benchmarking or regression detection in CI pipeline
- Not observed: No automated smoke tests or integration tests after release deployment
