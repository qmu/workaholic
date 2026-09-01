---
created_at: 2026-09-01T12:33:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: adjust-the-plan-hourly-not-only-report-it
merge_policy:
verification_handoff: 
---

# Say where planning lives and what authority it has

## Overview

PROPOSED. The ask's framing — three clerks and no planner — is accurate about the documents:
nothing names planning as a job, so no reader can tell whether "nothing re-plans" is a defect
or the design. After the tickets before this, planning exists in pieces: a limit that holds
divergence, an order the executor is offered, a question that escalates a date, a delta on the
post. This writes down that it is one job, where each piece lives, what it may decide on its
own, and what it may only ask about — so the next ask against it argues with a stated rule.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — origination and the limit that holds it.
- `plugins/workaholic/skills/drive/SKILL.md` — the Unified Run and the offer order.
- `plugins/workaholic/skills/moderate/SKILL.md` — the escalation and the delta on the post.
- `plugins/workaholic/skills/drive/reference/claims.md` — the proof/judgement rule this cites rather than restates.
- `CLAUDE.md` — in the same change.

## Implementation Steps

1. Write one section naming **planning as a job** and where each of its acts lives — the
   work-in-progress limit in `/propose`, the offer order in `plan-units.sh`, the arithmetic in
   the strategy readers, the escalation and the delta in `/moderate`. It is deliberately not a
   new command or a new routine: the acts belong to the ticks that already run.
2. State the authority in the repository's existing terms and **cite** rather than duplicate:
   an act on a **proof** re-derived at the moment of the act, idempotent, refusing every bound
   by its own word; a **judgement** may only be reported or asked about.
3. Say plainly what planning may **not** do, each with the rule that forbids it: it may not
   re-date a direction (`amend.sh` carries only an announced revision), may not merge two
   missions (no writer, and it asserts intent), may not retire a ticket it judges mooted (a
   reading about behaviour, not a file test), and may not close a mission that is not
   arithmetic (`close.sh` is the only writer of an end state).
4. Answer the ask's framing directly: whether "nothing re-plans" was defect or design. Name
   what is now the loop's and what remains the operator's, so the next reader is not left to
   infer it from four scattered mechanisms.
5. Record the ask's fourth item as **already largely answered and by what**: the tick log moved
   to its own orphan branch, and every pull request the loop merges is squash-merged — both
   shipped for exactly the reason the ask gives, that a commit is a change to the development
   target. Say what remains, if anything, rather than re-proposing it.
6. Update `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One section names planning as a job and where each act lives.
- Each thing planning may not do is stated with the rule that forbids it.
- The proof/judgement rule is cited, not duplicated.
- The ask's fourth item is answered with what already shipped.
- `CLAUDE.md` matches.

**Verification method** — the commands/tests/probes that prove them:

- A read of the section against each shipped mechanism from tickets 1–6, one by one.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **Drive this last.** It describes what tickets 1–6 built; written earlier it describes an
  intention, and an intention in `CLAUDE.md` is worse than a gap because it reads as behaviour.
- Two copies of the proof/judgement rule would drift, which is why this cites `claims.md`. The
  same discipline the moderation-boundary ticket in the sibling mission applies — coordinate
  the two so the repository ends with one statement of the rule, not three.
- The honest summary may be that the loop plans **less** than the ask wants, with the gaps
  named. That is a better artifact than a section implying an autonomy that does not exist,
  and it is what makes the next ask against it arguable.
