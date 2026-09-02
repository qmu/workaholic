---
created_at: 2026-09-02T23:20:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff: 
claim: work-20260902-225923
---

# Bump the version against the base, not the branch

## Overview

**Measured on `main`, 2026-09-02.** Five consecutive merges carry two version numbers between
them:

```
bb18deb4 Resolve a conflicted pull request in the tick (#896) -> 1.0.285
1ab2fa3d Settle a claim race at the remote            (#897) -> 1.0.285
ca45fc7d Take the moderation tick's log off main      (#898) -> 1.0.285
0711ad5d Read the base's colour past a bookkeeping tip(#894) -> 1.0.284
d6afa622 Refuse an ask the loop wrote to itself       (#895) -> 1.0.284
```

Three merges shipped plugin changes at `1.0.285`, and two at `1.0.284`. Each of those branches
**did** bump: `check-version-bump.sh` compares the branch against **its own base**, and several
sessions branch from one base, each bump `N → N+1`, and each is individually correct. The second
and third to merge then contribute **no version diff at all** — the file already holds the value
— so the squash carries no version change and nothing anywhere reports it.

**What it costs.** `.claude-plugin/marketplace.json` is the source of truth a consumer installs
from, and CI publishes a GitHub Release per version. So a released `1.0.285` and the `main` that
carries two further merges are different trees under one number, and `plugin-src.sh`'s
*newest version wins* resolution cannot tell them apart. Nothing is broken today; what is lost is
the ability to say which code a version is.

