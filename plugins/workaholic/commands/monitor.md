---
name: monitor
description: Run the current developer's missions in parallel — one autonomous drive per mission worktree — after a developer-confirmed pre-flight review, looping until every mission completes or only escalation-blocked items remain
skills:
  - workaholic:monitor
  - workaholic:mission
  - workaholic:drive
  - workaholic:branching
  - workaholic:gather
  - workaholic:check-deps
---

# Monitor

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

**Notice:** When user input contains `/monitor` — whether "run /monitor", "monitor the missions", "drive all my missions in parallel", or similar — they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command (main agent) runs the preloaded `workaholic:monitor` skill end to end (§1 Pre-flight → §2 Fan-out → §3 Loop/terminal → §4 Interference → §5 Final report). It owns **all** user interaction: the pre-flight confirmation and the between-wave escalation prompt are issued here — the per-mission drive leaves are `general-purpose` subagents that never call `AskUserQuestion` and never nest `Task` (CLAUDE.md One-Level Fan-Out). Run it from the **main tree**; each mission is driven inside its own `.worktrees/<slug>/` worktree by its own leaf.

### Pre-check: Dependencies

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

If `ok` is `false`, display the `message` and stop. If `missing_guards` is non-empty, warn about the stale/partial install before proceeding — do not block.

### Step 1: Pre-flight review (skill §1)

Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/monitor/scripts/preflight.sh` and present the four-part review from the skill: mission set with progress, current position per worktree (including unmerged work), eligibility (`not_authorized`/`no_plan` → route to `/mission` replan, never drive; `no_worktree` → offer `create-mission-worktree.sh`), and the interference/destination assessment. Then confirm the run with **one** `AskUserQuestion` (`multiSelect`, body prefixed with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`): each eligible mission as an option (unassigned ones labeled claim-and-drive), plus none-of-these to stop. Zero drivable missions → report why (empty set, all ineligible, or orphan worktrees) and stop.

**Unattended invocation** (the run arrives from a caller-side loop such as `/goal /monitor ok`, or the invocation contains "night"): the invocation is the authorization — log the pre-flight instead of prompting, drive only already-assigned eligible missions, and never claim unassigned work.

### Step 2: Fan-out (skill §2)

Spawn one `general-purpose` leaf per confirmed mission **in a single message**, each with the skill's §2 prompt: preload `workaholic:drive`, work only in `( cd <worktree_path> && … )`, prioritize inline, consult `drive-authorized.sh` per ticket, inherit Night Mode §3/§5 (attempt-first, closed outcomes, mint `deferred` tickets, safety floor), return the §2 JSON report.

### Step 3: Loop until terminal (skill §3)

After each wave, run `status.sh` per mission and classify: complete (gate included when declared) / still driveable / escalation-blocked. Surface a wave's escalations in **one** labeled `AskUserQuestion` (interactive) or record them (unattended). Re-drive driveable missions — at most 3 waves per invocation, and stop early on a zero-archive wave. Plan-changing answers route through `/mission` replan, never ad-hoc edits.

### Step 4: Final report (skill §5)

Emit the report — per-mission progress deltas and reconciled outcome counts, the escalation list (never silent), minted tickets, exclusions, stashes — and end with the terminal token on its own final line: `ok` (terminal state reached) or `pending` (work remains for the next invocation). PRs for finished missions are the developer's next step via `/report` / `/ship`, per mission worktree.
