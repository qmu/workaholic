---
title: Delivery Policy
description: CI/CD pipeline, release process, and deployment practices
category: developer
modified_at: 2026-02-12T10:20:09+0000
commit_hash: f385117
---

[English](delivery.md) | [Japanese](delivery_ja.md)

# Delivery Policy

This document describes the continuous integration, delivery, and release practices observed in the Workaholic repository. Delivery is automated through GitHub Actions workflows and plugin commands. The repository follows a ticket-driven development workflow where implementation work flows through structured stages from specification to release.

## CI/CD Pipeline

### Plugin Validation Workflow

The `validate-plugins.yml` workflow (`on: push/pull_request: branches: [main]`) runs on every push and pull request to `main`, executing four validation steps on `ubuntu-latest` with Node.js 20:

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

Not observed. As a Claude Code plugin marketplace, Workaholic does not produce compiled artifacts. The source files are the distributable assets.

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

The release command uses semantic versioning (e.g., `1.0.34`).

### Automated Release Notes

The release workflow prefers generated release notes from `.workaholic/release-notes/<branch-name>.md` over git log extraction. The `release-note-writer` subagent (`plugins/core/agents/release-note-writer.md`) generates release notes during PR creation via the `/report` command.

Release note generation happens at PR creation time, not at release time. The workflow consumes pre-generated notes if available.

### Manual Version Bump Required

Version bumping is manual (developer runs `/release` command) rather than automated. The GitHub workflow detects version changes but does not create them. This prevents accidental releases from unintentional version changes.

## Branch Strategy

### Branch Naming Convention

Development branches follow these patterns:

- `drive-<YYYYMMDD>-<HHMMSS>` - ticket-driven development branches (created by `branching` skill: `create.sh drive`)
- `trip-<YYYYMMDD>-<HHMMSS>` - alternative branch type for more AI-oriented development (created by `branching` skill: `create.sh trip`)

The base branch is `main`. All pull requests target `main`. Branch creation and state checking is handled by the `branching` skill (`plugins/core/skills/branching/SKILL.md`) with bundled shell scripts.

### PR Creation Workflow

The `/report` command (`plugins/core/commands/report.md`) orchestrates PR creation:

1. Check if version already bumped using `branching` skill (`bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/branching/sh/check-version-bump.sh`). If `already_bumped` is `true` (a "Bump version" commit exists in current branch since diverging from main), skip the bump. Otherwise, bump version following CLAUDE.md Version Management (patch increment).
2. Invoke `story-writer` subagent (`subagent_type: "core:story-writer"`, `model: "opus"`)
3. Display PR URL from story-writer result

The `story-writer` subagent (`plugins/core/agents/story-writer.md`) generates branch story, commits it, invokes `pr-creator` and `release-note-writer` in parallel, and outputs the PR URL.

The version bump idempotency check prevents double-bumping when `/report` is called multiple times in the same branch (implemented via `plugins/core/skills/branching/sh/check-version-bump.sh` which uses `git log main..HEAD --oneline --grep="Bump version"`).

### PR Creation Script

The `plugins/core/skills/create-pr/sh/create-or-update.sh` script handles PR operations:

1. Strip YAML frontmatter from `.workaholic/stories/<branch-name>.md` using `awk`
2. Check if PR exists using `gh pr list --head "$BRANCH"`
3. If PR does not exist: create with `gh pr create --title "$TITLE" --body-file /tmp/pr-body.md`
4. If PR exists: update via GitHub REST API using `gh api repos/{REPO}/pulls/{NUMBER} --method PATCH`

The script uses REST API for updates to avoid GraphQL Projects deprecation errors (comment in script: `# Update existing PR via REST API (avoids GraphQL Projects deprecation error)`).

### Ticket-Driven Workflow

The `/drive` command (`plugins/core/commands/drive.md`) implements tickets from `.workaholic/tickets/todo/` sequentially. For each ticket:

1. Implement changes according to ticket specification
2. Request user approval with selectable options
3. Update ticket frontmatter with effort and Final Report
4. Archive ticket to `.workaholic/tickets/archive/<branch>/` using `archive-ticket` skill
5. Commit using structured message format (from `commit` skill)

The `/drive` command commits each ticket individually, creating a commit per implemented ticket. Branch creation at the start of `/drive` uses the `branching` skill (`plugins/core/skills/branching/sh/check.sh` and `create.sh`).

## Commit Message Structure

### Structured Format

All commits use a structured message format enforced by the `commit` skill (`plugins/core/skills/commit/SKILL.md` and `commit/sh/commit.sh`). The format includes five sections:

