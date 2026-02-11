---
title: Test Policy
description: The verification and validation strategy -- testing levels, coverage targets, and processes that ensure correctness
category: developer
modified_at: 2026-02-11T00:00:00+09:00
commit_hash: f7f779f
---

[English](test.md) | [Japanese](test_ja.md)

# Test Policy

This document describes the testing and verification practices in the Workaholic repository. Workaholic is a configuration and documentation project composed of markdown files, JSON configuration, and shell scripts. Rather than traditional unit or integration tests, verification relies on structural validation, runtime hooks, and output validation.

## Testing Framework

No traditional testing frameworks are configured. No test configuration files (jest.config, vitest.config, playwright.config, cypress.config, pytest.ini) exist in the repository. This aligns with the project's nature as a Claude Code plugin marketplace composed entirely of configuration and documentation artifacts.

No shell script testing frameworks (bats, shunit2) or linting tools (shellcheck) are configured. The 19 shell scripts in `plugins/core/skills/*/sh/*.sh` rely on POSIX sh compliance standards documented in rule files rather than automated testing or linting (`.claude/rules/shell.md`).

No markdown linting tools (markdownlint-cli, remark-lint) are configured for the 366 markdown files in `.workaholic/`. Markdown quality relies on documented standards (Mermaid syntax, heading numbering, link format) enforced through code review (`plugins/core/rules/diagrams.md`, `plugins/core/rules/general.md`).

## Testing Levels

### Structural Validation (CI)

The `.github/workflows/validate-plugins.yml` workflow runs on every push and pull request to the main branch. It executes four validation steps:

1. Validates that `.claude-plugin/marketplace.json` is valid JSON using `jq empty`
2. Validates that each `plugins/*/.claude-plugin/plugin.json` is valid JSON and contains required `name` and `version` fields
3. Checks that all skill files declared in `plugin.json` files exist at their specified paths
4. Verifies that every plugin listed in `marketplace.json` has a corresponding directory in `plugins/`

All validation steps run on ubuntu-latest with Node.js 20 (`.github/workflows/validate-plugins.yml` lines 10-103).

### Runtime Validation (Hook)

The `plugins/core/hooks/validate-ticket.sh` script executes after every Write or Edit tool operation, configured in `plugins/core/hooks/hooks.json` with a 10-second timeout. The hook validates:

- File location: tickets must be in `.workaholic/tickets/todo/`, `.workaholic/tickets/icebox/`, or `.workaholic/tickets/archive/<branch>/` directories
- Filename format: must match `YYYYMMDDHHmmss-*.md` pattern
- Frontmatter presence: must start with YAML frontmatter (`---`)
- Required fields: `created_at` (ISO 8601 format), `author` (email, not @anthropic.com), `type` (enhancement|bugfix|refactoring|housekeeping), `layer` (YAML array of UX|Domain|Infrastructure|DB|Config)
- Optional fields: `effort` (0.1h|0.25h|0.5h|1h|2h|4h), `commit_hash` (7-40 hex chars), `category` (Added|Changed|Removed)

Exit code 2 blocks the operation; exit code 0 allows it to proceed (`plugins/core/hooks/validate-ticket.sh` lines 1-190).

### Output Validation (Scan)

The `plugins/core/skills/validate-writer-output/sh/validate.sh` script checks that expected output files exist and are non-empty before README index updates proceed. It validates:

- Viewpoint analyst output: 8 files in `.workaholic/specs/` (ux.md, model.md, usecase.md, infrastructure.md, application.md, component.md, data.md, feature.md)
- Policy analyst output: 7 files in `.workaholic/policies/` (test.md, security.md, quality.md, accessibility.md, observability.md, delivery.md, recovery.md)

Returns JSON with per-file status (ok|missing|empty) and overall pass/fail (`plugins/core/skills/validate-writer-output/sh/validate.sh` lines 1-35, `plugins/core/commands/scan.md` lines 70-82).

### Manual Review (Approval)

The `/drive` command implements a mandatory approval flow for every ticket implementation. After implementing each ticket, the system presents changes to the developer using `AskUserQuestion` with selectable options (Approve, Approve and stop, Abandon, Other). This manual review gates every commit to the codebase (`plugins/core/commands/drive.md` and `plugins/core/skills/drive-approval/SKILL.md`).

