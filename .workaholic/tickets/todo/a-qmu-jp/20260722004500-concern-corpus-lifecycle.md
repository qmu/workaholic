---
created_at: 2026-07-22T00:45:00+09:00
author: a@qmu.jp
type: feature
layer: [Application]
effort: M
commit_hash:
category:
depends_on:
---

# Reduce deferred-concern pile-up: corpus-wide judging, executable verification, lane scoping, and extraction hygiene

## Policies

- `objective-documentation` — every proposed mechanism must leave an auditable trail (who closed what, on what evidence), same as the existing mutators.
- Shell Script Principle — new behavior lands as scripts under the owning skill's `scripts/`, not inline prose in SKILL.md.
- Backward compatibility — existing concern files (already-migrated identity fields) must keep working; migrations stay idempotent and best-effort, like `migrate-concern-identity.sh`.

## Quality Gate

- **Acceptance**: each shipped mechanism is demonstrated on a synthetic corpus fixture (concerns that should auto-close, split, or be filtered actually are), with the verdict trail visible in `archive/`.
- **Verification**: unit-style fixture runs for the scripts; `list-active-deferred-concerns.sh` envelope changes covered by a fixture that exercises the new filters/counters.
- **Gate**: no change may close a concern without recording evidence; `accepted` (won't-fix) closures must still require explicit developer confirmation.

## Overview

An adopting repository's active concern corpus grew past 100 items within weeks (1 urgent / ~45 moderate / ~55 low) and a manual triage found clear structural tendencies. Each tendency below maps to a mechanism the plugin could own, so corpora shrink by design instead of by heroic cleanup missions.

Observed tendencies (from a full manual triage of ~100 active concerns):

1. **Resolution is branch-scoped, so cross-branch fixes never close concerns.** The report-time judge only credits work on the *current* branch (`origin_commit..HEAD`). A concern fixed by any other branch stays active forever; the corpus only ever grows between deliberate cleanups.
2. **Aggregate "carried-over N items" placeholder concerns are debris.** ~13% of the corpus were aggregate blocks ("N carried items from earlier PRs") that name no single risk. They were created at extraction time and then survived every judge pass because nothing can "fix" an aggregate.
3. **The largest disposition class is "verification pending".** Many concerns state a concrete, executable check ("re-run X and confirm Y") — but nothing ever runs it, so they idle as active despite being one command away from closure.
4. **Lane mixing inflates everyone's triage.** Concerns owned by one developer's mission lane surface in every developer's report and count toward the shared `CONCERN_TRIAGE_THRESHOLD`, so the triage prompt fires on people who cannot act on the majority of the items.
5. **Low severity has no decay.** More than half the corpus is `low` with aging `last_seen` and no expiry pressure, crowding the view.

## Implementation Steps

1. **Corpus-wide judge mode** — add a standalone pass (a `/triage` command mode or a report Phase-1 variant) that judges every active concern against the *current default-branch HEAD state* (referenced paths exist? flagged pattern still present? described behavior still reproducible?), not just the active branch's commit range. Verdicts apply through the existing `apply-deferred-concern-verdicts.sh`, keeping the audit trail identical.
2. **Executable verification field** — support optional `verify_command:` (or a structured `verify:` block) in concern frontmatter. The judge (report-time or corpus-wide) runs it when present and closes with the captured output as evidence; a failing check keeps the concern active and records the failure. Extraction should encourage authors to fill it when the concern's How-to-Fix is really "run this and confirm".
3. **Extraction hygiene for aggregates** — make `extract-deferred-concerns.sh` refuse (or split into linked singles) any section-6 block whose title matches an aggregate carry shape ("carried N items", "持ち越しN件"), and add an idempotent migration that collapses existing placeholder aggregates into their member concerns or closes them as superseded.
4. **Lane/owner scoping** — allow optional `mission:`/`owner:` frontmatter on concerns (inherited from the story's `mission:` at extraction). `list-active-deferred-concerns.sh` gains per-owner counts and a filter, and the triage trigger fires on the *actor's own* lane count rather than the global total. Unowned concerns stay visible to everyone (same spirit as unassigned missions in the mission lens).
5. **Staleness decay proposal** — when a concern's `last_seen` has not been refreshed for N ships *and* its referenced paths no longer exist, have the judge emit a `close-stale` proposal (never an auto-close without evidence); optionally a policy knob for low-severity expiry review.

## Considerations

- Keep "judge proposes / developer decides" for anything irreversible: `accepted` closures and severity re-grades stay behind explicit confirmation; only evidence-backed stale/verified closures may be auto-applied, and even those must write their rationale.
- The corpus-wide judge is the highest-value single change: it converts the corpus from append-only to self-cleaning, and tendencies 2/3/5 all become cheaper once it exists.
- Lane scoping should not hide risk: global counts remain available (e.g. `--all`), only the *prompting* becomes lane-aware.
