---
created_at: 2026-09-02T04:34:16+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: refuse-an-ask-the-loop-wrote-to-itself
merge_policy:
verification_handoff: 
---

# State in one place what may originate a mission

## Overview

PROPOSED. The operator's instruction contains a sentence the repository does not currently
state anywhere: **only a human's ask, or a strategy a human authored, originates a mission.**

The rule is spread across three skills as consequences — `/specificate`'s judgment bar says
feedback is the only input that can originate, `/propose` says a proposal must commit to a
strategy, `/fb` says what may be filed — and none of them says *whose* input. That gap is
what the five-link chain walked through. A rule that lives only as three consequences is a
rule the next session re-derives, and it re-derived it wrong.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/SKILL.md`, *The judgment bar* — the nearest thing
  to a statement today; the rule's home is either here or in `rules/`.
- `plugins/workaholic/skills/propose/SKILL.md` — the origination routine, which must cite
  the rule rather than restating it in different words.
- `plugins/workaholic/rules/workaholic.md` — where a cross-skill convention lives when it
  belongs to no single skill.
- `plugins/workaholic/skills/feedback/SKILL.md`, *Choosing the subject* — the three axes the
  rule is expressed in.
- `CLAUDE.md` — the ticket spine's *Sources*, which lists what fills the queue and does not
  say whose input each source carries.
- `scripts/test-workflow-scripts.mjs` — where the statement is pinned against drift.

## Implementation Steps

1. Choose the rule's one home and record why. It governs `/specificate`, `/propose` and
   `/fb`, so a single skill is the wrong home; `rules/workaholic.md` and `CLAUDE.md`'s
   *Sources* are the candidates.
2. Write it as a closed statement: what may originate a mission (a human's ask; a strategy
   a human authored), what may not (a record a routine wrote about the loop's own
   apparatus; a proposal refining a prior self-proposal; a tick into a channel where only
   the loop has spoken), and the measurement behind it.
3. Make every other surface **cite** it rather than restate it. Three restatements is how
   the rule drifted into three consequences in the first place.
4. Pin it: assert the statement exists at its home and that the citing surfaces reference it
   — the same drift pin the post formats already carry.
5. Update `CLAUDE.md`'s ticket-spine *Sources* so the queue's inputs are named with whose
   input each one is.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The rule is stated once, at a named home, with its measurement.
- The three consuming skills cite it rather than restating it.
- The statement and its citations are pinned by the suite.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The drift pin fails when one citing surface is edited to say something different.

## Considerations

- Sequenced last: the statement should describe the refusals the earlier tickets actually
  built, not the ones this ticket set imagined. Writing it first would leave prose the code
  does not match, which is the defect this whole mission is about.
