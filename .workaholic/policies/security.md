---
title: Security Policy
description: The assets worth protecting, threat model, authentication/authorization boundaries, and safeguards in place
category: developer
modified_at: 2026-03-10T00:00:00+00:00
commit_hash: f76bde2
---

[English](security.md) | [Japanese](security_ja.md)

# Security Policy

This document describes the security practices implemented in the Workaholic repository. As a Claude Code plugin marketplace that manages git operations autonomously through two plugins (drivin and trippin), security considerations center on credential protection, execution boundaries, input validation, worktree isolation, and safe operational patterns. The project has zero runtime dependencies and does not handle user credentials beyond git operations, which narrows the threat surface to git credential management, shell script execution safety, ticket metadata integrity, and worktree session isolation.

## Authentication

### Git Credential Management

Repository-scoped GitHub tokens are used exclusively for automated operations. The release workflow uses `${{ secrets.GITHUB_TOKEN }}`, which is a temporary, repository-scoped token automatically provided by GitHub Actions with limited permissions. The workflow explicitly declares `contents: write` permission scope, granting only the minimum required access for creating releases (implemented in `.github/workflows/release.yml` lines 9-10). No personal access tokens or custom secrets are required.

### Author Identity Validation

Ticket creation enforces authentic authorship by rejecting Anthropic email addresses in the `author` field. The validation hook explicitly blocks `@anthropic.com` emails using regex pattern matching (`[[ "$author" =~ @anthropic\.com$ ]]`), requiring developers to use their actual git email from `git config user.email`. This prevents AI-generated attribution from appearing in ticket metadata and ensures audit trail integrity (implemented in `plugins/drivin/hooks/validate-ticket.sh` lines 110-116).

### Email Format Validation

The validation hook enforces email format for the `author` field using regex pattern `^[^@]+@[^@]+\.[^@]+$`, ensuring basic structural validity before the Anthropic domain check. Tickets with malformed email addresses are rejected with clear error messages referencing the authoritative skill documentation (implemented in `plugins/drivin/hooks/validate-ticket.sh` lines 104-108).

## Authorization

### Git Operation Transparency

The root `README.md` includes a prominent warning section (lines 5-6) using GitHub's warning callout syntax that Workaholic drives git on the developer's behalf, including creating branches, committing, amending, pushing, and opening pull requests. This transparency allows developers to make informed decisions about installation and understand the scope of automated operations before enabling the plugin.

### Permission-Free Execution Model

Shell scripts are bundled within skills and executed via the `bash` command without requiring executable permissions. All 24 shell scripts across both plugins use strict error handling shebangs. The drivin plugin uses `#!/bin/sh -eu` for POSIX scripts and `#!/usr/bin/env bash` or `#!/bin/bash` for bash-specific scripts. The trippin plugin uses `#!/bin/bash` with `set -euo pipefail`, adding the pipefail option for stricter pipeline error detection. This eliminates permission prompts during plugin installation and ensures consistent behavior across all user environments regardless of filesystem permissions (scripts in `plugins/drivin/skills/*/sh/`, `plugins/drivin/hooks/`, and `plugins/trippin/skills/*/sh/`).

### Hook Timeout Enforcement

The PostToolUse validation hook enforces a 10-second timeout on the ticket validation script, preventing runaway validation from blocking development workflows. The timeout is declared in the hook configuration alongside the command specification, ensuring that validation failures fail fast rather than hanging indefinitely (implemented in `plugins/drivin/hooks/hooks.json` line 11: `"timeout": 10`).

### Git Directory-Scoped Command Denial

The `.claude/settings.json` explicitly denies the bash command pattern `git -C:*`, preventing directory-scoped git operations that could bypass the shell script principle. This forces all git operations to occur in the current working directory, making automated git behavior predictable and auditable (implemented in `.claude/settings.json` line 3).

### Worktree Session Isolation

The trippin plugin isolates exploration sessions using git worktrees, creating dedicated branches (`trip/<trip-name>`) and directories (`.worktrees/<trip-name>/`) for each session. The `ensure-worktree.sh` script validates that neither the worktree nor the branch already exists before creation, preventing accidental overwrites of in-progress sessions. Each worktree operates on its own branch, ensuring that experimental changes cannot affect the main working tree (implemented in `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh`).

### Branch Protection

Not observed. No GitHub branch protection rules are configured in the repository settings. Main branch can be committed to directly without pull request requirements. This is appropriate for a personal development tool repository but means automated git operations have full write access to all branches.

## Secrets Management

### Git-Ignored Local Settings

