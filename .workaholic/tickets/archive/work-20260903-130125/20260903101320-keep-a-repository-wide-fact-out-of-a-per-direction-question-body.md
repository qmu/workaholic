---
created_at: 2026-09-03T10:13:20+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-maintenance-tick-s-channel-presence-help-the-work-along
merge_policy:
verification_handoff: 
---

# Keep a repository-wide fact out of a per-direction question body

## Overview

Every `🙋` body carried `どの方向性にも属さない作業: <mission>（8 件が待ち）` — a repository-level
residue fact about one unattributed mission, pasted into all five questions because the composer
had it in hand. It is not about direction A, B or C. Remove it from the per-direction body; the
residue belongs where it is a fact about the subject.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/user-experience.md` — the reader of the post is the user here

## Final Report

**Outcome**: implemented.

The unattributed residue — rendered as *not attributed to any direction: `<mission>` (N queued)* —
was appended to the heading of **every** direction question because the composer had it in hand. It
now rides only **`arrived`** and its `cutover` refinement, and leaves `overdue`, `expiring`,
`dormant` and `settled`.

**Why those two keep it, stated rather than assumed.** The residue was added on 2026-08-28 by the
mission `say-what-the-direction-could-not-see-before-calling-it-arrived`, precisely so nobody would
be asked to call a direction finished without seeing what the loop could not attribute. There it is
a fact **about the subject** — it is the answer to *can this be called done*. On the other four it is
a fact about the repository, which is the ticket's own test: *the residue belongs where it is a fact
about the subject*. Deleting it everywhere would have re-opened the earlier mission's defect.

**Nothing else moved**: no key, no addressee, no cap, and the residue is still carried from the one
read `direction-state.sh` made rather than re-read here.

**Verified**: `node scripts/test-workflow-scripts.mjs`; a live run of the step.

**Suite addendum.** Two rows pinned the residue on the `overdue` and `expiring` headings and were
inverted in the same change: each now asserts the phrase is **absent** there, with the reason and the
2026-08-28 mission it defers to written beside it. Nothing was loosened — an absence assertion is as
strict as the presence one it replaced.