**This is not a slip in one run.** It is what the current rule produces whenever two units are in
flight at once, which since 2026-09-02 is the normal state (`/spawn-loops` runs three loops, and
the developer's own sessions run beside them).

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/delivery.md` — how the plugin reaches its consumers

## Key Files

- `plugins/workaholic/skills/branching/scripts/check-version-bump.sh` — the reader that answers
  `already_bumped`, today against the branch's own base.
- `plugins/workaholic/skills/story/SKILL.md` Phase 0 — the one caller, and the rule that a
  degraded read means bump.
- `.claude-plugin/marketplace.json` — the source of truth; `plugins/workaholic/.claude-plugin/plugin.json`,
  `plugins/workaholic/.codex-plugin/plugin.json` and the generated
  `outputs/workflows/.codex-plugin/plugin.json` follow it.
- `.github/workflows/release.yml` — publishes a Release per version reaching `main`.
- `CLAUDE.md`, *Version Management* — the manual-bump contract this changes.

## Implementation Steps

1. **Reproduce it offline before designing.** Two branches from one base, each bumped `N → N+1`,
   merged in turn: assert the second merge leaves `main` at `N+1` while carrying its own changes.
   That is the whole defect and it should be one hermetic row.
2. **Decide where the comparison belongs and record the reason.** The candidates are: read the
   **live base** at merge time rather than the branch's fork point (the merge is where the
   collision becomes visible); or make the bump a **post-merge seam** on `main` (one writer, no
   collision possible); or leave the bump per-branch and add a **reconciliation** that notices a
   merge landing on an unchanged version. Prefer the one that needs no new writer on `main`.
3. **Do not make it a gate that blocks a merge.** Quality is gated at the `release/*` window, not
   at merge time, and a version collision is a bookkeeping fact rather than a defect in the work
   — a run whose merge is refused for it would report `pending` for something no unit did wrong.
4. **Say what happens to the versions already collided.** `1.0.284` and `1.0.285` each name more
   than one tree today. Decide whether that is repaired (a bump naming the current `main`) or
   recorded and left, and say which — a silent re-use of a published number is the thing this
   ticket exists to stop.
5. Update `CLAUDE.md`'s *Version Management* and `workaholic:story` Phase 0 in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Two branches from one base, each bumped and merged in turn, leave `main` at two distinct
  versions — or the collision is reported by name where somebody reads it.
- No merge is refused for a version collision.
- The already-collided versions are ruled on explicitly, either way.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`, including the two-branch reproduction from step 1.
- A read of `git log` over the last ten merges showing one version per merge, or the named report.

**Gate** — what must pass before approval:

- The reproduction exists and fails before the change.

## Considerations

- **The per-branch bump is not wrong, it is incomplete.** `check-version-bump.sh` answers exactly
  what it was asked and its answer is true of the branch; what nothing asks is whether the value
  it lands on is still free. Repairing the reader's *question* rather than replacing the reader
  is likely the smaller change.
- An open pull request may already hold the next number (#899 holds `1.0.286` today), so any
  repair that picks a number must read the open publications, not only `main`.
- This was found by an `/implement` run that had nothing claimable, from `git log` alone. It is
  cheap to re-measure and should be re-measured before the fix, in case a session lands one
  meanwhile.

## Final Report

Development completed as planned.

- **Reproduced offline first** (step 1), and the reproduction is a real one rather than a
  reading: two branches from one base, each carrying its own work and each bumping `1.0.9 →
  1.0.10`, merged in turn — the second merge lands its work and leaves the manifest exactly
  where the first put it. It is one hermetic row and it fails without the change.
- **The comparison belongs at the reader, and the repair at the merge** (step 2, with the
  reason). `check-version-bump.sh` answered *did this branch make a bump commit*, which is true
  of the branch and says nothing about **which number it landed on**. It now answers a second
  question, **`version_ahead`**, comparing the branch's manifest to the base's field-wise (so
  `1.0.9 < 1.0.10`, which a string compare gets wrong) and three-valued — `null` with
  `manifest_unreadable`, never `false`. `/story` Phase 0 bumps unless **both** hold, and
  `/drive` §6 re-reads immediately before the merge and re-bumps when the base has overtaken the
  branch. **No new writer on `main`** — the preference the ticket states — and no new store.
- **It is a repair, never a gate** (step 3). The merge happens either way; a re-bump that cannot
  be made is reported by name (`version_rebump_failed: <reason>`) and the unit merges anyway,
  and §7 gains a token row saying so. A version collision is a bookkeeping fact, not a defect in
  the work, and this is the one seam quality is deliberately not gated at.
- **The already-collided numbers are recorded and left** (step 4), stated in `CLAUDE.md`:
  `1.0.284` and `1.0.285` each name more than one tree, and re-cutting published releases to
  tidy that is a worse act than the one it would cure. The next bump names the current `main`.
- `CLAUDE.md`'s *Version Management* and `workaholic:story` Phase 0 moved in the same change
  (step 5).

**The Considerations' open-publication point is answered rather than implemented.** They warn
that a repair picking a number must read the open pull requests, since one may already hold the
next value — #899 holds `1.0.286` today. It does not need to: **every merge re-checks**, so
whichever lands first takes `N+1` and the other re-bumps to `N+2` at its own seam. Reading the
open pull requests would add a network call per merge to arbitrate what the seam already settles.

**This branch is its own first case.** It read `version_ahead: false` at `1.0.285` against a base
at `1.0.285` — the exact shape — and was bumped to `1.0.286` under the new rule.

### Discovered Insights

- **Insight**: The old reader was not wrong, it was **incomplete**, and that distinction decided
  the whole design. `already_bumped` answers exactly what it was asked and its answer is true;
  what nothing asked is whether the value it landed on is still free. Repairing the reader's
  *question* was a smaller change than replacing the reader or moving the bump to a post-merge
  seam on `main`.
  **Context**: The same shape is worth looking for in every predicate this loop keys a decision
  on — a true answer to the wrong question fails silently and forever.
- **Insight**: A fixture of two branches from one base needs each branch to carry **its own
  work**. Identical trees and messages from one parent produce the *same commit object*, so the
  second branch becomes an ancestor of the first and `base..HEAD` is empty — the row then passes
  or fails for a reason that has nothing to do with versions. It cost one red row to find.
  **Context**: Any hermetic fixture modelling concurrent branches needs a distinguishing commit.
