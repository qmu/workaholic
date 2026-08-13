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
