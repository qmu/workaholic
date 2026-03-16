---
created_at: 2026-03-16T23:11:22+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Domain, Config]
effort: 2h
commit_hash: 57b2e34
category: Added
---

# Generate Trip Plan Markdown Document for State Persistence and Resume

## Overview

When a trip session is created, generate a `plan.md` Markdown document inside the trip's artifact directory (`.workaholic/.trips/<trip-name>/plan.md`). This document serves as the persistent state record for the entire trip lifecycle: it captures the initial idea from the user, tracks which workflow phase and step the trip is currently in, and records any amended changes to the plan as the session progresses. By reading this plan file on resume, the trip command and its agents can reconstruct exactly where the session left off after a shutdown, avoiding re-execution of completed steps and ensuring continuity of the collaborative process.

Currently, the trip command's resume logic (Step 1 in `trip.md`) only checks whether the worktree and artifact directories exist. It has no knowledge of what phase the trip was in, which steps were completed, or what the original user instruction was. If Claude Code shuts down mid-trip, resuming requires manually inspecting git history and artifacts to determine progress. The plan document fills this gap by providing a single authoritative source of trip state.

## Key Files

- `plugins/trippin/commands/trip.md` - Trip command orchestration; must write the initial plan document after artifact initialization, update it at phase transitions, and read it on resume to restore state
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill; must define the plan document format, update semantics, and how agents interact with it
- `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` - Trip directory initialization; should create the plan.md file with initial template as part of setup
- `plugins/trippin/agents/planner.md` - Planner agent; should update plan.md with direction summaries and test plan status
- `plugins/trippin/agents/architect.md` - Architect agent; should update plan.md with model summaries and review status
- `plugins/trippin/agents/constructor.md` - Constructor agent; should update plan.md with design summaries and implementation status
- `plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh` - Artifact gatherer; should include plan.md in gathered artifacts for the journey report
- `plugins/trippin/skills/write-trip-report/SKILL.md` - Trip report skill; can use plan.md as an alternative or supplement to history.md for the Journey section

## Related History

The trip workflow has been iteratively enhanced with worktree resume-or-create prompts, dev environment validation, and cross-command compatibility. The existing resume logic checks for worktree and artifact directory existence but has no awareness of workflow progress. The `history.md` file referenced in the trip report gathering is an optional manual artifact -- not a structured state document. The plan document proposed here is structured and machine-readable, enabling automated resume rather than requiring manual inspection.

Past tickets that touched similar areas:

- [20260312010257-trip-worktree-resume-or-create-prompt.md](.workaholic/tickets/archive/drive-20260312-102414/20260312010257-trip-worktree-resume-or-create-prompt.md) - Added resume-or-create worktree prompt; established the resume path that this ticket enhances with state awareness
- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Initial trip command implementation; created init-trip.sh and the artifact directory structure being extended
- [20260316143858-trip-drive-cross-command-compatibility.md](.workaholic/tickets/archive/drive-20260312-102414/20260316143858-trip-drive-cross-command-compatibility.md) - Trip-drive cross-command compatibility; resume awareness would also help drive-style continuation know where the trip left off
- [20260311011813-dev-environment-readiness-in-trip-worktree.md](.workaholic/tickets/archive/drive-20260310-220224/20260311011813-dev-environment-readiness-in-trip-worktree.md) - Dev environment validation step; plan.md can record whether dev env was already validated to skip re-validation on resume

## Implementation Steps

