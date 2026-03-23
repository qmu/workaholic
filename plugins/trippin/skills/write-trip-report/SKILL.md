---
name: write-trip-report
description: Generate trip journey report from agent artifacts and create PR.
allowed-tools: Bash, Read, Write, Glob, Grep
user-invocable: false
---

# Write Trip Report

Generate a development journey report from a trip session's artifacts and create a pull request.

## Gather Artifacts

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/write-trip-report/sh/gather-artifacts.sh <trip-name>
```

Parse JSON output for artifact paths. Read each artifact to extract summaries.

## Report Structure

The report file is written to `.workaholic/stories/<branch-name>.md` with the following sections:

### Template

```markdown
# Trip Report: <trip-name>

## Planner

### Direction
<Summary of the approved direction — goals, stakeholder needs, key decisions>

### Test Plan
<Summary of the test plan — coverage scope, E2E scenarios if applicable>

### Test Results
<Summary of test outcomes — pass/fail, key findings>

## Architect

### Model
<Summary of the approved model — system structure, boundaries, abstractions>

### Review Summary
<Key structural observations from the Architect's reviews — concerns raised, resolutions>

## Constructor

### Design
<Summary of the approved design — implementation approach, technical decisions>

### Implementation
<Summary of what was built — components, patterns used, notable trade-offs>

## Journey

<Contents of history.md if available, otherwise a journey summary generated from the git commit log>

## Trip Activity Log

<Contents of event-log.md if available. For logs exceeding 30 rows, show only
phase-transition events in the main table and include the full log in a
collapsed <details> block.>
```

### Extracting Summaries

For each artifact (direction, model, design): read the latest approved version, extract the Content section, summarize in 3-5 sentences focusing on key decisions and outcomes.

For reviews: read all files in `reviews/` (both `round-<N>-<agent>.md` and `response-<author>-to-<reviewer>.md`), identify key concerns and resolutions, summarize in 2-3 sentences.

### Journey Section

Priority order: (1) `history.md` contents if available, (2) `plan.md` Progress section if `has_plan` is true, (3) git log summary via `git log --oneline --reverse <base-branch>..<trip-branch>`. Commit messages follow `[Agent] description` format, providing a natural collaboration narrative.

### Trip Activity Log Section

If `has_event_log` is true, read `event_log_path`. For logs with 30 or fewer data rows, include the full table directly. For larger logs, show only `phase-transition`, `consensus-reached`, `gate-passed`, and `moderation-resolved` events in the main table and wrap the full log in a `<details><summary>Full event log (N events)</summary>` collapsed block.

## Create PR

After writing the report:

1. Stage and commit the report file
2. Push the branch
3. Create or update PR using `gh pr create` with the report as body

The PR title should be derived from the direction summary (first sentence or key phrase).
