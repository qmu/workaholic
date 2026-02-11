---
title: Security Policy
description: The assets worth protecting, threat model, authentication/authorization boundaries, and safeguards in place
category: developer
modified_at: 2026-02-11T15:20:15+00:00
commit_hash: f7f779f
---

[English](security.md) | [Japanese](security_ja.md)

# Security Policy

This document describes the security practices implemented in the Workaholic repository. As a Claude Code plugin that manages git operations autonomously, security considerations center on credential protection, execution boundaries, input validation, and safe operational patterns. The project has zero runtime dependencies and does not handle user credentials beyond git operations, which narrows the threat surface to git credential management, shell script execution safety, and ticket metadata integrity.

## Authentication

### Git Credential Management

Repository-scoped GitHub tokens are used exclusively for automated operations. The release workflow uses `${{ secrets.GITHUB_TOKEN }}`, which is a temporary, repository-scoped token automatically provided by GitHub Actions with limited permissions. The workflow explicitly declares `contents: write` permission scope, granting only the minimum required access for creating releases (implemented in `.github/workflows/release.yml` lines 9-10). No personal access tokens or custom secrets are required.

### Author Identity Validation

Ticket creation enforces authentic authorship by rejecting Anthropic email addresses in the `author` field. The validation hook explicitly blocks `@anthropic.com` emails using regex pattern matching (`[[ "$author" =~ @anthropic\.com$ ]]`), requiring developers to use their actual git email from `git config user.email`. This prevents AI-generated attribution from appearing in ticket metadata and ensures audit trail integrity (implemented in `plugins/core/hooks/validate-ticket.sh` lines 111-116).

### Email Format Validation

The validation hook enforces email format for the `author` field using regex pattern `^[^@]+@[^@]+\.[^@]+$`, ensuring basic structural validity before the Anthropic domain check. Tickets with malformed email addresses are rejected with clear error messages referencing the authoritative skill documentation (implemented in `plugins/core/hooks/validate-ticket.sh` lines 104-108).

## Authorization

### Git Operation Transparency

The root `README.md` includes a prominent warning section (lines 5-6) using GitHub's warning callout syntax that Workaholic drives git on the developer's behalf, including creating branches, committing, amending, pushing, and opening pull requests. This transparency allows developers to make informed decisions about installation and understand the scope of automated operations before enabling the plugin.

### Permission-Free Execution Model

Shell scripts are bundled within skills and executed via the `bash` command without requiring executable permissions. All 19 shell scripts in the repository use the shebang `#!/bin/sh -eu` pattern or equivalent, enabling strict error handling while avoiding the need for chmod +x. This eliminates permission prompts during plugin installation and ensures consistent behavior across all user environments regardless of filesystem permissions (all scripts in `plugins/core/skills/*/sh/` and `plugins/core/hooks/`).

### Hook Timeout Enforcement

The PostToolUse validation hook enforces a 10-second timeout on the ticket validation script, preventing runaway validation from blocking development workflows. The timeout is declared in the hook configuration alongside the command specification, ensuring that validation failures fail fast rather than hanging indefinitely (implemented in `plugins/core/hooks/hooks.json` line 11: `"timeout": 10`).

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

Comprehensive validation of ticket frontmatter is enforced on every Write and Edit operation through the PostToolUse hook. The validation script (`plugins/core/hooks/validate-ticket.sh`) validates file location, filename format, and multiple frontmatter fields:

**File constraints:**
- **Location**: Must be in `todo/`, `icebox/`, or `archive/<branch>/` directories (lines 32-42)
- **Filename format**: Must match `YYYYMMDDHHmmss-*.md` pattern using regex `^[0-9]{14}-.*\.md$` (lines 49-54)
- **Frontmatter presence**: Must start with `---` (lines 65-68)

**Required fields with validation:**
- **created_at**: Must be ISO 8601 format matching pattern `^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}$` (lines 83-95)
- **author**: Must be valid email format and not `@anthropic.com` (lines 97-116)
- **type**: Must be one of: `enhancement`, `bugfix`, `refactoring`, `housekeeping` (lines 118-127)
- **layer**: YAML array containing only: `UX`, `Domain`, `Infrastructure`, `DB`, `Config` (lines 129-145)

**Optional fields with validation when present:**
- **effort**: Must be one of: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h` (lines 147-156)
- **commit_hash**: Must be 7-40 hex characters (lines 158-167)
- **category**: Must be one of: `Added`, `Changed`, `Removed` (lines 169-178)

Validation errors exit with code 2, blocking the operation and providing clear error messages with references to authoritative documentation via `print_skill_reference()`.

### Shell Script Error Handling

All shell scripts use `set -eu` or stricter variants (`#!/bin/sh -eu`), enabling fail-fast behavior. The `-e` flag causes scripts to exit immediately on any command returning non-zero, and the `-u` flag exits on undefined variable usage. This prevents partial execution from leaving the system in an inconsistent state. Verified across all 19 shell scripts with pattern match on shebang and set commands.

### JSON Validation in CI

GitHub Actions workflows validate JSON configuration files on every push and pull request using jq for structural validation (`.github/workflows/validate-plugins.yml`):

- **marketplace.json validation**: Uses `jq empty` to ensure valid JSON structure (lines 23-29)
- **plugin.json validation**: Validates JSON structure with `jq empty` (lines 33-40)
- **Required field checks**: Extracts and validates `name` and `version` fields using jq selectors (lines 42-56)
- **Skill path verification**: Reads skill paths from plugin.json with `jq -r '.skills[]?.path // empty'` and verifies files exist (lines 61-79)
- **Marketplace consistency check**: Compares plugin names in marketplace.json against actual directories (lines 81-102)

These validations prevent malformed configuration from being merged, protecting against syntax errors that could cause plugin load failures.

### Git Command Injection Prevention

Shell scripts that construct git commands use fixed command structures without interpolating user-controlled input. For example, `gather-git-context/sh/gather.sh` uses static commands like `git branch --show-current`, `git remote show origin`, and `git remote get-url origin` with no variable interpolation into the command strings themselves. Variables are only used after command execution completes, operating on the output rather than the command construction (lines 8-16).

URL transformation operations use sed with fixed patterns (`sed 's|^git@github\.com:|https://github.com/|'`) rather than user-provided regex, preventing injection through malicious remote URLs.

### Markdown Content Safety

Not observed. No sanitization or validation is performed on the markdown body content of tickets beyond frontmatter validation. Malicious markdown could contain script tags, XSS payloads, or other content that would be unsafe if rendered in a web context. This is low risk given tickets are local files for AI consumption, but could be relevant if ticket content is ever displayed in a web UI.

## Observations

The project demonstrates defense-in-depth for its threat model through multiple layers of protection:

- Repository-scoped GitHub tokens with explicit minimal permissions avoid long-lived credential risks
- Local settings are git-ignored to prevent credential leakage or path disclosure
- Anthropic email rejection ensures audit trail integrity and prevents misattribution
- The `set -eu` pattern across all 19 shell scripts provides fail-fast behavior, preventing partial execution states
- Permission-free bundled scripts eliminate a common security prompt attack vector in plugin systems
- Comprehensive frontmatter validation with 7 validated fields ensures data integrity for the ticket system
- JSON validation in CI with required field checks prevents configuration corruption
- The 10-second hook timeout prevents denial-of-service from runaway validation scripts
- Zero runtime dependencies eliminate supply chain attack surface entirely
- Git command construction uses fixed patterns without user input interpolation
- Transparent warning in README gives users informed consent about git automation scope

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