```
<title>

Description: <why this change was needed, including motivation and rationale>

Changes: <what users will experience differently>

Test Planning: <what verification was done or should be done>

Release Preparation: <what is needed to ship and support afterward>

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Section Guidelines

Each section (except title) should be a short paragraph (3-5 sentences) that gives lead agents enough signal to act without reading the full diff:

- **Title**: Present-tense verb, what changed (50 chars max). No prefixes like `feat:` or `[fix]`.
- **Description**: Why this change was needed. Start with the problem or gap. Explain what triggered the work. State the chosen approach and rationale.
- **Changes**: What users will experience differently. Describe observable differences concretely. Write "None" with brief explanation if internal-only.
- **Test Planning**: What verification was done or should be done. Describe manual checks, automated tests, edge cases. Write "None" only if trivial.
- **Release Preparation**: What is needed to ship and support. Cover migrations, config changes, documentation updates, monitoring. Write "None" with brief explanation if straightforward.

### Commit Script

The `plugins/core/skills/commit/sh/commit.sh` script implements the commit workflow:

1. **Pre-flight check**: Verify on a branch (not detached HEAD)
2. **Staging**: If files specified, stage only those files. If no files specified, stage all tracked changes (`git add -u`). Never uses `git add -A`.
3. **Review**: Show diff summary of staged changes
4. **Commit**: Create commit with structured message

The script accepts an optional `--skip-staging` flag for when files are already staged.

### Archive Workflow

The `plugins/core/skills/archive-ticket/sh/archive.sh` script handles ticket archival:

1. Move ticket from `todo/` or `icebox/` to `archive/<branch>/`
2. Stage all changes including the archived ticket (`git add -A`)
3. Delegate to commit script with `--skip-staging` flag
4. Update ticket frontmatter with commit hash and category
5. Amend commit to include frontmatter updates

The script infers category from commit title (Add/Create/Implement → "Added", Remove/Delete → "Removed", default → "Changed").

## Story Generation and PR Description

### Story Writer Agent

The `story-writer` subagent (`plugins/core/agents/story-writer.md`) orchestrates story generation in five phases:

**Phase 0: Gather Context**
- Uses `gather-git-context` skill to get branch, base_branch, repo_url, archived_tickets, git_log

**Phase 1: Invoke Story Generation Agents**
- Invokes 4 agents in parallel via Task tool (single message with 4 tool calls):
  - `release-readiness` (model: opus) - analyzes branch for release readiness
  - `performance-analyst` (model: opus) - evaluates decision quality
  - `overview-writer` (model: opus) - generates overview, highlights, motivation, and journey
  - `section-reviewer` (model: opus) - generates sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas)

**Phase 2: Write Story File**
- Gathers source data from archived tickets
- Writes `.workaholic/stories/<branch-name>.md` following `write-story` skill template
- Updates `.workaholic/stories/README.md` index

**Phase 3: Commit and Push Story**
- Stages story files (`git add .workaholic/stories/`)
- Commits with message `Add branch story for <branch-name>`
- Pushes branch (`git push -u origin <branch-name>`)

**Phase 4: Generate Release Note and Create PR**
- Invokes 2 agents in parallel via Task tool (single message with 2 tool calls):
  - `release-note-writer` (model: haiku) - writes `.workaholic/release-notes/<branch-name>.md`
  - `pr-creator` (model: opus) - derives title, runs `gh` CLI operations
- Captures PR URL from pr-creator response

**Phase 5: Commit and Push Release Notes**
- Stages release notes (`git add .workaholic/release-notes/`)
- Commits with message `Add release notes for <branch-name>`
- Pushes changes

### Story Content Structure

The story file (`write-story` skill template) contains 11 sections with frontmatter:

```yaml
---
branch: <branch-name>
started_at: <from performance-analyst metrics>
ended_at: <from performance-analyst metrics>
tickets_completed: <count of tickets>
commits: <from performance-analyst metrics>
duration_hours: <from performance-analyst metrics>
duration_days: <from performance-analyst metrics if available>
velocity: <from performance-analyst metrics>
velocity_unit: <from performance-analyst metrics>
---
```

Sections populated from parallel agent outputs:

1. **Overview** (from overview-writer) - 2-3 sentence summary + 3 highlights
2. **Motivation** (from overview-writer) - paragraph synthesizing the "why" from commit context
3. **Journey** (from overview-writer) - Mermaid flowchart + prose summary
4. **Changes** (from archived tickets) - one subsection per ticket with commit hash link
5. **Outcome** (from section-reviewer) - what was accomplished
6. **Historical Analysis** (from section-reviewer) - context from related past work
7. **Concerns** (from section-reviewer) - risks, trade-offs, issues discovered
8. **Ideas** (from section-reviewer) - enhancement suggestions for future work
9. **Performance** (from performance-analyst) - metrics JSON + decision review markdown
10. **Release Preparation** (from release-readiness) - verdict, concerns, pre/post-release instructions
11. **Notes** (optional) - additional context for reviewers

The story file serves as the PR description (YAML frontmatter is stripped by `create-or-update.sh`).

## Documentation Generation

### Scan Command

The `/scan` command (`plugins/core/commands/scan.md`) updates all `.workaholic/` documentation (changelog, specs, terms, policies). It invokes 3 manager agents then 12 leader/writer agents in parallel:

**Phase 1: Gather Context**
- Uses `gather-git-context` skill to get branch, base_branch, repo_url
- Gets commit hash (`git rev-parse --short HEAD`)

**Phase 2: Select Agents**
- Runs `select-scan-agents` skill: `bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/select-scan-agents/sh/select.sh full`
- Parses JSON output to get lists of manager and leader agents

**Phase 3a: Invoke Manager Agents in Parallel**
- Invokes 3 managers in single message with parallel Task tool calls (each model: sonnet):
  - `project-manager` - pass base branch
  - `architecture-manager` - pass base branch
  - `quality-manager` - pass base branch
- Waits for all managers to complete before proceeding

**Phase 3b: Invoke Leader and Writer Agents in Parallel**
- Invokes 12 leaders/writers in single message with parallel Task tool calls (each model: sonnet):
  - `ux-lead`, `model-analyst`, `infra-lead`, `db-lead` (viewpoint leads)
  - `test-lead`, `security-lead`, `quality-lead`, `a11y-lead`, `observability-lead`, `delivery-lead`, `recovery-lead` (policy leads)
  - `changelog-writer`, `terms-writer` (content writers)
- All invocations MUST use `run_in_background: false` (agents need Write/Edit permissions which require interactive prompt access)

**Phase 4: Validate Output**
- Validates viewpoint spec output using `validate-writer-output` skill
- Validates policy output using `validate-writer-output` skill

**Phase 5: Update Index Files**
- Updates `.workaholic/specs/README.md` and `README_ja.md` if spec validation passed
- Updates `.workaholic/policies/README.md` and `README_ja.md` if policy validation passed

**Phase 6: Stage and Commit**
- Commits all documentation: `git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ .workaholic/constraints/ && git commit -m "Update documentation"`

**Phase 7: Report Results**
- Reports per-agent status showing which agents succeeded, failed, or were skipped

### Policy Analysis

The `analyze-policy` skill (`plugins/core/skills/analyze-policy/SKILL.md`) provides a generic framework for analyzing a repository from a specific policy domain. It gathers context using bundled script:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/analyze-policy/sh/gather.sh <policy-slug> [base-branch]
```

