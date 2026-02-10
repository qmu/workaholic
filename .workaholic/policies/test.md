---
title: Test Policy
description: The verification and validation strategy -- testing levels, coverage targets, and processes that ensure correctness
category: developer
modified_at: 2026-02-09T12:00:00+09:00
commit_hash: d627919
---

[English](test.md) | [Japanese](test_ja.md)

# Test Policy

This document describes the testing and verification practices in the Workaholic repository. Workaholic is a configuration and documentation project composed of markdown files, JSON configuration, and shell scripts. Rather than traditional unit or integration tests, verification relies on structural validation, runtime hooks, and output validation.

## Testing Framework

No testing frameworks are configured. No test configuration files (jest.config, vitest.config, playwright.config, cypress.config) exist in the repository. This aligns with the project's nature as a Claude Code plugin marketplace composed entirely of configuration and documentation artifacts.

## Testing Levels

### Structural Validation (CI)

The `.github/workflows/validate-plugins.yml` workflow runs on every push and pull request to the main branch. It executes four validation steps:

1. Validates that `.claude-plugin/marketplace.json` is valid JSON using `jq empty`
2. Validates that each `plugins/*/.claude-plugin/plugin.json` is valid JSON and contains required `name` and `version` fields
3. Checks that all skill files declared in `plugin.json` files exist at their specified paths
4. Verifies that every plugin listed in `marketplace.json` has a corresponding directory in `plugins/`

All validation steps run on ubuntu-latest with Node.js 20 (`.github/workflows/validate-plugins.yml` lines 10-102).

### Runtime Validation (Hook)

The `plugins/core/hooks/validate-ticket.sh` script executes after every Write or Edit tool operation, configured in `plugins/core/hooks/hooks.json` with a 10-second timeout. The hook validates:

- File location: tickets must be in `todo/`, `icebox/`, or `archive/<branch>/` directories
- Filename format: must match `YYYYMMDDHHmmss-*.md` pattern
- Frontmatter presence: must start with YAML frontmatter (`---`)
- Required fields: `created_at` (ISO 8601 format), `author` (email, not @anthropic.com), `type` (enhancement|bugfix|refactoring|housekeeping), `layer` (YAML array of UX|Domain|Infrastructure|DB|Config)
- Optional fields: `effort` (0.1h|0.25h|0.5h|1h|2h|4h), `commit_hash` (7-40 hex chars), `category` (Added|Changed|Removed)

Exit code 2 blocks the operation; exit code 0 allows it to proceed (`plugins/core/hooks/validate-ticket.sh` lines 1-189).

### Output Validation (Scan)

The `plugins/core/skills/validate-writer-output/sh/validate.sh` script checks that expected output files exist and are non-empty before README index updates proceed. It validates:

- Viewpoint analyst output: 8 files in `.workaholic/specs/` (stakeholder.md, model.md, usecase.md, infrastructure.md, application.md, component.md, data.md, feature.md)
- Policy analyst output: 7 files in `.workaholic/policies/` (test.md, security.md, quality.md, accessibility.md, observability.md, delivery.md, recovery.md)

Returns JSON with per-file status (ok|missing|empty) and overall pass/fail (`plugins/core/skills/validate-writer-output/sh/validate.sh` lines 1-35, `plugins/core/commands/scan.md` lines 64-74).

## Coverage Targets

Not observed. No code coverage measurement tools (nyc, c8, istanbul, coverage.py) or coverage targets are configured.

## Test Organization

Not observed. The repository does not contain test directories (`__tests__/`, `test/`, `tests/`, `spec/`) or test files following naming patterns (`*.test.js`, `*.spec.ts`, `*_test.py`).

The 19 shell scripts in `plugins/core/skills/*/sh/*.sh` do not have accompanying test files. Shell scripts are organized by skill domain but have no automated test coverage.

## Observations

- The CI pipeline validates JSON structure and plugin integrity before merging to main (`.github/workflows/validate-plugins.yml`).
- Runtime hooks provide immediate feedback during development sessions when ticket format is incorrect (`plugins/core/hooks/hooks.json`, `plugins/core/hooks/validate-ticket.sh`).
- The scan command validates documentation generator output to prevent broken links before committing index updates (`plugins/core/commands/scan.md` lines 64-74).
- The validation strategy prioritizes structural correctness (valid JSON, required fields, file existence) over behavioral correctness, matching the project's nature as a configuration repository.
- No automated testing prevents regressions in shell script logic, which constitutes the only executable code in the repository beyond JSON schema validation.

## Gaps

- Not observed: No shell script linting tools (shellcheck) or shell test frameworks (bats, shunit2) for the 19 bundled shell scripts.
- Not observed: No markdown linting (markdownlint-cli, remark-lint) or format validation for the 100+ markdown files.
- Not observed: No integration testing for end-to-end command workflows (ticket → drive → report).
- Not observed: No JSON schema validation beyond basic `jq empty` syntax checks.
