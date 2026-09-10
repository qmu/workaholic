---
created_at: 2026-09-10T14:30:00+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
feedback: 20260908123552-slack-bot, 20260908123606-honor-repository-declared-qfs-slack-bindings-before-connector-fallback
merge_policy:
verification_handoff: 
claim: work-20260910-150318
---

# Name the write path's fallback classes as the code maps them

## Overview

Minted 2026-09-10 while driving `20260910040721-say-that-an-authorization-refusal-never-falls-back`,
which repaired the same defect in `CLAUDE.md` and was **bound by its own Quality Gate** to leave
`plugins/workaholic/skills/transport/scripts/` byte-identical, so this one could not be fixed in
that change.

`perform.sh`'s write path carries this comment immediately above its fallback guard:

> A WRITE leaves the preferred route only on a failure that happened BEFORE the provider was
> asked to commit — capability, authorization, availability.

The guard on the next line is `[ "$(qfs_fallback_class "$reason")" != none ]`, and
`qfs_fallback_class()` maps the authorization word `qfs_preview_refused` to **`none`**. So the
comment names as a fallback-permitting class the one class the code two lines below it excludes —
the identical disagreement the `CLAUDE.md` ticket repaired, one layer down and in the file a
reader would check *to settle the question*.

The behaviour is right and must not move: an authorization denial stays a refusal, and no
alternate route, spelling, parent delegation or second account is used to get past one
(`branching/scripts/refusal-capability.sh`'s `not_permitted`).

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/transport/scripts/perform.sh` — the write path's fallback guard and
  the comment above it; `qfs_fallback_class()` is the one derivation and does not move.
- `CLAUDE.md` — the *An operation leaves the preferred route only on a TYPED failure* paragraph,
  already corrected, whose wording this comment should agree with.
- `scripts/test-workflow-scripts.mjs` — `an authorization refusal is typed and never falls back`
  already pins the mapping and the prose; consider whether the comment belongs to that row.

## Implementation Steps

1. Read `qfs_fallback_class()` and both consumers and confirm the mapping rather than restating
   this ticket's reading.
2. Correct the write path's comment so the classes it names are the ones the guard admits,
   keeping the *before the provider was asked to commit* distinction it is actually making —
   that part is true and is the reason a write may fall back at all.
3. Check the read path's neighbouring comments for the same grouping and correct any in the same
   change.
4. Change no mapping, widen no consumer and rename no class.

## Considerations

The comment's substantive point — that a write's fallback is a *first attempt* because nothing was
accepted — is correct and should survive. Only the class list is wrong.

A tempting over-reach is to have the comment enumerate the classes at all; the one derivation is
six lines above it, and naming a set in two places is what produced this defect. Pointing at
`qfs_fallback_class()` may be the smaller and more durable repair than a corrected list.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No comment in `perform.sh` names `qfs_preview_refused`, or the authorization class, among the
  failures on which an operation leaves the preferred route.
- `qfs_fallback_class()`, `read_fallback_class()` and both call sites are unchanged in behaviour:
  the same words map to the same classes and neither guard is widened.

**Verification method** — the commands/tests/probes that prove them:

- `git diff` over `perform.sh` shows comment lines only.
- `node scripts/test-workflow-scripts.mjs` and
  `node --test scripts/tests/agentic-loop/*.test.mjs` both report 0 failed.

**Gate** — what must pass before approval:

- A reader settling the question from `perform.sh` alone reaches the same answer as one reading
  `CLAUDE.md`: an authorization refusal is typed, and it does not fall back.

## Final Report

Development completed as planned.

The write path's comment named `capability, authorization, availability` as the classes on which an
operation leaves the preferred route, two lines above a guard that maps the authorization word to
`none`. Rather than correct the list, the comment now cites `qfs_fallback_class()` — the one
derivation — and enumerates nothing, which is the smaller repair the ticket's Considerations
preferred and the one a later edit cannot drift out of step with. The mapping function's own header
gained CLAUDE.md's *typed is not the same as fallback-permitting* distinction, so a reader settling
the question from `perform.sh` alone reaches the answer CLAUDE.md gives. No mapping, consumer or
guard moved: every changed line in `perform.sh` is a comment line.

### Discovered Insights

- **Insight**: the suite row that owns this rule strips comment lines before asserting on the
  mapping — *"a sentence about the class cannot stand in for the mapping itself"* — which is exactly
  why the identical defect could sit in a comment two lines above the guard while every assertion
  passed.
  **Context**: the repair adds assertions that read the comment block *immediately above the write
  guard* as a subject of its own, rather than relaxing the mechanical check. They pin that the
  comment cites the derivation and names no class, and were verified to bite: run against
  `origin/main`'s copy of the file they answer `cites derivation: false, enumerates a class: true`.

- **Insight**: `qfs_fallback_class()` admits `qfs_preview_failed` (reachability), so the neighbouring
  `read_fallback_class` comment's *"a READ may also leave on a reachability failure; a WRITE may
  NOT"* is true only of `qfs_connector_failure` — the one word that function adds, which its own next
  sentence names.
  **Context**: step 3 asked for a sweep of the read path's comments for the same grouping. This one
  reads correctly with the sentence that follows it and is identical in meaning to CLAUDE.md's own
  paragraph, so correcting it here alone would have put the two surfaces out of step — the drift this
  ticket exists to end. Left as it stands, deliberately, and recorded here rather than acted on.