1. **Define the plan document format** in `plugins/trippin/skills/trip-protocol/SKILL.md`:
   - Add a new "Trip Plan Document" section after the "Artifact Storage" section
   - Define the plan.md structure with YAML frontmatter for machine-readable state and Markdown body for human-readable narrative
   - Frontmatter fields: `instruction` (original user argument), `phase` (planning | coding | complete), `step` (current step identifier like `artifact-generation`, `mutual-review-1`, `concurrent-launch`, etc.), `iteration` (revision cycle count), `updated_at` (ISO timestamp of last update)
   - Body sections: "Initial Idea" (the user's original instruction, preserved verbatim), "Plan Amendments" (append-only log of changes to the plan with timestamps), "Progress" (checklist of completed steps with agent attribution)
   - Document the update rule: the team lead (trip command) updates plan.md at every phase transition and significant step completion, then commits it via `trip-commit.sh`

2. **Update `plugins/trippin/skills/trip-protocol/sh/init-trip.sh`** to create the initial plan.md:
   - Accept an optional second argument for the user instruction (the `$ARGUMENT` from the trip command)
   - After creating the directory structure, write `plan.md` with the initial template: frontmatter with `phase: planning`, `step: not-started`, `iteration: 0`, the user instruction, and empty amendments/progress sections
   - If the instruction argument is not provided, leave the `instruction` field as an empty string (backward compatible)
   - Update JSON output to include `plan_path` field

3. **Update `plugins/trippin/commands/trip.md`** to pass the user instruction and manage plan state:
   - In Step 2 (Initialize Trip Artifacts), pass `$ARGUMENT` as the second argument to `init-trip.sh`
   - In Step 1 resume path, after selecting an existing worktree, read `plan.md` from the trip directory to determine the current phase and step
   - Add a new sub-step between Step 2 and Step 3: if resuming and plan.md shows dev env was already validated (`step` is past `dev-env-validated`), skip Step 3
   - In Step 4 (Launch Agent Teams), include the plan.md path and its current state in the Agent Teams instruction so agents know where to resume
   - Add plan update instructions to the Agent Teams team lead prompt: after each phase transition (planning -> coding, coding -> complete), update plan.md frontmatter and append to the Progress section, then commit

4. **Update agent markdown files** to record progress in plan.md:
   - In `plugins/trippin/agents/planner.md`, `architect.md`, and `constructor.md`, add a rule: after completing a major step (artifact creation, review, test plan, implementation, E2E testing), the agent appends a progress entry to plan.md's Progress section
   - Progress entry format: `- [x] <phase>/<step> (<agent>) - <brief description> (<timestamp>)`
   - This is in addition to the commit-per-step rule; the plan.md provides a consolidated view while commits provide the full trace

5. **Create a shell script** `plugins/trippin/skills/trip-protocol/sh/read-plan.sh` to parse plan.md state:
   - Accept trip path as argument
   - Extract frontmatter fields (phase, step, iteration) from plan.md
   - Output JSON: `{"phase": "planning", "step": "mutual-review-1", "iteration": 2, "instruction": "...", "updated_at": "..."}`
   - If plan.md does not exist, output `{"phase": "unknown", "step": "unknown"}` (backward compatible with trips created before this feature)

6. **Update resume logic in `plugins/trippin/commands/trip.md`** to use plan state:
   - When resuming, call `read-plan.sh` to get the current state
   - Based on the phase and step, determine where to resume:
     - `phase: planning, step: artifact-generation` -> resume at Planning Phase Step 1 (agents create artifacts)
     - `phase: planning, step: mutual-review-N` -> resume at Planning Phase Step 2 (review session)
     - `phase: coding, step: concurrent-launch` -> resume at Coding Phase Step 1
     - `phase: coding, step: review-and-testing` -> resume at Coding Phase review/testing
     - `phase: complete` -> inform the user the trip is complete; suggest `/report` or drive transition
   - Pass the resume state to the Agent Teams instruction so the team lead can skip completed steps

7. **Update `plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh`** to include plan.md:
   - Add plan.md detection alongside the existing history.md detection
   - Output `has_plan` and `plan_path` fields in the JSON output
   - The trip report can use the plan's Progress section as a structured alternative to history.md for the Journey section

## Patches

### `plugins/trippin/skills/trip-protocol/sh/init-trip.sh`

```diff
--- a/plugins/trippin/skills/trip-protocol/sh/init-trip.sh
+++ b/plugins/trippin/skills/trip-protocol/sh/init-trip.sh
@@ -1,6 +1,7 @@
 #!/bin/bash
 # Initialize a trip directory structure under .workaholic/.trips/
-# Usage: bash init-trip.sh <trip-name>
+# Usage: bash init-trip.sh <trip-name> [instruction]
+# The optional instruction argument is the user's original trip description.
 # Output: JSON with trip_path

 set -euo pipefail
@@ -18,6 +19,28 @@
   exit 1
 fi

+trip_name="${1:-}"
+instruction="${2:-}"
+
 trip_path=".workaholic/.trips/${trip_name}"

 if [ -d "$trip_path" ]; then
@@ -26,4 +29,24 @@
 fi

 mkdir -p "${trip_path}/directions/reviews" "${trip_path}/models/reviews" "${trip_path}/designs/reviews" "${trip_path}/rollbacks/reviews"

-echo '{"trip_path": "'"$trip_path"'"}'
+# Create plan.md with initial state
+updated_at="$(date -Iseconds)"
+cat > "${trip_path}/plan.md" << PLAN_EOF
+---
+instruction: "${instruction}"
+phase: planning
+step: not-started
+iteration: 0
+updated_at: ${updated_at}
+---
+
+# Trip Plan
+
+## Initial Idea
+
+${instruction:-_(No instruction provided)_}
+
+## Plan Amendments
+
+## Progress
+PLAN_EOF
+
+echo '{"trip_path": "'"$trip_path"'", "plan_path": "'"${trip_path}/plan.md"'"}'
```

> **Note**: This patch is speculative - the exact variable positioning for `trip_name` and `instruction` parsing needs to account for the existing `trip_name` assignment on line 8. The second argument extraction should be added after the existing validation block.

### `plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh`

```diff
--- a/plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh
+++ b/plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh
@@ -37,6 +37,12 @@
 # Check for history.md
 has_history=false
 history_path="${trip_path}/history.md"
 if [ -f "$history_path" ]; then
   has_history=true
 fi
+
+# Check for plan.md
+has_plan=false
+plan_path="${trip_path}/plan.md"
+if [ -f "$plan_path" ]; then
+  has_plan=true
+fi

@@ -78,5 +84,7 @@
   "design_reviews": ${des_rev_json},
   "has_history": ${has_history},
-  "history_path": "${history_path}"
+  "history_path": "${history_path}",
+  "has_plan": ${has_plan},
+  "plan_path": "${plan_path}"
 }
 EOF
```

## Considerations

- The plan.md frontmatter uses a simplified step identifier (e.g., `mutual-review-1`, `concurrent-launch`) rather than encoding the full state of all three agents. If one agent completed a step but another did not before shutdown, the plan.md only records the last completed gate. The Agent Teams team lead should check both plan.md and the actual artifact files to determine precisely which agents need to resume work. (`plugins/trippin/commands/trip.md` Step 4)
- The `instruction` field in plan.md frontmatter may contain special characters, quotes, or multi-line content from the user's input. The shell script writing this field must properly escape or quote the content to avoid YAML parsing issues. Consider using a heredoc with proper quoting or a JSON-to-YAML conversion. (`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`)
- Updating plan.md at every step creates additional commits via `trip-commit.sh`. This increases the commit count on the trip branch. Since the plan update is small (appending a progress line and updating frontmatter), it could be bundled with the agent's artifact commit rather than being a separate commit. The implementation should clarify whether plan updates are standalone commits or part of the agent's step commit. (`plugins/trippin/skills/trip-protocol/SKILL.md` Commit-per-Step Rule)
- The `read-plan.sh` script parses YAML frontmatter from a Markdown file. Shell-based YAML parsing is fragile. The script should use simple `grep`/`sed` patterns to extract known fields rather than attempting full YAML parsing. If the frontmatter format is kept flat (no nested objects), basic line-by-line extraction is reliable. (`plugins/trippin/skills/trip-protocol/sh/read-plan.sh`)
- Existing trips created before this feature will not have a plan.md file. The `read-plan.sh` script handles this by returning `{"phase": "unknown"}`, and the resume logic should fall back to the current behavior (check for artifact directory existence only) when no plan.md is found. This ensures backward compatibility. (`plugins/trippin/commands/trip.md` Step 1)
- The plan.md Progress section uses an append-only pattern. Over long trips with many iterations, this section could grow large. This is acceptable because trips are bounded (they eventually complete or are abandoned), and the full progress log is valuable for the trip report's Journey section. (`plugins/trippin/skills/trip-protocol/SKILL.md`)
- The relationship between plan.md and the existing optional `history.md` (used by `write-trip-report`) should be clarified. Plan.md is structured and machine-readable for resume; history.md is a free-form narrative written by agents. They serve different purposes and both can coexist. The trip report skill should prefer plan.md's Progress section over git log when available, and history.md over plan.md when both exist (since history.md is a deliberate narrative choice). (`plugins/trippin/skills/write-trip-report/SKILL.md` lines 75-82)

## Final Report

### Changes

- Added Trip Plan Document section to `plugins/trippin/skills/trip-protocol/SKILL.md` defining plan.md format, step identifiers, and update rules
- Updated `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` to accept optional instruction argument and create plan.md with initial state
- Created `plugins/trippin/skills/trip-protocol/sh/read-plan.sh` to parse plan.md frontmatter and output JSON state
- Updated `plugins/trippin/commands/trip.md` resume logic to read plan state and skip completed steps; passes instruction and plan context to Agent Teams
- Updated `plugins/trippin/agents/planner.md`, `architect.md`, `constructor.md` with progress tracking rule for plan.md
- Updated `plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh` to detect and output plan.md availability
- Updated `plugins/trippin/skills/write-trip-report/SKILL.md` Journey section with priority order: history.md > plan.md Progress > git log

### Test Plan

- Verified init-trip.sh creates plan.md with correct frontmatter and body (with and without instruction argument)
- Verified read-plan.sh correctly parses plan state from plan.md
- Verified read-plan.sh returns backward-compatible `{"phase": "unknown"}` when plan.md does not exist
