---
created_at: 2026-08-26T11:32:04+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: tell-a-merged-claim-from-a-live-one-at-both-grains
merge_policy:
verification_handoff: 
---

# Make the oracle degrade by name, not by guess

## Overview

PROPOSED. Ticket 3 of 8. `list-claims.sh` promises that the reader degrades offline; the
new reader makes a network call, so that promise has to be kept explicitly rather than
inherited. When ticket 2's reader answers `unanswerable`, the row keeps **precisely** the
verdict it has today and the scan reports which claims it could not answer for and why.

The asymmetry is deliberate and worth stating in the code: a wrong `merged` releases work
that is still in flight; a wrong `in flight` only delays a claim. So an unread answer
never becomes `superseded`.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_scan`, where the
  reader is consulted and the verdict assembled. Its header states the degradation
  contract; extend the header in the same change.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the reported shape; the
  unanswered set is surfaced here.
- `scripts/test-workflow-scripts.mjs` — the offline case.

## Implementation Steps

1. Read `claims_scan`'s ordering comments. `superseded` sits after `claim_active` and
   before the drained fork for stated reasons; the degradation must not disturb that.
2. Consult ticket 2's reader where the verdict is decided, and on `unanswerable` leave the
   row's verdict byte-identical to today's — not `superseded`, not a new state.
3. Report the unanswered claims by name with their reasons, as a field of the scan's own
   output rather than on stderr, so a consumer can render it.
4. Bound the cost: one reader call per claim at most, and make the whole thing skippable
   so a fully offline run is not slowed by a call that cannot succeed.
5. Write the asymmetry into the header, in one sentence, beside the existing rules.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With the reader unavailable, every row's verdict is identical to the pre-change output.
- The scan names each claim it could not answer for, with a reason.
- No claim is ever reported `superseded` on a failed read.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — an offline case diffed against the
  pre-change output for byte-identity.

**Gate** — what must pass before approval:

- The offline output is proved identical, not asserted to be.

## Considerations

- Byte-identity offline is the strongest form of this and is what should be tested. A
  weaker "no row became superseded" check would pass while something else drifted.

## Final Report

Development completed as planned. The merged lookup is consulted through one function,
`claims_merged_state`, and every way it can fail to answer is named rather than guessed.

**The asymmetry is in the header, in one sentence, beside the existing one.** `claims_fetch`'s
header has always explained why an unreachable origin degrades the reader and fails the writer;
the new sentence runs the same way for the lookup — *a wrong `merged` releases work that is
still in flight, a wrong `in flight` only delays a claim* — so an unread answer is never
promoted to `merged`.

**It is skipped whenever it cannot succeed, by name.** A run whose fetch just failed has proved
it has no network, so no call is spent per claim (`offline`); `WORKAHOLIC_CLAIM_MERGED_LOOKUP=0`
is the explicit opt-out (`disabled`). Both are recorded rather than silently answered
`not_merged`, and both are asserted to make no call at all.

**The unanswered set goes to a file the caller names, not to an extra TSV column.** The column
was the obvious route and is refused by the row's own longest warning: a tab is IFS whitespace,
so an empty middle field shifts every field after it, and that has already cost this protocol
one incident. A variable was refused too — `claims_scan` runs inside a command substitution, so
anything it sets dies with the subshell. `list-claims.sh` creates the file, reads it back as
`merged_lookup_unanswered: [{branch, reason}]`, and removes it; a caller that does not care sets
nothing and the recorder is a no-op.

**The verdicts are proved identical, not asserted to be.** Over the ticket-1 fixture, the whole
`claims` array with the lookup disabled is compared byte-for-byte against the array produced
with it enabled but unable to reach anything.

**Two divergences from the ticket, both forced and both recorded.**

*The reader moved out of `lib/`.* Ticket 2 placed `claim-merged.sh` at
`drive/scripts/lib/claim-merged.sh`, and `verify.mjs` rejected it: the bundle build detects a
cross-skill closure by the literal form `${SCRIPT_DIR}/../../<skill>/scripts/`, which is only
writable from `scripts/`. From `lib/` the reference needs a third `../` and the build reports it
as undetectable — so the reader would have shipped to every non-Claude agent with its transport
missing. It now sits at `drive/scripts/claim-merged.sh`, and ticket 2's archived Final Report
names the old path; this is the correction.

*The call site is not wired here.* Ticket 3's own acceptance is about what happens when the
reader cannot answer, and ticket 4 owns routing a mission unit to it. Consulting it here and
discarding the result would spend one network call per claim for nothing, so this ticket ships
the mechanism, the skip policy and the reporting surface, and ticket 4 supplies the one call
site — which is why `merged_lookup_unanswered` is an empty list until it lands.

### Discovered Insights

- **Insight**: `CLAIMS_LIB_DIR` has to be passed in by the caller. A sourced shell file cannot
  ask where it is — `$0` is the *caller's* script — and the caller may be in a worktree, a
  publish tree or the installed plugin cache.
  **Context**: Every sourcer already computes its own script directory in order to source
  `claims.sh` at all, so passing it costs one line. The `$0` walk kept as a fallback resolves
  correctly only when the caller happens to sit one level above `lib/`, which is a coincidence
  rather than a contract — and it is exactly what failed first.
- **Insight**: The bundle build's closure detection constrains *where a script may live*, not
  just how it writes a path. A helper that needs a sibling skill cannot sit in a nested
  directory.
  **Context**: `verify.mjs` catches it, but only after the file exists and the bundle has been
  rebuilt — so the cheapest order for a new cross-skill helper is to place it in `scripts/`
  first and move it down only if it turns out to need nothing outside its own skill.
