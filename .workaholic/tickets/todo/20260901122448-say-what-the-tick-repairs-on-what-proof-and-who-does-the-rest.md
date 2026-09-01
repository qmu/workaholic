---
created_at: 2026-09-01T12:24:48+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-add-to-a-standing-thread-instead-of-restating-itself
merge_policy:
verification_handoff: 
---

# Say what the tick repairs, on what proof, and who does the rest

## Overview

PROPOSED. The ask reads `/moderate` as a pure reporter — "it finds, files, and says what needs
a human" — and asks for that to be either changed or stated plainly with the repairer named. It
is already neither: `retire-claims` acts, `closable-missions` closes, `standing-rulings` drafts
a pull request, `file-findings` files an issue. The rule that governs which is written down in
`drive/reference/claims.md` — **a consumer may act on a proof and may only report or ask about
a judgement** — but it lives beside the claim verdicts, so a reader of `workaholic:moderate`
meets a skill that describes itself as never repairing while several of its steps do. This
states the boundary where the tick is read, and names who repairs the rest.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/SKILL.md` — the self-description that reads as pure reporter.
- `plugins/workaholic/skills/drive/reference/claims.md` — where the proof/judgement rule and its bounded-act exception already live.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — per-step specs, several of which already act.
- `CLAUDE.md` — the `/moderate` section, in the same change.

## Implementation Steps

1. Enumerate what the tick **already** repairs and on what: `retire-claims` acting on
   `superseded`, `closable-missions` closing on arithmetic it re-proves, `standing-rulings`
   drafting one pull request, `file-findings` opening one issue. Read each step's own spec
   rather than summarising from memory.
2. State the boundary in `workaholic:moderate` in one section, in the rule's existing terms:
   the tick acts where a **proof** licenses it — re-derived at the moment of the act,
   idempotent, refusing every bound by its own word — and reports or asks everywhere else.
   Cite `drive/reference/claims.md` rather than restating its table; two copies of that rule
   would drift.
3. Name **who repairs the rest**, per class, from the mechanisms that already exist: a
   `content` conflict and an operator-facing pull request wait on a person and reach them by
   question; a `mechanical` one is settled by `[Implement]`'s catch-up; a finding becomes an
   `[FB]` issue the next `[Specificate]` ingests. If a class has no repairer, say so — that is
   the finding this ticket exists to surface.
4. Correct the self-description so "never merges a pull request, never pushes into a branch
   the claim protocol owns" reads as the bound it is, not as "repairs nothing".
5. Update `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `workaholic:moderate` states what the tick repairs, on what licenses it, and who repairs
  what it does not.
- The proof/judgement rule is cited, not duplicated.
- No document still describes the tick as repairing nothing.
- A class with no repairer is named as such.

**Verification method** — the commands/tests/probes that prove them:

- A read of the section against each acting step's spec, one by one.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **This ticket states a boundary; it does not move one.** The ask offers "decide whether a
  step that can repair a thing may repair it, or say plainly that the tick is a reporter" —
  and the repository has already ruled on the underlying principle (act on a proof, report a
  judgement) and shipped four steps under it. Widening what the tick may repair is a separate
  ask against that rule, with its own measurement; doing it inside a documentation ticket
  would be a machine deciding its own licence.
- The ask's own evidence — five conflicted pull requests unblocked by a person in an afternoon
  after the tick reported them for days — is the strongest argument for a later widening, and
  it should be recorded here so that ask has somewhere to start.
- Watch the human question budget: the boundary statement should name it as the drain it is,
  since the operator's complaint was that they discover the backlog by asking.
