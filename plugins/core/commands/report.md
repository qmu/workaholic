---
name: report
description: Context-aware report generation and PR creation for drive and trip workflows.
skills:
  - work:trip-protocol
  - work:write-trip-report
  - branching
---

# Report

**Notice:** When user input contains `/report`, `/report-drive`, or `/report-trip` - whether "run /report", "do /report", "create report", or similar - they likely want this command.

Context-aware report command that auto-detects whether you are in a drive or trip workflow and generates the appropriate report.

## Instructions

### Step 0: Workspace Guard

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh
```

Parse the JSON output. If `clean` is `true`, proceed silently to Step 1.

If `clean` is `false`, display the `summary` to the user and ask via AskUserQuestion with selectable options:
- **"Ignore and proceed"** - Continue with the report workflow. The unrelated changes will remain in the workspace after the command completes.
- **"Stop"** - Halt the command so you can handle the changes first.

If the user selects "Stop", end the command immediately.

### Step 1: Detect Context

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh
```

Parse the JSON output. Route to the appropriate workflow based on `context`.

### Step 2: Route by Context

#### Work Context (`context: "work"`)

Route by `mode` from detect-context output:

##### Drive Mode (`mode: "drive"`)

1. **Bump version** following CLAUDE.md Version Management section (patch increment). **Skip if a "Bump version" commit already exists in the current branch** (check with `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-version-bump.sh`; if `already_bumped` is `true`, skip this step).
2. **Invoke story-writer** (`subagent_type: "work:story-writer"`, `model: "opus"`)
3. **Display story content**: Read the story file from the `story_file` path in the story-writer result and output the entire Markdown content so the developer can review inline
4. **Display PR URL** from story-writer result (mandatory)

##### Trip Mode (`mode: "trip"`)

1. Locate the trip directory at `.workaholic/.trips/`. Find the most recent trip directory. If none exists, inform the user and stop.
2. **Gather artifacts**: `bash ${CLAUDE_PLUGIN_ROOT}/../work/skills/write-trip-report/scripts/gather-artifacts.sh "<trip-name>"`
3. **Generate report**: Follow the preloaded **write-trip-report** skill. Write to `.workaholic/stories/<branch-name>.md`.
4. **Commit and push**:
   ```bash
   git add .workaholic/stories/<branch-name>.md
   git commit -m "Add trip journey report"
   git push -u origin <branch-name>
   ```
5. **Create or update PR**: Extract the first highlight from the Overview section as the PR title.
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/../work/skills/report/scripts/create-or-update.sh <branch-name> "<title>"
   ```
6. **Display story content**: Read `.workaholic/stories/<branch-name>.md` and output the entire Markdown content so the developer can review inline
7. **Display PR URL** from `create-or-update.sh` output (mandatory)

##### Hybrid Mode (`mode: "hybrid"`)

This branch has both trip artifacts and drive-style tickets. Ask the user which report to generate using AskUserQuestion:
- **"Drive story"** - Follow the Drive Mode workflow (version bump + story-writer). The story will capture the full narrative including the trip origin.
- **"Trip journey report"** - Follow the Trip Mode workflow (artifact gathering + journey report).

Route to the selected workflow above.

#### Worktree Context (`context: "worktree"`)

Not on a work branch, but worktrees exist.

1. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh`
2. Filter to worktrees where `has_pr` is `false` (unreported work)
3. If no unreported worktrees found: inform the user "No unreported worktrees found." and stop.
4. If exactly one unreported worktree: ask the user "Found worktree '<name>'. Generate report?" using AskUserQuestion. If confirmed, use it.
5. If multiple unreported worktrees: list them and ask the user which one to report on using AskUserQuestion.
6. Once selected, all subsequent git operations must run from within the worktree directory.
7. Re-run context detection from within the worktree and follow the appropriate mode workflow.

#### Unknown Context (`context: "unknown"`)

Ask the user: "Could not determine development context from branch '<branch>'. Are you working on a drive or trip?" using AskUserQuestion with options "Drive" and "Trip". Route accordingly.
