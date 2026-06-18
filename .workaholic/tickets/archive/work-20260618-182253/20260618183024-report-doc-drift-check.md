---
created_at: 2026-06-18T18:30:24+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort: 2h
commit_hash: 66d30d2
category: Added
depends_on:
---

# `/report`: assess documentation drift (README, CLAUDE.md, SKILL.md, docs/) against the branch's changes

## Overview

When `/report` assesses a branch, it should surface the meta/documentation files that **shouldn't** have drifted out of sync with the branch's code/structure changes but did — so stale docs are caught before ship rather than discovered later (the just-ticketed `/trip` lag and the recent README policy-index/Mermaid drift are concrete examples of exactly this failure mode).

Today the `## Assess Release Readiness` section of `workaholic:report` lists "Documentation that needs updating" as an impressionistic actionable item; there is no systematic check of the branch diff against the doc/meta files that index the code. Add that check.

**Approach** (keeps the script deterministic and leaves judgment to the model, mirroring the carry-over judge):
- A new bundled POSIX-sh script `plugins/workaholic/skills/report/scripts/doc-drift.sh` emits structured **facts** from the branch diff: which structural files changed (added/renamed/removed skills under `plugins/workaholic/skills/`, commands, agents, hooks, scripts), and whether the index/meta docs (`CLAUDE.md`, `README.md`, the relevant `SKILL.md`) were touched in the same branch.
- The existing **release-readiness** leaf subagent (already spawned in Phase 2) consumes those facts plus the diff and **judges** which candidates are real drift, then surfaces them.
- Findings surface in **two** places: as release-readiness actionable items (story Section 8 — the ship gate), and, for confirmed drift, as a durable Section 6 Concern (via `workaholic:review-sections`) so it carries over on `/ship` if not fixed first.

