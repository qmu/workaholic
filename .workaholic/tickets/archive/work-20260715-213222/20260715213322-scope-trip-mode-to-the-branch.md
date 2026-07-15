---
created_at: 2026-07-15T21:33:22+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
---

# detect-context.sh calls every branch a trip once any trip has ever existed

## Motivation

`detect_mode()` decides `drive` / `trip` / `hybrid` from two predicates. One is scoped to the current work; the other is not:

```sh
if [ -d "$trips_dir" ]; then
  trip_dirs=$(find "$trips_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
  if [ "$trip_dirs" -gt 0 ]; then
    has_trips=true
  fi
fi

# Scope the count to the current user's subdirectory so another developer's
# leftover tickets don't flip mode detection for this user.
ticket_count=$(find "${todo_dir}/${USER_SLUG}" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l)
```

The ticket half is scoped — deliberately, with a comment explaining why. The trips half three lines above is a repo-wide `find`: **any** trip directory that has ever been created, on any branch, at any time, sets `has_trips=true` forever. The asymmetry inside a single function is the defect.

This repository holds exactly one trip directory — `.workaholic/trips/trip-20260319-040153/`, from March 2026 — so **every branch since has reported `trip` or `hybrid`**. Observed today on `work-20260715-112717`, a pure `/drive` branch with no trip artifacts of its own: `/report` detected `mode: "trip"`.

**This was already known and shipped anyway.** Story `work-20260713-144839.md` records it verbatim at line 124: *"mode detected as trip only because an unrelated March trip directory predates this branch; no trip rationale applies."* No ticket, no concern — so the corpus never carried it and it surfaced again two days later.

There is direct precedent for the fix. The archived concern `.workaholic/concerns/archive/30-the-detect-context-sh-change-introduces.md` flagged exactly this class — "state-dependent context detection… non-deterministic based solely on branch name" — and was marked **resolved**. It was resolved for the ticket half only; the trips half was never touched.

**Impact today is nil, which is why this is `low`-effort rather than urgent.** Drive, Trip and Hybrid Mode all run the identical Write Story orchestration. Trip Mode's only addition is step 3 (link the trip rationale), which is itself already guarded by *"if a `.workaholic/trips/<trip-name>/` directory exists for this branch"* — a branch-scoped test the detector should have been making all along. The cost is a wrong signal that a future trip-specific behaviour would act on, plus Hybrid Mode prompting drive branches with a choice that has no meaning.

## Policies

- `implementation/directory-structure` — the detector stays in its role-named `scripts/` slot.
- `implementation/coding-standards` — the predicate keeps its contract: it answers "is this branch a trip", not "does any trip exist".
- `implementation/test` — the boundary condition to target deliberately: a repo holding another branch's trip dir must still detect drive mode.

## Implementation Steps

1. Scope `has_trips` to the current branch in `plugins/workaholic/skills/branching/scripts/detect-context.sh`, mirroring the `USER_SLUG` precedent sitting three lines below it. The trip↔branch association is what needs deciding — a trip's directory is `.workaholic/trips/<trip-name>/` and the legacy `trip/*` branch case (lines 68-78) already carries a `trip_name`, so use the association the repo already relies on rather than inventing one. Look at how `report/SKILL.md` step 3 decides "a trip directory exists **for this branch**" and use the same test; two different answers to one question is how this defect was born.
2. **Preserve the `trip/*` legacy floor.** Lines 68-78 force `mode: trip` for a `trip/*` branch even when `detect_mode()` says drive. That floor must survive — a `trip/*` branch is a trip by name, regardless of directories.
3. Update the **Mode Detection table** in `plugins/workaholic/skills/branching/SKILL.md`, which currently documents the bug as the contract (`trip` = "Trip artifacts exist, no tickets in todo"). Docs change with the behaviour, in the same commit.
4. `node scripts/build-plugins/build.mjs` — `detect-context.sh` has the widest footprint of any script in this batch: **four** bundled copies (`outputs/workflows/skills/{create-ticket,drive,report,ship}/branching/scripts/`). Then `verify.mjs`, `validate-metadata.mjs`, `posix-lint.sh`.

## Quality Gate

**Acceptance criteria** (assertions in `scripts/test-workflow-scripts.mjs`, temp repos, no network):

| case | must hold |
| --- | --- |
| **`work-*` branch + an unrelated trip dir + a user todo ticket** | `mode: "drive"` — **not** `hybrid`. This is today's bug, and it is the assertion the existing test gets backwards. |
| `work-*` branch + an unrelated trip dir + **no** tickets | `mode: "drive"` — not `trip`. The exact state of `work-20260715-112717` when `/report` misfired. |
| A branch **with its own** trip dir | `mode: "trip"` (or `hybrid` with tickets) — the real trip case must still detect. |
| `trip/*` legacy branch, no trip dir at all | `mode: "trip"` — the name-based floor survives. |
| `main` → `unknown`; `drive-*` → `drive`; `feature-xyz` → `unknown` | unchanged. No regression in the branch-pattern routing. |

**Rewrite the test that encodes the bug.** `testDetectContext` (≈lines 168-212) currently asserts that branch `work-20260528-foo` + a bare `.workaholic/trips/some-trip` dir + a ticket ⇒ **`hybrid`**. That assertion states the defect as the contract, and it is the one test this fix must break. Correcting it *is* the proof — a green suite that still contains it would mean nothing changed.

**The gate:**

