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

This command (main agent) runs the preloaded `workaholic:monitor` skill end to end (§1 Pre-flight → §2 Fan-out → §3 Loop/terminal → §4 Interference → §5 Final report). It owns **all** user interaction, and resolves it **up front**: every foreseeable decision is pushed in one pre-flight batch here, before any leaf is spawned; after dispatch the run is **unattended** and nothing is asked (skill §1/§3). The per-mission drive leaves are `general-purpose` subagents that never call `AskUserQuestion` and never nest `Task` (CLAUDE.md One-Level Fan-Out). Run it from the **main tree**; each mission is driven inside its own `.worktrees/<slug>/` worktree by its own leaf.

### Pre-check: Dependencies

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

If `ok` is `false`, display the `message` and stop. If `missing_guards` is non-empty, warn about the stale/partial install before proceeding — do not block.

### Step 1: Pre-flight review (skill §1)

Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/monitor/scripts/preflight.sh` and present the skill's review, led by the **whole-roadmap progress headline** (aggregate `checked/total` and each mission's next acceptance item across **all** assigned active missions, from `progress.sh`/`next-acceptance.sh` — no `mission.md` parsing, no new artifact), then the four parts: mission set, current position per worktree (including unmerged work), eligibility, and interference/destination. **Do not ask which missions to drive** — the assigned + eligible set is the run by default (skill §1). Reevaluate and replan every assigned mission: **auto-apply mechanical replans silently** (leaf work), surfacing only genuine **design** rulings.

**Front-load one blocking batch (skill §1) — the run's only interaction point.** Gather every foreseeable escalation the pre-flight surfaces — unassigned-mission claims, `no_worktree` creation, authorization, replan design rulings — and push each as its own labeled `AskUserQuestion` (body prefixed with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`), **one decision at a time**, **before** spawning any leaf. After it is answered, **no `AskUserQuestion` fires for the rest of the run**.

**Blockers become decisions (skill §1) — never "report why and stop".** When the pre-flight finds nothing drivable — or leaves ineligible missions behind — push each blocker to the developer as its own labeled `AskUserQuestion`, **one decision at a time**, all in the up-front batch: no missions → offer to start `/mission` creation now; `not_authorized`/`no_plan` → offer to run that mission's replan **interrogation** now (the developer rulings only — applying the replan is the leaf's job, skill §2); `no_worktree` → offer `create-mission-worktree.sh` now; unassigned → the claim question. Proceed with whatever each answer unlocks; only an explicit decline ends the run early. Everything here happens before dispatch — mid-run the run cannot ask (skill §3).

**Collect every ruling first, then dispatch (skill §1).** Gather every developer decision this run needs — the run authorization, the claim-and-drive choices, and each replan's design rulings — here in the main agent **before** spawning any leaf. A leaf cannot prompt (one-level fan-out), so each ruling rides in its mission's dispatch payload; a leaf is never spawned to wait on an answer it cannot ask for.

**Front-loading supersedes the during-run push model (skill §1).** Commit `edf246a4`'s one-at-a-time push **during** the run is deliberately reversed for the mission run: foreseeable decisions are pushed up front, and after dispatch the run is unattended (`overnight-ai`; `ai-native-future`'s human-in-the-loop checkpoint placed before the autonomy, not through it).

**Unattended invocation** (the run arrives from a caller-side loop such as `/goal /monitor ok`, or the invocation contains "night"): the invocation is the authorization — log the pre-flight instead of prompting, drive only already-assigned eligible missions, and never claim unassigned work.

**Mint the run-id here (skill §1):** a single branch-safe timestamp for the whole invocation, reused across every wave. It is the idempotency key for the agent-hours accumulation (Step 2).

### Step 2: Fan-out (skill §2)

Spawn one `general-purpose` leaf per confirmed mission **in a single message, in the background**, each with the skill's §2 prompt: preload `workaholic:drive`, work only in `( cd <worktree_path> && … )`, prioritize inline, consult `drive-authorized.sh` per ticket, inherit Night Mode §3/§3a/§3b/§5 (attempt-first — a `blocked` entry carries the attempted command and its raw output; long/heavy/exclusive live verification is *preferred* overnight work, never a deferral reason; closed outcomes, mint `deferred` tickets, safety floor), return the §2 JSON report. **A mission flagged for replan at pre-flight:** its leaf applies the collected rulings in its own worktree first — emit the delta tickets, write `## Experience`/`## Goal`/`## Scope`, stamp `drive_authorized` through the mission skill's mutators, commit — and only then drives (skill §2).

