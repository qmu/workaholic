---
created_at: 2026-08-29T19:31:03+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-two-executors-agree-about-a-proved-empty-claim
merge_policy:
verification_handoff: 
---

# Say why CI's turn never saw a unit the container proves empty

## Overview

PROPOSED. CI's recorded reading on the current tip is
`claim-retirement candidates ok=true reason= count=0` while the container's
`list-retirable-claims.sh` names three units, each `state: present`. `ok: true` with
`count: 0` is **byte-identical to a healthy, empty turn**, so a unit CI never saw reads
exactly like a unit CI had nothing to do about.

The record already carries the count. What is missing is the **per-unit** reading: a unit
the container proves `superseded` and the recorded candidate reading never named must read
by its own name — never `taken` — and reach `/moderate`'s existing
`retire-blocked:<unit>:<refusal word>` question.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a reading nobody made is never an answer
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/runtime-resilience.md` — a degraded read is named, not defaulted

## Key Files

- `plugins/workaholic/skills/drive/scripts/read-ci-retirement-record.sh` — the per-unit
  reader: `taken` / `refused:<word>` / `pending` / `unavailable` / `unreadable`. The unit
  in question is named by **no** entry in a turn whose candidate reading was `count: 0`.
- `plugins/workaholic/skills/drive/scripts/ci-retirement-turn.sh` — the composed reading
  the `/moderate` step consults.
- `plugins/workaholic/skills/drive/scripts/record-ci-retirement-turn.sh` — the writer,
  which copies the candidate reading's `ok`/`reason`/`count` and each act's own words.
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the consumer, and
  the rule that only `taken` and `pending` hold the question.
- `plugins/workaholic/skills/drive/reference/claims.md`, *Whether an act the loop took had
  its effect* — where the words are classified; a new word goes there or nowhere.

## Implementation Steps

1. **Reproduce first, both sides.** From the checkout run
   `list-retirable-claims.sh`; from GitHub read the `retire` job's `::notice::`
   annotations for the same head
   (`GET /repos/{o}/{r}/commits/<sha>/check-runs` → `.../check-runs/<id>/annotations`).
   Record both readings verbatim in the branch story. Measured 2026-08-29 at head
   `7cdc58f1`: three candidates locally, `ok=true reason= count=0` in CI, check run
   `99149022509`, every run of the day `success`.
2. Establish what `read-ci-retirement-record.sh` currently answers for one of the three
   units against that record, and what `ci-retirement-turn.sh` composes from it. The
   finding reports `ci_turn: taken` with `units: []` at base `6cdf99a9`, and `no_run_id`
   at the tip — confirm which is reached and when.
3. Make a unit **absent from a completed turn's candidate reading** read by its own name
   rather than `taken`. `unreadable` already means *a run completed and we cannot say what
   it did*; whether this is that, or a distinct word, is the implementer's call — decide
   it in `drive/reference/claims.md`'s existing sub-table and nowhere else, and add a word
   only if the existing five genuinely cannot carry it.
4. Whatever it reads must **not** hold the question: only `taken` and `pending` hold, and
   a unit CI never saw is owed a question, not silence.
5. Extend the classification pin so the suite fails if the new reading is unclassified or
   if a consumer acts on it. Every value here stays a **judgement**.
6. Update `CLAUDE.md`'s claim-protocol bullet in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit the container proves `superseded` that a completed turn's candidate reading never
  named reads by its own name and never `taken`.
- That reading does not hold `retire-blocked:<unit>`, so the person is asked.
- The reading is classified in `drive/reference/claims.md` as a judgement with its
  enumerated consumers named.
- No verdict word is added to `lib/claims.sh` and the proof gate is untouched.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-ci-retirement`
- The step-1 readings recorded in the branch story.

**Gate** — what must pass before approval:

- Both commands pass and the step-1 reproduction is recorded.

## Considerations

- This ticket makes the silence **legible**; ticket 2 removes its cause. Doing only this
  one leaves the branches standing, which is why the mission carries both.
- The tempting shortcut is to treat `count: 0` as a degradation. It is not — the scan
  succeeded and honestly found nothing; the defect is that *what it looked for* differed
  between executors, which is a fact about the unit, not about the read.

## Final Report

**Already delivered by an earlier turn of the loop — verified, not assumed, and no word was
added.** The ticket was written from a finding taken at base `6cdf99a9`; the repair shipped by
mission `read-back-whether-the-loop-s-own-act-took-effect` landed before this ran, and it
already answers exactly what this ticket asks for.

**Step 1 — reproduced, both sides, at head `4563afa1`:**

- `list-retirable-claims.sh` from the checkout names **three** units — `batch-20260819063000`,
  `make-a-rename-a-registry-entry-not-a-sweep`,
  `make-the-draft-release-note-an-agent-s-release-plan` — each `state: present`.
- `ci-retirement-turn.sh` over those three answers, per unit, **`ci_turn: unreadable`** — never
  `taken`, with the run-level word `taken` meaning only *CI had its turn and we can see what it
  did*.

**Step 2 — what the readers compose.** `read-ci-retirement-record.sh` reads a healthy candidate
reading (`candidates_ok: true`) that names none of the three, and `ci-retirement-turn.sh`'s
`unnamed` branch resolves that to `unreadable` rather than `refused:<reason>` — the correct
distinction, since nothing went wrong that we can name.

**Steps 3–4 — the implementer's call, exercised rather than deferred.** `unreadable` **carries
it**: `drive/reference/claims.md` already documents that word as *the record … names this unit
nothing while the candidate reading itself was fine*, which is precisely this case, and
`step-retire-claims.sh` holds only `taken` and `pending`, so the question is **not** held. Live
proof: the step reports all three in `needs_agent` with the event *3 claims proved finished are
still standing*. **No fifth word is added**, which is also the mission's own third acceptance
item.

**Steps 5–6.** The classification pin and `CLAUDE.md`'s claim-protocol bullet already carry it;
what this branch adds to both is the **second cause** the finding missed, which is ticket 2's.

**Gate:** `node scripts/test-workflow-scripts.mjs` (5168/0) and the live readings above.
