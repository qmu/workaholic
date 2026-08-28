---
created_at: 2026-08-28T18:20:02+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-what-the-loop-already-knows-to-the-person-who-can-act
merge_policy:
verification_handoff: 
---

# Make a tick that reached nobody an event

## Overview

PROPOSED. The root's gate is *a question*, and `step-human-checkin.sh` supplies **no `event`
field at all** (verified: the step's JSON has no `event` key). So a tick with 22 candidates
and zero delivered posts nothing, and total silence is byte-identical to a quiet hour — for
eight consecutive ticks, with a red base, a 31-hour handoff, three undeletable branches and
seven undrivable units all held behind it.

A delivery failure **is** the event the root exists to carry. Give the check-in step an
`event` for exactly that case, so `render-tick-post.sh`'s existing machinery carries it. One
line, naming no dedup key.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a state that reaches nobody is reported, not silent

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — gains the `event`
  field, from the previous ticket's reading.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — read only: line 193
  skips a step with no event, line 230 emits `no_question`. **Neither changes.**
- `plugins/workaholic/skills/moderate/run.sh` — read only; confirms the step is last and
  deadline-exempt (line 213).
- `plugins/workaholic/skills/notify/reference/notifications.md` — where the line's wording is
  named, if the catalog owns it.
- `scripts/test-workflow-scripts.mjs` — the gate cases.

## Implementation Steps

1. **Supply `event` only when the tick had candidates and delivered none.** Every other case
   supplies **no** event and therefore renders no line — the existing independent guard
   against a nothing-happened line reaching the root. In particular a genuinely quiet hour
   (`no_candidates`) supplies nothing, and a tick that delivered questions needs no event
   because the questions themselves are the delivery.
2. **Write the line as what a person must act on**, in one sentence: how many findings are
   waiting and why none reached anybody — the previous ticket's reason word rendered in
   words. It names **no dedup key** (`tick:`/`ask:`/`fb:` keys left the roots on
   2026-08-22) and carries **no mention token**: the root is addressed to nobody, and the
   questions are the mentioned replies inside it.
3. **`cap_spent` is a real state and says so plainly** — the budget worked as designed. It is
   still worth one line, because a reader must be able to tell it from `cap_unbounded`, which
   is the loop broken.
4. **Change no gate.** The question gate stays the root's gate; this only makes a step supply
   an event it never supplied, which the existing OR-free gate already knows how to carry.
   Do **not** reintroduce the retired changed-step half of the gate.
5. **Do not let it restate.** The root's line is a diff against the previous tick's summary,
   so an unchanged reason renders once; confirm the summary this event derives from is stable
   across ticks with the same reading (no timestamp, no count that moves by construction) —
   the normalisation `inbound-sweep` and `doc-drift` needed.
6. Add cases: candidates-and-none-delivered supplies an event and the root posts; a quiet hour
   supplies none and posts nothing; a delivering tick posts its questions as before; two
   consecutive identical-reason ticks render one line.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick with candidates and zero delivered supplies an `event` and the root carries it.
- A tick with no candidates supplies no `event` and posts nothing.
- A tick that delivered questions behaves exactly as before.
- The event line carries no dedup key and no mention token, and two consecutive ticks with
  the same reason render one line, not two.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the four gate cases.
- `sh scripts/e2e/loop-drill.sh verify-moderate` — the tick's existing drill still passes.

**Gate** — what must pass before approval:

- `render-tick-post.sh` and the question gate are unmodified.
- If the wording lives in `workaholic:notify`'s catalog, the step's copy is byte-identical to
  it and pinned against drift by the suite, as every other shape is.

## Considerations

- **This is not a status root.** `🔧 Needs a decision` and `📦 Release Preparation` were
  retired for restating an unchanged answer to nobody; this line fires only on a delivery
  *failure*, is suppressed by the same diff that suppresses every other restatement, and
  stops entirely once the channel is delivering.
- The honest tension: on a genuinely spent day this line says "the cap worked", which is close
  to a status line. It is kept because `cap_spent` and `cap_unbounded` must be
  distinguishable by a reader, and the diff means it is said once a day at most. If it proves
  noisy, narrowing it to the non-`cap_spent` reasons is the first thing to try.
- Nothing here raises a cap or asks an extra question: it makes the loop's own silence
  visible, which is the contraction the mission declares.
