---
name: report
description: Context-aware report generation and PR creation for drive and trip workflows.
skills:
  - trip-protocol
  - write-trip-report
  - branching
---

# Report

**Notice:** When user input contains `/report`, `/report-drive`, or `/report-trip` - whether "run /report", "do /report", "create report", or similar - they likely want this command.

Context-aware report command that auto-detects whether you are in a drive or trip workflow and generates the appropriate report.

## Instructions

### Step 1: Detect Context

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/detect-context.sh
```

Parse the JSON output. Route to the appropriate workflow based on `context`.

### Step 2: Route by Context

#### Drive Context (`context: "drive"`)

1. **Bump version** following CLAUDE.md Version Management section (patch increment). **Skip if a "Bump version" commit already exists in the current branch** (check with `bash ${CLAUDE_PLUGIN_ROOT}/../drivin/skills/branching/sh/check-version-bump.sh`; if `already_bumped` is `true`, skip this step).
2. **Invoke story-writer** (`subagent_type: "drivin:story-writer"`, `model: "opus"`)
3. **Display story content**: Read the story file from the `story_file` path in the story-writer result and output the entire Markdown content so the developer can review inline
4. **Display PR URL** from story-writer result (mandatory)

#### Trip Context (`context: "trip"`)

Use the `trip_name` from the detection result, or `$ARGUMENT` if provided.

1. Locate the trip directory at `.workaholic/.trips/<trip-name>/`. If it does not exist, inform the user and stop.
2. **Gather artifacts**: `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/write-trip-report/sh/gather-artifacts.sh "<trip-name>"`
3. **Generate journey report**: Follow the preloaded **write-trip-report** skill **strictly**. The report **must** use the exact template structure defined in the skill — no sections added, removed, renamed, or reordered. Follow the skill's extraction guidelines precisely. Write to `.workaholic/stories/<branch-name>.md`.
4. **Commit and push**:
   ```bash
   git add .workaholic/stories/<branch-name>.md
   git commit -m "Add trip journey report"
   git push -u origin <branch-name>
   ```
5. **Create or update PR**: Derive title from direction summary. Use `gh pr create` or `gh pr edit` if PR already exists.
6. **Display story content**: Read `.workaholic/stories/<branch-name>.md` and output the entire Markdown content so the developer can review inline
7. **Display PR URL** (mandatory)

#### Trip-Drive Hybrid Context (`context: "trip_drive"`)

This branch started as a trip and now has drive-style tickets. Ask the user which report to generate using AskUserQuestion:
- **"Drive story"** - Follow the Drive Context workflow (version bump + story-writer). The story will capture the full narrative including the trip origin.
- **"Trip journey report"** - Follow the Trip Context workflow (artifact gathering + journey report). Use `trip_name` from detection result.

Route to the selected workflow above.

#### Trip Worktree Context (`context: "trip_worktree"`)

Not on a trip branch, but trip worktrees exist.

1. Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/trip-protocol/sh/list-trip-worktrees.sh`
2. Filter to worktrees where `has_pr` is `false` (unreported trips)
3. If no unreported trips found: inform the user "No unreported trip worktrees found." and stop.
4. If exactly one unreported trip: ask the user "Found trip '<trip_name>'. Generate report for this trip?" using AskUserQuestion. If confirmed, use it.
5. If multiple unreported trips: list them and ask the user which one to report on using AskUserQuestion.
6. Once selected, locate the trip directory at `<worktree_path>/.workaholic/.trips/<trip-name>/`. All subsequent git operations must run from within the worktree directory.
7. Follow Trip Context steps 2-7 from within the worktree. The write-trip-report skill template is mandatory — follow it exactly.

#### Unknown Context (`context: "unknown"`)

Ask the user: "Could not determine development context from branch '<branch>'. Are you working on a drive or trip?" using AskUserQuestion with options "Drive" and "Trip". Route accordingly.
