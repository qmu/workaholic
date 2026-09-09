---
created_at: 2026-09-09T13:01:38+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-a-native-tick-from-reconciled-evidence-not-from-a-worker-s-word
merge_policy:
verification_handoff: 
---

# Verify a constraint-tightening migration against legacy rows

## Overview

PROPOSED. A stricter `CHECK` constraint passed local tests against an **empty** database and then
failed the existing-row copy in a production rebuild migration; the deployment failure was
reported as a healthy completion. The operator asks that this finding be carried into Workaholic's
implementation and operation verification guidance: when a change tightens a constraint over
persisted data, the evidence required is the upgrade path exercised against representative legacy
rows, not fresh schema creation.

Domain-specific data conversion belongs to the consuming application. What Workaholic owns is that
the evidence is **requested** at ticket-writing time and that the delivery outcome is **observed**
rather than assumed.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/implementation/policies/persistence.md` — where a persisted-data
  constraint change is governed.
- `plugins/workaholic/skills/implementation/policies/test.md` — what evidence a change must
  produce.
- `plugins/workaholic/skills/operation/policies/ci-cd.md` — the delivery path's own verification.
- `plugins/workaholic/skills/create-ticket/reference/ticket-format.md` — the Quality Gate a ticket
  writes, where the legacy-row requirement must be asked for.
- `plugins/workaholic/skills/ship/SKILL.md` — the deployment plan and confirmation seam, where a
  failed run must stay visible.

## Implementation Steps

1. **Localize before writing guidance.** Read the three policy pages and the ticket format and
   record exactly what each says today about persisted data and about upgrade paths, so the change
   is an addition to a named gap rather than a restatement.
2. Add to the persistence and test policies the one rule the finding establishes: a change that
   **tightens** a constraint over persisted data is verified by exercising the upgrade path against
   representative legacy rows; a fresh-schema pass is not evidence.
3. Make the ticket format ask for it: when a ticket's change tightens a persisted-data constraint,
   its Verification method names the legacy fixture and the upgrade run.
4. Confirm — in `ship`'s own words — that a failed or pending deployment stays a separate visible
   state and can never be rendered as a healthy completion. Do not add a new gate; state the rule
   where the confirmation is already read.
5. Update `CLAUDE.md` and any affected `plugins/workaholic/rules/*.md` in the same change, as the
   documentation rule requires.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The persistence and test policies state the legacy-row requirement for a constraint-tightening
  change over persisted data.
- The ticket format asks for the legacy fixture and the upgrade run in the Verification method.
- A failed or pending deployment stays its own visible state and is never reported as healthy.
- The affected documents are updated in the same change.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — the generated
  bundle carries the revised policy text.
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- This is guidance, not a machine gate. Workaholic cannot inspect a consuming application's
  fixtures, and inventing a cross-repository check would be scope nobody asked for.
- Keep it to the rule the finding establishes. Do not generalize into a wider migration framework.

## Final Report

Development completed, with **one step deliberately not taken and the reason recorded** — read
this section before reading the acceptance criteria as met.

Step 1 (localize before writing) produced the finding that reshaped the rest. Reading the three
named policy pages showed that none of them says anything about upgrade paths or persisted rows —
so the gap the ticket names is real. But reading *around* them showed something the ticket did not
account for: those pages are English **hard copies** whose source of truth is qmu.co.jp
(`implementation/SKILL.md`: *"The published article is the source of truth"*), whose refresh
arrives as an upstream `standards-sync/*` pull request and for which **this repository runs no
fetching step of its own** (`README.md`); their whole git history here is two wholesale sync
commits; and a prior mission (`reorganize-missions-under-strategies`) already put *"editing the
qmu.co.jp policy hard copies under `skills/<pillar>/policies/`"* out of scope **by name**.

So step 2 as literally written could not be done honestly. A local edit to `persistence.md` /
`test.md` / `ci-cd.md` would satisfy acceptance criterion 1 on the day it landed and be silently
reverted by the next upstream sync — a change that reads as done and quietly stops being true,
which is the exact failure shape this whole mission exists to prevent. Writing that here rather
than doing it is the same judgement the mission asks of a tick report.

**What was done instead, all of it inside what the ticket's own Overview says Workaholic owns**
(*"the evidence is requested at ticket-writing time and the delivery outcome is observed rather
than assumed"*):

- The rule has a home this repository owns and every session reads:
  `plugins/workaholic/rules/general.md` (`paths: '**/*'`), stating the requirement, the negative
  half (a fresh-schema pass is not evidence), that it is a writing rule rather than a machine
  gate, and why the mirrors were left alone.
- `create-ticket/reference/ticket-format.md` asks for it: a change tightening a persisted-data
  constraint names its representative legacy fixture and the upgrade run in its Verification
  method, with the constraint kinds enumerated so the trigger is recognisable.
- `ship/SKILL.md` gained *A failed or pending deployment is its own state*, placed where the
  confirmation is already read and adding no gate: `fail` and `not_run` stay visible, `not_run` is
  not a soft pass, and a merged pull request establishes nothing about any target.
- `CLAUDE.md` carries it, cited once rather than restated.
- Hermetic rows pin the three surfaces that carry the rule **and** pin that the three policy pages
  do not — an absence that is easy to "helpfully" fill later without knowing why it is empty.

**Acceptance criterion 1 is therefore met in substance and not literally**: the legacy-row
requirement is stated where every ticket writer and the policy lens reach it, and is not stated in
the two mirrored policy pages. Carrying it into the canonical `persistence` / `test` / `ci-cd`
articles is an upstream authoring act on qmu.co.jp; the operator's route is to author it there,
after which the ordinary `standards-sync/*` pull request brings the hard copies into line. The
other three criteria are met literally.

### Discovered Insights

- **Insight**: `skills/<pillar>/policies/*.md` is a read-only mirror in everything but file
  permissions, and nothing in the file itself says so.
  **Context**: The contract lives in `implementation/SKILL.md`'s prose, in `README.md`'s
  "How policies stay in sync" note, and in one archived mission's out-of-scope list — none of
  which a session editing the file is likely to be holding. Only the `source:` frontmatter line
  hints at it. A future ticket naming one of these pages as a Key File will hit the same fork, so
  the reason is now recorded in `rules/general.md` where a session that touches anything will see
  it.

- **Insight**: The pinned *absence* is the load-bearing half of this change.
  **Context**: Asserting that the three pages carry no locally-authored legacy-row rule looks
  redundant next to asserting that `rules/general.md` does. It is the opposite: the rule is
  stated, so a later reader finding the policy pages silent has every reason to "complete" the
  work by adding it there — and would be reverted by a sync nobody was watching. Pinning the
  absence turns that into a failing row with the reason attached.

- **Insight**: Step 4 needed no new mechanism, only a sentence, and finding that out required
  reading D2 and §6 rather than assuming a gap.
  **Context**: `record-evidence.sh` already carries four honest statuses, D2 already records a
  failing confirmation as a failed deployment and promotes nothing, and §6 already refuses to
  skip its confirmation. What was genuinely missing was the statement that those statuses may
  never be collapsed into a healthy completion — a rule about the *report*, which is where the
  measured failure actually happened.
