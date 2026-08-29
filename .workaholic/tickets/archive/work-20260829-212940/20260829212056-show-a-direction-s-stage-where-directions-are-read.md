---
created_at: 2026-08-29T21:20:56+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-lifecycle-a-declared-stage
merge_policy:
verification_handoff: 
---

# Show a direction's stage where directions are read

## Overview

PROPOSED. The ask's *positioning* half: the stage is the direction's declared phase and
must be visible **wherever directions are read** — "one word per direction, not a bundle
of readings the reader must cross-reference".

Three surfaces read directions today and none of them says the phase:

- the bare `/mission` roadmap, which already names each mission's strategy;
- `/standup`'s per-strategy digest, rendered at the top of the JST-morning
  `🔎 Moderation` root by `/moderate`'s `strategy-digest` step;
- `/moderate`'s direction questions, which name a reading (`arrived`, `overdue`,
  `dormant`, `expiring`) but never the declared phase the person is being asked about.

All three render from readers that carry `stage` after the earlier ticket, so this is
render work with **no new read**. One word, beside the title, in the operator's own
characters.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/interface-clarity.md` — one word, one meaning, at the point of reading

## Key Files

- `plugins/workaholic/skills/standup/scripts/digest.sh` — carries `stage` per strategy
  row from the reader it already composes; the render names it beside the bold title.
- `plugins/workaholic/skills/mission/` roadmap render — the bare `/mission` output, which
  already names each mission's strategy through `mission-strategy.sh`.
- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the question
  heading names the declared stage beside the reading.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the post shapes, if the
  digest's rendered line is one of the pinned copies.
- `CLAUDE.md`.

## Implementation Steps

1. Read `digest.sh`'s render and `notify/reference/notifications.md`'s `📣 Standup` shape
   whole before changing a rendered line — the routine templates carry byte-identical
   copies that a drift pin fails on.
2. Carry `stage` through `digest.sh` from the reader that already supplies the row; render
   it as one word beside the strategy's title, and render an **unreadable** stage as
   unreadable by its reason rather than as 進行中.
3. Name the stage on the `/mission` roadmap's strategy line, beside the slug it already
   prints, with an explicit rendering for a direction whose stage could not be read.
4. Add the stage to `direction-health`'s question **heading** — where the residue and the
   leaving already ride — never to the body, which `workaholic:notify` bounds to one
   sentence of 25 words reserved for the operator's act.
5. Change **no** dedup key, no question key, no asked-once gate and no cap: a body or a
   heading that changes never re-asks a question, since the ledger keys on the step id.
6. If a rendered line is one of the pinned copies, update the routine template and the
   pin in the same change.
7. Update `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The morning digest, the `/mission` roadmap and every `direction-*` question name the
  direction's declared stage.
- A direction whose stage could not be read renders as unreadable, never as 進行中.
- No question key, dedup key, cap or hold moves; no question is re-asked by this change.
- Every pinned post copy still matches its routine template byte-for-byte.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-standup`
- `sh scripts/e2e/loop-drill.sh verify-direction-health`

**Gate** — what must pass before approval:

- The digest still posts nothing on `no_strategies` / `no_activity` /
  `strategy_list_unreadable`; the stage is never a reason to post.

## Considerations

- The digest is a daily post and a standing claim on attention: adding a word must not
  turn a silent morning into a spoken one. The silence rules are untouched.
- The `/mission` roadmap is read by a person scanning many rows, so the stage goes where
  the strategy already is rather than as a new column.

## Final Report

Development completed as planned.

Three surfaces name the stage now: the morning digest (one word beside the title, off the row
it already reads), the bare `/mission` roadmap (beside the strategy it already prints), and
every `direction-*` question heading — including `direction-last`, which composes its heading
separately. No question key, cap or hold moved, and the digest's silence rules are untouched.

**One ticket was minted mid-run** and the current one continued:
`20260829231500-stop-a-swallowed-jq-error-reading-as-a-quiet-tick.md`.

### Discovered Insights

- **Insight**: `step-direction-health.sh` ends its subject composition with
  `jq -c '…' 2>/dev/null || echo '[]'`, so a jq **compile** error is discarded and the step
  reports `status: ok`, `"1 overdue, 1 dormant … 0 to ask"`, `needs_agent: []`. A tick that
  found two directions needing a person, could not compile the expression naming them, and
  called itself healthy. `sh -n` passes — the shell is fine, the embedded jq is not.
  **Context**: this is the exact collapse the step's own header forbids elsewhere, and it is
  the shape rather than the file, so it is minted as its own ticket rather than patched here.
  While developing against one of these scripts, temporarily removing the `2>/dev/null` is the
  fastest way to see what is actually wrong.

- **Insight**: `heading: (if … end) + $var` does not parse in jq inside an object; the value
  needs its own parentheses — `heading: ((if … end) + $var)`. Combined with the swallowed
  error above, the symptom was an empty question list rather than any error at all.
  **Context**: the live repository hid it for a further reason worth knowing — a single live
  direction takes the `direction-last` branch, which composes its heading separately, so the
  main chain was never exercised by a smoke check against this tree. A fixture with **two**
  directions is what runs it.

- **Insight**: two scripts in this mission were broken by an apostrophe inside a comment in a
  single-quoted jq program. `every shipped shell script parses` was added to the suite as a
  permanent guard and was proved able to fail by re-introducing the defect.
