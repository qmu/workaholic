---
created_at: 2026-08-28T18:20:02+00:00
status: done
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

## Final Report

Development completed, with **one deviation from the ticket's stated Gate, recorded here
rather than worked around**.

**The deviation.** The Gate says *"`render-tick-post.sh` and the question gate are
unmodified"*, and the acceptance says *"A tick with candidates and zero delivered supplies an
`event` **and the root carries it**"*. On the tree as it stood those two cannot both hold, for
two reasons the ticket's Key Files did not name:

1. `render-tick-post.sh` skipped the check-in **by name** in its diff loop
   (`[ "$step" = "human-checkin" ] && continue`), on the sound reasoning that its own summary
   changing is not news about the repository. An event supplied by this step could therefore
   never reach the root at all.
2. The post gate requires `QUESTIONS >= 1` (or the morning digest), and the failing tick has
   zero questions by definition — that *is* the failure. So the event would render no line
   and the root would still not post.

The acceptance and the mission's Experience (*"A tick that reached nobody says so instead of
looking quiet"*) are the load-bearing statement: a step supplying an `event` that nothing can
ever render delivers exactly as much as before, which is nothing. So the acceptance was taken
and `render-tick-post.sh` was changed, as narrowly as the two obstacles allow:

- **The `human-checkin` skip is removed rather than narrowed**, because the guard that
  replaces it already exists and is more general: *a step with no event renders no line*
  (line 193, unmodified). The check-in supplies an event only on a delivery failure, so a
  delivering check-in and a quiet one are dropped exactly where every other event-less step
  is — before they can be counted as a change. Behaviour for every other tick is unchanged.
- **A third gate is added beside the digest, on the digest's own precedent**: the question
  gate's own expression (`[ "$QUESTIONS" -eq 0 ]`) is byte-identical, and a second condition
  is OR'd next to it, exactly as `digest_ready` was on 2026-08-24. So *"the question gate
  stays the root's gate"* holds in substance; what does not hold is the literal
  "`render-tick-post.sh` is unmodified".

**It is not the retired changed-step half of the gate** (step 4's explicit prohibition). That
half let *any* changed step earn a question-less root. This fires only when the check-in
itself supplied an event, and `delivery_failure` is set **inside the diff loop**, so it
inherits the diff: an unchanged reading an hour later is suppressed by the same derivation
that suppresses every other restatement, the line is said once, and it stops entirely once the
channel is delivering. That is step 5's "do not let it restate", obtained by construction
rather than by a suppression list.

**The wording** names how many findings are waiting and why none reached anybody, in one
sentence, with **no dedup key and no mention token**. It is not added to
`workaholic:notify`'s catalog: the catalog names post *shapes*, and a root body line is not
one — no other step's `event` is named there either. The `🔎 Moderation` root's own shape,
which already says *"one line per changed step that has an event"*, is unchanged.

`cap_spent` gets a line even though the budget worked, per step 3: a reader must be able to
tell it from `cap_unbounded`. The honest tension the ticket records stands — on a genuinely
spent day this is close to a status line — and the diff means it is said at most once a day;
if it proves noisy, narrowing to the non-`cap_spent` reasons is the first thing to try.

Verification — `node scripts/test-workflow-scripts.mjs`, the four gate cases added to
`testModerateTickPost`: a tick with candidates and none delivered posts with **zero**
questions and the root carries the line; two consecutive ticks with the same reading render
one line, not two; a quiet hour supplies no event and posts nothing; a delivering tick
behaves exactly as before. `sh scripts/e2e/loop-drill.sh verify-checkin-delivery` passes,
including `checkin_root_carries_it` and `checkin_quiet_hour_silent`.

### Discovered Insights

- **Insight**: the two obstacles are independent guards, and only one of them was documented.
  **Context**: the ticket's Key Files named line 193 (the no-event guard) and line 230 (the
  `no_question` emit) as read-only, and both genuinely are. What it did not name is line 186,
  the by-name skip that made the whole design unreachable. A ticket that names the lines it
  expects to be enough is worth re-deriving against the file rather than trusting.
- **Insight**: setting the gate flag *inside* the diff loop rather than beside it is what
  makes "do not let it restate" free.
  **Context**: a flag set from the step's raw output would post every hour for as long as the
  cap stayed spent — the `📦 Release Preparation` failure exactly. Inside the loop it can only
  be set for a reading that survived the diff.
