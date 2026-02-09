---
title: Security Policy
description: The assets worth protecting, threat model, authentication/authorization boundaries, and safeguards in place
category: developer
modified_at: 2026-02-09T13:52:23+09:00
commit_hash: d627919
---

[English](security.md) | [Japanese](security_ja.md)

# Security Policy

This document describes the security practices implemented in the Workaholic repository. As a Claude Code plugin that manages git operations autonomously, security considerations center on credential protection, execution boundaries, input validation, and safe operational patterns.

## Authentication

### Git Credential Management

Repository-scoped GitHub tokens are used exclusively for automated operations. The release workflow uses `${{ secrets.GITHUB_TOKEN }}`, which is a temporary, repository-scoped token automatically provided by GitHub Actions with limited permissions (`contents: write`). No personal access tokens or custom secrets are required (implemented in `.github/workflows/release.yml`).

### Author Identity Validation

Ticket creation enforces authentic authorship by rejecting Anthropic email addresses in the `author` field. The validation hook explicitly blocks `@anthropic.com` emails, requiring developers to use their actual git email from `git config user.email`. This prevents AI-generated attribution from appearing in ticket metadata (implemented in `plugins/core/hooks/validate-ticket.sh` lines 110-116).

## Authorization

### Git Operation Transparency

The root `README.md` includes a prominent warning section that Workaholic drives git on the developer's behalf, including creating branches, committing, amending, pushing, and opening pull requests. This transparency allows developers to make informed decisions about installation and understand the scope of automated operations.

### Permission-Free Execution Model

Shell scripts are bundled within skills and executed via the `bash` command without requiring executable permissions. This eliminates the need for permission prompts during plugin installation and ensures consistent behavior across all user environments. Scripts use the shebang `#!/bin/sh -eu` pattern for strict error handling (all scripts in `plugins/core/skills/*/sh/`).

### Hook Timeout Enforcement

The PostToolUse validation hook enforces a 10-second timeout, preventing runaway validation scripts from blocking development workflows. This ensures that validation failures fail fast rather than hanging indefinitely (implemented in `plugins/core/hooks/hooks.json`).

## Secrets Management

### Git-Ignored Local Settings

The `.gitignore` file excludes `.DS_Store` and `.claude/settings.local.json`, preventing local settings and user-specific configuration from being committed to the repository. Local settings may contain file system paths or user preferences that should not be shared.

### No Secret Scanning Required

Not observed. The project has zero runtime dependencies and does not handle user credentials, API keys, or other secrets in the codebase. All authentication is handled through GitHub's built-in token mechanism.

## Input Validation

### Ticket Frontmatter Validation

Comprehensive validation of ticket frontmatter is enforced on every Write and Edit operation through the PostToolUse hook. The validation script (`plugins/core/hooks/validate-ticket.sh`) validates:

- **File location**: Must be in `todo/`, `icebox/`, or `archive/<branch>/` directories
- **Filename format**: Must match `YYYYMMDDHHmmss-*.md` pattern
- **YAML frontmatter presence**: Must start with `---`
- **created_at field**: Must be ISO 8601 format (e.g., `2026-01-29T04:19:24+09:00`)
- **author field**: Must be valid email format and not `@anthropic.com`
- **type field**: Must be one of: `enhancement`, `bugfix`, `refactoring`, `housekeeping`
- **layer field**: YAML array containing only: `UX`, `Domain`, `Infrastructure`, `DB`, `Config`
- **effort field**: If present, must be one of: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`
- **commit_hash field**: If present, must be 7-40 hex characters
- **category field**: If present, must be one of: `Added`, `Changed`, `Removed`

Validation errors exit with code 2, blocking the operation and providing clear error messages with references to authoritative documentation.

### Shell Script Error Handling

All shell scripts use `set -eu` (or stricter variants), enabling fail-fast behavior. This ensures that scripts exit immediately on errors (`-e`) and on undefined variable usage (`-u`), preventing partial execution from leaving the system in an inconsistent state (implemented in all 19 shell scripts across `plugins/core/skills/*/sh/` and `plugins/core/hooks/`).

### JSON Validation in CI

GitHub Actions workflows validate JSON configuration files on every push and pull request:

- **marketplace.json validation**: Ensures valid JSON structure using `jq empty`
- **plugin.json validation**: Validates JSON structure and checks required fields (`name`, `version`)
- **Skill path verification**: Verifies all skill paths referenced in `plugin.json` exist in the filesystem
- **Marketplace consistency check**: Ensures plugins listed in `marketplace.json` have corresponding directories

These validations run in the `validate-plugins.yml` workflow, preventing malformed configuration from being merged.

### Git Command Injection Prevention

Shell scripts that construct git commands use shell quoting and avoid user-controlled input in command construction. Git operations use fixed commands with predictable arguments. For example, `gather-git-context/sh/gather.sh` uses `git branch --show-current` and `git remote get-url origin` without interpolating user input into command strings.

## Observations

- The project uses repository-scoped GitHub tokens exclusively, avoiding the security risks of long-lived personal access tokens.
- Local settings are git-ignored to prevent credential leakage or path disclosure.
- Anthropic email rejection prevents misattribution in ticket authorship and ensures audit trail integrity.
- The `set -eu` pattern in all shell scripts provides fail-fast behavior, preventing partial execution states.
- Permission-free bundled scripts eliminate a common security prompt attack vector in plugin systems.
- Comprehensive frontmatter validation ensures data integrity for the ticket system, which serves as the source of truth for project history.
- JSON validation in CI prevents configuration corruption that could lead to plugin malfunction.
- The 10-second hook timeout prevents denial-of-service from runaway validation scripts.

## Gaps

- Not observed: No dependency scanning or supply chain security tooling. This is appropriate given zero runtime dependencies, but future npm or other package additions would require scanning.
- Not observed: No signed commits or GPG signature verification on git operations.
- Not observed: No explicit security policy document (SECURITY.md) for vulnerability reporting or security contact information.
- Not observed: No Content Security Policy or sandboxing beyond Claude Code's built-in execution restrictions.
- Not observed: No rate limiting or resource consumption limits on shell script execution beyond the single 10-second timeout on validation hooks.
- Not observed: No input sanitization for special characters in ticket content, though markdown format provides some inherent safety.