Policy documents follow a strict inference rule: **Only document what is implemented**. Every policy statement must describe something that is actually implemented and executable in the codebase -- a CI check, hook, script, linter rule, or test. After each statement, cite the mechanism that implements it. Mark gaps clearly with "Not observed" rather than omitting them.

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
- Story generation invokes 6 subagents in parallel (4 for story content, 2 for PR operations) using Task tool
- The `/scan` command invokes 15 documentation agents in parallel (3 managers first, then 12 leaders/writers) to update `.workaholic/` documentation
- Documentation generation is decoupled from code changes and triggered explicitly via `/scan`
- Commit message structure provides structured sections (Description, Changes, Test Planning, Release Preparation) for lead agents to parse without reading diffs
- Archive workflow uses `git add -A` only after moving ticket to archive directory, then stages specific files for frontmatter update
- No git hooks are active (only sample hooks exist in `.git/hooks/`)
- Commit script never uses `git add -A` to avoid accidentally staging untracked files from other contributors
- Multi-contributor awareness built into commit workflow: review staged changes before committing to avoid including others' uncommitted work
- Version bump idempotency check prevents double-bumping when `/report` runs multiple times in same branch (uses `git log main..HEAD --oneline --grep="Bump version"` via `branching` skill)
- Branch operations (check, create, version bump detection) are extracted to shell scripts in the `branching` skill rather than inline commands in markdown files
- The `/scan` command now includes `.workaholic/constraints/` in the commit step to capture manager constraint files

## Gaps

- Not observed: No staging or preview environment for testing plugin changes before release
- Not observed: No canary or gradual rollout mechanism for new versions
- Not observed: No automated rollback capability if a release introduces issues
- Not observed: No changelog validation to ensure changelog is updated before release
- Not observed: No automated dependency scanning or security vulnerability checks in CI
- Not observed: No performance benchmarking or regression detection in CI pipeline
- Not observed: No automated smoke tests or integration tests after release deployment
- Not observed: No git hooks for pre-commit or pre-push validation (only sample hooks exist)
- Not observed: No automated enforcement of commit message format (structure is enforced by convention via commit skill, not git hook)
