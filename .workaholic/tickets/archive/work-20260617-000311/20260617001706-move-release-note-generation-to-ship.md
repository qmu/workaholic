---
created_at: 2026-06-17T00:17:06+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash: 0a23ff0
category: Changed
depends_on:
---

# Move release-note generation from /report to /ship

## Overview

Today `core:report` generates the release note (Phase 5 step 2 spawns a
`core:write-release-note` worker that writes `.workaholic/release-notes/<branch>.md`,
Phase 6 commits and pushes it). This is the **foundation** ticket for the
ship-side release feature: relocate release-note **generation** to `/ship` so each
ship event produces its own note(s), which is the prerequisite for publishing a
GitHub Release on ship and for supporting **multiple releases per branch**.

After this change:
- `/report` stops generating release notes. Remove Phase 5 step 2 (the
  release-note worker) and Phase 6 (commit/push release notes); drop
  `release_note_writer` from the Report Output Schema and the Worker Output
  Mapping table. `/report` still creates the PR and the story.
- `core:ship`'s Ship Flow gains a **generate-release-note step that runs before
  the merge**, so the note file is committed to the branch and included in the
  merge to main (requirement #2 and #3). It feeds `core:write-release-note`
  (pure prose, cross-agent-exposed — unchanged) the story file plus the PR URL,
  which `pre-check.sh` already returns (`{found, pr_number, url, state, merged}`).
- Introduce a release-note **naming scheme that supports multiple notes per
  branch**, replacing the single `<branch>.md` convention (requirement #1).

This ticket only **moves generation and establishes the file scheme**; the actual
`gh release create` publishing and the CI-already-publishes detection live in the
dependent ticket [20260617001707-publish-github-release-on-ship.md].

## Key Files

- `plugins/core/skills/report/SKILL.md` - Remove Phase 5 step 2 ("Generate release note", L147-154) and Phase 6 ("Commit and Push Release Notes", L156-160). Update the Report Output Schema (L162-179, drop `release_note_file` / `release_note_writer`) and the Worker Output Mapping table (L190, drop the release-note-writer row). `/report` keeps Phase 5 step 1 (Create PR).
- `plugins/core/skills/ship/SKILL.md` - Add a "Generate release note" step to the Ship Flow (§5, L126-135) **before** Merge PR, and a short subsection describing how it invokes `core:write-release-note` with the story file + PR URL and commits the note to the branch. `allowed-tools` already includes `Bash, Read, Glob, Grep`.
- `plugins/core/skills/write-release-note/SKILL.md` - Update the **Output Location** section (L74-75) from the single `.workaholic/release-notes/<branch-name>.md` to the new multi-release scheme. Keep it **pure prose** — no bundled script, no `${CLAUDE_PLUGIN_ROOT}`, no namespaced preload (it is intentionally cross-agent-exposed; see CLAUDE.md Cross-Agent Skill Exposure).
- `plugins/core/skills/ship/scripts/pre-check.sh` - Already returns the PR `url` — the input `core:write-release-note` needs. No change expected, just the consumer.
- `plugins/work/commands/ship.md` - Thin command; add a one-line routing note that ship now generates the release note (no logic here).
- `.workaholic/release-notes/` - Current convention is one flat `<branch>.md` per branch (39 files). The new scheme changes this for multi-release.
- `dist/workflows/skills/report/`, `dist/workflows/skills/ship/`, `dist/workflows/skills/write-release-note/` - GENERATED mirrors; regenerate via `node scripts/build-plugins/build.mjs` (Dist Freshness CI guard).

## Related History

- [20260204201108-add-release-note-writer-to-report.md](.workaholic/tickets/archive/drive-20260204-160722/20260204201108-add-release-note-writer-to-report.md) - Origin of the whole release-note pipeline: the write-release-note skill, the report-side writer, and the one-file-per-branch `<branch>.md` convention this ticket relocates and re-shapes.
- [20260406204012-fix-missing-release-notes.md](.workaholic/tickets/archive/work-20260406-193458/20260406204012-fix-missing-release-notes.md) - Documents the `release.yml` Actions workflow that turns the per-branch file into a GitHub Release on merge (keyed off branch name / `ls -t`). The naming-scheme change here affects that selector (reconciled in the dependent ticket).
- [20260527012300-decouple-core-ship-from-trip.md](.workaholic/tickets/archive/work-20260518-235327/20260527012300-decouple-core-ship-from-trip.md) - Established `core:ship` as the trip-independent essence wrapped by `core:trip-protocol`; the new generate step added to Ship Flow §5 is inherited by the trip path automatically.

## Implementation Steps

1. **Choose the multi-release naming scheme.** Recommended default: keep the flat
   `.workaholic/release-notes/<branch>.md` for a branch's first/only release, and
   add `<branch>-2.md`, `<branch>-3.md`, … for subsequent releases on the same
   branch — preserving backward-compatibility with the 39 existing flat files and
   the `release.yml` `ls -t` selector. (Alternative: a per-branch subdirectory
   `.workaholic/release-notes/<branch>/<NN>.md`; see Considerations.)
2. **Update `core:write-release-note` Output Location** to the chosen scheme,
   keeping the skill pure prose.
3. **Remove generation from `core:report`**: delete Phase 5 step 2 and Phase 6,
   and prune `release_note_file` / `release_note_writer` from the Output Schema and
   Worker Output Mapping. Leave Phase 5 step 1 (Create PR) intact.
4. **Add generation to `core:ship` Ship Flow** as a new step before Merge PR:
   obtain the PR URL from `pre-check.sh`, run `core:write-release-note` against
   `.workaholic/stories/<branch>.md`, write the note to the scheme path, then
   `git add` + commit (`"Add release notes for <branch>"`) + push to the branch so
   it is included in the merge. (The merge itself stays in `merge-pr.sh`.)
5. **Regenerate `dist/`** with `node scripts/build-plugins/build.mjs`; run
   `verify.mjs`, `validate-metadata.mjs`, and `test-workflow-scripts.mjs`.
6. **Update prose**: `CLAUDE.md` / READMEs where they describe report generating
   the release note (move that description to ship).

## Considerations

- **Generation must run before merge** so the note is committed to the branch and
  carried into main (requirement #2/#3). Sequence in Ship Flow: pre-check →
  generate+commit+push note → merge-pr → (publish, dependent ticket) → carry-overs
  → deploy → verify → summarize. (`plugins/core/skills/ship/SKILL.md` §5)
- **PR URL coupling.** `/report` used to produce the PR URL and pass it to the
  note worker. `/ship` gets it from `pre-check.sh` (`url` field), so no new
  dependency on `/report` output is needed. (`plugins/core/skills/ship/scripts/pre-check.sh`)
- **Keep `write-release-note` pure prose and cross-agent-exposed** — no script, no
  `${CLAUDE_PLUGIN_ROOT}`. It must keep resolving on every agent via the `skills`
  CLI. (CLAUDE.md Cross-Agent Skill Exposure; `standards:implementation` Conservative Vendor Dependence — keep note *generation* decoupled from any publishing vendor.)
- **Naming scheme is the main design decision.** The flat `<branch>-N.md` default
  is backward-compatible; a `<branch>/` subdirectory is cleaner for many releases
  but breaks the existing `ls -t` selector in `release.yml` and the 39 existing
  files. Whichever is chosen, the dependent publish ticket consumes the same
  scheme. (`.workaholic/release-notes/`)
- **Trip/worktree path inherits automatically** because `core:trip-protocol`'s
  Trip Ship delegates to `core:ship`'s Ship Flow — but the note commit/push must
  happen in the worktree before `cleanup-worktree.sh` runs. Verify ordering.
  (`plugins/core/skills/trip-protocol/SKILL.md` Trip Ship flow)
- **Dist regen is mandatory** — `core:ship`/`core:report`/`core:write-release-note`
  all have committed `dist/workflows` mirrors guarded by Dist Freshness CI.
  (`scripts/build-plugins/build.mjs`)
- `standards:operation` (CI/CD — delivery as code): the note is a version-controlled
  artifact committed to the branch and merged to main, so the release record lives
  in-repo, not in operator memory. (`plugins/standards/skills/operation/`)

## Final Report

Development completed as planned (night drive, auto-approved). Removed release-note
generation from `core:report` (Phase 5 step 2 + Phase 6 deleted; pruned
`release_note_file`/`release_note_writer` from the Output Schema and Worker Output
Mapping; renamed Phase 5 to "Create PR"; updated "Phases 0–6" → "0–5"). Added a
generate-release-note step to the `core:ship` Ship Flow before merge, fed by
`pre-check.sh`'s PR `url`, with a new bundled `commit-release-note.sh` that
stages/commits/pushes the note so it rides into the merge. Updated
`write-release-note`'s Output Location to the multi-release scheme
(`<branch>.md`, then `<branch>-<N>.md`) and added `core:write-release-note` to the
ship command's preloads. Regenerated `dist/`; build/verify/validate-metadata and
47 smoke tests all pass.

### Discovered Insights

- **Insight**: The release-note step is correctly placed *before* `merge-pr.sh`
  (which checks out main and pulls), so the note is committed on the topic branch
  and carried into the merge. Placing it after merge would commit it onto main
  out-of-band. **Context**: any future ship-flow step that must land in the PR has
  to run before step 3 (Merge PR).