The `.gitignore` file excludes `.DS_Store` and `.claude/settings.local.json`, preventing local settings and user-specific configuration from being committed to the repository. The settings.local.json file may contain file system paths or user preferences that should not be shared. macOS metadata files (.DS_Store) are also excluded to prevent unintentional information disclosure about directory structures.

### Zero Runtime Dependencies

The project has zero npm dependencies, Python packages, or other runtime libraries beyond shell commands and GitHub Actions. This eliminates entire classes of supply chain attacks. The validation workflow verifies JSON structure but does not install or execute external packages (verified by absence of package.json, requirements.txt, or similar dependency manifests).

### GitHub Actions Token Scope

The release workflow declares explicit permission scope (`contents: write`) rather than using default workflow permissions. This follows the principle of least privilege by restricting the workflow's capabilities to only what is necessary for creating releases. No other permission scopes (issues, pull requests, deployments) are granted (implemented in `.github/workflows/release.yml` lines 9-10).

### No Secret Scanning

Not observed. The repository does not configure GitHub's secret scanning feature or use third-party secret detection tools. Given zero runtime dependencies and no handling of user credentials beyond GitHub's built-in token mechanism, this gap is low risk but could be valuable for detecting accidentally committed personal tokens or API keys in future additions.

## Input Validation

### Ticket Frontmatter Validation

Comprehensive validation of ticket frontmatter is enforced on every Write and Edit operation through the PostToolUse hook. The validation script (`plugins/drivin/hooks/validate-ticket.sh`) validates file location, filename format, and multiple frontmatter fields:

**File constraints:**
- **Location**: Must be in `todo/`, `icebox/`, or `archive/<branch>/` directories (lines 32-43)
- **Filename format**: Must match `YYYYMMDDHHmmss-*.md` pattern using regex `^[0-9]{14}-.*\.md$` (lines 49-54)
- **Frontmatter presence**: Must start with `---` (lines 65-69)

**Required fields with validation:**
- **created_at**: Must be ISO 8601 format matching pattern `^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}$` (lines 83-95)
- **author**: Must be valid email format and not `@anthropic.com` (lines 97-116)
- **type**: Must be one of: `enhancement`, `bugfix`, `refactoring`, `housekeeping` (lines 118-130)
- **layer**: YAML array containing only: `UX`, `Domain`, `Infrastructure`, `DB`, `Config` (lines 132-153)

**Optional fields with validation when present:**
- **effort**: Must be one of: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h` (lines 155-164)
- **commit_hash**: Must be 7-40 hex characters (lines 166-175)
- **category**: Must be one of: `Added`, `Changed`, `Removed` (lines 177-186)

Validation errors exit with code 2, blocking the operation and providing clear error messages with references to authoritative documentation via `print_skill_reference()`.

### Trip Name Validation

The trippin plugin's `init-trip.sh` script validates trip session names using the regex pattern `^[a-z0-9][a-z0-9-]*[a-z0-9]$`, enforcing lowercase alphanumeric characters with hyphens and prohibiting leading or trailing hyphens. This prevents directory traversal via malicious trip names and ensures consistent, predictable file system paths for trip artifacts under `.workaholic/.trips/` (implemented in `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` lines 15-18).

### Shell Script Error Handling

All 24 shell scripts use strict error handling. The drivin plugin's POSIX scripts use `set -eu` or `#!/bin/sh -eu`, enabling fail-fast behavior. The `-e` flag causes scripts to exit immediately on any command returning non-zero, and the `-u` flag exits on undefined variable usage. The trippin plugin's bash scripts use `set -euo pipefail`, adding the `pipefail` option which causes pipelines to fail if any command in the pipeline fails, not just the last one. Three drivin scripts (`branching/sh/check.sh`, `branching/sh/create.sh`, `branching/sh/check-version-bump.sh`) use `#!/bin/sh` without `-eu` flags. This prevents partial execution from leaving the system in an inconsistent state.

### JSON Validation in CI

GitHub Actions workflows validate JSON configuration files on every push and pull request using jq for structural validation (`.github/workflows/validate-plugins.yml`):

- **marketplace.json validation**: Uses `jq empty` to ensure valid JSON structure (lines 23-29)
- **plugin.json validation**: Iterates over `plugins/*/.claude-plugin/plugin.json` and validates JSON structure with `jq empty` (lines 33-58)
- **Required field checks**: Extracts and validates `name` and `version` fields using jq selectors (lines 42-56)
- **Skill path verification**: Reads skill paths from plugin.json with `jq -r '.skills[]?.path // empty'` and verifies files exist (lines 61-79)
- **Marketplace consistency check**: Compares plugin names in marketplace.json against actual directories (lines 81-102)

