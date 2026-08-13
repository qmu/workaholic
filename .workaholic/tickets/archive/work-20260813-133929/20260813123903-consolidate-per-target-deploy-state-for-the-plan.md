---
created_at: 2026-08-13T12:39:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: draft-deployment-plans-in-the-release-note-before-deploying
merge_policy:
---

# Consolidate per-target deploy state for the plan

## Overview

PROPOSED. Issue #438's step 1: "consolidate the latest release notes, deployment target info, commit messages, and commit history for each deployment target defined under `Deployments` in `.workaholic` on the latest `main`". Everything after it — the drafted plan, the developer's review, the recorded verification — reads from this consolidation, so it is the first unit.

Today nothing produces it. `ship/scripts/read-deployments.sh` reads the target records (`## Procedure`, `## Confirmation`, `confirmation_method`) but knows nothing about what is *waiting* to deploy; `.workaholic/release-notes/` holds 96 per-branch notes with no "latest per target" reader; and the unreleased range is derived only inside `record-release-cut.sh`, for the batch as a whole. This ticket adds one read-only reader that joins the three, on the base rather than on a work branch: for each target, its record, the most recent release note that names it, and the merged-but-unreleased commit range with subjects.

## Policies

- `workaholic:operation` / `policies/ci-cd.md` — the delivery path this reader describes
- `workaholic:implementation` / `policies/command-scripts.md` — a workflow script's JSON envelope and refusal reasons
- `workaholic:implementation` / `policies/objective-documentation.md` — a derived range must name how it was chosen
- `workaholic:planning` / `policies/modeling-centric-design.md` — model the per-target state before wiring a writer to it

## Key Files

- `plugins/workaholic/skills/ship/scripts/read-deployments.sh` — the existing per-target reader; the new script composes it rather than re-parsing the records.
- `plugins/workaholic/skills/ship/scripts/record-release-cut.sh` — already derives an unreleased range with a `since_reason`; the precedent to follow, not to duplicate.
- `plugins/workaholic/skills/propose/scripts/survey-state.sh` — the shape to copy: composes existing readers, names `since_reason`, never parses frontmatter itself.
- `.workaholic/deployments/marketplace.md` — the only target that exists today; the reader must be honest with one target and with none.
- `.workaholic/release-notes/` — 96 notes keyed `branch: work-*`, `pr:`; there is no target field to join on yet (see Open Decisions).
- `plugins/workaholic/skills/ship/reference/scripts.md` — the script contract table this new entry joins.
- `scripts/test-workflow-scripts.mjs` — hermetic coverage; the suite creates throwaway repos and never calls the network.

## Implementation Steps

1. Define the reader's output envelope: one entry per target (`title`, `environment`, `confirmation_method`, deploy model), its latest release note (or `null`), and the unreleased range (`since`, `since_reason`, commit subjects) — plus a top-level `ok`/`reason` for an unreadable base.
2. Add `ship/scripts/read-deploy-state.sh` (name provisional) composing `read-deployments.sh` and the same git derivation `record-release-cut.sh` uses; no frontmatter parsing of its own.
3. Decide and record how "latest release note for this target" is resolved with no target field on the note — see Open Decisions; implement the resolution chosen, and report `unresolved` rather than guessing when it cannot be answered.
4. Make the empty and single-target cases explicit: zero targets returns an empty list with a reason, never an error; one target must not read as "everything".
5. Degrade rather than fail on a truncated clone or a missing tag: report the range's `since_reason` as `unresolvable`, as `survey-state.sh` does.
6. Add hermetic cases to `scripts/test-workflow-scripts.mjs`: no targets, one target with no prior note, one target with a prior note and a non-empty range, and an unresolvable range.
7. Document the script in `ship/reference/scripts.md`, and regenerate `outputs/` with argument-less `node scripts/build-plugins/build.mjs`.

## Open Decisions

Resolve explicitly while driving and record the resolution in the Final Report.

- **How is a commit attributed to a target?** The ask says "commit history for each deployment target", which presumes an attribution this repo has no data for: one target exists and no path→target mapping is recorded anywhere. Options: give every target the whole unreleased range (honest with one target, wrong with several); add path globs to the target record; or have each target declare the paths it ships. Do not silently pick the first because it happens to work here.
- **What is "the latest release note" for a target?** Notes are keyed by branch, not by target, so "latest" can only mean the newest note overall until the note carries a target — which is the sibling ticket's schema change. Options: depend on that ticket and join on the new field, or resolve by recency and report the weakness.

