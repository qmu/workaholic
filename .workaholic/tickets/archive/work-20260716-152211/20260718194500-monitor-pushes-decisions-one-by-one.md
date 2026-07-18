---
created_at: 2026-07-18T19:45:00+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Domain]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
---

# /monitor pushes decisions one by one instead of reporting blockers

## Overview

Developer feedback (2026-07-18, first `/goal /monitor ok` experience): when the run cannot proceed — no missions, ineligible missions, escalations — `/monitor` currently *states* the blockers ("nothing to do until you decide") and considers itself done. That satisfies the letter of the report contract and defeats its purpose: the developer asked to be **worked through the decisions**, one at a time, until the run can actually finish — "don't just get enough by saying it, push me work for it."

Revise the monitor spec so that **in an interactive session, "waiting on the developer" is never a terminal state**:

- **Pre-flight blockers become sequential decisions.** No missions at all → offer to start a `/mission` creation interrogation now. A mission failing eligibility (`not_authorized`/`no_plan`) → offer to run its replan interrogation now. A missing worktree → offer to create it now. An unassigned mission → the claim question. Each is its own `AskUserQuestion`, asked **one at a time**, and the run proceeds with whatever the answers unlock. Only an explicit decline ("stop", "later") ends the run early.
- **Escalations are asked one by one, not batched.** Between waves, each leaf escalation is its own decision prompt — not one summary prompt listing them all. An answer feeds the next wave (plan changes still route through `/mission` replan); only a decision the developer **explicitly defers** counts as escalation-blocked.
- **The terminal contract tightens accordingly**: `escalation-blocked` means *asked and explicitly deferred* (or a genuinely unattended run — the night/caller-loop invocation where nobody can answer). A decision that was never pushed to the developer never justifies `ok`.
- The unattended path is unchanged: a run that cannot ask records escalations for the report, exactly as today.

**Second feedback round (same session): the main agent is a non-blocking dispatcher.** The `/monitor` main agent's whole job is to interpret the developer's instructions, do light investigation, and direct subagents to work in their worktrees — so it must never block itself: it does **no implementation work inline**, spawns the per-mission drive leaves **in the background** (parallel, collected as their reports arrive — never a synchronous wait that freezes the session on the slowest leaf), and stays responsive to the developer throughout the run (new instructions, progress questions, and the one-at-a-time decision prompts all keep flowing while leaves work).

## Discussion

### Revision 1 - 2026-07-18T19:52:00+09:00

**User feedback**: また、モニターコマンドで起動する処理というのは、主にユーザーに言われたことを解釈して簡単な調査などを行い、サブエージェントに対してワークツリーで作業することを指示する、といったものになっています。なので、/monitorを実行するメインのエージェントがブロッキングしてしまわないように注意してください。

**Ticket updates**: Added the non-blocking-dispatcher requirement to the Overview; added Implementation Step 6 (dispatcher rule in SKILL §2 + command Step 2: background leaf spawning, collect-as-they-arrive, main agent stays interpretive/investigative only) and matching acceptance criteria + prose sentinels.

**Direction change**: The main agent's role is narrowed and made explicit — interpret, lightly investigate, dispatch, stay responsive; all heavy work lives in the worktree leaves.

### Revision 2 - 2026-07-18T19:58:00+09:00

**User feedback**: あと必要な開発環境の起動なども/monitorのタイミングで各worktree内で行いましょう

**Ticket updates**: Added Implementation Step 7 and an acceptance criterion: at dispatch, /monitor boots each driven mission's development environment **inside its own worktree** — the project's own declared dev/start command, run in the background on the worktree's allocated ports (the `.env` port base `create-mission-worktree.sh` assigned; the same ports `gate.sh` reports) — so leaves verify and gates run against a live environment. Skipped silently when the project declares no dev command; environments the run started are stopped at the terminal state.

**Direction change**: Environment lifecycle joins the dispatcher's duties: boot per worktree at dispatch, run leaves against it, tear down what the run itself started.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions (applies to all code work)
- `workaholic:development` / `policies/overnight-ai.md` — "eliminate the causes of stopping before the run starts": pushing each judgment call to a decision at pre-flight is that practice applied interactively
- `workaholic:development` / `policies/qa-engineering.md` — the developer owns the judgment; the tool's job is to bring every judgment to them, not to narrate around it
- `workaholic:design` / `policies/modeless-design.md` — sequential single decisions, each actionable, instead of one modal wall of blockers

## Key Files

