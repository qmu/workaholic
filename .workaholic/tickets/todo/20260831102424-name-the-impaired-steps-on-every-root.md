---
created_at: 2026-08-31T10:24:24+00:00
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