1. **Watch it fail first.** `git checkout HEAD -- plugins/workaholic/skills/branching/scripts/detect-context.sh` (never `git stash`, which removes the tests with the fix and passes vacuously), confirm the corrected assertions go RED, restore.
2. Full suite green (648+ passing, 0 failed); `posix-lint.sh` conforming; `verify.mjs`, `validate-metadata.mjs` pass.
3. `node scripts/build-plugins/build.mjs` then `git status --porcelain outputs/` is **empty** — four bundled copies.
4. **Drive the real thing, not only the fixture:** run `bash plugins/workaholic/skills/branching/scripts/detect-context.sh` on a `work-*` branch in this repository (which holds the March trip dir) and confirm it reports `drive`. The hermetic test proves the logic; this proves the actual repository that exhibited the bug.

## Findings

- **Blast radius is small and known.** Exhaustive grep of `plugins/`, `outputs/` and `scripts/` finds only two live consumers of `detect-context.sh`: `commands/ship.md:22`, which reads `context` only and never touches `mode`; and `report/SKILL.md:56,65`, which routes `mode` to the Drive/Trip/Hybrid sections. Since those three sections run identical orchestration, the single user-visible change is that `/report` stops asking drive branches to choose.
- The OKF `index.md` at `.workaholic/trips/index.md` is already excluded correctly by `-type d`; the count is of directories, not files. That part is fine.

## Considerations

- Do not solve this by deleting or relocating the March trip directory. It is a legitimate historical artifact and `trips/` is the recorded *why* behind past work; the detector is what is wrong.
- If no clean branch↔trip association exists, say so rather than inventing a fragile one (e.g. matching on branch name inside `plan.md`). A detector that is wrong in a *new* way is worse than one that is wrong in a known way — record the finding and propose the association as its own decision.

## Final Report

Development completed, but **not as planned** — the Considerations' escape hatch fired, and the developer took it.

**The finding: no branch↔trip association exists at all.** The ticket's step 1 assumed one could be reused ("use the association the repo already relies on"). It cannot, because for a modern `work-*` branch there is none. Verified on four independent points:

- `init-trip.sh` records no branch anywhere.
- `plan.md` frontmatter carries `instruction`/`phase`/`step`/`iteration`/`updated_at` — no branch. Confirmed on the real March artifact.
- `read-plan.sh` exposes no branch field.
- A trip's branch comes from `create.sh` as an independent `work-YYYYMMDD-HHMMSS`, unrelated to the trip name.

The only association that exists is the legacy `trip/<name>` → `trips/<name>` naming convention.

**This forced a conflict between the ticket's own two halves**, which is why it went back to the developer rather than being resolved silently. The Quality Gate demanded "a branch with its own trip dir → `mode: trip`"; the Considerations forbade inventing the association that row requires. Both could not hold. The developer chose the **narrow fix**: `has_trips` is now sourced solely from the legacy `trip/<name>` association, so a `work-*`/`drive-*` branch never claims a trip. The "own trip dir" gate row is satisfied only for `trip/*` branches — it is currently unrepresentable for `work-*` ones, and that row was dropped as such rather than faked.

Two candidate associations were costed and rejected as decisions too big to make inside a bugfix: a **git-history** test (untracked, or introduced by `main..HEAD`) — attractive because it needs no new metadata and reuses the trunk assumption the script already makes at line 81, but it silently decides the association and misreads stacked branches; and **stamping `branch:` into `plan.md`** — which is literally the anti-example the Considerations name, and breaks when a trip is resumed on another branch.

**Gate results.** Watched it fail first (backing the file up before reverting, not after — see the insights): the two corrected `work-*` assertions went red on the old script, then green. Full suite 694 passed / 0 failed. Real-repository check, which is the one that matters here: this branch, still holding `.workaholic/trips/trip-20260319-040153/`, now reports `{"mode": "drive"}` where it reported `trip` this morning. `posix-lint` conforming; `verify.mjs` and `validate-metadata.mjs` pass; `build.mjs` touched exactly the four bundled copies the ticket predicted.

### Discovered Insights

- **Insight**: The trip path is **inoperative end-to-end for modern branches, not merely mis-detected** — a strictly larger finding than the ticket describes. `detect-context.sh` emits `trip_name` only for `trip/*` branches, so `report/SKILL.md`'s Trip Mode step 3 ("if a `.workaholic/trips/<trip-name>/` directory exists for this branch") cannot resolve `<trip-name>` on a `work-*` branch either.
  **Context**: This reframes the deferred work. The follow-up is not "scope a boolean" but "define the trip↔branch association", and it must answer `has_trips` **and** `trip_name` together — two consumers, one missing fact. Fixing either alone leaves the other silently wrong. It also explains why the impact was nil: the mode was wrong, but nothing downstream could act on it anyway.

- **Insight**: The ticket's Motivation is the strongest argument in it: this defect was **written down verbatim in a story and shipped anyway** (`work-20260713-144839.md:124`), because a story observation carries no obligation — no ticket, no concern, so the corpus never held it and it resurfaced two days later.
  **Context**: The lesson generalizes past this fix. `/report`'s section 6 is the seam where an observation becomes a tracked obligation; anything noticed but left in prose is, in practice, discarded. That is precisely what makes the deferred association above worth filing rather than leaving in this report.

- **Insight**: The asymmetry was the tell, and it was visible in three lines of one function. The ticket half was scoped to `USER_SLUG` **with a comment explaining why**; the trips half three lines above was repo-wide. A reviewer who asked "why is one predicate scoped and its neighbour not?" would have found this in March.
  **Context**: Two predicates feeding one decision should share a scope, and a comment justifying one of them is a standing invitation to ask about the other. Worth noting the archived concern `30-the-detect-context-sh-change-introduces` flagged exactly this class and was marked **resolved** — for the ticket half only. "Resolved" on a class-level concern deserves a check that every member of the class was actually fixed.