These validations cover both the drivin and trippin plugins, preventing malformed configuration from being merged and protecting against syntax errors that could cause plugin load failures.

### Git Command Injection Prevention

Shell scripts that construct git commands use fixed command structures without interpolating user-controlled input. For example, `gather-git-context/sh/gather.sh` uses static commands like `git branch --show-current`, `git remote show origin`, and `git remote get-url origin` with no variable interpolation into the command strings themselves. Variables are only used after command execution completes, operating on the output rather than the command construction.

URL transformation operations use sed with fixed patterns (`sed 's|^git@github\.com:|https://github.com/|'`) rather than user-provided regex, preventing injection through malicious remote URLs.

The trippin plugin's `ensure-worktree.sh` passes the trip name as a branch name argument (`trip/${trip_name}`) to `git worktree add`. While the trip name originates from user input, the `init-trip.sh` validation restricts it to `[a-z0-9-]` characters, preventing shell metacharacter injection.

### Markdown Content Safety

Not observed. No sanitization or validation is performed on the markdown body content of tickets beyond frontmatter validation. Malicious markdown could contain script tags, XSS payloads, or other content that would be unsafe if rendered in a web context. This is low risk given tickets are local files for AI consumption, but could be relevant if ticket content is ever displayed in a web UI.

## Observations

The project demonstrates defense-in-depth for its threat model through multiple layers of protection:

- Repository-scoped GitHub tokens with explicit minimal permissions avoid long-lived credential risks
- Local settings are git-ignored to prevent credential leakage or path disclosure
- Anthropic email rejection ensures audit trail integrity and prevents misattribution
- The `set -eu` and `set -euo pipefail` patterns across all 24 shell scripts provide fail-fast behavior, preventing partial execution states
- Permission-free bundled scripts eliminate a common security prompt attack vector in plugin systems
- Comprehensive frontmatter validation with 7 validated fields ensures data integrity for the ticket system
- JSON validation in CI with required field checks prevents configuration corruption across both plugins
- The 10-second hook timeout prevents denial-of-service from runaway validation scripts
- Zero runtime dependencies eliminate supply chain attack surface entirely
- Git command construction uses fixed patterns without user input interpolation
- Transparent warning in README gives users informed consent about git automation scope
- The `git -C` command denial in settings.json enforces predictable git operation scope
- Trip name validation restricts session names to safe alphanumeric characters, preventing directory traversal
- Worktree isolation ensures exploration sessions cannot corrupt the main working tree
- The trippin plugin's `pipefail` option provides stricter pipeline failure detection than the drivin plugin's POSIX-compatible scripts

The security posture is appropriate for a development tool handling local git operations with no network services, user authentication systems, or sensitive data storage beyond git credentials managed by the platform.

## Gaps

Areas where no implementation was observed but could be relevant for future consideration:

- Not observed: No dependency scanning or supply chain security tooling such as Dependabot or Snyk. Currently appropriate given zero runtime dependencies, but any future addition of npm packages, Python libraries, or GitHub Actions would require dependency scanning to monitor for known vulnerabilities.

- Not observed: No signed commits or GPG signature verification on git operations. Ticket authorship validation provides audit trail integrity at the metadata level, but git commits themselves are not cryptographically signed or verified.

- Not observed: No explicit security policy document (SECURITY.md) for vulnerability reporting or security contact information. If vulnerabilities are discovered by external researchers, there is no documented channel for responsible disclosure.

- Not observed: No Content Security Policy or sandboxing beyond Claude Code's built-in execution restrictions. Shell scripts run with the user's full permissions, including file system access and git operations.

- Not observed: No rate limiting or resource consumption limits on shell script execution beyond the single 10-second timeout on validation hooks. Long-running scripts in skills could consume excessive CPU or memory.

- Not observed: No input sanitization for special characters in ticket markdown body content. While frontmatter is validated, the markdown content itself is not sanitized for potentially malicious content.

- Not observed: No GitHub branch protection rules. Main branch can be committed to directly without pull request review requirements, code owner approval, or status checks.

- Not observed: No automated security scanning of shell scripts for common vulnerabilities such as command injection patterns, unsafe use of eval, or unquoted variable expansion in dangerous contexts.

- Not observed: The trippin plugin's `trip-commit.sh` uses `git add -A` to stage all changes in the worktree before committing. While this operates within an isolated worktree, it stages all untracked and modified files without selective filtering, which could inadvertently commit sensitive files if they exist in the worktree.
