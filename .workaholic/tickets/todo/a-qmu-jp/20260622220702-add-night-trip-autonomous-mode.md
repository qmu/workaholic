---
created_at: 2026-06-22T22:07:02+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Add Night Trip: an autonomous, unattended `/trip night` that never stops to ask the developer

## Overview

Add a **Night Trip** mode to `/trip`, mirroring the existing **Night Drive** mode of `/drive`. When invoked as `/trip night <instruction>` (or "go night /trip …"), the trip runs end-to-end **unattended**: it never pauses to ask the developer a question. The Agent Team judges everything itself — direction, model, design, implementation, and testing — resolving disagreements through the protocol's own mechanisms, and finishes (or safely parks) on its own, leaving a morning-review report.

This is a natural fit because the trip is **already autonomous internally**: the three teammates (Planner/Architect/Constructor) generate artifacts concurrently, review each other in one-turn rounds, respond/escalate, and the leader enforces a **3-round convergence cap with forced moderation** (`trip-protocol` Consensus Gate / Convergence Cap), plus 2/3-majority rollback. None of that needs the developer. The only places the current flow stops for a **human** are:

1. **Step 1 (Create or Resume Trip)** — two command-level `AskUserQuestion`s: which existing worktree to resume vs. create new (when `count>0`), and "Create worktree" vs "Branch only" for a new trip (`trip-protocol` Step 1, lines ~223 and ~231).
2. **The team-lead instruction (Step 4)** — it does not currently tell the lead/agents to run unattended; a lead could reasonably pause to check in with the developer at a phase transition or on a hard call.
3. **Ambiguity in `$ARGUMENT`** — nothing says whether to ask the developer to clarify; in night mode the team must assume-and-record instead.

Night Trip closes those three by: auto-resolving the Step 1 choices with safe defaults, adding a night directive to the team-lead instruction, and specifying assume-and-record for ambiguity — exactly paralleling Night Drive's "the invocation is the authorization" model.

**Night Trip is stricter than Night Drive on questions.** Night Drive permits exactly one question (the §1b distinct-topic-groups prompt). Night Trip permits **zero** developer questions — the team's internal consensus machinery is what "judges everything itself."

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` - REFERENCE (the model to mirror). Its `### Night Mode (mode = "night")` section (the §1–§5 structure: invocation-is-authorization, autonomous loop, safe-by-default failure policy, bounded run, whole-night report) is the template for the new Night Trip section. Do not edit.
- `plugins/workaholic/commands/drive.md` - REFERENCE. Its short "**Night mode**" paragraph is the shape for the analogous paragraph in `commands/trip.md`. Do not edit.
- `plugins/workaholic/skills/trip-protocol/SKILL.md` - PRIMARY. Add a `## Night Mode` section, and add night-mode branches to the **Trip Command Procedure**: Step 1 (auto-resolve worktree choices, no `AskUserQuestion`), Step 4 (append a night directive to the team-lead instruction), Step 5 (emit the morning-review report). Also document night detection / stripping the `night` token from `$ARGUMENT`.
- `plugins/workaholic/commands/trip.md` - PRIMARY (thin). Add a short "**Night mode**" paragraph (mirroring `commands/drive.md`) that points at the skill's Night Mode section and states the invocation authorizes an unattended run with no developer questions.
- `plugins/workaholic/skills/trip-protocol/scripts/init-trip.sh` - REFERENCE. Receives `$ARGUMENT` as the instruction (Step 2). The `night` flag must be **stripped** from the instruction before it is passed here and into the team-lead instruction, so "night" is never treated as part of the user's actual request. Verify the call site; no script change expected unless stripping is done in-script.
- `plugins/workaholic/agents/{planner,architect,constructor}.md` - REFERENCE. The teammates' roles/constraints are unchanged by night mode; night mode only changes whether the team pauses for the **developer**, not the agents' behavior toward each other. Do not edit (and note the just-added "trip-only" description guard remains correct — night mode is still launched by `/trip`).

## Related History

- Night Drive itself (the `### Night Mode` section in `skills/drive/SKILL.md` and the night paragraph in `commands/drive.md`) — the canonical pattern this ticket mirrors. Same five-part shape, adapted from a ticket queue to an Agent-Teams session.
- `trip-protocol` Convergence Cap / forced moderation (lines ~95-96) and Rollback 2/3 majority (line ~115) — the existing autonomous decision machinery Night Trip relies on to "judge everything itself" without a human. Night mode adds no new decision mechanism; it just removes the developer stop points and guarantees the existing ones run to a terminal state.
- The `/trip` policy-lens catch-up and the agent-frontmatter scoping work on this branch — confirm Night Trip prose stays consistent with the current trip surface (workaholic namespaces, Agent Teams exemption, merge-last Trip Ship).

## Implementation Steps

