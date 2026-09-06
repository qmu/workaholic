---
created_at: 2026-09-06T18:55:01+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: see-a-frozen-runner-and-give-back-its-slot
merge_policy:
verification_handoff: 
---

# Read whether a running loop subagent is still advancing

## Overview

`ListAgents` reports `running` for both "executing a tool" and "blocked forever on a permission
dialog nobody will answer". Measured 2026-09-06 in an unattended `/work` loop: `implement-10`
made its last tool call at 05:42:49 UTC and was reported `running` by nine consecutive
`ListAgents` calls until the parent stopped it by hand at 06:21:18 — 38m29s. Nothing in the tick
distinguished the two, and the parent's own derivation was the **absence** of task
notifications.

This ticket adds no new status to the harness — that is the harness's to give. It adds a reader
this repository can build from evidence it already owns, answering per running loop name whether
the run is still advancing, so the next ticket can act on the answer.

**This is a failure report, so it opens with reproducing and localizing, not with a design.**
Which evidence actually separates the two states is the question the diagnosis must settle, and
the reporter's own three suggestions are recorded under Considerations as hypotheses.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the reading is operational evidence; a degraded read is named, never
  rendered as healthy

## Key Files

- `plugins/workaholic/skills/loops/scripts/` — where the reader belongs, beside
  `claimable-units.sh` and `read-machine-load.sh`, which are the tick's other two readings
- `plugins/workaholic/commands/infinite-development.md` §2 — the one caller: `ListAgents` is
  called once there and answers exactly one question today
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` / `log-append.sh` — the tick log, the
  only store the loop already keeps and the source of the `loop-finish-<name>` cadence
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the claim oracle, whose branch tip
  is the runner's heartbeat
- `plugins/workaholic/skills/loops/SKILL.md` — where the tick's premise and its measurements are
  recorded

## Implementation Steps

1. **Reproduce.** Drive a loop subagent into a permission dialog it cannot answer (the measured
   trigger was a `Bash` call under `~/.claude/plugins/cache/...`). Record what `ListAgents`
   answers for it, at what interval, and for how long.
2. **Localize.** For that frozen run and for a healthy one alongside it, record what each leaves
   behind over the same window: the claim branch tip, the tick log, the worktree, the pull
   request, the archived tickets. Name which of these **moves** during healthy work and is
   **flat** during a freeze. That difference is the reader's evidence; anything that is flat in
   both is not.
3. **Then** write `loops/scripts/read-runner-advance.sh` over exactly the evidence step 2
   proved, answering per running loop name `advancing` / `not_advancing` / `unreadable:<reason>`.
4. Make it **offline and local** — no network read — so it costs a five-minute tick nothing, the
   way `read-machine-load.sh` costs it nothing.
5. **A reading that cannot be made is `unreadable:<reason>` with a null age, never
   `not_advancing`.** A wrong `not_advancing` sends the loop after a runner that is working; the
   repository's own rule is that a gate which cannot be read is not a gate.
6. Report the reading in §3 of the tick report as evidence only. **This ticket changes no
   allocation and stops no agent** — the accounting is the next ticket's and the killing is
   nobody's.
7. Drill it offline in `scripts/e2e/loop-drill.sh` with a breaker row written against the
   behaviour, and register it in `docs/loop-drill-runbook.md` §9.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reader answers `advancing` / `not_advancing` / `unreadable:<reason>` per running loop name.
- The reproduction and the localization are recorded, naming which evidence separates the two
  states and which does not.
- An unreadable read never renders as `not_advancing`.
- The reader makes no network call and stops no agent.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- The new drill, exercising a frozen fixture and a healthy one against the same reader.

**Gate** — what must pass before approval:

- The above pass, and the localization names its evidence rather than asserting it.

## Considerations

- **The reporter's three suggestions are hypotheses, not the design.** Two of them — a
  last-activity time per agent in `ListAgents`, and an `awaiting_approval` status — are harness
  capabilities this repository cannot add, and neither may be assumed present. The third, not
  counting a non-advancing runner, is the next ticket.
- **The heartbeat is a tempting evidence source and is known to lie in the other direction.**
  Record `20260906121540` measured, the same day, a run that was legitimately mid-ticket with an
  old claim tip: the beat is step 0 of every ticket, not a cadence. Step 2 must establish that
  before the tip is used, or this reader inherits that false positive.
- **`started` age is retired as a cadence source** (`commands/infinite-development.md` §2) and
  must not come back here: it measured the previous run's start plus its whole duration.
- **Not stopping the runner is deliberate.** The tick's existing rule stops every `idle` agent
  unconditionally; extending an unconditional stop to a *judgement* about advancement would kill
  work in progress on a reading, which is the mistake the machine-load bound already refuses by
  name.

## Final Report

Development completed as planned.

The diagnosis ran first, as the ticket required. **Reproduction** was taken from this
repository's own dated record rather than re-staged: driving a live subagent into a permission
dialog is not something this run can do from inside one, and the measurement it would produce
already exists (`implement-10`, last tool call 05:42:49 UTC, nine consecutive `ListAgents` calls
reporting `running`, stopped by hand at 06:21:18 — 38m29s). **Localization was measured here**,
and it is what decided the design.

Over one reading of the live checkout: the claim worktree of a run that was mid-ticket had a
newest file mtime **101 seconds** old, while three worktrees of runs that had stopped read
**15, 17 and 18 hours**. That is the only candidate that moves during healthy work and is flat
during a freeze. Each of the others was ruled out by evidence rather than by preference: the
claim tip and heartbeat are flat in *both* (the beat is step 0 of every ticket, so a run
legitimately mid-ticket carries an old tip — the ticket's own Considerations demanded this be
established before the tip was used, and it does not survive it), and are besides carried on a
**remote** ref this reader may not fetch; `loop-finish-<name>` is written when a run is first
observed **idle**, so it says nothing during any run; archived tickets share the tip's
granularity; the pull request is a network read.

`loops/scripts/read-runner-advance.sh` reads exactly that and nothing else.

### Discovered Insights

- **Insight**: nothing this repository owns is keyed by loop subagent name — a claim is keyed by
  unit, a worktree by unit, `loop-finish-<name>` by role.
  **Context**: so a running name cannot in general be bound to the worktree its runner is writing
  in, and the reader refuses that binding (`ambiguous_binding`) rather than inventing one. It
  answers exactly where the binding is not needed: all names `advancing` when at least as many
  worktrees advance as there are runners, all `not_advancing` when none does and every claim was
  readable. A later change wanting per-name precision has to add the keying first, not loosen the
  refusal.

- **Insight**: `frozen_count` had to be defined as *the names actually answered `not_advancing`*,
  not as `running - advancing`.
  **Context**: the arithmetic form is sound about **how many** runners are stuck while naming
  none of them, so a consumer would be told "one is frozen" on a tick where every name read
  `unreadable` — spending a reading the reader had explicitly declined to make. Two defects of
  exactly this kind were caught by exercising the fixtures rather than by reading the code: the
  count leaked through `no_claim_evidence`, and one unreadable claim let the all-frozen branch
  fire on evidence that was never established.

- **Insight**: an empty `.worktrees/` must answer `no_claim_evidence`, never `not_advancing`.
  **Context**: a runner still in its survey has claimed nothing yet and has no worktree to move,
  so the flat reading is indistinguishable from a freeze. This is the one false-positive path
  that would have the loop spawn a second runner against a working one.
