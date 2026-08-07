---
created_at: 2026-08-07T08:42:46+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [.workaholic/feedbacks/20260807084216-define-explicit-notify-templates-for-propose-and-implement-routine-prompts.md]
merge_policy:
claim: work-20260807-102749
---

# Encode the notify templates for /propose and /implement in workaholic:notify

## Overview

<!-- PROPOSED. What this ticket would implement and why, from the feedback and
     repository state the proposal grew from. Merging the pull request this was
     published on is what turns it from a proposal into queued work. -->

Follow-up to qmu/workaholic#298/#299 (agents must not self-authorize a
notification format beyond what the routine prompt specifies). Issue #300
supplies the explicit start/finish templates the `[Propose]` and `[Implement]`
routine prompts should carry, so a running session has a specified format to
follow rather than inferring one from `workaholic:notify`'s existing shapes.
This ticket updates the `workaholic:notify` skill (`SKILL.md` and
`reference/notifications.md`) to encode issue #300's exact templates as the
sole sanctioned formats for these two routines' start/finish posts, and
reconciles them with the shapes already documented there (the existing 🟢
Proposed/🟠 drive started/🟡 Handoff/🚀🟣 merge/🔴 blocked set) so the skill
states one consistent, unambiguous contract rather than two overlapping ones.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

<!-- The files this ticket would touch, each with why it is relevant. -->

- `plugins/workaholic/skills/notify/SKILL.md` — states the standing rules (*One
  thread per feedback item*, *Post shapes, mentions, and the red-alert dedup*);
  the section a template's "the `workaholic:notify` lookup" phrase points at.
- `plugins/workaholic/skills/notify/reference/notifications.md` — carries the
  exact post shapes today (🟢 Proposed / 🔴 blocked / 🟠 started / 🟡 Handoff /
  🚀🟣 merge); needs the `/propose` "design started" and "proposed" shapes and
  the `/implement` "implementation started" and "implemented" shapes from
  issue #300, reconciled with what already exists.
- `plugins/workaholic/skills/workaholify/routines/` (`fb` = `[Propose]`,
  `implement` = `[Implement]`) — the routine prompt templates that must defer
  to the reconciled shapes rather than embed their own wording.

## Implementation Steps

<!-- The ordered steps. A proposal is judged on these, so they are the point. -->

1. Read issue qmu/workaholic#300 in full and extract its four literal
   templates (`[Propose]` started/finished, `[Implement]` started/finished).
2. Reconcile them with `reference/notifications.md`'s existing shapes: decide,
   and record the decision, whether issue #300's wording *replaces* the
   corresponding existing shape (e.g. the 🟢 Proposed root) or is additive —
   the skill must end up stating exactly one sanctioned format per event, not
   two that could each look authoritative.
3. Update `reference/notifications.md`'s shape block and `SKILL.md`'s
   standing-rules prose to match the reconciled set.
4. Update the `[Propose]`/`[Implement]` routine templates under
   `skills/workaholify/routines/` so their "notify the thread" instructions
   point at the reconciled shapes rather than restating wording that could
   drift from the skill (per the existing "a template is a thin pointer, not
   a procedure" convention).
5. Run `node scripts/build-plugins/build.mjs` and
   `node scripts/build-plugins/verify.mjs` since `workaholic:notify` and the
   routine templates are read by the generated bundle.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `workaholic:notify`'s `reference/notifications.md` and `SKILL.md` state
  issue #300's four templates as the sole sanctioned `/propose`/`/implement`
  start/finish formats, with no ambiguity against the pre-existing shapes.
- The `[Propose]` and `[Implement]` routine templates reference the
  reconciled shapes rather than embedding their own copy of the wording.

**Verification method** — the commands/tests/probes that prove them:

- Manual read-through of the updated `notify` skill and routine templates
  against issue #300's literal blocks.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- <proposed>

## Considerations

<!-- Risks and open questions the proposal already sees. -->

- Issue #300's proposed wording ("📐 Designing for…", "✅ Proposed…") differs
  from `reference/notifications.md`'s current 🟢/🟠/🟡/🚀/🟣/🔴 shapes; this
  ticket's implementer must decide the reconciliation rather than mechanically
  appending a second, conflicting set of formats.
- Issue #298 exists precisely because a session added a notification shape
  beyond what its routine prompt specified — this change should leave no
  ambiguity for a future session to fill in on its own judgment.
