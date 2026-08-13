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

## Final Report

Development completed as planned.

### Open Decisions — resolved

- **Which document is "the Release Note" here?** Resolved as **(i), the per-branch note**
  (`.workaholic/release-notes/<branch>.md`), which gains a `## Deployment Plan` section.
  Reasoning, in the order it decided the question: (a) the ask's own word is "Release
  Note", and this is the only artifact in the tree carrying `type: Release Note`; (b)
  option (ii) is refused by the repository's own written rule — `.workaholic/releases/` is
  "derived from git, never hand-authored" — and a drafted plan is the opposite of derived;
  (c) option (iii) would create a *third* artifact competing for the same name, which is
  exactly the confusion this ticket's Considerations warn about, and would cost both
  lockstep sources plus OKF plumbing to register; (d) the note is written at the ship
  seam, which is precisely where the plan is drafted — one document, one seam. The
  mission's own `## Experience` ("It leaves a Release Note whose plan says, per target
  …") reads naturally as one note carrying an entry per target, and that is what was
  built. **No new area was introduced, so `layout-doctor.sh` is unaffected.**

- **Is the plan mutable?** Resolved as **mutable within a branch, append-only across
  branches**. The section is regenerated in place on every refresh — it is a draft, and
  drafts are rewritten — but each ship writes its own note file, so the *tree* stays
  append-only history and `history-structures.md` holds. A merged note's plan becomes the
  permanent record of what was planned at that ship. The conflict worry in the ticket does
  not materialise: only the current, unmerged branch's note is ever rewritten, and
  `catchup-main.sh`'s append-only `.workaholic/` resolution never has two sides to
  reconcile on a note that exactly one branch owns.

### Discovered Insights

- **Insight**: the first idempotence attempt was not idempotent, because stamping
  `targets:` made the note match *itself* as "the latest note for this target" — the
  answer flipped `recency` → `declared` on run 2 and only settled on run 3.
  **Context**: A self-referential lookup is the specific way an "obviously idempotent"
  regenerator fails: nothing about the rendering is time-varying, but the *input* includes
  the output. `--exclude-note` is the fix, and the general rule is that a writer feeding a
  reader that scans the writer's own output area must exclude its target.

- **Insight**: the plan section deliberately carries no timestamp — its datum is the
  base's commit sha.
  **Context**: `released_at`-style stamping is the reflex for a `.workaholic/` document,
  and it is exactly what makes a refresh non-idempotent. The sha is both a stabler datum
  and a more useful one: a reader can check the plan against `git log` from it.

- **Insight**: a `${CLAUDE_PLUGIN_ROOT}` script reference in `write-release-note` breaks
  the generated bundle — `verify.mjs` reports `MISS` because the prose-only skill's
  closure carries no `ship/scripts/`.
  **Context**: The skill is publicly exposed, so its guidance has to name the *skill* that
  owns a mechanic rather than the script path. `verify.mjs` catches this, but it exits 0
  while reporting the misses, so the line has to be read rather than waited for.
