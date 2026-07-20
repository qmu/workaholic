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

Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/monitor/scripts/preflight.sh` and present the four-part review from the skill: mission set with progress, current position per worktree (including unmerged work), eligibility, and the interference/destination assessment. Then confirm the run with **one** `AskUserQuestion` (`multiSelect`, body prefixed with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`): each eligible mission as an option (unassigned ones labeled claim-and-drive), plus none-of-these to stop.

**Blockers become decisions (skill §1) — never "report why and stop".** When the pre-flight finds nothing drivable — or leaves ineligible missions behind — push each blocker to the developer as its own labeled `AskUserQuestion`, **one decision at a time**: no missions → offer to start `/mission` creation now; `not_authorized`/`no_plan` → offer to run that mission's replan **interrogation** now (the developer rulings only — applying the replan is the leaf's job, skill §2); `no_worktree` → offer `create-mission-worktree.sh` now; unassigned → the claim question. Proceed with whatever each answer unlocks; only an explicit decline ends the run early, and only an explicitly deferred decision counts as escalation-blocked later.

**Collect every ruling first, then dispatch (skill §1).** Gather every developer decision this run needs — the run authorization, the claim-and-drive choices, and each replan's design rulings — here in the main agent **before** spawning any leaf. A leaf cannot prompt (one-level fan-out), so each ruling rides in its mission's dispatch payload; a leaf is never spawned to wait on an answer it cannot ask for.

**Unattended invocation** (the run arrives from a caller-side loop such as `/goal /monitor ok`, or the invocation contains "night"): the invocation is the authorization — log the pre-flight instead of prompting, drive only already-assigned eligible missions, and never claim unassigned work.

**Mint the run-id here (skill §1):** a single branch-safe timestamp for the whole invocation, reused across every wave. It is the idempotency key for the agent-hours accumulation (Step 2).

### Step 2: Fan-out (skill §2)

Spawn one `general-purpose` leaf per confirmed mission **in a single message, in the background**, each with the skill's §2 prompt: preload `workaholic:drive`, work only in `( cd <worktree_path> && … )`, prioritize inline, consult `drive-authorized.sh` per ticket, inherit Night Mode §3/§5 (attempt-first, closed outcomes, mint `deferred` tickets, safety floor), return the §2 JSON report. **A mission flagged for replan at pre-flight:** its leaf applies the collected rulings in its own worktree first — emit the delta tickets, write `## Experience`/`## Goal`/`## Scope`, stamp `drive_authorized` through the mission skill's mutators, commit — and only then drives (skill §2).

**This command is a non-blocking dispatcher** (skill §2): it interprets, lightly investigates, and directs — it never implements inline, never edits inside a mission worktree (**the replan phase included** — no ticket writes, body-section edits, or authorizing commits in the main agent), and never freezes the session waiting synchronously on the slowest leaf. Collect leaf reports as they arrive; between dispatches keep answering the developer's instructions and progress questions from `status.sh` and the reports already in.

**Control the degree of concurrency (skill §2):** favor parallelism, but tune the wave size **down** — never spawn everything at once — when the interference assessment shows missions sharing Key Files or when their booted dev environments would contend for the host's resources; revise the dial between waves as reports arrive.

**Boot the dev environments at dispatch** (skill §2): for each driven mission, start the project's declared dev/start command in the background inside `( cd <worktree_path> && … )` on the worktree's allocated ports (`.env` port base; the ports `gate.sh` reports), so leaves and declared gates run against a live environment. Skip silently when the project declares no dev command; at the terminal state stop whatever this run itself started and note it in the final report.

**Accumulate agent-hours (skill §2):** note each leaf's dispatch and completion timestamps; when a mission reaches its terminal classification, record its summed leaf wall-clock **once** with `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/record-run-hours.sh "<slug>" "<hours>" "<run-id>"` (idempotent per run-id, the only writer of `actual_hours`).

### Step 3: Loop until terminal (skill §3)

After each wave, run `status.sh` per mission and classify: complete (gate included when declared) / still driveable / escalation-blocked. Interactive: ask each escalation as **its own** labeled `AskUserQuestion`, one decision at a time — never one summary prompt, never a report in place of the questions; only an explicit "defer" moves an item to escalation-blocked. Unattended: record them. Re-drive driveable missions — at most 3 waves per invocation, and stop early on a zero-archive wave. Plan-changing answers route through `/mission` replan, never ad-hoc edits. An interactive run never emits `ok` over a decision it did not ask (skill §3).

### Step 4: Final report (skill §5)

Emit the report — per-mission progress deltas and reconciled outcome counts, **predicted vs accumulated actual hours** per mission (skill §5), the escalation list (never silent), minted tickets, exclusions, stashes — and end with the terminal token on its own final line: `ok` (terminal state reached) or `pending` (work remains for the next invocation). PRs for finished missions are the developer's next step via `/report` / `/ship`, per mission worktree.
