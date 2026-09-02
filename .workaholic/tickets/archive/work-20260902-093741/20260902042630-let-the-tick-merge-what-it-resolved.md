---
created_at: 2026-09-02T04:26:30+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: resolve-a-conflicted-pull-request-in-the-tick-not-report-it
merge_policy:
verification_handoff: 
---

# Let the tick merge what it resolved

## Overview

PROPOSED. Resolving a conflict and stopping there leaves the pull request open, which is the
stagnation the operator is describing. The instruction is to bring every conflicted pull
request into a mergeable state **and merge it**.

`/moderate` today states, as a bound, that it never merges a pull request. The operator has
ruled otherwise for this class. This ticket carries the merge and rewrites the bound to say
what is now true.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — delivery is part of the act, not a separate hope

## Key Files

- `plugins/workaholic/skills/gather/scripts/merge-method.sh` — the one derivation of the
  merge method; the new call site reads it and never spells it (the suite fails on a literal).
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one transport; the merge is a
  REST `PUT .../merge`, never `gh pr merge`.
- `plugins/workaholic/skills/ship/scripts/merge-pr.sh` and
  `plugins/workaholic/skills/drive/scripts/retry-undelivered.sh` — existing merge call
  sites whose refusal vocabulary (`merge_reason`) this reuses rather than inventing.
- `plugins/workaholic/skills/branching/scripts/settle-stranded-publication.sh` — already
  merges after settling; the shape to follow.
- `plugins/workaholic/skills/moderate/SKILL.md`, `CLAUDE.md` — the "never merges" bound.
- `plugins/workaholic/skills/release-scan/scan-branch-safety.sh` — the gate that runs
  before any merge and is not widened by this.

## Implementation Steps

1. After a successful resolution and push, run the release-safety scan and merge only on
   `pass` or `override_only` — the existing tier policy through `gate-decision.sh`. A
   `secret` finding hard-stops and is never overridden; a `leak` finding holds the pull
   request open. Resolving does not lower a gate.
2. Merge through the existing REST seam, reading the method from `merge-method.sh`, and
   report the outcome in the existing merge vocabulary (`merged` / `merge_refused: <word>`).
3. Handle `session_type_cannot_merge` as the one retryable refusal, through
   `mcp__github__merge_pull_request`, once, reporting both outcomes by name — the same
   qualification every other merge call site holds.
4. Report what the tick did, per pull request, in the step's summary and in the channel
   line: resolved and merged, resolved and refused with the word, or not attempted with the
   reason. The operator's standing expectation is that the tick reports what it **did**.
5. Rewrite the bound in `workaholic:moderate` and `CLAUDE.md`: the tick merges the pull
   requests it resolved, and here is what it still never does. A stale "never merges"
   sentence beside a merging tick is worse than no sentence.
6. Add a hermetic assertion that the scan runs before the merge and that a `secret` finding
   leaves the pull request open.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A pull request the tick resolved is merged by the tick, or refused with a named word.
- The release-safety scan runs before every such merge and is never overridden.
- The bounds prose states what the tick now does.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- The suite still fails on a literal merge method at the new call site.
- The scan-before-merge assertion fails when the order is reversed.

## Considerations

- This is the largest widening in the mission: an unattended hourly tick that merges. The
  brakes that stay are the scan, the fast checks from the sibling ticket, and the named
  refusal vocabulary. State them together in the bounds prose so the widening is legible
  rather than discovered.

## Final Report

Development completed as planned, with **one deliberate deviation from step 5**, recorded
below because it is a deviation and not an oversight.

The catch-up now delivers what it made mergeable: after the push, `catch-up-claim.sh` runs
the release-safety scan, reads it through `gate-decision.sh`'s **severity tier** — never the
binary verdict — and merges on `pass` or `override_only` through the same REST seam and the
same `merge-method.sh` derivation every other caller reads. The outcome rides its own field,
`delivery`, in §6's existing merge vocabulary.

### `delivery` is a second field, not a wider `outcome`

A branch can be genuinely caught up — merged onto the base, regenerated, validated, pushed —
while its pull request is held by a gate or refused by the transport. Those are two facts.
Collapsing them would either report a real repair as a failure or report an open pull request
as delivered, and the second is the error this mission exists to end. So `outcome` stays the
branch's fate and `delivery` is the pull request's, and the run report names both.

