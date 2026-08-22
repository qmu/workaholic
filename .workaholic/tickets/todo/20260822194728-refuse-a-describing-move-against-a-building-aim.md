---
created_at: 2026-08-22T19:47:28+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: refuse-the-move-that-describes-the-aim-instead-of-advancing-it
merge_policy:
verification_handoff: 
---

# Refuse a describing move against a building aim

## Overview

`workaholic:propose` refuses housekeeping by name and explains why it can: *"tidy this up", "the
docs drifted", "add a test", "rename for consistency"* are chosen against **nothing** — nobody
argues for the mess — so the body floor's `## What this is chosen against` section catches them.

A new page about the Aim passes that floor. It is chosen against something real (the Aim is
undocumented here), it commits in the imperative, and it is a textbook `depth` move: *go further
into what the aim already covers than the landed work has gone.* A document about what the aim
covers is further than no document.

So a strategy whose Aim is to **build** something can be answered, forever, with pages about
building it — measured over weeks on a consuming repository, where every mission attributed to a
build strategy produced documentation and the deployment worker still has no code of its own.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — *The one thing it is for: an evolutionary move,
  never housekeeping*, the three-move table, and the body floor. The new refusal is a sibling of
  the housekeeping one and belongs beside it.
- `plugins/workaholic/skills/propose/scripts/open-proposal.sh` — takes `--move`; where a refusal
  becomes machine-readable.
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — emits each gate by name; the
  precedent for how a refusal is reported.
- `plugins/workaholic/skills/propose/reference/loop.md` — how a proposal reaches `/specificate`.
- `plugins/workaholic/skills/strategy/SKILL.md` — the Aim's definition, which is what "building"
  is read from.

## Implementation Steps

1. **Reproduce.** Take the measured strategy's Aim and one of the documentation proposals made
   against it, and confirm from the SKILL that the proposal satisfies `depth` and the body floor
   as written. The point of this step is to establish that the loop was obeyed, not broken.
2. **Localize.** Confirm the move's definition and the body floor are the only two places a
   proposal is judged, and that neither reads what kind of artifact the move would produce.
3. Define the refusal: a proposal whose move would produce **documentation about the Aim**, on a
   strategy whose Aim names something to be built, is refused by name — the same standing the
   housekeeping refusal has.
4. Make the exemption explicit and mechanical: **a strategy whose Aim is itself documentation is
   unaffected.** This is what keeps the rule checkable rather than a matter of taste, and it must
   be stated as the test, not as a footnote.
5. Report the refusal by name from the run, like every other gate, so a tick that proposes nothing
   for this reason says so rather than reading as idle.
6. State it in `CLAUDE.md`'s `/propose` row and in the `[Propose]` template's own prose if the
   template describes the refusals.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A documentation proposal against a build-aim strategy is refused, by name, and nothing is opened.
- A documentation proposal against a documentation-aim strategy is unaffected.
- A build proposal against a build-aim strategy is unaffected.
- The refusal appears in the run report; a tick refusing for this reason never reads as idle.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-propose`
- Fixtures for all three cases above, asserting the refusal name and the opened/not-opened state.

**Gate** — what must pass before approval:

- All four criteria hold and the suite plus the propose drill are clean.

## Considerations

- Documentation is not being banned. A build strategy legitimately needs some — what is refused is
  documentation as *the move*, chosen instead of the build. Say that in the SKILL so a later reader
  does not over-apply it.
- The judgement is the run's and is stated in the proposal body, where it can be argued with. Do
  not try to detect "is this a document" from a file extension; the proposal declares what it will
  produce.