**This command is a non-blocking dispatcher** (skill §2): it interprets, lightly investigates, and directs — it never implements inline, never edits inside a mission worktree (**the replan phase included** — no ticket writes, body-section edits, or authorizing commits in the main agent), and never freezes the session waiting synchronously on the slowest leaf. Collect leaf reports as they arrive; between dispatches keep answering the developer's instructions and progress questions from `status.sh` and the reports already in.

**Control the degree of concurrency (skill §2):** favor parallelism, but tune the wave size **down** — never spawn everything at once — when the interference assessment shows missions sharing Key Files or when their booted dev environments would contend for the host's resources; revise the dial between waves as reports arrive. **The dial bounds parallelism only.** Contention is answered by running fewer things at once — ideally a wave of one for a mission needing exclusive use of a service — never by a leaf skipping authorized work. And **never seed contention-avoidance framing into a leaf's prompt** ("unsafe amid contention", "leave it for a daytime window"): a leaf reads that as permission to defer the heavy verification the night was reserved for. State the scheduling facts; express the judgment by sizing the wave.

**Boot the dev environments at dispatch** (skill §2): for each driven mission, start the project's declared dev/start command in the background inside `( cd <worktree_path> && … )` on the worktree's allocated ports (`.env` port base; the ports `gate.sh` reports), so leaves and declared gates run against a live environment. Skip silently when the project declares no dev command; at the terminal state stop whatever this run itself started and note it in the final report.

**Accumulate agent-hours (skill §2):** note each leaf's dispatch and completion timestamps; when a mission reaches its terminal classification, record its summed leaf wall-clock **once** with `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/record-run-hours.sh "<slug>" "<hours>" "<run-id>"` (idempotent per run-id, the only writer of `actual_hours`).

### Step 3: Loop until terminal (skill §3)

After each wave, run `status.sh` per mission and classify: complete (gate included when declared) / still driveable / escalation-blocked. **Check a blocker earned the label (skill §3):** accept `escalation-blocked` only when the leaf recorded an attempted command with its raw output, or named one of drive §3a's two no-attempt buckets. Work deferred for being long, heavy, exclusive, or abstractly "human-only" is **still driveable** — re-dispatch it next wave with the §3a/§3b rule restated (narrowing the wave if it needs the environment to itself), never launder it into the escalation list. The run is **unattended after dispatch** — a genuine mid-run escalation the pre-flight did not foresee is **deferred and recorded in the final report, never asked** (recorded once, not re-logged each wave). Re-drive driveable missions — at most 3 waves per invocation, and stop early on a zero-archive wave. Any plan change routes through `/mission` replan, never ad-hoc edits. **Honest terminal signal (skill §3):** emit `ok` **only** when every driven mission genuinely reached `complete` per `status.sh`; if any is incomplete or escalation-blocked, emit `pending` — escalation-blocked is `pending`, not `ok`. This makes `/monitor`'s terminal token honest (the `/monitor` half of `20260719000021`; the `/goal`-gate side stays separate).

### Step 4: Final report (skill §5)

Emit the report (skill §5). **Per driven mission, in order:** (0) **for each mission classified `complete` per `status.sh` — and only those — open a PR** (the dispatcher's own work, sequentially): inside `( cd <worktree_path> && … )` generate the story via `workaholic:report`'s Write Story flow, run release-scan warn-tier (fold findings into the PR body, never a prompt), then `bash ${CLAUDE_PLUGIN_ROOT}/skills/report/scripts/create-or-update.sh <branch> "<title>"`; collect `{mission, pr_url | pr_error}`. Reuse the report flow, do not fork it; no `AskUserQuestion` in this phase. (a) state completed-as-planned or the categorized reason from the fixed vocabulary (`complete` / `escalation-blocked` / `deferred` / `gate-failed` / `wave-exhausted`), and (b) compose the three-bullet reflection from the run's own evidence and write it with `append-reflection.sh "<slug>" "<run-id>" "<date>"` (idempotent per run-id; records causes, never the pending decisions the escalation list owns). Then the report body — per-mission progress deltas, reconciled outcome counts, **predicted vs accumulated actual hours**, the **PR url/error per completed mission**, the escalation list including every deferred mid-run item (never silent), minted tickets, exclusions, stashes — and end with a **reconciliation line** (`N/M missions complete, K escalation-blocked`, every deferral named) then the terminal token on its own final line: `ok` **only** when every driven mission genuinely completed, else `pending`. A PR-creation failure is its own item and changes **nothing** else — not the completion counts, not the token. Merge stays `/ship` (deploy-gated); worktree teardown stays `/mission close`.