### It delivers a `queue_drained` claim and nothing else

The bound is **ownership of the act**, not caution. A `report_undelivered` unit's merge
already belongs to `retry-undelivered.sh`, which `/implement` runs immediately after a
`caught_up` (`workaholic:drive` §6). Delivering here as well would attempt one pull request
twice in one turn, and the second attempt — landing on an already-merged pull request — would
be reported as `merge_refused` and would withhold `ok` from a run that had in fact delivered.
That is the precise shape this mission is trying to remove, so introducing it would be
self-defeating. One act owns one delivery.

### The deviation: `/moderate`'s "never merges" bound is left standing, and stated

Step 5 asked to rewrite that bound "to say what is now true". **It is still true, so
rewriting it would have made it false.** No `/moderate` step resolves a conflict — the acts
that do are `[Implement]`'s `catch-up-claim.sh` and `settle-stranded-publication.sh` — and a
step that resolved nothing has nothing to deliver. Putting a merge into the asking tick would
have given it an act it never earned and would have retired a bound that is doing real work.

So the merge went where the **resolution** happens, and `moderate/SKILL.md` now says
explicitly that the bound is unchanged and why, so a later session does not "fix" the omission
by reinstating a merge there. The sentence this mission must remove is not that bound — it is
the one that says a conflict belongs to a claim holder, and that is the third ticket's.

This is the third premise in this mission that did not survive contact with the tree; the
first two are recorded in the diagnosis ticket's findings.

### The other named brakes, each unchanged

- **The scan runs before the merge**, and the order is asserted as an order — a scan after a
  merge has gated nothing. `secret` is a hard stop, `leak` holds the pull request open, and
  only the `override_only` granularity nudge proceeds.
- **An unreadable gate is never `pass`** — it reports `not_attempted: scan_unreadable`.
- **A delivery this environment could not attempt never becomes a refusal of the catch-up.**
  A missing transport, an unresolved slug, no open pull request or a held gate all report
  `caught_up` with the reason on `delivery`: the branch really was repaired, and saying
  otherwise would make the loop distrust its own successful acts.
- **`session_type_cannot_merge`** takes the same numbered connector step every other refused
  merge takes, and it lives in the calling agent because **no script may call an MCP tool**
  (`workaholic:drive` §6). Step 3 asked for it inside the script; that would have broken a
  standing rule, so it was contracted in the run report instead.
- The fast checks, the identity bound, `claim_active`, `pull_request_reviewed` and the
  recorded-`scan_held` refusal are all untouched.

### Verification

- `node scripts/test-workflow-scripts.mjs` — **6033 passed, 0 failed** (5 new rows).
- `sh scripts/e2e/loop-drill.sh verify-catch-up` — `pass`, 15 load-bearing, 3 breakers.
- `sh scripts/e2e/loop-drill.sh verify-all` — **43 drills, 0 failed, 33 proved.**
- `build.mjs` / `verify.mjs` / `validate-metadata.mjs` — clean.

The new assertions pin the delivery's existence, **the scan-before-merge order**, that no
scan finding passes, that the method is read rather than spelled, and that the
`queue_drained` bound holds.

### Discovered Insights

- **Insight**: The scan-before-merge property has to be asserted as an **order** (the scan's
  offset in the source is before the merge's), not as the presence of both. A test that only
  checks both are present passes a file where the merge runs first, which is the one
  arrangement that gates nothing.
  **Context**: This is the general shape for any "X must happen before Y" safety property in
  these scripts. Presence assertions are the default reflex and they are worthless here.

- **Insight**: Three of this mission's five tickets carried a premise that the tree
  contradicted — a step said not to exist that does (`stuck-prs`), a reader named that is not
  the one producing the line (`claim-mergeability.sh` vs `pulls-state.sh`), and a bound said
  to be false that is true (`/moderate` never merges).
  **Context**: The tickets were written from quoted channel output rather than from the tree,
  which is exactly why the mission opened with a diagnosis ticket. The lesson for the
  remaining tickets is to re-verify each premise against the tree before implementing it, and
  to record the correction rather than quietly implementing something adjacent.
