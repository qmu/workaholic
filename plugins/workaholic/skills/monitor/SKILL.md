---
name: monitor
description: Use when the user runs `/monitor`, asks to "run my missions in parallel", "drive every mission worktree", or "keep the missions moving until they're done". Assembles a developer-confirmed pre-flight over the current developer's missions, fans out one autonomous drive per mission worktree, and loops from a bird's-eye vantage until every mission's completion conditions are met or only escalation-blocked items remain.
skills:
  - workaholic:mission
  - workaholic:drive
  - workaholic:branching
  - workaholic:gather
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Monitor

Run the current developer's **missions in parallel** — one autonomous drive per mission worktree — after a developer-confirmed pre-flight review, and do not stop until every driven mission's completion conditions are met or only items blocked on unanswered developer escalations remain. `/monitor` is the parallel-missions **executor** alongside `/drive` (solo) and `/trip` (team): all three drain ticket queues; `/monitor`'s unit is the mission, and its vantage is the whole roadmap.

`/monitor` operationalizes `workaholic:development` / `overnight-ai`: judgment is pre-answered (the mission interrogation + the pre-flight confirmation), the run does not stop mid-flight, and the judgment calls that still need a human are **collected** into the final report for review — never resolved by guessing. Pull requests during missions flow through `/report` and `/ship` unchanged; `/monitor` never merges anything itself.

## Agent Compatibility

Claude-Code-only, like `/trip`: the parallel fan-out below is the command's substance, not an optimization, and the skill is not built into `outputs/workflows`. On an agent without subagent fan-out, drive each mission's worktree sequentially with `workaholic:drive` instead.

## Scope: whose missions

The run covers missions that are **the current developer's business** — the `mission/scripts/summary.sh` gate: `assignee` matches `git config user.email`, or the mission is **unassigned** (unclaimed). Another developer's missions are never touched. An unassigned mission is offered at pre-flight as **claimable**: driving it means claiming it, so including it sets its `assignee` to the current developer (in its own worktree's checkout) before any leaf is spawned. Never claim silently — inclusion is a pre-flight decision, not a default.

## 1. Pre-flight (mandatory — confirmed before anything drives)

Assemble the facts:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/monitor/scripts/preflight.sh
```

The script discovers missions in **both** places they live — each mission-type worktree's own checkout (a mission's `mission.md` is invisible to the main tree until its branch merges), then main-tree active missions owning no worktree — and emits, per mission: derived `checked/total`, the next unchecked acceptance item, its `worktree_path`, and its unattended-drive eligibility (`authorized` + `reason`). Mission-type worktrees holding no `mission.md` are reported as `orphan_worktrees`, never guessed at.

Present the review to the developer — this is the roadmap conversation, and it must cover four things:

1. **The mission set** — every listed mission with its progress and next acceptance item; unassigned ones marked claimable.
2. **Current position** — per mission, what is already merged vs in flight: read each worktree's own queue (`status.sh` `todo_count`) and unmerged branch state (`git log main..HEAD --oneline` inside the worktree via the gather skill's context, not inline git in prose).
3. **Eligibility** — missions that cannot be driven unattended, by `reason`:
   - `not_authorized` / `no_plan` — the mission was never interrogated to a drive-ready state (or has an empty `## Acceptance`). **Do not drive it.** Route it to `/mission <instruction referencing it>` (replan); it stays in the report as excluded.
   - `no_worktree` — authorized but not yet materialized; offer to run `branching/scripts/create-mission-worktree.sh "<slug>"` as part of the run.
4. **Interference and destination** — where each mission is intended to land this run, and the cross-mission interference assessment (below).

Confirm with **one** `AskUserQuestion` (the command issues it, body prefixed `[<project label>]`): which eligible missions to drive (multiSelect; unassigned ones labeled as claim-and-drive). The confirmation is the batch authorization for this run — the same shape as `/drive night`'s §1: approval is **relocated to here**, not removed. In an unattended invocation (a caller-side loop such as `/goal /monitor ok`, where the invocation itself is the authorization), print the pre-flight content into the run log instead of prompting, and drive only missions that are already assigned to the current developer and eligible — an unattended run never claims unassigned work.

## 2. Fan-out: one drive leaf per mission

After confirmation, spawn **one `general-purpose` subagent per chosen mission, in a single message** (parallel Task calls). Leaves are one-level: they cannot spawn subagents and cannot `AskUserQuestion` (CLAUDE.md One-Level Fan-Out), which is exactly why only `drive-authorized` missions run unattended. Each leaf's prompt says:

- Preload `workaholic:drive`. Work **only** inside `<worktree_path>`: every bash call wrapped `( cd <worktree_path> && … )` or absolute-pathed (the cwd resets between calls), every write confined to that worktree.
- Run the drive **Workflow** over the worktree's own todo queue (`drive/scripts/list-todo.sh` from the worktree), prioritizing **inline** (drive's Agent Compatibility note — no prioritizer subagent).
- Per ticket, consult `mission/scripts/drive-authorized.sh <ticket-path>` — the resolver, not prose, decides. Authorized → implement, verify against the ticket's `## Quality Gate`, update effort, append the Final Report, `archive.sh`. **Not authorized → do not implement it**; record it `blocked` with the resolver's `reason`.
- Inherit drive **Night Mode §3/§5 verbatim**: attempt every authorized ticket (size/complexity never skip), `failed` = implemented but red (stash, record, continue), `blocked` = a named hard external blocker, `deferred` = an unqueued observed problem becomes a minted ticket (inheriting the `mission:` relation) and the run continues. Safety floor unchanged: never auto-icebox, never destructive git.
- Return JSON only: `{"slug", "outcomes": [{"ticket", "outcome": "implemented|failed|blocked", "commit_or_reason"}], "minted": [...], "escalations": ["<judgment call a human must answer>", ...]}` — outcomes reconciling to the queue it was handed.