1. **Detect night mode and separate it from the instruction.** In the Trip Command Procedure (and `commands/trip.md`), determine `mode = "night"` when `$ARGUMENT` contains the `night` token (e.g. "go night /trip build X", "/trip night build X"). **Strip** the `night` token so the remaining text is the real trip instruction passed to `init-trip.sh` and the team-lead instruction. Default (no token) is the existing interactive mode.
2. **Auto-resolve Step 1 with safe defaults (no `AskUserQuestion`).** In night mode, do not present the worktree-selection or create/branch prompts. Default to a **new isolated worktree** for the instruction (run `create.sh` then `adopt-worktree.sh`, as the "Create worktree" branch does) — the isolated default matches the overnight intent. Do **not** auto-resume an arbitrary existing worktree (resuming is an interactive decision). Log the chosen default to `event-log.md`. *(Decision flagged for the requester — see Considerations: confirm "new isolated worktree, never auto-resume" is the desired night default.)*
3. **Add a `## Night Mode` section to `trip-protocol/SKILL.md`** mirroring Night Drive's five parts, adapted to Agent Teams:
   - **Authorization** — invoking `/trip night` authorizes the whole unattended run; no developer questions at any point (stricter than Night Drive's one-question allowance).
   - **Autonomous session** — the lead and teammates proceed Planning → Coding → Completion judging everything themselves; all disagreements resolve via the existing review/respond/moderate flow and the 3-round convergence cap with forced moderation (and 2/3 rollback). Never escalate a decision to the developer.
   - **Ambiguity = assume-and-record** — if `$ARGUMENT` is underspecified, the Planner makes the most reasonable interpretation and records the assumptions in `directions/direction-v1.md` and `plan.md`, rather than asking.
   - **Safe-by-default (no human present)** — if a phase cannot complete (dev-env unfixable, a blocking external dependency, an irreducibly ambiguous requirement), **record the blocker** in `plan.md` (a "Night Park" amendment) and `event-log.md` and **park gracefully** at the furthest safe state; never halt waiting for a human, never run destructive git (`git reset --hard` / `git clean` / `restore .`), and never create new agents.
   - **Bounded run** — night mode runs the single instruction given at invocation through to `complete/done` (or a recorded park); it does not expand scope mid-run.
4. **Append a night directive to the Step 4 team-lead instruction** (only in night mode): e.g. "NIGHT MODE: run unattended. Never pause to ask the developer a question. Resolve every disagreement through the trip-protocol review/moderation/convergence-cap mechanisms; for ambiguous requirements, make and record reasonable assumptions. If something cannot be completed, record the blocker in plan.md/event-log.md and park gracefully — do not wait for a human, do not run destructive git, do not create new agents." Keep the normal-mode instruction unchanged.
5. **Add a night variant of Step 5 (the morning-review report).** Instead of interactive "present results + guidance", emit a complete, skimmable stdout report for morning review: phases completed; the agreed direction/model/design; implementation + internal/E2E test results; any forced-convergence entries, recorded assumptions, and parked blockers (with where to find them); the trip branch/worktree; and next steps (`/report`, `/ship`). This is the deliverable.
6. **Add the night paragraph to `commands/trip.md`** (thin pointer), mirroring `commands/drive.md`: state that `/trip night …` authorizes an unattended run with no developer questions and points at the skill's Night Mode section.
7. **Verify.** No `outputs/` impact — `trip`/`trip-protocol` are excluded from the cross-agent build (`DEFAULT_TARGETS`/`EXTRA_SKILLS` in `build.mjs`), so confirm `git status outputs/` stays clean after `node scripts/build-plugins/build.mjs`. Run `node scripts/build-plugins/verify.mjs` and `validate-metadata.mjs`. Re-read the night branches to confirm: zero `AskUserQuestion` reachable in night mode, the `night` token is stripped from the instruction, and the report is emitted. (No hermetic script test applies unless step 1 stripping is implemented in a script.)

## Considerations

- **Implementation is the binding lens** (`workaholic:implementation`): Config/skill-prose + thin-command work — `directory-structure` (edit `plugins/`, never `.claude/`), thin-command/comprehensive-skill (night knowledge lives in `trip-protocol`, the command gets a short pointer), and the Shell Script Principle (no inline conditionals in markdown — night detection/stripping is prose the agent applies, or a small bundled script if logic is needed). `operation` applies lightly (an unattended run must terminate and never wedge — the convergence cap already guarantees termination; the safe-park rule guarantees graceful failure). `design`/`planning` do not bind.
- **Agent Teams exemption is unchanged.** `/trip` and its three members stay exempt from the nesting / one-level-fan-out tables; Night Trip must not introduce new agents, must keep the strict three-member composition, and is Claude-Code-only (Agent Teams) — there is no cross-agent build of it.
- **Stricter-than-drive on questions, by request.** The user asked that Night Trip "not stop to ask the developer questions … judge everything itself." So night mode allows **zero** developer questions (unlike Night Drive's single §1b prompt). The team's existing consensus machinery is what makes that safe.
- **Default worktree choice is a real decision — confirm it.** Step 2 defaults night mode to a *new isolated worktree* and *never auto-resumes*. Auto-resuming an existing worktree unattended could target the wrong in-progress work; creating new is the safe default. Flag this to the requester in case they want night mode to resume a single matching worktree instead.
- **Termination is guaranteed; wedging is the risk to design out.** The 3-round convergence cap + forced moderation already bounds Planning, and Coding iterates until approved — but an unattended run must not loop forever on a failing build or an impossible requirement. The safe-park rule (record blocker, stop at furthest safe state) is the backstop; make it explicit so a night trip always ends in either `complete/done` or a clearly-reported park, never a silent hang.
- **No destructive git, no silent truncation.** Mirror Night Drive's safety: never `reset --hard`/`clean`/`restore .`; if the run is parked or partial, say so prominently in the report with the exact artifacts/locations, so "morning review" reflects reality rather than reading as a clean finish.
- **No `outputs/` regeneration and no version bump implied.** Trip is excluded from the build; confirm `git status outputs/` stays clean. A patch bump happens at `/report`/release time as usual.
