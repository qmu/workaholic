---
type: Mission
title: Make acceptance ticking measure satisfaction, not marker shape
slug: make-acceptance-ticking-measure-satisfaction-not-marker-shape
status: active
merge_policy:
created_at: 2026-07-31T06:23:49+00:00
author: noreply@anthropic.com
assignees: []
assignee:
predicted_hours:
actual_hours: 1.2
feedback: [20260731062209-quality-gates-must-assist-delivery-not-block-well-done-work.md, 20260731062305-every-markerless-acceptance-item-in-this-repo-belongs-to-a-proposed-draft.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260804-113856
---

# Make acceptance ticking measure satisfaction, not marker shape

## Goal

A quality gate should report whether the work is done, not whether the work was authored in the
shape the gate's tooling expects. Today one gate fails that test outright: `tick-acceptance.sh`
can flip an acceptance item only when the line carries a `(#<artifact-filename>)` marker, and
nothing at authoring time requires one — so an item written without a marker is unreachable by
the only sanctioned writer of an `[x]`, and the mission's derived `checked/total` is pinned for
good.

The measurement in the source feedback shows this is not a stylistic slip. Every one of the 24
acceptance items across the three `/propose`-scaffolded active missions is markerless; every one
of the 19 items across the four interrogation-authored archived missions carries a marker. A
draft is proposed before any ticket exists, so at that moment there is no filename to link to —
and `adopt-a-git-flow-branching-model-with-durable-ship-records` is already `approved` with
`merge_policy: auto`, `tickets: []`, and a board reading `0/8` that no sanctioned script can
move. The gate is not slowing the work down; it is misreporting it, and the only ways out are a
discipline violation (hand-editing `[x]`) or a permanently stuck board.

## Scope

Proposed as a mission rather than a ticket because the work decomposes into at least three
related units that must land together to be coherent:

1. **Close the seam.** Decide and implement where the acceptance-to-artifact link is established
   for a proposed draft — most plausibly at the approval/replan seam that emits the ticket set,
   which is the first moment a filename exists. A fix confined to the ticker would leave the
   missing links missing.
2. **Decide the ticker's contract.** Relax it to resolve markerless items, keep the marker and
   enforce it at authoring time so an unreachable item cannot be written, or replace the marker
   key with a satisfaction check that does not depend on it. The reporter left this open on
   purpose; it is the one real decision in this mission.
3. **Repair what is already stranded.** The three active missions carry 24 unreachable items
   today. Whatever mechanism is chosen must have a sanctioned path that brings those boards to
   the truth, without anyone hand-editing a checkbox.

A fourth unit is proposed but explicitly severable: **audit the remaining gates** (the write-time
mission floor, the ticket hooks, the layout allowlist, the branch-safety scan) for the same
failure mode — green depending on a marker convention, a file location, or a formatting shape
rather than on a real quality failure. The reporter asked for this generalization; it should not
block the concrete fix.

Out of scope: loosening any gate that blocks on an actual quality failure, and the `/propose`
ticket-vs-mission cardinality rule already recorded under issue #114.

## Experience

A developer whose acceptance criteria are satisfied sees a board that says so. Concretely: after
the fix, no active mission shows `0/N` while its work is done; a mission whose acceptance items
were written as prose can still reach `N/N` through a sanctioned script; and an item that the
tooling would be unable to tick is either impossible to write or no longer possible to strand —
never merely tolerated. Nobody has to hand-edit an `[x]`, and nobody has to re-author working
prose into a marker convention to be counted.

## Acceptance

PROPOSED sketch for discussion, not a plan. `/mission approve` replans this to drive-ready.

Note that these items are themselves markerless — this batch has no tickets to link to yet,
which is precisely the condition the mission exists to fix.

- [x] The chosen contract for the acceptance-to-artifact link is decided and written where the
      convention already lives (`mission/reference/schema.md` and `mission/SKILL.md`), with the
      rejected alternatives named (#20260801185301-decide-the-acceptance-to-artifact-link.md)
- [x] The seam that emits a mission's ticket set also establishes the link for each acceptance
      item, so a mission approved from a draft no longer starts unreachable (#20260801185302-establish-the-link-when-tickets-are-emitted.md)
- [x] `tick-acceptance.sh` implements the chosen contract, and its `no_unchecked_match` result
      means "not satisfied" rather than "not addressable" (#20260801185303-make-the-ticker-measure-satisfaction.md)
- [x] The 24 stranded items across the three active missions are reachable by a sanctioned
      script, with no checkbox hand-edited (#20260801185303-make-the-ticker-measure-satisfaction.md)
- [x] A markerless acceptance item is either impossible to author or provably tickable — the
      measured 0-of-24 split cannot recur silently (#20260801185303-make-the-ticker-measure-satisfaction.md)
- [x] `node scripts/test-workflow-scripts.mjs` covers the new semantics hermetically, including
      a mission whose acceptance items carry no marker (#20260801185303-make-the-ticker-measure-satisfaction.md)
- [x] The gate audit (Scope unit 4) is either completed or split out as its own artifact, with
      the decision recorded rather than left implicit (#20260803213000-audit-the-gates-for-shape-dependent-green.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-03 — ticket archived — 20260801185301-decide-the-acceptance-to-artifact-link.md
- 2026-08-03 — ticket archived — 20260801185302-establish-the-link-when-tickets-are-emitted.md
- 2026-08-03 — ticket archived — 20260801185303-make-the-ticker-measure-satisfaction.md
- 2026-08-03 — story reported — work-20260803-212324.md
- 2026-08-03 — run recorded (+0.7h) — work-20260803-212324
- 2026-08-03 — concern deferred (stuck) — 20260803221906-21-acceptance-items-across-four-other.md
- 2026-08-03 — concern deferred (stuck) — 20260803221906-the-link-stamping-step-is-prose.md
- 2026-08-03 — concern deferred (stuck) — 20260803221906-v1-0-119-may-collide-with.md
- 2026-08-03 — concern deferred (stuck) — 20260803221906-readme-md-still-describes-the-retired.md
- 2026-08-04 — ticket archived — 20260803213000-audit-the-gates-for-shape-dependent-green.md
- 2026-08-04 — story reported — work-20260804-113856.md
- 2026-08-04 — run recorded (+0.5h) — 20260804-105700
