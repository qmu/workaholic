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
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh <trip-name>
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
```

### Extracting Summaries

For each artifact (direction, model, design):
1. Read the latest approved version
2. Extract the Content section
3. Summarize in 3-5 sentences focusing on key decisions and outcomes

For reviews:
1. Read all review files for each artifact type
2. Identify the key concerns raised and how they were resolved
3. Summarize in 2-3 sentences

### Journey Section

If `history.md` exists in the trip directory, include its contents directly.

If `history.md` does not exist, generate a journey summary from the git commit log:

```bash
git log --oneline --reverse <base-branch>..<trip-branch>
```

The commit messages follow `[Agent] description` format, providing a natural narrative of how the collaboration proceeded.

## Create PR

After writing the report:

1. Stage and commit the report file
2. Push the branch
3. Create or update PR using `gh pr create` with the report as body

The PR title should be derived from the direction summary (first sentence or key phrase).
