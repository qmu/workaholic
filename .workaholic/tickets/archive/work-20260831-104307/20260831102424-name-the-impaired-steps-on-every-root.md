---
created_at: 2026-08-31T10:24:24+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260831102424-read-the-impairment-off-the-tick-s-own-rows.md
mission: name-the-steps-a-tick-could-not-read
merge_policy:
verification_handoff: 
---

# Name the impaired steps on every root

## Overview

PROPOSED. The root reads `🔎 Moderation - N change(s), M question(s)` and its body is the
`event` phrases of the steps the diff called changed. A degraded step normally supplies no
`event`, and *a step with no event renders no line* — so a tick where six steps saw nothing
renders identically to a tick where everything was read and everything was fine.

This ticket renders the reading `read-the-impairment-off-the-tick-s-own-rows` derived: every
root the tick posts names the steps that could not read, with their reasons.

**It rides outside the diff, and that is the load-bearing decision.** A step degraded the
same way for twenty-four ticks has an unchanged summary, so the diff calls it unchanged and
it would be said once and then vanish — which is the defect, not the fix. The ask is
explicit: *report the impairment by name, every tick, until it clears.* So the impairment
line is composed from `impaired[]` directly, on every root that posts.

**Why that is not the twice-retired status root.** `🔧 Needs a decision` and `📦 Release
Preparation` were retired for **earning a post** with an unchanged answer. This earns
nothing: it adds a clause to a root that was already going to be posted for a question, a
digest or a delivery failure. What breaks silence on its own is the next ticket, and that
one *is* gated on the diff.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — an unattended surface must never report coverage it did not have
- `workaholic:design` — the post is the operator's one reading surface; what it omits is
  what they will not know

## Key Files

- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — composes `HEAD` and
  `BODY` and the single `emit true ready ...` call; the impairment clause lands here.
- `plugins/workaholic/skills/moderate/reference/workflow.md` §"The post this step
  produces" — states what `root_text` carries; must move with the render.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the post-shape catalog;
  the root's shape is named there and the clause must be named once, not twice.

## Implementation Steps

1. Confirm the reproduction from the previous ticket still shows a clean-looking root over
   an impaired tick — this time with `--questions 1`, so a root is actually produced and
   the omission is visible in `root_text` rather than in silence.
2. Compose the impairment clause from `impaired[]` **only** — never from `counts`, never by
   re-tokenising the rows. One derivation, two consumers.
3. Put the **count** in the head, beside the two terms already there, so an impaired tick is
   distinguishable at a glance from a quiet one:
   `🔎 Moderation - N change(s), M question(s), K step(s) could not read`. Omit the third
   term entirely when `K` is 0, so a healthy tick's head is byte-identical to today's.
4. Put the **names and reasons** in the body, as one line per impaired step
   (`⚠️ <step> — <status>: <reason>`), appended after the event lines. Bound the render the
   way this repository bounds every other list: name at most the first N in `STEPS` order
   and count the rest as `and K more`, never a silent truncation.
5. Carry **no dedup key, no mention token and no session URL** on the clause — the root
   already carries what it carries, and the developer's standing instruction is to stop
   mixing ids into Slack.
6. Leave the diff, `changes[]`, `change_count`, the question replies and every existing
   gate untouched. A root that posts today posts today, with this clause added when `K > 0`.
7. Update `reference/workflow.md` and the notify catalog copy in the same change, and
   re-run the drift pin.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every `post: true` root whose tick had `impaired_count > 0` names each impaired step and
  its reason in `root_text`, and carries the count in the head.
- A tick with `impaired_count == 0` renders a `root_text` byte-identical to the pre-change
  renderer.
- The clause is rendered on a root the tick was already posting; `post` and its `reason` are
  byte-identical to the pre-change renderer for every input.
- A standing impairment is named on every tick that posts, not only on the tick it appeared.
- The clause carries no dedup key and no mention token.

**Verification method** — the commands/tests/probes that prove them:

- Fixture: two consecutive ticks with the same six steps degraded and one question each;
  assert both roots name all six.
- Fixture: a healthy tick; diff `root_text` against the pre-change renderer.
- `node scripts/test-workflow-scripts.mjs` (including the notify-catalog drift pin)
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The two-consecutive-ticks fixture passes — that is the whole difference between this and
  a line the diff would have swallowed.

## Considerations

