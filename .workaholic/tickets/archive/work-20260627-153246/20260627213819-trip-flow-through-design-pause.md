---
created_at: 2026-06-27T21:38:19+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash: 0d432a1
category: Changed
depends_on:
---

# Make a design-first `/trip` flow through the design→build seam by default (no green-light pause)

## Overview

A design-first `/trip` (over an empty queue: design → decompose → drive) reaches the end of the
Planning phase — agreed design committed under `trips/<name>/designs/` plus a dependency-ordered
ticket queue from the Decomposition gate — and then **parks**, idling the three Agent Teams members
with "ready whenever you want to review or green-light the build." The user does not want this halt:
per the overnight-trip vision, a design-first trip should carry straight through the Planning→Coding
seam into the per-ticket build (Constructor implements → Architect reviews → Planner E2E, archiving
each ticket) autonomously, and surface the **finished** branch for morning review via `/report`.

**The non-obvious finding (reconcile the premise):** there is **no literal blocking
design-approval gate** to delete. Discovery confirmed the pause is **emergent from prose framing**,
not a line of code — there is no `AskUserQuestion`, no "STOP and await green-light", and no
script-level phase gate between Planning and Coding. The Coding loop *already* has no developer gate
(`trip-protocol/SKILL.md` lines 117, 137: "the three-agent QA **is** the per-ticket approval gate —
there is no developer `AskUserQuestion`"). The halt arises because **Night Mode is the only place
that grants "never pauses for the developer"** (lines 330, 350, 352, 362-364), so a *default*
(non-night) team lead infers it should present the design for confirmation before building. The
autonomous behavior the user wants therefore already exists as `/trip night`; this ticket makes that
flow-through the **default** for any design-first trip.

The fix is a **prose hoist**: move the "do not pause for developer approval between Planning and
Coding; the review/moderation/convergence machinery is the design gate; any pre-build checkpoint is
opt-in" directive out of the night-only directive and into the **default** team-lead instruction,
and shrink Night Mode to its genuinely night-specific overrides (setup auto-resolve, safe-park
failure policy, morning-review report). All edits are confined to `trip-protocol/SKILL.md` (primary)
and `commands/trip.md` (sync); `trip` is **excluded from the `outputs/` build** (Agent Teams,
Claude-only), so **no rebuild**.

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills —
that govern this ticket. The implementing session **MUST** read each linked policy hard copy before
writing and keep every change defensible against that policy's Goal (目標), Responsibility (責務),
and Practices (実践).

- `workaholic:design` / `policies/modeless-design.md` — **the spine of the rationale.** A blocking "you cannot proceed until you confirm the design" step is precisely the unjustified *mode* this policy forbids: modes/gates are sanctioned only where concentration is genuinely required (e.g. irreversible operations), and an overnight design→code handoff is not such a moment. Flow-through is the policy-aligned default; "AI agents can compose any sequence of operations without navigating wizard state." Record the trade-off of removing the gate.
- `workaholic:operation` / `policies/ci-cd.md` — frame the change as **converting a synchronous human gate into an asynchronous, evidence-recorded decision**, not removing a decision point. The agreed design committed under `designs/` is the recorded decision; morning review via `/report` is the async approval. A manual gate reachable only by hand is the anti-state; a recorded, reproducible handoff is the goal. Keep the rollback-to-Planning path.
- `workaholic:implementation` / `policies/observability.md` — **the counterweight.** Because the run no longer pauses synchronously for a human, it must be explainable from the outside: the Planning→Coding handoff must emit a structured `event-log.md` entry and persist the `designs/` rationale, so a morning reviewer can reconstruct what was decided and built without having been present.

Supporting (apply only if a script is touched — none expected, the halt is prose-encoded):
`workaholic:implementation` / `policies/directory-structure.md` (any new script lands in
`skills/<name>/scripts/`, trips keep the canonical `.workaholic/` layout) and
`policies/coding-standards.md`. Repo-own rules (CLAUDE.md): **Thin commands, comprehensive skills**
(the change lives in the skill + command prose, not a new agent file); **`rules/shell.md`** POSIX +
`posix-lint` **if** any conditional shell is extracted; **trip is Claude-Code-only / excluded from
`outputs/`** so no `build.mjs` rebuild; the Agent Teams members are exempt from the nesting table.

## Key Files

- `plugins/workaholic/skills/trip-protocol/SKILL.md` — **primary.** Edit sites (line refs from discovery):
  - **Step 4 default team-lead instruction (lines ~312-328):** ADD an explicit default flow-through directive — when the plan is fixed (consensus / accepted revisions / forced convergence) and the Decomposition gate has written all tickets, proceed **directly** into the Coding Phase **without** pausing to present the design for a developer green-light. The one-turn review / respond-escalate / moderation / 3-round convergence cap **are** the design gate; the three-agent per-ticket QA is the build gate. A pre-build developer checkpoint is **opt-in only**.
  - **Line ~330 (night flow-through grant):** drop "so the team runs unattended and never pauses for the developer" as the *night-only* differentiator (no-developer-pause is now default). The night append should carry only setup-autoresolve + safe-park + morning report.
  - **Decomposition gate (line ~111):** clarify the `GATE` is a team-internal sync ("wait for all tickets, then flow straight into the Coding Phase — no developer confirmation between Planning and Coding"). Keep the gate; only state it does not block on the developer.
  - **Night Mode subsection (lines ~348-366):** rephrase so "asks the developer nothing" for the design→build transition reads as inherited-from-default; night mode keeps point 2 (skip the setup `AskUserQuestion`), point 4 (safe-park failure policy), point 5 (bounded run), and the morning-review report. The Team-lead night directive (362-364) loses "never pause to ask the developer" as a night-exclusive claim.
  - **Workflow Overview (lines ~30-31):** optionally add a one-clause flow-through affirmation to the design-first line so the prose matches.
- `plugins/workaholic/commands/trip.md` — **sync.** Lines ~18 and ~24: affirm design-first flows Planning → Decomposition → Coding with no green-light pause by default; the night paragraph keeps only setup/failure/report autonomy.
- `CLAUDE.md` (Architecture Policy → trip section) — consider a wording tweak so "`/trip <instruction>` over an empty queue is source+executor (design → decompose → drive)" reads as one **continuous unattended run**, not a design-then-wait.
- **No change needed:** `plugins/workaholic/agents/{planner,architect,constructor}.md` (they defer to the protocol; none encodes a developer-wait), `trip-protocol/scripts/{read-plan,init-trip,log-event}.sh` (the phase machine is prose-driven, not script-enforced), `scripts/build-plugins/build.mjs` (`DEFAULT_TARGETS` excludes trip).

## Related History

The trip's Planning→Coding handoff has always been an **agent-internal consensus gate, never a
human green-light**; the autonomy this ticket defaults already exists for night mode.

Past tickets that touched similar areas:

- [20260622220702-add-night-trip-autonomous-mode.md](.workaholic/tickets/archive/work-20260621-192132/20260622220702-add-night-trip-autonomous-mode.md) - Most relevant: already runs design-first `/trip night` end-to-end unattended with a morning report; its Insights note the trip "was already autonomous internally." This ticket promotes that flow-through to the default.
- [20260623235348-trip-coding-phase-drive-ticket-queue.md](.workaholic/tickets/archive/work-20260623-235347/20260623235348-trip-coding-phase-drive-ticket-queue.md) - Established that the three-agent QA replaces the developer approval gate ("no developer prompt — night-mode-safe"), so the Coding loop already flows without a human gate.
- [20260623235347-trip-decompose-design-into-tickets.md](.workaholic/tickets/archive/work-20260623-235347/20260623235347-trip-decompose-design-into-tickets.md) - Created the Decomposition gate (design → tickets) that stays intact; it is the design→drive bridge.
- [20260311213007-phase-rollback-from-coding-to-planning.md](.workaholic/tickets/archive/drive-20260311-125319/20260311213007-phase-rollback-from-coding-to-planning.md) - The 2/3-majority rollback path that makes autonomous flow-through safe (the team self-corrects without a human).
- [20260310221131-enforce-phase-gate-synchronization-in-trip.md](.workaholic/tickets/archive/drive-20260310-220224/20260310221131-enforce-phase-gate-synchronization-in-trip.md) - Defines the leader as the sole coordinator; clarifies trip GATEs are teammate sync, not human approval — the rationale to reconcile.

## Implementation Steps

1. **Read the three policy hard copies** (modeless-design, ci-cd, observability) and the current
   `trip-protocol/SKILL.md` Workflow Overview, Phase Gate Policy, Steps 4/5, Coding Phase, and Night
   Mode sections so the hoist preserves the team-internal sync gates while removing the developer pause.
2. **Hoist flow-through into the default team-lead instruction** (Step 4, ~312-328): add the directive
   that design-first proceeds from a fixed plan + completed Decomposition straight into Coding without
   a developer green-light; name the review/moderation/convergence machinery as the design gate and
   the per-ticket QA as the build gate; state a pre-build checkpoint is opt-in.
3. **Demote the night-only grant** (~330) and **rephrase Night Mode** (~348-366) so night retains only
   setup auto-resolve, safe-park failure policy, bounded run, and the morning report — not the
   now-default no-developer-pause.
4. **Clarify the Decomposition GATE** (~111) as a team-internal sync that flows straight into Coding.
5. **Sync `commands/trip.md`** (~18, ~24) and optionally the **CLAUDE.md** trip wording so the docs
   read as one continuous unattended design→decompose→drive run.
6. **Reaffirm observability:** ensure the protocol still requires an `event-log.md` entry at the
   Planning→Coding handoff and the persisted `designs/` rationale (morning-review trace) — add a line
   if it is implicit.
7. **Verify (no-op for outputs):** `node scripts/build-plugins/build.mjs` then `git status --porcelain outputs/`
   is empty (trip is excluded — confirms no accidental coupling); `node scripts/build-plugins/verify.mjs`;
   if any shell was extracted, `sh plugins/workaholic/hooks/posix-lint.sh` is conforming and
   `node scripts/test-workflow-scripts.mjs` is green.

## Considerations

- **Reconcile the premise, don't invent a gate.** There is no blocking `AskUserQuestion` to delete; the
  fix is making the *default* lead instruction grant flow-through (currently only the night directive
  does). Frame the commit accordingly so a future reader understands the change is a prose hoist, not a
  code path removal. (`plugins/workaholic/skills/trip-protocol/SKILL.md` lines 312-328, 330)
- **Keep these intact (do NOT relax):** the Decomposition gate (Planning Step 5), design artifacts +
  `event-log.md`, the team-internal sync GATEs ("wait for all three"), rollback-to-Planning (2/3
  majority), the convergence cap, and the genuinely-blocking safety gates — system-safety `detect.sh`
  (project-local enforcement), the Trip Ship deploy-confirmation-gated merge, `check-deps`, and the
  worktree gitignored-file prompt. Only the *design-review pause on the developer* becomes flow-through.
- **CI/CD framing:** this converts a synchronous human gate into an asynchronous, recorded one — the
  committed design is the decision record and `/report` morning review is the approval. Do not let it
  read as a silent skip of a decision point. (`operation/ci-cd`)
- **Observability is the price of removing the pause:** the handoff must stay explainable from the
  outside for the morning reviewer (event log + `designs/` rationale). (`implementation/observability`)
- **Opt-in checkpoint, never default:** if a pre-build design review is ever wanted, it must be an
  explicit opt-in (e.g. a token/flag), never the default behavior. (`design/modeless-design`)
- **No `outputs/` rebuild and no script change expected** — trip is excluded from `DEFAULT_TARGETS`
  and the halt is prose-encoded. If the change tempts any inline conditional shell in the command/skill
  markdown, extract it to a POSIX `#!/bin/sh -eu` script per `rules/shell.md` instead.

## Final Report

Development completed as a prose hoist, exactly as scoped. Three files changed (CLAUDE.md,
`commands/trip.md`, `trip-protocol/SKILL.md`); no scripts, no `outputs/` rebuild (trip is excluded
from `DEFAULT_TARGETS` — confirmed `git status --porcelain outputs/` empty after `build.mjs`).
Verify green, posix-lint conforming, 154/0. The default Step-4 team-lead instruction now explicitly
flows design→build with no green-light pause; Night Mode keeps only its genuine overrides (setup
auto-resolve, safe-park, morning report); the Decomposition gate, rollback, convergence cap, and all
safety gates are untouched.

### Discovered Insights

- **Insight**: The "design pause" the user reported was **not encoded anywhere** — no
  `AskUserQuestion`, no STOP line, no script gate between Planning and Coding. It was an *emergent*
  behavior: Night Mode was the **only** place granting "never pauses for the developer," so a default
  (non-night) team lead *inferred* it should present the design for confirmation before building. The
  fix was therefore subtractive/clarifying (hoist the grant to the default, demote night to its real
  specifics), not a code change. When a user reports a "gate," check whether it is literally encoded or
  emergent from what the default path *fails to say* — the latter is fixed by making the default
  explicit, not by deleting a gate.
  **Context**: `plugins/workaholic/skills/trip-protocol/SKILL.md` Step 4 instruction + Night Mode; this
  mirrors the night-trip ticket's own finding that the trip "was already autonomous internally."
- **Insight**: Removing a synchronous human gate is policy-defensible only when paired with an
  asynchronous, recorded substitute (operation/ci-cd) and outside-observability
  (implementation/observability). Concretely the edit added a phase-transition `event-log.md`
  requirement at the Planning→Coding handoff and leaned on the committed `designs/` artifacts as the
  decision record `/report` reviews the morning after — so the gate became async, not absent.
  modeless-design supplied the positive case (a forced "can't proceed until you confirm" is an
  unjustified mode). Quote those three when relaxing any forced-stop in this repo.
  **Context**: `design/modeless-design`, `operation/ci-cd`, `implementation/observability`.