## Quality Gate

Provisional — sharpened by the interrogation that replans this mission to drive-ready.

**Acceptance criteria** — the checkable conditions that must hold:

- One read-only script returns, per `Deployments` target, the target's info, its latest release note (or an explicit null), and the unreleased commit range with a `since_reason`.
- It is honest about degradation: zero targets, no prior note, and an unresolvable range are each reported with a reason rather than as an error or an empty success.
- It parses no frontmatter of its own — the existing readers are composed.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, including the four new cases.
- The script run against this repository returns `marketplace` with a non-empty range and a named `since_reason`.
- `node scripts/build-plugins/build.mjs` then `verify.mjs` green with `outputs/` committed.

**Gate** — what must pass before approval:

- Suite, build and verify green, plus the live run above pasted into the Final Report.

## Considerations

- Read-only is the whole point of this unit: it must be safe to run on the base from an unattended tick, so it writes nothing and never checks a branch out.
- The two deploy models (`deploy-from-branch`, `deploy-on-merge`) answer "what needs deploying" differently — for a deploy-on-merge target the unreleased range is already *on* `main` and what is pending is the tag. The envelope must carry the model so the drafting step is not forced to re-derive it.
- Resist growing this into the plan writer. The next ticket owns the prose; a reader that also writes is the seam where the ask's "keep it up to date" quietly becomes "rewrite it every tick".

## Final Report

Development completed as planned.

### Open Decisions — resolved

- **How is a commit attributed to a target?** Resolved by **naming the answer instead of
  picking one silently**. The target record gains an optional `paths:` field; a target
  that declares it gets its unreleased range filtered to those paths and the reader
  reports `attribution: declared_paths`. A target that declares none gets the whole
  unreleased range and the reader reports `attribution: whole_range`. Reasoning: the ask
  presumes a path→target map the repository has no data for, and all three options in the
  ticket were about *which wrong-in-some-case default to hide*. Reporting the attribution
  makes the weakness readable at the point of use — honest with this repository's one
  target, visibly weak the moment a second appears — and `paths:` is how a multi-target
  repository upgrades the answer with no change to the reader.
- **What is "the latest release note" for a target?** Resolved as **both options, tiered
  and reported**. `read-release-notes.sh --latest-for <slug>` returns `match: declared`
  when a note's `targets:` names the slug, and `match: recency` when none does and the
  newest note overall was returned. The sibling ticket's writer stamps `targets:`, so the
  join strengthens from `recency` to `declared` as notes accumulate, without a migration
  and without this reader ever guessing. `match: none` for an empty area.

### Discovered Insights

- **Insight**: `read-deployments.sh` counted `.workaholic/deployments/index.md` — the
  OKF-generated index — as a deployment target, so this repository reported two targets
  where one exists.
  **Context**: The bug was invisible because `has_confirmation` is an OR across entries
  and the §1-4 gate only reads that flag, so a phantom target never changed a decision.
  The moment anything iterates targets — as the plan drafting does — it becomes a
  phantom plan entry. A reader that is only ever consumed as a boolean can carry a
  structural error indefinitely.

- **Insight**: tab is an IFS *whitespace* character, so `read -r` collapses adjacent tabs
  and shifts every later field whenever an optional value is empty. `--rows` uses `\037`.
  **Context**: This repository has already measured the same defect twice — `read_pulls`
  in `scripts/e2e/loop-drill.sh` carries a comment about an unmerged PR's empty
  `merged_at` shifting the body into the title, and `survey-state.sh` uses git's `%x1f`
  for the same reason. Any new tab-separated record format in this codebase is a
  regression waiting for its first empty middle field.

- **Insight**: the consolidation is repo-level in its *boundary* and per-target only in
  its *filter* — `since`/`since_reason` are derived once and shared.
  **Context**: The boundary comes from `.workaholic/releases/` records or the latest tag,
  neither of which is per-target. Deriving it per target would invite a future reader to
  assume targets can have different boundaries, which nothing in the tree supports.
