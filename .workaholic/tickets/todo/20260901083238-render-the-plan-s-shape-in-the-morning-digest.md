---
created_at: 2026-09-01T08:32:38+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260901083237-read-the-plan-s-shape-at-the-mission-grain.md
mission: report-where-the-work-stands-not-only-what-is-wrong
merge_policy:
verification_handoff: 
---

# Render the plan's shape in the morning digest

## Overview

The reading from the previous ticket has to reach the operator, and where it reaches them
is a decision this repository has already made twice. The ask says "post it on the ordinary
tick rather than only when something is wrong". The repository has retired two status roots
addressed to nobody — `🔧 Needs a decision` and `📦 Release Preparation` — with the rule
recorded in `CLAUDE.md`: *a status line addressed to nobody is noise whatever its dedup
key*, and an unchanged answer restated hourly is exactly what the second retirement was
for. The surface that already exists for this is `strategy-digest`: once per `Asia/Tokyo`
day, at the top of the morning `🔎 Moderation` root, and it is a **second gate** on that
root beside the question gate — so a morning tick with zero questions still posts it.

So the plan's shape goes there, and into `/standup`, from the one derivation both already
read. The hourly placement is recorded as the ask's own request and answered with the
retirements rather than silently declined.

## Policies

- `workaholic:design` / `policies/interaction-design-standard.md` — what earns a post, and where a reader looks
- `workaholic:implementation` / `policies/observability.md` — one derivation, two consumers, never a second parser
- `workaholic:implementation` / `policies/objective-documentation.md` — the decision is written where the step is read

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-strategy-digest.sh` — the once-a-day
  gate and the hand-off of the digest to the agent to render; its header carries the
  ruling that created it.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's render spec, in
  the numbered form the developer specified.
- `plugins/workaholic/skills/standup/SKILL.md` — `/standup`'s own render rules (numbered
  strategies, bold titles, the honesty line, the caps, the degraded row).
- `plugins/workaholic/skills/notify/reference/notifications.md` — the `🔎 Moderation` root's
  exact shape; a render change must not drift from it.
- `plugins/workaholic/commands/moderate.md` — the command is the ceiling for what a routine
  emits.

## Implementation Steps

1. **Reproduce first**: run `step-strategy-digest.sh` with a morning tick id on this
   repository and capture what it hands the agent today; run `/standup`'s digest read
   beside it. Show that neither carries a mission or a queued count.
2. **Localize** the render rules: they are prose in `moderate/reference/workflow.md` and
   `standup/SKILL.md`, not code, so this ticket is mostly a specification change plus
   whatever `step-strategy-digest.sh` passes through.
3. Extend both render specs with the mission grain: under each numbered strategy, its
   missions with acceptance done/total and queued count, and the repository's total queued
   on the honesty line. Keep the caps and name every omission, as both surfaces already do.
4. Keep the shapes byte-identical to `notify/reference/notifications.md`'s copies — the
   suite pins them against drift. If the root's shape must change, change it there first.
5. Leave the gates untouched: once per JST day, first tick at or after 09:00, dedup off the
   tick log, `digest_unreadable` named and nothing emitted. No new gate, no new key, no
   second root.
6. Record the hourly-placement decision where a reader will meet it — in the step's header
   and in `moderate/reference/workflow.md` — naming the two retired status roots as the
   reason, so the next ask for an hourly plan post meets an answer rather than a silence.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The morning `🔎 Moderation` root and `/standup` both render the mission grain and the
  total queued, from `digest.sh` alone.
- The step's gates, dedup key and once-a-day cadence are unchanged, and no second root or
  hourly status post is added.
- The rendered shapes still match `notify/reference/notifications.md` byte for byte.
- The reason the digest is daily rather than hourly is written down where the step is read.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the post-shape drift rows)
- `sh scripts/e2e/loop-drill.sh verify-all`
- `step-strategy-digest.sh` run with a morning tick id, output compared against the step-1
  capture

**Gate** — what must pass before approval:

- Both commands pass, and a diff review shows no gate, key or cadence moved.

## Considerations

- **The ask's own request is that this post every tick, and it is answered rather than
  granted.** The sources are `CLAUDE.md` (`/moderate`: the two retired status roots stay
  retired) and `step-strategy-digest.sh`'s header (the ruling that put the standup in the
  morning root rather than in a second routine). If the operator rules for an hourly plan
  post after reading that, it is their call and a new ask — this ticket does not decide it
  for them, and it does not pretend the request was met.
- A morning root already carries the digest, the change lines and the impairment lines. The
  mission grain is the largest block yet; the caps are what keep it readable, so a raised
  cap is a deliberate edit with its own reason, not a convenience.