**Scope notes from discovery:**
- The "shouldn't-drift" target set in this repo: `README.md` (root), `CLAUDE.md` (root), the 18 `SKILL.md` files under `plugins/workaholic/skills/<name>/`, and the 5 rules under `plugins/workaholic/rules/`. **`docs/` does not exist in this repo** — treat it as a forward-looking/optional target the script checks only if present (so the feature works in consuming projects that do have `docs/`).
- **Do not duplicate existing guards.** `outputs/` freshness is owned by `.github/workflows/outputs-freshness.yml` + `verify.mjs`, and version/manifest lockstep by `validate-metadata.mjs` + CLAUDE.md Version Management. The drift check must **exclude** `outputs/` staleness and version-number drift and focus on prose/structural doc-vs-code drift.
- Respect "What NOT to Flag": a drift finding must be **actionable** (a specific doc that should have changed and didn't), never a theoretical/internal-refactor warning.

## Key Files

- `plugins/workaholic/skills/report/SKILL.md` - PRIMARY. Extend `## Assess Release Readiness` (lines ~596-620) with a drift-scan Analysis Task and a "Documentation Drift" subsection; its release-readiness JSON already maps to story Section 8 (lines ~466-502). Worker fan-out is at lines ~126-134.
- `plugins/workaholic/skills/report/scripts/doc-drift.sh` - NEW bundled POSIX-sh script that emits the drift facts JSON from `<base>..HEAD`.
- `plugins/workaholic/skills/review-sections/SKILL.md` - Section 6 Concerns (lines ~46-71) is composed from still_active carry-overs + ticket Considerations; add confirmed drift as a third Concerns source so it persists via the carry-over pipeline. **Keep this skill script-free** (it is an intentionally-exposed pure-prose skill — no `metadata.internal`, no `${CLAUDE_PLUGIN_ROOT}`); reference the drift facts the release-readiness leaf already computed rather than calling the script here.
- `plugins/workaholic/skills/gather/scripts/git-context.sh` - Already resolves `base_branch` (from `git remote show origin`); reuse that base, don't hardcode `main`.
- `plugins/workaholic/skills/report/scripts/collect-commits.sh` - The shape to copy for the new script (parameterized base `${1:-main}`, JSON output).
- `scripts/test-workflow-scripts.mjs` - Add a hermetic smoke test for `doc-drift.sh` (throwaway temp repo, JSON assertions, no working-tree/gh/network touch).
- `.github/workflows/outputs-freshness.yml`, `scripts/build-plugins/verify.mjs`, `scripts/build-plugins/validate-metadata.mjs` - Existing guards to ALIGN WITH (exclude their domains); reference only, not edited.

## Related History

Documentation/artifact drift is a recurring failure mode here, caught so far only reactively or by narrow automated guards (outputs freshness, version lockstep, standards-sync) — never a report-time prose check.

- [20260618182253-polish-trip-command-catch-up.md](.workaholic/tickets/todo/a-qmu-jp/20260618182253-polish-trip-command-catch-up.md) - Queued sibling: the canonical drift instance this feature would have caught (the `/trip` surface lagging post-merge changes). A **consumer/motivator**, not a duplicate — that ticket manually remediates one drift; this one builds the detector. Not a hard dependency.
- [20260618100047-fix-readme-mermaid-and-policy-sync.md](.workaholic/tickets/archive/work-20260618-100127/20260618100047-fix-readme-mermaid-and-policy-sync.md) - Recent README drift (stale 3-pillar policy index after the `planning` pillar landed, obsolete namespace, Mermaid rule violation) — prime target for the proposed check.
- [20260212230145-fix-stale-skill-references-in-generated-docs.md](.workaholic/tickets/archive/main/20260212230145-fix-stale-skill-references-in-generated-docs.md) - Prior drift incident: generated docs carried stale references to renamed skills. Shows source-rename vs dependent-doc drift is a known recurring failure.
- [20260514154717-thin-report-umbrella-into-skill.md](.workaholic/tickets/archive/work-20260417-092936/20260514154717-thin-report-umbrella-into-skill.md) - Established the report architecture (thin command + comprehensive skill + parallel release-readiness/overview/section-reviewer leaves) — where the new check slots in.
- [20260519110656-propagate-concerns-and-ideas-as-carryover.md](.workaholic/tickets/archive/work-20260518-235327/20260519110656-propagate-concerns-and-ideas-as-carryover.md) - Defines the `.workaholic/concerns/` carry-over pipeline the durable drift findings would feed into rather than reinvent.

## Implementation Steps

1. **Write `plugins/workaholic/skills/report/scripts/doc-drift.sh`** (POSIX sh, `#!/bin/sh -eu` + `set -eu` fallback; no bash-isms, no arrays/`[[ ]]`):
   - Accept the base branch as `${1:-main}` (reuse the report workflow's resolved `base_branch`).
   - Compute the changed-file list once: `git diff <base>..HEAD --name-only`.
   - Classify changes into **structural signals**: skills added/renamed/removed (`plugins/workaholic/skills/<name>/`), commands (`plugins/workaholic/commands/`), agents (`plugins/workaholic/agents/`), hooks (`plugins/workaholic/hooks/`), top-level `scripts/`.
   - Determine whether the **index/meta docs** were touched in the same range: `CLAUDE.md`, `README.md`, each affected skill's own `SKILL.md`, and `docs/` **only if the directory exists**.
   - Emit JSON facts (NOT verdicts), e.g.:
     ```json
     {
       "base": "main",
       "structural_changes": [{"kind":"skill_added","path":"plugins/workaholic/skills/foo/"}],
       "meta_docs": {"CLAUDE.md":{"changed":false},"README.md":{"changed":false}},
       "docs_dir_present": false,
       "candidates": [{"signal":"skill_added","doc":"CLAUDE.md","reason":"new skill foo/ but CLAUDE.md (which enumerates skills) unchanged"}]
     }
     ```
   - **Degrade gracefully** (operation policy): a detached/missing base ref, no `README`, or no `docs/` returns an empty/`not_applicable` result with exit 0 — never error the whole report. Exclude `outputs/` and version/manifest files entirely (other guards own them).
2. **Extend `## Assess Release Readiness`** in `report/SKILL.md`:
   - Add an Analysis Task that runs `bash ${CLAUDE_PLUGIN_ROOT}/skills/report/scripts/doc-drift.sh "<base_branch>"` and, for each `candidate`, has the leaf **judge** against the diff + doc content whether it is real, actionable drift (a doc that genuinely should have been updated). Keep all logic in the script — the SKILL prose must contain no inline conditionals/pipes/grep/sed (Shell Script Principle).
   - Specify that confirmed drift becomes: (a) a release-readiness `concerns[]` entry + `pre_release` instruction (Section 8 gate), and (b) a durable Section 6 Concern. Update the "Identify actionable items" / "What NOT to Flag" prose to name the drift check and its exclusions (no `outputs/`, no version drift, no theoretical warnings).
3. **Wire the durable finding into Section 6** (`review-sections/SKILL.md`): add "confirmed documentation drift" as a third Concerns source, rendered in the exact `### / **Severity:** / **Description:** / **How to Fix:**` block format (so `extract-carryover.sh` parses it on `/ship`). Keep the skill script-free and self-contained.
4. **Add a hermetic smoke test** to `scripts/test-workflow-scripts.mjs` for `doc-drift.sh`: create a throwaway temp repo, commit a base, branch and add a fake skill dir without touching `CLAUDE.md`, run the script, assert the JSON reports the `skill_added` candidate; add a negative case (doc touched → no candidate) and a graceful-degradation case (no `docs/`, missing base). No working-tree/`gh`/network access.
5. **Regenerate and verify**: `node scripts/build-plugins/build.mjs` (the report skill + its script closure changed, so `outputs/workflows/` must be regenerated and committed), then `node scripts/build-plugins/verify.mjs`, `node scripts/build-plugins/validate-metadata.mjs`, and `node scripts/test-workflow-scripts.mjs`. Confirm CI Outputs Freshness would pass (no uncommitted `outputs/` diff).

## Patches

> **Note**: Speculative — line numbers approximate; verify exact surrounding text before applying. The new `doc-drift.sh` is a new file (no diff shown).

### `plugins/workaholic/skills/report/SKILL.md`

```diff
--- a/plugins/workaholic/skills/report/SKILL.md
+++ b/plugins/workaholic/skills/report/SKILL.md
@@ ### Analysis Tasks
 2. **Check for blocking issues**:
    - Tests failing (if tests exist)
    - Type errors (if type checking exists)
    - Missing files referenced in code
 
+3. **Assess documentation drift**: run
+   `bash ${CLAUDE_PLUGIN_ROOT}/skills/report/scripts/doc-drift.sh "<base_branch>"`
+   to get the drift facts (structural changes vs. whether the index/meta docs were
+   touched). For each `candidate`, judge against the diff and the doc's content
+   whether a meta/doc file (`CLAUDE.md`, `README.md`, an affected `SKILL.md`, or
+   `docs/` when present) genuinely should have been updated and was not. Confirmed
+   drift becomes a release-readiness concern + a `pre_release` instruction, and is
+   also emitted as a durable Section 6 Concern (see `workaholic:review-sections`).
+   Exclude `outputs/` staleness and version/manifest drift — the Outputs Freshness
+   CI and `validate-metadata.mjs` own those.
+
-3. **Identify actionable items** (not theoretical concerns):
+4. **Identify actionable items** (not theoretical concerns):
    - Documentation that needs updating
    - Version numbers to bump
    - Files to stage/commit before release
 
 ### What NOT to Flag
 
 - "Breaking changes" for command renames - users adapt
 - API changes in a plugin - plugins are configuration, not APIs
 - Internal refactoring - doesn't affect users
 - Theoretical upgrade concerns - users pull fresh versions
+- Doc drift the existing guards already own: `outputs/` staleness (Outputs Freshness CI) and version-number mismatches across manifests (`validate-metadata.mjs`)
```

## Considerations

- **Implementation + Operation are the binding lenses.** `workaholic:implementation` (directory-structure: script under `skills/report/scripts/`, knowledge in the SKILL.md; coding-standards: strict POSIX sh, deterministic JSON) and `workaholic:operation` (the release-readiness verdict gates `/ship`, so the check must degrade gracefully and never false-block an otherwise-shippable branch). `design`/`planning` do not bind.
- **Heuristic, not omniscient** — a script cannot know intent, so it emits *facts/candidates* and the release-readiness leaf judges, exactly like the carry-over judge. Keep false positives low: structural add/rename/remove with an untouched index doc is a strong signal; avoid flagging on every code edit (`plugins/workaholic/skills/report/scripts/doc-drift.sh`).
- **Shell Script Principle** — all diff parsing, classification, and presence checks live in `doc-drift.sh`; the SKILL.md prose only invokes it via `${CLAUDE_PLUGIN_ROOT}` and interprets the JSON. No inline `if`/`grep`/`sed`/pipes in markdown.
- **Don't duplicate existing guards** — exclude `outputs/` and version/manifest drift; align with `outputs-freshness.yml` and `validate-metadata.mjs` rather than re-checking their domains (`.github/workflows/outputs-freshness.yml`).
- **`docs/` is forward-looking** — it does not exist in this repo, so the script must treat it as optional (check only if present); the feature should still be useful in consuming projects that do have `docs/`.
- **Regenerate `outputs/`** — this changes a workflow skill and its script closure, so `outputs/workflows/` must be rebuilt and committed or CI fails; `review-sections` must stay script-free so it keeps resolving cross-agent via the `skills` CLI.
- **One-level fan-out / no new agent file** — the work runs inside the existing release-readiness `general-purpose` leaf; do not add a new worker or agent `.md`. On non-Claude agents the same logic runs sequentially in-session with identical inputs/outputs.
- **Routing choice (decided, but flag for the implementer):** findings surface both as a Section 8 release gate and a durable Section 6 Concern. If the implementer finds the double-surfacing noisy, Section 6 (carry-over durable) is the higher-value of the two — confirm with the requester before dropping either.

## Final Report

Development completed as planned. The double-surfacing routing (Section 8 gate + Section 6 durable Concern) was kept as specified.

### Discovered Insights

- **Insight**: The `doc-drift.sh` candidate logic deliberately fires only on **presence** changes (git status A/D/R/C), never on plain content edits (M). The smoke test pins this by merging a skill add onto `main` and then editing it on the branch — confirming a content-only `M` produces zero candidates.
  **Context**: The Considerations warned "avoid flagging on every code edit." Restricting to presence changes is what keeps the check from false-blocking; any future broadening to content edits would reintroduce that noise and should be gated behind the judge, not the script.
- **Insight**: `outputs/`, version manifests, and the script's own exclusions never reach the candidate stage because they fail the category `case` (they are not under `skills/|commands/|agents/|hooks/|scripts/`) — the exclusion is structural, not a separate filter.
  **Context**: The `verify.mjs` rewrite placed the new script at `outputs/workflows/skills/{report,ship}/report/scripts/doc-drift.sh` (ship's closure includes report); confirming the build is transitive, not per-skill.
