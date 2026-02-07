---
title: Test Policy
description: The verification and validation strategy -- testing levels, coverage targets, and processes that ensure correctness
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](test.md) | [Japanese](test_ja.md)

# 1. Test Policy

This document describes the testing and verification practices observed in the Workaholic repository. Workaholic is a configuration and documentation project (markdown, JSON, shell scripts) with no application code requiring unit or integration tests in the traditional sense.

## 2. Testing Framework

[Explicit] No testing frameworks (Jest, Vitest, Mocha, pytest, etc.) are configured in the repository. No test configuration files exist. This is consistent with the project's nature as a Claude Code plugin composed entirely of markdown and shell scripts.

## 3. Testing Levels

### 3-1. Structural Validation (CI)

[Explicit] The `validate-plugins.yml` GitHub Action provides structural validation on every push and pull request to `main`. It validates that `marketplace.json` is valid JSON, that each `plugin.json` contains required fields (`name`, `version`), that skill files referenced by plugins exist, and that every plugin in `marketplace.json` has a corresponding directory.

### 3-2. Runtime Validation (Hook)

[Explicit] A PostToolUse hook (`validate-ticket.sh`) runs after every Write or Edit operation with a 10-second timeout. This provides continuous runtime validation of ticket frontmatter format and location during development.

### 3-3. Output Validation (Scan)

[Explicit] The `validate-writer-output` skill verifies that expected output files from analyst subagents exist and are non-empty before README index updates proceed. This prevents broken links in documentation.

## 4. Coverage Targets

Not observed. No code coverage tools or targets are configured, which is appropriate given the absence of traditional application code.

## 5. Test Organization

Not observed. Tests are not organized in dedicated directories or files since the project relies on structural and runtime validation rather than traditional test suites.

## 6. Observations

- [Explicit] The CI pipeline validates JSON structure and plugin integrity on every PR.
- [Explicit] Runtime hooks provide continuous validation during Claude Code sessions.
- [Explicit] The scan process validates output before updating index files.
- [Inferred] The validation strategy is appropriate for a configuration-heavy project where correctness means structural integrity (valid JSON, required fields, file existence) rather than behavioral correctness.

## 7. Gaps

- Not observed: No shell script testing (e.g., `shellcheck`, `bats` tests for the 28+ bundled shell scripts).
- Not observed: No linting or format validation for markdown files.
- Not observed: No integration testing for the end-to-end command workflows.