When developers provide feedback, the ticket file is updated BEFORE code changes. A Discussion section is appended with timestamp, verbatim feedback, ticket updates, and direction change interpretation. Subsequent revisions are numbered (Revision 1, Revision 2, etc.) for traceability (`plugins/core/skills/drive-approval/SKILL.md`).

## Coverage Targets

Not observed. No code coverage measurement tools (nyc, c8, istanbul, coverage.py) or coverage targets are configured.

The project's verification strategy focuses on structural correctness (valid JSON, required fields, file existence) rather than behavioral test coverage. This aligns with the codebase composition: configuration files (JSON), documentation files (markdown), and executable scripts (shell) have no application logic requiring traditional unit test coverage.

## Test Organization

Not observed. The repository does not contain test directories (`__tests__/`, `test/`, `tests/`, `spec/`) or test files following naming patterns (`*.test.js`, `*.spec.ts`, `*_test.py`).

The 19 shell scripts in `plugins/core/skills/*/sh/*.sh` do not have accompanying test files. Shell scripts are organized by skill domain but have no automated test coverage. Script correctness relies on POSIX sh compliance standards documented in `plugins/core/rules/shell.md` (shebang `#!/bin/sh -eu`, forbidden bash features, inline complexity prohibition) and enforced through code review.

The 366 markdown files in `.workaholic/` are organized by content type (specs, policies, tickets, terms) but have no automated validation beyond structural checks. Markdown quality relies on documented standards (Mermaid syntax, heading numbering, link format) enforced through code review (`plugins/core/rules/diagrams.md`, `plugins/core/rules/general.md`).

## Observations

The verification strategy prioritizes correctness at key integration points rather than comprehensive test coverage:

- **CI pipeline validation**: Validates JSON structure and plugin integrity before merging to main (`.github/workflows/validate-plugins.yml`). Prevents broken marketplace configuration from entering the main branch.
- **Runtime hook validation**: Provides immediate feedback during development sessions when ticket format is incorrect (`plugins/core/hooks/validate-ticket.sh`). Blocks malformed tickets at write time rather than at commit time.
- **Output validation**: Validates documentation generator output to prevent broken links before committing index updates (`plugins/core/commands/scan.md` lines 70-82). Ensures README files only link to existing documents.
- **Manual approval gates**: Requires developer review before committing each ticket implementation (`plugins/core/skills/drive-approval/SKILL.md`). Provides human judgment on correctness and quality.

The validation strategy matches the project's nature as a configuration repository. Structural correctness (valid JSON, required fields, file existence) is more critical than behavioral correctness for configuration and documentation artifacts.

The absence of shell script testing means that logic regressions in the 19 bundled scripts would not be caught until runtime. However, the scripts are primarily data transformation (git context gathering, ticket metadata extraction, branch creation) rather than complex business logic, reducing regression risk.

## Gaps

**Shell script linting**: No shellcheck or shell test frameworks (bats, shunit2) are configured for the 19 bundled shell scripts. Script correctness relies on documented POSIX sh compliance standards and code review rather than automated linting.

**Markdown linting**: No markdownlint-cli or remark-lint is configured for the 366 markdown files. Markdown quality relies on documented standards (Mermaid syntax, heading numbering, link format) and code review rather than automated validation.

**Integration testing**: No end-to-end command workflow testing exists. The `/ticket` → `/drive` → `/report` workflow is verified through manual use rather than automated integration tests.

**JSON schema validation**: JSON validation uses only basic syntax checking (`jq empty`). No JSON schema validation exists for structure beyond required field presence (name, version). More complex schema constraints (field types, allowed values, interdependencies) are not enforced.

**Shell script unit tests**: The 19 shell scripts have no accompanying unit tests. Functions within scripts (validation, parsing, transformation) are not tested in isolation. Script correctness relies on manual testing during development and review.

**Regression test suite**: No regression test suite exists to verify that bug fixes remain fixed. The only regression prevention mechanism is the CI structural validation, which catches configuration/structure regressions but not behavioral regressions in scripts.

**Performance testing**: No performance benchmarks or tests exist for shell scripts. Script execution time and resource usage are not measured or validated.

**Contract testing**: No contract testing exists between components (commands, agents, skills). Interface changes that break callers are caught through manual review and runtime errors rather than automated contract tests.
