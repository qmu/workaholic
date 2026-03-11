---
name: report-trip
description: Generate trip journey report and create/update a pull request.
skills:
  - trip-protocol
  - write-trip-report
---

# Report Trip

**Notice:** When user input contains `/report-trip` - whether "run /report-trip", "do /report-trip", "update /report-trip", or similar - they likely want this command.

Generate a journey report from trip artifacts and create or update a pull request for the trip branch.

## Instructions

### Step 1: Identify Trip Context

Determine the trip name from the current branch or argument:

- If `$ARGUMENT` is provided, use it as the trip name
- Otherwise, detect from current branch: `trip/<trip-name>` format

```bash
branch=$(git branch --show-current)
```

If the branch does not start with `trip/` and no argument was provided, check for available trip worktrees:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh
```

Parse the JSON output and filter to worktrees where `has_pr` is `false` (unreported trips):

- If no trip worktrees found: inform the user "No active trip worktrees found. Run `/trip` to start a new trip session." and stop.
- If exactly one unreported trip worktree found: ask the user "Found trip '<trip_name>'. Generate report for this trip?" using AskUserQuestion. If confirmed, use its `trip_name` and `branch`.
- If multiple unreported trip worktrees found: list them and ask the user which one to report on using AskUserQuestion.

When operating on a worktree trip (not the current branch), locate the trip directory at `<worktree_path>/.workaholic/.trips/<trip-name>/` rather than the current working directory. All subsequent git operations (add, commit, push) must run from within the worktree directory.

Locate the trip directory at `.workaholic/.trips/<trip-name>/` (or `<worktree_path>/.workaholic/.trips/<trip-name>/` for worktree trips). If it does not exist, inform the user and stop.

### Step 2: Gather Trip Artifacts

Run the gather-artifacts script:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh "<trip-name>"
```

Parse the JSON output. Read each artifact file to understand the content.

### Step 3: Generate Journey Report

Follow the preloaded **write-trip-report** skill to generate the report.

Read each artifact (direction, model, design) and their reviews. Write the report to `.workaholic/stories/<branch-name>.md` with sections for each agent:

- **Planner**: Direction summary, test plan summary, test results
- **Architect**: Model summary, review summary
- **Constructor**: Design summary, implementation summary
- **Journey**: Contents of `history.md` or git commit log summary

### Step 4: Commit and Push

```bash
git add .workaholic/stories/<branch-name>.md
git commit -m "Add trip journey report"
git push -u origin <branch-name>
```

### Step 5: Create PR

Create or update the PR. Derive the title from the direction summary.

```bash
gh pr create --title "<title>" --body-file .workaholic/stories/<branch-name>.md
```

If a PR already exists for this branch, update it instead:

```bash
gh pr edit --body-file .workaholic/stories/<branch-name>.md
```

### Step 6: Return PR URL

Display the PR URL to the user. This is mandatory.
