---
created_at: 2026-08-01T18:53:01+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: make-acceptance-ticking-measure-satisfaction-not-marker-shape
merge_policy: auto
---

# Decide the acceptance-to-artifact link contract

## Overview

The mission's one real decision, left open on purpose by the reporter. `tick-acceptance.sh`
can flip an acceptance item only when the line carries a `(#<artifact-filename>)` marker,
and nothing at authoring time requires one — so an item written without a marker is
unreachable by the only sanctioned writer of an `[x]`.

The measurement is not a stylistic observation: **all 24** acceptance items across the
`/propose`-scaffolded active missions are markerless, and **all 19** across the
interrogation-authored archived missions carry a marker. The split is 0-of-24 versus
19-of-19, and it has a structural cause — a draft is proposed before any ticket exists, so
at that moment there is no filename to link to.

Three candidate contracts, and they are not equivalent:

1. **Relax the ticker** to resolve markerless items — by title match, or by position.
2. **Keep the marker and enforce it at authoring time**, so an unreachable item cannot be
   written. This collides head-on with the structural cause: a proposed draft has no
   filename yet, so enforcement would have to be deferred to the approval seam.
3. **Replace the marker key with a satisfaction check** that does not depend on it.

The mission also asks a fourth, severable question: audit the other gates for the same
failure mode — green depending on a marker convention, a file location, or a formatting
shape rather than on a real quality failure. That must be decided here (do it, or split it
out) rather than left implicit.

## Policies

- `workaholic:development` / `policies/qa-engineering.md` — a quality gate reports whether the work is done, not whether it was authored in the shape the tooling expects.
- `workaholic:implementation` / `policies/observability.md` — a board pinned at `0/N` while the work is done is a misreport, not a slow gate.
- `workaholic:implementation` / `policies/objective-documentation.md` — the convention belongs where it already lives, with the rejected alternatives named.

## Key Files

- `plugins/workaholic/skills/mission/scripts/tick-acceptance.sh` - the only sanctioned writer of an `[x]`
- `plugins/workaholic/skills/mission/reference/schema.md` - where the acceptance convention is documented
- `plugins/workaholic/skills/mission/SKILL.md` - the developer-facing statement
- `plugins/workaholic/skills/propose/scripts/scaffold-draft.sh` - writes the markerless items
- `plugins/workaholic/skills/mission/scripts/progress.sh` - derives `checked/total` from the same lines

## Implementation Steps

1. Re-measure before deciding. The counts came from a specific date and missions have
   moved since; a decision argued from stale numbers is the failure this mission is about.
2. Choose among the three contracts. Weigh them against the structural cause: whichever is
   chosen must work for an item authored **before** its ticket exists, because that is when
   `/propose` writes one.
3. Write the decision into `mission/reference/schema.md` and `mission/SKILL.md`, naming the
   rejected alternatives and why.
4. Decide the gate audit explicitly: complete it here, or split it into its own artifact.
   Record which, and the reason.
5. No code in this ticket.

## Quality Gate

**Acceptance criteria**

- The contract is decided and written in `mission/reference/schema.md` and `mission/SKILL.md`, with rejected alternatives named.
- The decision demonstrably works for an item authored before its ticket exists — stated against the `/propose` case, not in the abstract.
- The counts are re-measured and recorded, rather than carried over from the mission text.
- The gate audit is either scheduled as its own artifact or committed to here, with the choice recorded.
- No code change.

**Verification method**

- Re-run the count of markered versus markerless items across active and archived missions, and record it.
- Read-through of the written contract against the `/propose` authoring moment.

**Gate**

- The contract handles the before-a-ticket-exists case. A contract that only works once a filename exists re-creates the defect at the moment it matters.

Decided: the decision is its own ticket, because the reporter left this open deliberately and a fix confined to the ticker would leave the missing links missing (developer may override at /drive).

## Considerations

- `progress.sh` reads the same lines to derive `checked/total`. Whatever changes about the line's shape must keep it working, or every board moves for the wrong reason.
