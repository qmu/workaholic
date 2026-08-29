---
created_at: 2026-08-29T11:10:00+00:00
status:
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
claim: work-20260829-113435
---

# Carry the minting unit's relation onto a minted ticket

## Overview

MEASURED by `/implement` on 2026-08-29, one hour after the sibling defect it completes.

`/implement` §3 mints a ticket when it hits a mid-run problem. That ticket is written with
**no `feedback:` refs and no `mission:` slug** — so the unit that later drives it resolves
`{"count": 0, "stems": []}` through `drive/scripts/unit-feedback-stems.sh` and its finish line
has **no thread to land in and no record to compose a description root from**. The run's only
correct outcome is to report the line unposted, and the merge is announced to nobody.

Measured this run, end to end:

- Unit `batch-20260829093639` (PR #714) hit a resolver gap and minted
  `20260829102500-resolve-a-units-stems-through-an-archived-mission.md`.
- That ticket became unit `batch-20260829102127` (PR #716), merged.
- `unit-feedback-stems.sh` answered `count: 0` for it. Both notify searches were therefore
  unavailable — case 2 has no stem to search, and case 4's root shape
  (`📝 FB - [<title>](…/feedbacks/<stem>.md)`) has no record to link. The finish line for a
  merged unit went unposted.

**This is the other half of the gap PR #716 closed, not a repeat of it.** #716 taught the
resolver the `mission:` hop, so a ticket that *names* a mission now reaches that mission's
refs. A minted ticket names nothing at all, so no hop can help it: the refs must be written at
minting time or they do not exist.

**The minting unit always knows the answer.** It is driving a unit whose own artifacts
resolve to stems by construction — that is what makes its own finish line postable — so the
relation to carry is already in hand at the moment the ticket is written.

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — §3, the mid-run mint; the contract that must
  say what the minted ticket carries
- `plugins/workaholic/skills/create-ticket/reference/ticket-format.md` — the ticket floor the
  carried field must satisfy
- `plugins/workaholic/skills/drive/scripts/unit-feedback-stems.sh` — the reader that measures
  the outcome; **it is not expected to change**
- `plugins/workaholic/hooks/validate-ticket.sh` — the write floor on `todo/`

## Steps

1. Reproduce without driving anything: take a ticket carrying neither `feedback:` nor
   `mission:` and run `unit-feedback-stems.sh` over it. `count: 0` is the whole defect and it
   is one command to see.
2. Decide **which** relation the mint carries, and argue it in the commit body. The two
   candidates are not equivalent:
   - `mission:` — cheapest, and the hop PR #716 already built resolves it. It is wrong when
     the minting unit is a **batch** with no mission, which is exactly the measured case.
   - `feedback:` — the refs the minting unit itself resolved. Correct for both unit kinds, and
     it is the field `/specificate` already writes for the same purpose.
   Carrying **both when both are in hand** is admissible; carrying neither is the status quo.
3. Write the carried refs through the **existing single writer** of that field. Do not add a
   second emitter, and do not hand-format a frontmatter line: `feedback:` is emitted by
   `feedback/scripts/ask-feedback-line.sh` and read by
   `specificate/scripts/read-feedback-relation.sh`.
4. State the rule in `drive/SKILL.md` §3 in one sentence, so a mint that drops the relation is
   visibly non-conformant rather than merely quiet.
5. Assert it: a minted ticket, driven as its own unit, resolves a non-empty stem set. The
   assertion belongs beside the `unit-feedback-stems.sh` slice, which already has the fixtures.

## Considerations

- **A minted ticket is not always about the same item as its minting unit.** The measured one
  was; a mint that is genuinely unrelated would carry a ref that sends its finish line into
  somebody else's thread — a wrong thread is worse than none (`workaholic:notify`, *Fuzzy
  matching is prohibited*). If the run cannot say the mint is about the item, it should carry
  nothing and the line should stay unposted. Say which side the change takes.
- **Do not make an empty stem set an error.** It is a designed answer for artifacts written by
  hand and for a checkout that has never held the record; the caller keys such a unit on
  `unit:<unit-id>`.
- The alternative repair — teaching case 4 a record-less root shape — is worse and should be
  named as rejected: the routine prompt is the ceiling on what shapes may be posted, and a
  root that links nothing is the "status emoji, PR number, bare machine key" post the
  developer ruled unusable on 2026-08-22.

## Policies

- Design: one writer per relation; compose the existing readers rather than parsing a field
  twice.
- Operation: an event the loop produced on its own must be announceable; silence is correct
  only when attribution is genuinely absent, never when it was in hand and dropped.

## Quality Gate

- A ticket minted by a driving unit carries the relation the change chose, written through
  that relation's existing single writer.
- Driving that ticket as its own unit resolves a **non-empty** stem set, asserted in
  `scripts/test-workflow-scripts.mjs`.
- `unit-feedback-stems.sh` still answers `count: 0` — exit 0, not an error — for an artifact
  that genuinely names nothing.
- `drive/SKILL.md` §3 states the rule.

## Final Report

Development completed as planned. Both of the ticket's open judgments are decided and argued
below rather than left implicit.

**Step 1 — reproduced before anything changed.** `unit-feedback-stems.sh` over this very ticket
(which carries neither `feedback:` nor `mission:`) answers `{"count": 0, "stems": []}`. One
command, and it is the whole defect. A second live instance was produced by this same run an hour
later: the unit driving `20260829110500-make-the-channel-default-assertions-hermetic` — itself a
ticket minted with no relation — merged as PR #718 with `count: 0`, so its finish line had no
thread to land in and no record to compose a root from, and went unposted.

**Step 2 — the carried relation is `feedback:`, and the argument is the batch case.** The
`mission:` hop PR #716 built already rescues a mint made while driving a *mission* unit; a
**batch** with no mission has no hop to make, and that is exactly what was measured, twice. So
`mission:` alone is insufficient by construction, while `feedback:` is correct for both unit kinds
and is the field `/specificate` already writes for this purpose. The existing `mission:`
inheritance is untouched, so a mint that has both carries both. The refs cost no new lookup: the
minting unit resolved its own stems in order to post its own finish line, so the relation is in
hand at the moment the ticket is written.

**The Consideration's fork is answered explicitly: carry only when the run can say the mint is
about the same item.** A mint that is genuinely unrelated carries nothing and its finish line
stays unposted — a ref carried on a guess routes that line into somebody else's thread, and a
wrong thread is worse than none (`workaholic:notify`, *Fuzzy matching is prohibited by name*).
The test pins that this side was taken: an unattributable mint still answers `count: 0` as an
answer rather than an error.

**The rejected alternative is named, as the ticket asked.** Teaching case 4 a record-less root
shape is worse and was not done: the routine prompt is the ceiling on what shapes may be posted,
and a root that links nothing is the "status emoji, pull-request number, bare machine key" post
the developer ruled unusable on 2026-08-22.

**Step 3 — written through the existing single writer.** `feedback/scripts/ask-feedback-line.sh`
emits the line; no second emitter was added and no frontmatter line is hand-formatted. The test
asserts the emitted line's exact text, so a future hand-rolled `printf` diverging from the writer
fails rather than drifting.

**Steps 4 and 5.** The rule is stated where the mint is governed — the mint bullet in
`drive/SKILL.md`'s failure contract and the *An unqueued problem becomes a ticket* section of
`drive/reference/failure-contract.md` — with the measurement, the `feedback:`-over-`mission:`
argument and the attribution bound. Four assertions were added beside the
`unit-feedback-stems.sh` slice, which already had the fixtures.

**Quality Gate**

- A minted ticket carries the chosen relation, emitted by that relation's one writer — asserted
  on the writer's exact output.
- Driven as its own unit it resolves a **non-empty** stem set (`count: 2`) — asserted, from a
  **missionless** fixture, so the assertion cannot pass through the `mission:` hop instead.
- `unit-feedback-stems.sh` still answers `count: 0`, exit 0, for an artifact that genuinely names
  nothing — asserted for the unattributable-mint shape as well as the pre-existing ones. The
  script is unchanged.
- `drive/SKILL.md` states the rule; the test also pins that the contract text names the field and
  its writer, so deleting the prose fails the suite.
- `node scripts/test-workflow-scripts.mjs`: **5040 passed, 0 failed** (was 5036); `build.mjs`
  regenerated `outputs/`, `verify.mjs` reports all built skills self-contained.

### Discovered Insights

- **Insight**: This is a prose contract with no script seam, so the enforcement had to be built
  out of what *is* checkable.
  **Context**: The mint is performed by the agent, not by a `mint-ticket.sh`, so nothing can
  mechanically force the carry. What the change buys instead is three checkable things: the rule
  is written where the mint is governed, the test pins that the contract text still names the
  field and its writer, and the resolver behaviour a correct mint depends on is asserted from a
  missionless fixture. A mint that drops the relation is then visibly non-conformant rather than
  merely quiet — the same standard the `## Open Decisions` read requirement settled for.

- **Insight**: The fixture had to be missionless or it would have proved nothing.
  **Context**: The slice already asserts that a ticket resolves through its mission, so a minted
  fixture carrying a `mission:` would have passed via the hop built in PR #716 and the new
  assertion would have been vacuous on exactly the case this ticket exists for.