- `plugins/workaholic/skills/monitor/SKILL.md` - §1 pre-flight (zero-drivable path), §3 escalation handling and terminal-state definition
- `plugins/workaholic/commands/monitor.md` - Step 1 (zero drivable → stop) and Step 3 wording must match
- `scripts/test-workflow-scripts.mjs` - add prose-sentinel assertions (the suite's existing pattern for drive night mode / mission interrogation): the skill states one-decision-at-a-time, forbids treating an unasked decision as terminal, and keeps the unattended exception

## Related History

The /monitor feature landed earlier on this branch (20260718185410) with a passive escalation contract ("surface in one AskUserQuestion / record and report"). This ticket is the first-use correction: the same feedback shape as the Step 4b revision (20260718185411) — the tool must distinguish what it can resolve itself from what it must actively bring to the developer, and never stop at describing the difference.

## Implementation Steps

1. Revise `skills/monitor/SKILL.md` §1: replace the "zero drivable missions → report why and stop" outcome with a **decision loop** — one `AskUserQuestion` per blocker (create-mission route, replan-now route, create-worktree, claim), proceeding with whatever each answer unlocks; explicit decline is the only early stop.
2. Revise §3: escalations are asked **one decision at a time** between waves; define `escalation-blocked` as *asked and explicitly deferred*; keep the unattended exception and the bounded-wave cap.
3. Update `commands/monitor.md` Steps 1 and 3 to the same contract.
4. Add prose-sentinel assertions to `scripts/test-workflow-scripts.mjs` (new test or extension): the skill and command state the one-at-a-time rule, the asked-and-deferred definition, and the interactive-never-terminal-on-unasked rule.
5. Docs check: CLAUDE.md `/monitor` row and README wording still tell the truth (adjust "only escalation-blocked items remain" phrasing if needed).
6. Add the **non-blocking dispatcher** rule to `skills/monitor/SKILL.md` §2 and `commands/monitor.md` Step 2: the main agent only interprets, lightly investigates, and dispatches; leaves are spawned **in the background** and their reports collected as they arrive; the main agent never implements inline and never freezes the session waiting synchronously on the slowest leaf — it stays available for the developer's instructions and the decision prompts throughout. Cover with prose sentinels in the suite.
7. Add the **dev-environment boot** duty to §2 and command Step 2: at dispatch, start each driven mission's development environment inside its own worktree — the project's declared dev/start command, backgrounded, on the worktree's allocated ports (`.env` port base from `create-mission-worktree.sh`; the ports `gate.sh` reports) — so leaves and gates run against a live environment. Skip silently when the project declares none; stop at terminal state whatever the run itself started. Cover with prose sentinels.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `skills/monitor/SKILL.md` states: blockers become sequential decisions (one `AskUserQuestion` each); `escalation-blocked` = asked and explicitly deferred; an interactive run never terminates on a decision that was not pushed; the unattended path records instead of asking.
- `commands/monitor.md` carries the same contract in Steps 1 and 3 (no "report why and stop" remnant for the interactive path).
- `skills/monitor/SKILL.md` §2 and `commands/monitor.md` Step 2 state the non-blocking dispatcher rule: interpret/investigate/dispatch only, background leaf spawning with collect-as-they-arrive, no inline implementation, no synchronous freeze on the slowest leaf, responsive to the developer throughout.
- §2 and Step 2 state the dev-environment duty: boot each driven mission's declared dev command inside its own worktree on its allocated ports at dispatch; skip silently when none is declared; stop at terminal state what the run itself started.
- Suite prose-sentinel assertions cover the statements above and are green; full suite stays green.
- CLAUDE.md/README `/monitor` descriptions remain truthful under the new contract.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green with the new assertions; manual read of the revised sections against the criteria.

**Gate** — what must pass before approval:

- Suite green; the developer confirms the revised contract matches the feedback ("push me through the decisions one by one") at the approval prompt.

## Considerations

- Monitor stays Claude-Code-only with no `outputs/` footprint — no rebuild needed (`scripts/build-plugins/build.mjs` `DEFAULT_TARGETS` untouched)
- The guard hook requires the `[<project label>]` prefix on every one of these sequential prompts (`plugins/workaholic/hooks/guard-askuserquestion-label.sh`)
- Do not regress the leaves: they still never ask; all new questions live at the command level (`CLAUDE.md` One-Level Fan-Out)

## Final Report

Development completed as planned, absorbing three feedback rounds in one revision: blockers-as-sequential-decisions with the strict asked-and-explicitly-deferred terminal contract, the non-blocking dispatcher role (background leaves, collect-as-they-arrive, no inline implementation), and dev-environment boot per worktree at dispatch (allocated ports; stop only what the run started).

### Discovered Insights

- **Insight**: The monitor contract is orchestration prose, so its regression floor is prose sentinels — the suite now pins fifteen sentences across the skill and command, the same technique the drive night-mode and mission-interrogation contracts use.
  **Context**: When changing monitor behavior, update the sentinel assertions deliberately with the prose; a reworded sentence that drops a sentinel is the test doing its job.