One leaf per worktree, never two (**data plural, placement singular**: a ticket is driven in exactly one worktree). Leaves run concurrently across worktrees; port contention is already handled by the per-worktree port allocation.

## 3. The loop, and the terminal state

After each wave, read every driven mission:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/monitor/scripts/status.sh <worktree_path> [slug]
```

`complete` is derived (`## Acceptance` non-empty and fully checked — `0/0` is not complete); `todo_count` is the worktree queue's remainder. When the mission declares a gate (`gate_type` non-empty), completion additionally requires exercising it via `mission/scripts/gate.sh`: `check` → run `target` in the worktree, exit 0; `documentation`/`live-app` → serve on the worktree's `dev_port` and drive `target` with the Playwright plugin against `assert`. No gate declared (the normal case) → `## Experience` is the bar, judged, not run.

Classify each incomplete mission:

- **Still driveable** — tickets remain that are not escalation-blocked → include it in the next wave.
- **Escalation-blocked** — every remaining item waits on a judgment in some leaf's `escalations` (or a `blocked` with no in-repo unblock). Interactive run: surface all of a wave's escalations in **one** labeled `AskUserQuestion` between waves; answers feed the next wave (an answer that changes a mission's plan routes through `/mission` replan, not ad-hoc edits). Unattended run: record them — an escalation nobody is there to answer **is** the "ignored" of the terminal contract.

**Bounded run**: at most **3 waves per invocation**, and a wave that archives nothing terminates the loop (no spinning on the same blockers). The caller's loop (`/goal`) provides the long horizon; one invocation provides bounded progress plus an honest report.

**Terminal state** — every driven mission `complete` (gate included, when declared), **or** every incomplete one is escalation-blocked with its escalations surfaced-and-unanswered. In the terminal state the run's **final output line is exactly `ok`** — the deterministic token a caller-side convention like `/goal /monitor ok` waits for (`/goal` itself is not a command of this plugin; the token is the whole contract). Not terminal → the final line is `pending`, with the report saying what the next invocation will do.

## 4. Cross-mission interference (the bird's-eye judgment)

Leaves run in isolated worktrees off `main` and cannot see each other's uncommitted work; conflicts materialize at `/report`/`/ship` merge time. Interference analysis is therefore **advisory synthesis at the command level**, not a mechanical gate:

- Before the run: compare the queued tickets' **Key Files** across missions. Overlap → say so in the pre-flight, propose sequencing (drive one first, or plan the second's `/ship` to catch up main — `/ship` always reconciles with main anyway).
- During the run: a leaf's `deferred`/`blocked` naming a file another mission owns is an interference finding — report it, and sequence the next wave accordingly.
- Never "resolve" interference by editing across worktrees; the resolution is ordering, replan, or the developer's call at the escalation prompt.

## 5. The final report (the deliverable)

Always emitted, terminal or not — the morning-review artifact (`workaholic:implementation` / `observability`):

- Per mission: `checked/total` before → after, outcome counts (implemented / failed / blocked) reconciling to its handed queue, commits, gate result when one was declared.
- **Escalations left for the developer** — every unanswered judgment call, one line each, never silent. This list is the QA seam `workaholic:development` / `qa-engineering` requires; the looking-through happens here and at each mission's PR.
- Minted tickets (`deferred`), one line each: what was found, which ticket provoked it, the new filename.
- Excluded missions and why (`not_authorized` → replan pointer; orphan worktrees).
- Stashed partial work and where.
- Last line: `ok` or `pending` (§3).

## Scripts

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/monitor/scripts/preflight.sh
```

Assemble the pre-flight facts (read-only): the developer's missions across worktree and main-tree checkouts, each with derived progress, next acceptance item, worktree path, and unattended-drive eligibility (`authorized`/`reason`: `not_authorized`, `no_plan`, `no_worktree`), plus orphan mission-type worktrees. Mirrors `drive-authorized.sh`'s per-mission floor advisorily; the ticket-scoped resolver stays the authority at drive time.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/monitor/scripts/status.sh <worktree_path> [slug]
```

Objective per-mission run status (read-only): derived `checked/total`, `complete` (non-empty and fully checked), the worktree queue's `todo_count` (via `drive/list-todo.sh` inside the worktree), and `gate_type` so the caller knows whether completion needs a gate run. Escalation classification is deliberately **not** here — which blockers a developer left unanswered is judgment, not derivation.
