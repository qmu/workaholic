---
created_at: 2026-08-22T15:52:50+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: tell-an-unanswered-question-from-an-answered-one
merge_policy:
verification_handoff: 
---

# Surface the outstanding questions and their age

## Overview

With the sibling ticket landed, the tick can tell a question whose subject is still live from
one that is settled. This ticket spends that answer: an outstanding blocker must reach a person
before a day passes.

The measured case is the bound to design against — a question saying the loop could not start,
unanswered for twenty hours and twenty ticks, with every tick reporting itself healthy and no
surface anywhere carrying its age.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — renders the `🔎 Moderation`
  root and decides whether the tick posts at all; an outstanding line lands here.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the `already_asked` gate, if the
  chosen shape re-asks.
- `plugins/workaholic/skills/moderate/SKILL.md` — the two posting gates and the "an idle hour is
  silent" rule, which the chosen shape must not quietly break.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the root's shape, and the
  routine template copy pinned byte-identical to it.
- `plugins/workaholic/skills/workaholify/routines/moderate.md` — the template copy.

## Implementation Steps

1. Resolve the `## Open Decisions` item below before writing code; record the ruling and its
   reasoning in the Final Report.
2. **Reproduce.** Leave a question unanswered across two ticks and record what the channel shows
   today: nothing at all after the first post.
3. Implement the ruled shape, and only that one.
4. Hold the existing gates: an hour with nothing changed and nothing to ask stays silent. An
   outstanding-questions line must not by itself make an otherwise idle tick post — decide and
   state whether it rides an already-posting tick only, or whether a threshold age earns its own
   post, and say which in the SKILL.
5. Keep the root's shape consistent with `notify/reference/notifications.md`, and mirror any
   wording change into `workaholify/routines/moderate.md` in the same commit — the suite pins the
   two byte-identical.
6. Update `CLAUDE.md`, the moderate `SKILL.md` and `reference/workflow.md` in the same commit.

## Open Decisions

- **Which shape surfaces an outstanding question.** The ask states both and explicitly declines
  to recommend one, so this is the reporter's fork, not a gap in the report.

  Sources read: `moderate/SKILL.md` (*two gates, and an idle hour is silent*; the retirement of
  `📦 Release Preparation` for restating an unchanged answer ten hours running), the feedback
  record this ticket answers, and ticket `20260819061902`'s record of the opposite defect. They
  establish the constraint — a status line addressed to nobody is noise at any frequency — but
  they do not decide between these two, because both respect it in different ways.

  - **(a) Re-ask on persistence, bounded** — a question whose subject is still `live` is re-asked
    on a widening interval (an hour, then a day, then never). Restores a bounded amount of the
    noise ticket `20260819061902` removed, deliberately. It is addressed to a person, which is
    the property the retired status roots lacked.
  - **(b) Never re-ask; report the outstanding set** — the tick's root carries a standing
    `N questions outstanding, oldest <age>` line. Repeats nothing and adds no post, but it is a
    line addressed to nobody, which is the shape this repository has retired twice.

  The driving session resolves it explicitly and records the resolution; it may not pick a side
  silently, and it may not invent a third shape without saying so.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A question outstanding for more than a day has reached a surface a person reads, with its age.
- An hour with nothing changed and nothing to ask is still silent.
- The root's wording matches `notify/reference/notifications.md` and the routine template
  byte-for-byte.
- The Open Decision above is resolved in the Final Report with its reasoning.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the byte-identical pin)
- `sh scripts/e2e/loop-drill.sh verify-moderate`
- A multi-tick hermetic run over a question left unanswered, asserting what is posted and when.

**Gate** — what must pass before approval:

- All four criteria hold and the suite plus the moderate drill are clean.

## Considerations

- Drive this after its sibling; without the liveness read there is nothing to surface.
- Whichever shape is chosen, the failure to avoid is a third silent state — a question that is
  neither re-asked nor counted because its subject resolved to `unknown`.

## Final Report

Development completed as planned. A still-`live` question first asked on an earlier day is
re-asked **once**, at the next working day, and never again.

### The Open Decision, ruled: (a) re-ask on persistence, bounded

The ask named both shapes and declined to recommend one, so this is a real fork and the ruling is
recorded rather than assumed.

**(b) — a standing `N questions outstanding, oldest <age>` line on the root — is refused.** The one
property both retired status roots lacked is being **addressed to a person**. A count addressed to
nobody reproduces exactly that lack, and putting an age on it does not change who it reaches; it is
the shape this repository has retired twice, most recently for restating an unchanged answer ten
hours running. The measured harm here was twenty hours and twenty ticks with **nothing** carrying
the question — and only a mentioned reply reaches anybody.

**(a) is taken with the smallest interval that answers the measurement**: one re-ask, at the next
working day, then never. Ticket `20260819061902` removed *unbounded* re-asking — the same key every
hour with the question still open — and that removal stands: this is at most **one** extra ask,
ever, logged under its own step id `human-checkin-reasked-<slug>`, so a third is impossible by
construction rather than by a counter somebody must maintain. The boundary is the working day the
quiet-hours gate already owns, so no constant is invented — the same composition that fixed the
alert cool-down the same day.

### What the drive corrected in itself

Two defects were caught by exercising it rather than by reading it:

- **The day was read from the wall clock**, so a tick dated yesterday re-asked itself on its own
  first run. It now comes from the **tick id**, putting both sides on one axis and making a
  re-entered tick answer the same way twice.
- **The re-ask was decided before the hold gates.** `already_asked` returns before the off-day and
  quiet-hours checks, so the re-ask would have posted at 03:00 on a Sunday — the exact failure
  `WORKAHOLIC_WORK_DAYS` exists to prevent. It is now gated on both, and held is not dropped: the
  re-ask is logged only when actually asked, so it waits for the next eligible tick and stays
  bounded to one.

### What did not change

**Only a `live` subject is re-asked.** `settled` needs nobody, and `unknown` is a reading that could
not be made — spending a person's attention on our own degradation is the rule `strategy-pace`
already applies to its own `unknown`.

**No posting rule and no post shape moved.** A re-ask is a question, so it rides the existing "post
when there is at least one question" gate: an hour with nothing changed and nothing to ask is still
silent, by construction rather than by a new exception. It goes out as the same `🙋 <@U…>` reply
with its age in the question's own sentence (`first_asked` rides the gate's answer), so the root's
wording is untouched and the copies in `notify/reference/notifications.md` and
`workaholify/routines/moderate.md` stay byte-identical — the suite's pin passes unchanged.

**Verification**: `node scripts/test-workflow-scripts.mjs` — 3388 passed, 0 failed, including a
multi-tick fixture asserting no re-ask the same day, the quiet-hours and off-day holds, exactly one
re-ask on the next working day naming when it was first asked, silence after that, and that a
settled subject is never re-asked.
