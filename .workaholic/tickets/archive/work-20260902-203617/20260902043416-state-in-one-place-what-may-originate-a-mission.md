---
created_at: 2026-09-02T04:34:16+00:00
status: done
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

## Final Report

Development completed as planned, and sequenced last as the ticket asked, so the statement
describes the refusals the earlier tickets actually built rather than the ones this set
imagined.

**The home is `plugins/workaholic/rules/workaholic.md`** (step 1), and the reason is recorded
in the statement itself: the rule governs three skills and belongs to none of them; it **ships
in the plugin**, so it reaches every repository that installs it, where a repository's own
`CLAUDE.md` cannot carry a rule for the fleet; and the queue it governs lives under
`.workaholic/`, which is that file's own path scope.

**It is written as a closed statement** (step 2) — what may originate (a human's ask, whatever
channel it arrived through; a strategy a human authored), what may not (`self_authored`,
`self_refining`, `only_the_loop_spoke`), and the measurement that earned it: five `[FB]` roots
in one day that no human wrote, each merged by the next ticks, the direction abandoned
mid-drive, every gate holding and none of them asking *who wanted this*.

**Every other surface cites it** (step 3): `workaholic:specificate`'s judgment bar,
`workaholic:propose`, and `workaholic:feedback`'s filing bar each point at the home and say
they are citing rather than restating. The feedback bar also names the distinction that keeps
the two rules apart — **filing is wider than origination**, a machine's observation is still
worth recording, and `subject:` is what tells them apart.

**`CLAUDE.md`'s ticket-spine *Sources* now names whose input each source carries** (step 5):
`/ticket` and `/mission` a human's direction, `/specificate` a human's ask or a human-authored
strategy and never a record the loop wrote about itself.

**Pinned, and the pin was proved to fail** (step 4, and the gate): thirteen rows assert the
statement exists at its home with its measurement and its three refusal words, that each of
the three skills cites it, and that `CLAUDE.md`'s *Sources* is attributed. Rewriting one
citation to *anything the loop finds worth doing may originate a mission* turned two rows red;
restoring it turned them green.

### Discovered Insights

- **Insight**: The choice of home is not a filing preference — it decides **who the rule
  reaches**. `CLAUDE.md` is one repository's document, so a rule written there governs this
  repository and no consumer of the plugin; `rules/workaholic.md` ships. For a rule whose
  whole failure mode was *the next session re-derived it*, reaching every session that
  installs the plugin is the property that matters.
  **Context**: The same test applies to any future cross-skill convention: if a consuming
  repository would need it and cannot get it, `CLAUDE.md` is the wrong home.
