---
created_at: 2026-08-22T17:51:31+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: make-the-tick-s-root-earn-its-hour
merge_policy:
verification_handoff: 
---

# Make a question-less root earn its post

## Overview

The root's two posting gates are OR: at least one question, **or** at least one changed step.
The measured post carried `0 question(s)`.

The skill states the root's reason to exist plainly — it carries the tick's questions beneath
it, and that is what distinguishes it from the two keyed status roots retired on the ground
that *a status line addressed to nobody is noise whatever its dedup key*. With no question
under it, the root is that status line again.

The sibling ticket makes changes rare and real. This ticket decides whether a real change, on
its own, is enough to speak.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — the `post: true/false`
  decision and its `idle` / `no_previous_tick` / `no_log` reasons.
- `plugins/workaholic/skills/moderate/SKILL.md` — *two gates, and an idle hour is silent*, and
  the retirement record for the two status roots.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the root's shape and the
  retirement of `📦 Release Preparation`.
- `plugins/workaholic/skills/workaholify/routines/moderate.md` — the template copy, pinned
  byte-identical.

## Implementation Steps

1. Resolve the Open Decision below before writing code; record the ruling and its reasoning in
   the Final Report.
2. **Reproduce.** Run a tick with a real change and no question, and record that it posts today.
3. Implement the ruled condition in `render-tick-post.sh`, adding a named reason for a tick that
   is suppressed by it — never a silent `post: false`.
4. Leave `no_previous_tick` and `no_log` exactly as they are: a degraded read must stay
   distinguishable from a quiet hour.
5. State the resulting rule in `SKILL.md` and mirror any wording change into the routine
   template in the same commit.
6. Update `CLAUDE.md` in the same commit.

## Open Decisions

- **Whether a changed step, with no question attached, earns a post.**

  Sources read: `moderate/SKILL.md` (*two gates, and an idle hour is silent*; the retirement of
  `🔧 Needs a decision` and `📦 Release Preparation`, with the measured ten-posts-in-ten-hours
  finding and the ruling that a status line addressed to nobody is noise whatever its dedup
  key); `render-tick-post.sh`'s header (the root exists to carry the questions beneath it, told
  apart from them by position in the thread); `notify/reference/notifications.md` (the root's
  shape). These establish that *unchanging* status is noise. They do not settle whether a
  *genuine, rare* change addressed to nobody is noise too, and the ask does not either — it
  demands only that the class be named rather than being "a differing summary string".

  - **(a) A question is the precondition.** No question, no root. Simplest, and it makes the
    root's stated purpose its actual condition. Cost: a real change nobody is being asked about
    is visible only in the tick log.
  - **(b) A named class of change earns a question-less root.** The class must be enumerated in
    the SKILL — e.g. a merge conflict appearing, a pull request failing to auto-merge, a
    deployment target starting to need a human — and anything outside it stays log-only. Cost:
    a list to maintain, and a judgement each time a step is added.

  The driving session rules explicitly and records why; it may not pick a side silently, and if
  it rules (b) it must write the class out rather than leaving it to be inferred.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick with no question and no qualifying change posts nothing, with a named reason.
- `no_previous_tick` and `no_log` remain distinct from a quiet hour.
- The resulting rule is stated in `SKILL.md` and the routine template matches byte-for-byte.
- The Open Decision is resolved in the Final Report with its reasoning.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-moderate`
- Hermetic ticks covering: question only, change only, both, neither, unreadable log.

**Gate** — what must pass before approval:

- All four criteria hold and the suite plus the moderate drill are clean.

## Considerations

- Drive this after its sibling. Deciding the gate while every tick reports two phantom changes
  would be deciding it against noise rather than against the real rate.
