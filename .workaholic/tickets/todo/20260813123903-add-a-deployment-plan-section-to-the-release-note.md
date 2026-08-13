---
created_at: 2026-08-13T12:39:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: draft-deployment-plans-in-the-release-note-before-deploying
merge_policy:
---

# Add a deployment plan section to the Release Note

## Overview

PROPOSED. Issue #438's step 2: the Release Note should say "what deployment is needed for which target and what verification is required". That is a section the note does not have, and — more importantly — a *tense* the note does not have. Every one of the 96 notes in `.workaholic/release-notes/` is retrospective and per-branch (`type: Release Note`, `branch: work-*`, `pr:`), written at ship step 5 from a branch that is about to merge, describing what changed. A deployment plan is prospective and per-target, and it is refreshed rather than written once.

This ticket defines that artifact shape and the writer that fills it: which document holds the plan, what one target's entry contains (what is waiting, which procedure applies, which verification is required), and how a refresh is idempotent so a periodic run does not churn the file. `workaholic:write-release-note` owns the note's content structure today and is where the section is specified.

## Policies

- `workaholic:planning` / `policies/modeling-centric-design.md` — decide the artifact before the writer; this is the ticket where that decision is made
- `workaholic:implementation` / `policies/objective-documentation.md` — a plan a reader cannot check against the repository is not a plan
- `workaholic:operation` / `policies/ci-cd.md` — the delivery path the plan describes
- `workaholic:design` / `policies/history-structures.md` — an append-versus-rewrite ruling for a document a periodic agent touches

## Key Files

- `plugins/workaholic/skills/write-release-note/SKILL.md` — the release note's content structure; the plan section is specified here (a publicly exposed, prose-only skill — it must stay script-free).
- `plugins/workaholic/skills/ship/scripts/commit-release-note.sh` — commits and pushes the note; a failed push is already a pre-merge hard stop, and a refresh path must not weaken that.
- `.workaholic/release-notes/work-20260807-004323.md` — a representative note: retrospective, per-branch, Added/Changed/Removed/Upgrading.
- `.workaholic/release-notes/index.md` — OKF-indexed; a new document shape must stay regenerable by `okf/scripts/refresh-index.sh`.
- `plugins/workaholic/skills/ship/scripts/record-release-cut.sh` and `.workaholic/releases/` — the *other* artifact with a claim to this content: batch-level, derived from git, "never hand-authored".
- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` and `plugins/workaholic/rules/workaholic.md` — the two lockstep sources, if the plan lands in a new or currently-unused area (`releases/` is allowlisted and empty).
- `plugins/workaholic/hooks/validate-story.sh` — the pattern for a write-time schema floor, should the plan need one.

## Implementation Steps

1. Resolve the artifact fork recorded under Open Decisions and write the resolution down before any code: which document holds the plan, and whether it is per-branch, per-release-window, or per-target.
2. Specify one target's plan entry: the target, the deploy model, what is waiting to deploy (from the sibling reader's range), the procedure that would run, and the verification that would be required — each field traceable to something the reader returned, never invented prose.
3. Specify the plan's tense and lifecycle in the skill: a plan is a *draft* until a deployment is instructed, and what happens to it afterwards (superseded, ticked, or carried into the record the next ticket writes).
4. Make the refresh idempotent: re-running against an unchanged base must leave the file byte-identical, so a periodic agent's no-op commits nothing. State this as the writer's contract, not as a nicety.
5. Wire the writer at the seam the sibling `/ship` ticket defines, keeping `write-release-note` prose-only — any shell belongs in `ship/scripts/`.
6. If a new area or a new `type:` value is introduced, register it in both lockstep sources and extend the OKF index refresh in the same change.
7. Update `.workaholic/README.md`, `README.md`, `CLAUDE.md` and `plugins/workaholic/rules/workaholic.md` for the new document shape; regenerate `outputs/` with argument-less `node scripts/build-plugins/build.mjs`.

## Open Decisions

Resolve explicitly while driving and record the resolution in the Final Report.

- **Which document is "the Release Note" here?** The repository has two artifacts with a claim to the name and neither fits as-is: `.workaholic/release-notes/*.md` is per-branch and retrospective (96 files, written at ship step 5), while `.workaholic/releases/<release-branch>.md` is the batch-level ship record, derived from git and documented as never hand-authored. Options: (i) add the plan section to the per-branch note, which makes a plan per merged branch; (ii) put it in the release record, which contradicts "derived from git, never hand-authored"; (iii) introduce a per-target or per-window plan document. The ask says "Release Note" and the reporter may mean either; this session cannot recommend one.
- **Is the plan mutable?** A draft kept current by a periodic agent is rewritten; the `.workaholic/` convention is append-only history (`history-structures.md`, and `catchup-main.sh` resolves `.workaholic/` conflicts as append-only). A rewritten plan file will conflict differently from every other artifact in the tree.

## Quality Gate

Provisional — sharpened by the interrogation that replans this mission to drive-ready.

**Acceptance criteria** — the checkable conditions that must hold:

- The chosen document carries a deployment-plan section with one entry per target, each naming what needs deploying, the procedure, and the required verification.
- Every field in an entry is traceable to the consolidation reader's output; nothing in the section is prose a reader cannot check against the repository.
- Re-running the writer against an unchanged base leaves the file byte-identical.
- If a new area or `type:` was introduced, both lockstep sources and the OKF index carry it, and `layout-doctor.sh` reports `conforming: true`.

**Verification method** — the commands/tests/probes that prove them:

- Write the plan for this repository's `marketplace` target and read it back; the pending item and its verification match `.workaholic/deployments/marketplace.md`.
- Run the writer twice; `git status --porcelain` is empty after the second run.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` conforming; `node scripts/test-workflow-scripts.mjs`, `build.mjs` and `verify.mjs` green.

**Gate** — what must pass before approval:

- The artifact decision recorded in the Final Report, the idempotence demo, and the suite/build/layout checks green.

## Considerations

- The deploy-on-merge case is the one that makes this section worth writing and the one most likely to read wrong: for `marketplace.md` the code is already on `main`, so "what needs deploying" is the tag and the published release, not the commits. A plan that lists commits as "to deploy" for that target would be actively misleading.
- Keep the retrospective note and the prospective plan distinguishable in the document itself. A reader who cannot tell "this shipped" from "this is proposed to ship" is worse off than one with no plan.
- `write-release-note` is exposed to non-Claude agents through the generated bundle, so its guidance must not assume Claude Code's tooling.
