---
created_at: 2026-08-27T05:22:41+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-and-retire-what-the-loop-already-proved-finished
merge_policy:
verification_handoff: 
---

# Add the /moderate step that retires a proved claim

## Overview

PROPOSED. `retire-claim.sh` (ticket 4) is the writer; this ticket adds its **only** caller —
a `/moderate` step beside `undelivered-units`. The step re-proves each `superseded` row in the
tick's own read of the oracle, retires what the re-proof confirms, and reports every
retirement and every refusal by name. It **asks no question** — a retirement is not a person's
business — and writes nothing into the tree but its own log line.

This follows the precedent `closable-missions` set on 2026-08-24: the tick closes what the
step proved, with the proof re-taken at the moment of the act rather than trusted from an
earlier read.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the maintenance tick's contract

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — **new**; the step.
- `plugins/workaholic/skills/moderate/scripts/step-undelivered-units.sh` — the step it runs
  beside; read it for the `list-claims.sh`-not-`plan-units.sh` rule and the reporting shape.
- `plugins/workaholic/skills/moderate/scripts/step-closable-missions.sh` — the re-prove-then-act
  precedent, including why the survey may not be composed here.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — invokes every step; the step is added
  to the ordered list.
- `plugins/workaholic/skills/moderate/SKILL.md` — the step count and the step's record.
- `CLAUDE.md` — the `/moderate` row.

## Implementation Steps

1. Read `step-undelivered-units.sh` and `step-closable-missions.sh` in full, including their
   headers' reasons for reading `list-claims.sh` rather than `plan-units.sh` — the survey runs
   the living migrations and **stages** what they change, and a step whose contract is *writes
   nothing into the tree* may not reach it through something that writes.
2. Read the oracle once in the step, take every row whose verdict is `superseded`, and
   **re-prove** it at the moment of the act rather than trusting an earlier read.
3. Call `retire-claim.sh` per confirmed row. A row the re-proof rejects is **reported, not
   retired**.
4. Report per row: retired (with the three acts' outcomes) or refused (with the reason).
5. Ask **no** question — the step's `needs_agent` carries nothing for the check-in.
6. Write one log line through `log-append.sh` like every other step; nothing else in the tree.
7. Update the step count in `moderate/SKILL.md` and `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every `superseded` row confirmed by the re-proof is retired; every rejected one is reported.
- The step asks no question and contributes nothing to the check-in.
- The step reads `list-claims.sh`, never `plan-units.sh`.
- The step writes nothing into the tree but its own log line.
- `run.sh` invokes it and it contributes a report line whether or not it retired anything.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire` (ticket 7)
- `git status` clean after a step run over a fixture — the check that caught
  `closable-missions` leaving a modified mission in the index.

**Gate** — what must pass before approval:

- No `plan-units.sh` call anywhere in the step's reach, and the tree is unmodified after a run.

## Considerations

- The step is the writer's only caller, deliberately: one caller is what keeps the retirement's
  bounds checkable.
- A degraded oracle read is reported `degraded` by name and retires nothing — a proof that
  could not be read is not a proof.

## Final Report

Development completed as planned.

`step-retire-claims.sh` runs at position 19, immediately after `undelivered-units`, and is
`retire-claim.sh`'s only caller. It reads `list-claims.sh` and nothing else — no `plan-units.sh`
anywhere in its reach — takes every row whose verdict is `superseded`, and hands each to the
writer, which re-derives the verdict itself before touching anything. So the re-proof happens at
the moment of the act rather than from this step's snapshot, which is the `closable-missions`
precedent applied where it belongs.

`needs_agent` is empty and the step asks nothing. Per-row detail lives in the log-facing
`summary`: a retired row names all three acts, a refused row names its reason. The tick's
step-count prose (`moderate/SKILL.md`, `reference/workflow.md`, `CLAUDE.md`) moved from eighteen
to nineteen, and the suite's pinned step list gained the entry with its reason.

Verified: the degraded paths (`origin_unreachable`, `claims_unreadable`) report by name, retire
nothing, carry `needs_agent: []` and supply an empty `event` so the root renders no line; `git
status` was unchanged across those runs. The full three-act proof over a fixture with the
transport stubbed is the next ticket's drill (`verify-retire`), which is why this run deliberately
did **not** exercise the live retirement against this repository's four real `superseded` claims:
retiring them is the tick's act on its own schedule, not a side effect of testing the step that
calls it.

### Discovered Insights

- **Insight**: This step acts directly where `closable-missions` hands off, and the difference is
  the tree seam rather than a preference about autonomy.
  **Context**: `closable-missions` cannot act because `close.sh` writes into the tree and needs a
  publish tree to do it — the tick's *writes nothing but its own log line* contract is what
  forces the hand-off there. `retire-claim.sh` writes nothing into the tree at all (one REST
  PATCH, one branch delete, one local worktree reap), so there is no seam to cross and a hand-off
  would spend a round trip for nothing.

- **Insight**: `needs_agent` is the wrong home for a report, even a report with no question in it.
  **Context**: The field is a request to the agent; a structured payload sitting in it with no
  `action` reads as one. The per-row outcomes went into the log-facing `summary` instead, which
  is where the audit trail already lives and where somebody diagnosing a retirement will look.

- **Insight**: A tick that only *refused* supplies no `event` either.
  **Context**: The 2026-08-23 rule is that a root line names a repository event. A retirement is
  one — a pull request closed, a branch deleted — but a refusal is the step's own bookkeeping and
  belongs in the tick log, not on the root. The event is therefore keyed on `retired > 0` rather
  than on the step having run.

- **Insight**: The suite's pinned step list is the mechanical guard on this addition.
  **Context**: Four assertions failed on the count alone (the ordered list, the log line count,
  the re-entered tick and the crash-path coverage), all derived from one `STEPS` array. Adding a
  step without registering it there is caught immediately, which is why the array carries a
  reason per entry rather than being a bare list.
