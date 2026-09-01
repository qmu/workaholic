---
created_at: 2026-08-29T06:20:39+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: land-the-loop-s-own-work-when-the-base-moves-under-it
merge_policy:
verification_handoff: 
---

# State the catch-up and its refusals

## Overview

PROPOSED. `drive/reference/claims.md` and `CLAUDE.md`, in the same change: the reading, the
writer, its bounds, and an **explicit reversal** of *resolving a conflict on a claimed branch
is still nobody's job here* — narrowed to the mechanical case on this identity's own claim,
with the contested case named as staying a person's.

The sentence being narrowed is load-bearing and appears in more than one place, so the change
must find every copy rather than the first one. `step-merge-conflicts.sh`'s own header carries
the fullest statement of the reasoning, and that reasoning is **answered rather than dropped**:
a third party rebasing races the holder's pushes, and this act is neither a third party nor a
rebase.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/drive/reference/claims.md` — the protocol's home; the reading's
  classification and the writer's bounds.
- `plugins/workaholic/skills/moderate/scripts/step-merge-conflicts.sh` — its header states the
  standing rule; the narrowing must be recorded there too.
- `CLAUDE.md` — the claim-protocol section and the `/implement` contract row.
- `plugins/workaholic/skills/drive/SKILL.md` — the routing table's `content` conflict row.

## Implementation Steps

1. Find every copy of the standing rule before editing any of them.
2. State in `claims.md`: the four-valued reading and its classification as judgements, the
   writer's six refusals, the order of its acts, and what it never does (no rebase, no amend,
   no force-push, no scan-held pull request, no colleague's claim).
3. Record the narrowing where the standing rule lives, answering its reasoning by name rather
   than deleting it.
4. Update `CLAUDE.md` in the same commit — this repository treats outdated documentation as a
   defect, and `doc-drift.sh` is a backstop rather than the check.
5. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) if any workflow skill or its
   script closure moved.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The narrowing is stated in every place the standing rule appears.
- The standing rule's reasoning is answered by name, not dropped.
- `CLAUDE.md` is updated in the same change.
- `outputs/` is regenerated and CI's freshness check is clean.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- No documentation drift, and the generated bundle diff is empty after a rebuild.

## Considerations

Writing the reversal in one place and leaving another copy standing is the failure mode here;
the rule is quoted in prose rather than derived from a constant, so only a search finds them all.

## Final Report

Development completed as planned, and the ticket's own instruction — **find every copy of the
standing rule before editing any of them** — was followed literally. A repository-wide search
for the sentence and its paraphrases found four live copies plus the routing table's `content`
row, and every one is updated in this change:

1. `plugins/workaholic/skills/moderate/scripts/step-merge-conflicts.sh` — the fullest statement
   of the reasoning. Its two halves are **answered by name** rather than deleted: not a third
   party (the claim is this identity's own, and a live one is refused `claim_active`, so the
   race the header is about cannot arise) and not a rebase (a merge commit keeps the holder's
   checkout valid, which is what a history rewrite destroys). The header also records the
   refusal to filter its own output, with the measurement behind it.
2. `plugins/workaholic/skills/drive/reference/claims.md` — a new *Catch a claim up with a base
   that moved* section stating the reading's four values, the writer's refusals, the order of
   its acts and what it never does; plus a third sub-table under *Proofs and judgements*
   classifying `clean`/`mechanical`/`content`/`unanswerable` as **judgements**, keyed apart from
   the other two vocabularies because three of them share the word `unanswerable`.
3. `CLAUDE.md` — the claim-protocol bullet, the `/implement` contract row, the `/moderate` row
   (step 26 and the step count), the drill list, and the 2026-08-19 bullet whose closing clause
   is the sentence being narrowed.
4. `plugins/workaholic/skills/moderate/reference/workflow.md` — the `merge-conflicts` findings
   row, which rested on the sentence explicitly.
5. `plugins/workaholic/skills/drive/SKILL.md` — §6, §7 and the routing table's `content`
   conflict row, which is **unchanged in behaviour** and now says why: that row is a unit on its
   way to shipping, where the demotion *is* the repair; the catch-up reads the same two words
   for a unit that has already reported and cannot be demoted anywhere.

`outputs/` is regenerated (`build.mjs`), and the generated bundle carries the two new scripts
and the shared library with their cross-skill paths rewritten — checked by running the bundled
`claim-mergeability.sh` against a fixture. `verify.mjs`, `validate-metadata.mjs`,
`test-workflow-scripts.mjs` (4949 passing) and `layout-doctor.sh` are all clean.

### Discovered Insights

- **Insight**: The `unanswerable` word now appears in three of `claims.md`'s vocabularies, and
  the pin that keys words to classes parses the document by slicing at section headings.
  **Context**: A fourth vocabulary must be sliced apart the same way and placed after the
  existing ones, or the claim tables' parse swallows it and every shared word reports as a
  duplicate rule. The failure is loud but the cause is not obvious from the message.
- **Insight**: A narrowing is only findable later if the *reasoning* stays where the rule was.
  **Context**: Deleting `step-merge-conflicts.sh`'s two-alternative paragraph would have made
  the narrowing look like a reversal to the next reader. Answering each half by name, in place,
  is what keeps the refusal legible.
