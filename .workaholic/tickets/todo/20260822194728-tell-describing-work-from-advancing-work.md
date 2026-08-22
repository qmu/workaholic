---
created_at: 2026-08-22T19:47:28+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: refuse-the-move-that-describes-the-aim-instead-of-advancing-it
merge_policy:
verification_handoff: 
---

# Tell describing work from advancing work

## Overview

The sibling ticket stops a describing proposal being made. This one stops describing work already
in flight from **blocking** the proposal that would have built something.

`attributed-work.sh` attributes work to a strategy through `strategy.feedback[] ∩
artifact.feedback[]`. A page about the work cites the same ref the work would, so the two are
indistinguishable by construction. `survey-strategies.sh` then reads `waiting_count > 0` as
`work_waiting` and proposes nothing further for that strategy until the queue drains.

That is what made the measured loop self-sustaining: each documentation mission queued
documentation tickets, which kept `work_waiting` true, which prevented any proposal that might
have been the build; when they merged, the gate lifted and the next documentation move was named.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — the one attribution reader;
  its header states the no-new-field rule and why the `strategy:` relation stays retired.
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — `waiting_count` and the
  `work_waiting` gate (~line 187).
- `plugins/workaholic/skills/propose/SKILL.md` — the gate's stated purpose: one proposal per
  strategy in flight at a time, with no cursor and no stored state.
- `plugins/workaholic/skills/specificate/SKILL.md` — where a proposal's move could be carried onto
  what it emits, if that is the shape chosen.

## Implementation Steps

1. Resolve the `## Open Decisions` item below before writing code; record the ruling and its
   reasoning in the Final Report.
2. **Reproduce.** Build a fixture with a build-aim strategy and only documentation tickets
   attributed to it, and confirm `work_waiting` holds and no proposal is made.
3. Implement the ruled mechanism, and keep `attributed-work.sh` the **one** reader of attribution
   — whatever distinguishes the two kinds must not become a second attribution path.
4. Make `work_waiting` read the distinction: descriptive work in flight must not gate a strategy
   whose Aim is to build.
5. Preserve the gate's purpose for the case it was written for — a build proposal genuinely in
   flight still gates its strategy, with no cursor and no stored state.
6. Report the distinction in the survey's output so a strategy suppressed, or not suppressed, says
   which kind of work it saw.
7. Update `CLAUDE.md` and both skills in the same commit.

## Open Decisions

- **What makes describing work distinguishable from advancing work.**

  Sources read: `attributed-work.sh`'s header (attribution adds no field, walks the citation that
  already exists, and is explicitly *transitive and lossy* — every consumer reports what it could
  not attribute); `workaholic:strategy` (the `strategy:` relation and its ownership hop are
  retired and must stay retired); `workaholic:propose` (the gate exists to give *one proposal per
  strategy in flight at a time* with **no cursor and no stored state**); `CLAUDE.md`'s
  no-new-field ruling of 2026-08-17. Together these establish the constraints — no new relation,
  no stored state, one reader — but they do not choose among the shapes that satisfy them.

  - **(a) Carry the proposal's `move` onto what `/specificate` emits.** The proposal already
    declares `depth`/`breadth`/`contraction` and, after the sibling ticket, whether it builds or
    describes; `/specificate` already carries the strategy's refs forward, so it could carry this
    too. Cost: a field on the mission — exactly what the 2026-08-17 no-new-field ruling refused,
    though that ruling was about *attribution* rather than about kind.
  - **(b) Derive it from the ticket's own paths.** A ticket whose Key Files are all documentation
    paths is descriptive. No field, no new relation. Cost: a heuristic, and a repository whose
    product *is* documentation inverts it — the same case the sibling ticket exempts by Aim.
  - **(c) Do not distinguish; drop `work_waiting` for a build-aim strategy entirely.** Simplest,
    no new data at all. Cost: that strategy loses its in-flight brake and can accumulate parallel
    proposals, which is the failure `work_waiting` was added to prevent.

  The driving session rules explicitly and records why. It may not pick silently, and if it rules
  (b) it must state the inversion case and how the Aim exemption covers it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A build-aim strategy with only descriptive work attributed is not gated `work_waiting`.
- A build-aim strategy with a build proposal in flight is still gated.
- `attributed-work.sh` remains the one attribution reader, and no retired relation returns.
- The survey names which kind of work it saw; the Open Decision is resolved in the Final Report.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-propose`
- Fixtures for the first three criteria, asserting the gate and the reported kind.

**Gate** — what must pass before approval:

- All four criteria hold and the suite plus the propose drill are clean.

## Considerations

- Drive this last. With the describing move refused at the source, the gating case becomes rare,
  and the mechanism should be chosen against the residue rather than against today's backlog.
- Whatever is ruled, resist reintroducing the `strategy:` relation. It was retired deliberately and
  the attribution reader exists to make it unnecessary.
