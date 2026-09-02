---
created_at: 2026-09-02T04:34:16+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: refuse-an-ask-the-loop-wrote-to-itself
merge_policy:
verification_handoff: 
---

# Refuse a machine-authored ask at the proposal seam

## Overview

PROPOSED. The operator's first instruction: a feedback record whose author is a routine
session and whose subject is the loop's own artifact is **not an ask** and must not be
ingested by the proposal seam. Only a human's ask, or a strategy a human authored,
originates a mission.

`/specificate`'s judgment bar today asks *is this decomposable*, *is it actionable*, *does
it restate something*. It never asks *did a person want it*, so a machine-authored record
reached the four forms exactly as a human's did — which is how five self-referential roots
became five merged missions in one day.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/SKILL.md`, *The judgment bar* — where the new
  refusal is stated beside the existing ones.
- `plugins/workaholic/skills/specificate/reference/workflow.md` step 7 — the judgment, and
  step 1, where the ask is taken in hand.
- `plugins/workaholic/skills/specificate/scripts/list-inbound-issues.sh` — the discovery
  that supplies asks; whether the refusal belongs at discovery or at the judgment is this
  ticket's first decision.
- The reader from the sibling ticket — the one source of the `human` / `machine` answer.
- `plugins/workaholic/skills/propose/scripts/file-inbound-ask.sh` and
  `plugins/workaholic/skills/feedback/scripts/open-issue.sh` — the writers whose output the
  refusal must not catch: a human's channel message swept by a routine is a **human** ask.
- `CLAUDE.md` — the `/specificate` contract.

## Implementation Steps

1. Decide where the refusal sits — at discovery, or at the judgment — and record the reason.
   At the judgment the record is still written, which keeps the capture honest and the
   issue closed; at discovery the ask is never taken in hand at all. Prefer the judgment,
   because *the record is written whatever the judgment concludes* is a standing contract.
2. Read the sibling reader's answer for the ask in hand. On `machine`, apply the operator's
   second condition — *and its subject is the loop's own artifact* — as the run's own
   judgement, stated in words in the pull-request body where a person can argue with it.
3. On both conditions holding, the outcome is **record-only** with a named reason
   (`self_authored`), reported like every other refusal. Not silence, not an error: the
   record is written, the issue closes, and the run says which rule refused.
4. On `unreadable`, do **not** refuse. A grandfathered record with no subject is an ordinary
   ask and refusing it would silence real history; report the unreadable reading by name.
5. Do not catch the sweep. A message a person wrote in the channel, filed as an issue by a
   routine, has `subject: person:<author>` by the sweep's own contract — that is a human ask
   arriving through a machine, and the reader's subject axis already tells the two apart.
   Pin that case in the suite explicitly; it is the regression that would break the loop's
   main inbound path.
6. State the refusal in `workaholic:specificate`'s judgment bar and in `CLAUDE.md`, in the
   same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An ask reading `machine` about the loop's own apparatus is record-only, reported
  `self_authored`.
- A swept human message is unaffected, and that case is pinned.
- An `unreadable` reading never refuses.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`, including the swept-message regression.

**Gate** — what must pass before approval:

- The record is still written for a refused ask; the capture contract does not move.

## Considerations

- The second condition is a judgement and always will be: a machine *can* write a genuine
  finding about something other than the loop's own apparatus. Stating it in the pull
  request rather than encoding it is the honest shape, and it matches how
  `describing_move` already lives beside the mechanical gates.

## Final Report

Development completed as planned.

- **The refusal sits at the judgment, and the reason is recorded** (step 1). At discovery the
  ask is never taken in hand and **no record is written**; at the judgment *the record is
  written whatever this step concludes* is a standing contract of the seam, so the capture
  stays honest and the triggering issue still closes. Discovery's own `self_originated`
  exclusion (issue #864) is a **different test on a different signal** — a `source: moderate`
  body header — and is untouched; the two are stated side by side so a later reader does not
  fold one into the other.
- **The reading comes from the sibling ticket's one reader** (step 2), and the second
  condition — *is its subject the loop's own apparatus?* — is the run's own judgement, written
  into the pull-request body where a person can argue with it. It is not encoded, and the
  document says why: a machine can write a genuine finding about something else.
- **The outcome is record-only, reported `self_authored`** (step 3) — not silence, not an
  error.
- **`unreadable` never refuses** (step 4): a grandfathered record with no `subject:` is an
  ordinary ask, and the reading is reported by its reason.
- **The sweep is not caught** (step 5): a person's channel message filed as an issue by a
  routine carries `subject: person:<author>`, so the reader answers `human`. Pinned explicitly
  in the suite — it is the loop's main inbound path and the one regression that would matter.
- **Stated in `workaholic:specificate`'s judgment bar, in `reference/workflow.md` step 7 and in
  `CLAUDE.md`, in the same change** (step 6), and pinned: the suite asserts all three name the
  same word and the same reader, that each states the three safety properties, and that **no
  script under `specificate/scripts/` parses the `subject:` axis itself**.

### Discovered Insights

- **Insight**: The drift pin worth having here is not "the rule exists" but "**no second parser
  grew**". The refusal is prose a model applies, so nothing can check that a run asked the
  question — but a `subject:` parse appearing inside `/specificate` would be a second reading
  of the axis, and that is mechanically checkable and is the failure that actually costs
  something.
  **Context**: The same shape suits every prose refusal in this repository that rests on a
  script's single reading.