- Rendering the clause **inside** the diff was the obvious implementation and is refused
  here with its reason: it reproduces the defect for exactly the case that was measured, a
  steady impairment lasting days.
- The list is bounded rather than unbounded because twenty-nine steps could in principle all
  be impaired at once and a root is a Slack message; the bound is stated in the render rather
  than left to Slack to truncate.
- `blocked` is rendered beside `degraded` under one clause. They differ in cause and are
  identical in consequence to the reader — the tick did not do the job — and two clauses
  would be two vocabularies for one question.

## Final Report

Development completed as planned.

The reproduction was confirmed first at `--questions 1`, where a root *is* produced: over a
tick with two `degraded` steps and one `blocked` one, `root_text` read
`🔎 Moderation - 1 change(s), 1 question(s)` followed by the single event line — a clean-looking
root over an impaired tick, with the omission visible in the text rather than in silence.

The clause is composed from the derived set the previous ticket added and from nothing else:
the derivation loop now also writes `${TMP}/impaired`, and the render reads that file. `counts`
is never consulted and the rows are never re-tokenised.

- **Head**: a third term, `, <K> step(s) could not read`, appended to the two already there and
  **omitted entirely at `K == 0`**.
- **Body**: one line per impaired step, `⚠️ <step> — <status>: <reason>`, appended after the
  event lines. An empty reason renders without the colon rather than with a dangling one.
- **Bound**: `WORKAHOLIC_IMPAIRED_MAX` (default 5) named, the rest counted as `and <K> more`.
  The head always carries the full count, so the bound cannot hide the size of the problem.

It rides outside the diff and is gated on nothing the diff decided. It reaches no gate either:
`post`, its `reason`, `changes[]`, `change_count`, the question replies and all three posting
gates are untouched, so a tick that would have been silent stays silent.

`reference/workflow.md`, the notify catalog and the `[Moderate]` routine template moved in the
same change, and the drift pin's expected first-line list moved with them.

Verified:

- **The gate — two consecutive ticks.** Tick A at 10:45 and tick B at 11:45 over the same three
  impaired steps with identical summaries. Tick B reports `change_count: 0` — the diff swallowed
  every one of them — and its root still names all three. That is the whole difference between
  this and a line the diff would have said once and dropped.
- **A healthy tick.** With every status flipped to `ok`, `root_text` is byte-identical to the
  pre-change capture, and the head carries no third term.
- **The bound.** Seven impaired steps render five names and `and 2 more`, with
  `impaired_count: 7` in the head and the JSON; `WORKAHOLIC_IMPAIRED_MAX=2` renders two and
  `and 5 more`.
- **No key, no token.** `root_text` carries no `tick:` line and no `<@U`.
- `node scripts/test-workflow-scripts.mjs`: 5422 passed, 0 failed, including the notify-catalog
  drift pin (the template and catalog copies verified byte-identical under the new shape).
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`: clean.
  `outputs/` is unchanged, correctly — `notify`, `moderate` and `workaholify` are not in the
  cross-agent bundle.

### Discovered Insights

- **Insight**: `BODY=$(printf '%s%s' "$lines" "$IMPAIRED_BODY")` composes two newline-terminated
  blocks and gets the healthy case byte-identical for free, because command substitution strips
  the trailing newline exactly as it did for `lines` alone.
  **Context**: The obvious alternative — a conditional that appends `\n` plus the clause only
  when non-empty — has the same result and one more branch to get wrong. The existing
  `$(printf '%s' "$lines")` was already relying on that stripping; extending it rather than
  working around it is what makes "byte-identical when K is 0" structural instead of tested.

- **Insight**: Rendering the clause inside the diff loop is the shorter implementation and
  reproduces the measured defect exactly. The steady, days-long impairment is the case that was
  measured, and it is precisely the case a diff calls unchanged.
  **Context**: Worth stating for a later reader who sees an unconditional clause in a file whose
  entire header argues that everything should be diffed. The diff exists to stop an *unchanged
  answer earning a post*; this clause earns no post, so the argument does not reach it.

- **Insight**: The distinction that keeps this from being `📦 Release Preparation` again is
  *earning a post* versus *riding one*. Both retired status roots were retired for the former.
  **Context**: The next ticket in this mission gives a changed impairment a root of its own, and
  that one *is* diff-gated — so the mission ends up with both halves and neither is a status line
  addressed to nobody. The two tickets look contradictory read separately and are not.
