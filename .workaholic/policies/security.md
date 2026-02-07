---
title: Security Policy
description: Authentication, authorization, secrets management, and security practices
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](security.md) | [Japanese](security_ja.md)

# 1. Security Policy

This document describes the security practices observed in the Workaholic repository. As a Claude Code plugin that manages git operations autonomously, security considerations center on credential protection, input validation, and safe execution boundaries.

## 2. Credential Protection

### 2-1. Git-Ignored Secrets

[Explicit] The `.gitignore` file excludes `.DS_Store` and `.claude/settings.local.json`, preventing local settings from being committed. The local settings file may contain user-specific configuration that should not be shared.

### 2-2. Author Validation

[Explicit] The ticket creation process explicitly rejects Anthropic email addresses in the `author` field, requiring the developer's own git email. This prevents AI-generated attribution from appearing in ticket metadata.

### 2-3. GitHub Token Handling

[Explicit] The release GitHub Action uses `${{ secrets.GITHUB_TOKEN }}` for authentication, which is a repository-scoped token automatically provided by GitHub Actions. No custom secrets are required.

## 3. Execution Boundaries

### 3-1. Git Operation Warning

[Explicit] The root `README.md` includes a prominent warning that Workaholic drives git on the developer's behalf, including creating branches, committing, amending, pushing, and opening pull requests. This transparency allows developers to make informed decisions about installation.

### 3-2. Permission-Free Shell Scripts

[Explicit] Shell scripts are bundled within skills and executed via `bash` command, avoiding the need for executable permissions. Scripts use `#!/bin/sh -eu` with strict error handling (`set -eu`).

### 3-3. Hook Timeout

[Explicit] The PostToolUse validation hook has a 10-second timeout, preventing runaway validation scripts from blocking development.

## 4. Input Validation

[Explicit] Ticket frontmatter is validated on every Write and Edit operation through the PostToolUse hook. This ensures structural integrity of the primary data format.

## 5. Observations

- [Explicit] The project uses repository-scoped GitHub tokens, not personal access tokens.
- [Explicit] Local settings are git-ignored to prevent credential leakage.
- [Explicit] Anthropic email rejection prevents misattribution in ticket authorship.
- [Inferred] The `set -eu` pattern in shell scripts provides fail-fast behavior, preventing partial execution from leaving the system in an inconsistent state.

## 6. Gaps

- Not observed: No dependency scanning or supply chain security tooling (appropriate given zero runtime dependencies).
- Not observed: No signed commits or tag verification.
- Not observed: No explicit security policy document (SECURITY.md) for vulnerability reporting.
- Not observed: No Content Security Policy or sandboxing beyond Claude Code's built-in restrictions.
