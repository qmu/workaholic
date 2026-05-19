---
created_at: 2026-05-19T11:06:56+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort:
commit_hash:
category:
depends_on:
---

# Propagate Story Concerns and Ideas as Carry-Over Documents

## Overview

When `/report` runs, it generates a branch story whose sections 6 (Concerns) and 7 (Ideas) capture risks, trade-offs, and forward-looking suggestions that emerged during the branch. Today those insights live exclusively inside the story Markdown. Once the PR is merged via `/ship`, the items effectively vanish: there is no system that revisits them, decides whether they remain relevant, or converts them into actionable work.

This ticket introduces a carry-over pipeline so concerns and ideas survive the lifetime of a single PR and become first-class inputs to future planning:

1. Persist unresolved concerns and ideas to a new `.workaholic/concerns/` directory (and a sibling `.workaholic/ideas/` directory) when `/ship` merges a PR.
2. Tag each carried-over entry with its origin PR (URL, number, branch) so its provenance is traceable.
3. Teach `/report` to read existing carry-over files at the start of every run and judge — per item — whether the concern/idea is still active or has been resolved elsewhere. Resolved items are marked closed (not deleted) with a pointer to the PR/commit that addressed them.
4. Have the coding agent (story-writer / a new sweeper step) emit housekeeping tickets under `.workaholic/tickets/todo/` referencing the still-active carry-overs so the queue stays loaded with the team's accumulated improvements.

Concerns 6.N and Ideas 7.N in the story are written symmetrically — Idea N is the constructive counterpart of Concern N — so the carry-over schema preserves that pairing.

## Key Files

- `plugins/core/skills/report/SKILL.md` - Story Content Structure defines sections 6 (Concerns) and 7 (Ideas); this is where the carry-over read/judge step must be wired in before story generation begins (Phase 0 or Phase 1).
- `plugins/core/skills/review-sections/SKILL.md` - Section-reviewer guidelines for generating Concerns and Ideas; must learn to mark items as "carried" vs "new" and to consume the existing carry-over corpus when deciding what to re-emit.
- `plugins/work/agents/section-reviewer.md` - Subagent that calls `core:review-sections`; its input contract grows to include the existing carry-over directories.
- `plugins/work/agents/story-writer.md` - Orchestrates story generation; the carry-over read+judge step is invoked here (Phase 1) so its result flows into section-reviewer.
- `plugins/core/skills/ship/SKILL.md` - The ship workflow merges the PR and is the natural place to extract section 6/7 from the just-shipped story and write/append them to `.workaholic/concerns/` and `.workaholic/ideas/`. Add a new step between "Merge PR" and "Clean up worktree".
- `plugins/work/commands/ship.md` - Thin command for ship; no logic change here, but it should preload the updated ship skill.
- `plugins/core/skills/create-ticket/SKILL.md` - Allowed Locations section currently forbids writing into other `.workaholic/` subdirs. Carry-over files are written by `/ship` and `/report`, not by `create-ticket`, so the prohibition list stays correct; but the housekeeping ticket auto-generation must use this skill's format. Cross-reference here.
- `plugins/work/hooks/validate-ticket.sh` - Validates ticket-shaped files (`YYYYMMDDHHmmss-*.md`) live only under `.workaholic/tickets/`. Carry-over files must use a different filename convention (e.g. `concern-<short>.md` or `<pr-number>-<slug>.md`) so they don't trip this hook.
- `.workaholic/stories/work-20260417-092936.md` - Reference example of sections 6 and 7 demonstrating the existing format and symmetry that the carry-over extractor must parse.
- `.workaholic/tickets/archive/drive-20260205-195920/20260205195247-improve-concerns-section-traceability.md` - Prior work that added commit-hash + file-path traceability to Concerns; the carry-over schema must preserve those references.

## Related History

The codebase has steadily increased the structure and traceability of Concerns/Ideas (adding section-reviewer in early 2026, then commit-hash + file-path references). This ticket continues that arc by extending those items beyond a single story's lifetime into a persistent corpus that future runs read back, judge, and promote into tickets.

Past tickets that touched similar areas:

- [20260205195247-improve-concerns-section-traceability.md](.workaholic/tickets/archive/drive-20260205-195920/20260205195247-improve-concerns-section-traceability.md) - Added commit-hash and file-path references to the Concerns section (same Concerns/Ideas surface, same traceability philosophy).
- [20260202201519-add-section-reviewer-subagent.md](.workaholic/tickets/archive/drive-20260202-134332/20260202201519-add-section-reviewer-subagent.md) - Introduced the section-reviewer subagent that produces sections 6 and 7 today (the agent that must be extended).
- [20260204172657-remove-translator-from-story-writer.md](.workaholic/tickets/archive/drive-20260204-160722/20260204172657-remove-translator-from-story-writer.md) - Restructured story-writer orchestration (same orchestration surface that must absorb the carry-over read step).

## Implementation Steps

1. **Define the carry-over schema.** Create `.workaholic/concerns/README.md` and `.workaholic/ideas/README.md` describing the directory's purpose and the per-file format. One file per concern (or idea) keeps git history clean and makes resolution easy.

   Filename convention: `<pr-number>-<slug>.md` (e.g. `42-pathspec-exclusion-modern-git.md`). Pair Concern N with Idea N by reusing the same slug across the two directories when the story emitted them symmetrically.

   Per-file frontmatter:

   ```yaml
   ---
   origin_pr: 42
   origin_pr_url: https://github.com/qmu/workaholic/pull/42
   origin_branch: work-20260417-092936
   origin_commit: 7eab801
   created_at: 2026-05-19T11:06:56+09:00
   status: active            # active | resolved
   resolved_by_pr:           # filled when status becomes resolved
   resolved_by_commit:
   paired_idea: 42-pathspec-modern-git-gate.md   # optional symmetry pointer
   ---
   ```

   Body: the original bullet copied verbatim from section 6 (or 7) of the story, including its `(see [hash](url) in path/to/file.ext)` reference.

2. **Add the carry-over write step to `/ship`.** In `plugins/core/skills/ship/SKILL.md`, between step 6.2 "Merge PR" and step 6.4 "Clean up worktree" (Work Context route), add: "Extract Concerns and Ideas from the shipped story."

   Logistics: after merge, read `.workaholic/stories/<branch>.md`, parse sections `## 6. Concerns` and `## 7. Ideas` (split on blank lines / bullets), and emit one file per bullet under the appropriate directory with the frontmatter above. Skip a bullet if it equals "None". Implement parsing in a new bundled script `plugins/core/skills/ship/scripts/extract-carryover.sh` so the markdown stays free of inline shell logic (per the Shell Script Principle).

3. **Add the carry-over read+judge step to `/report`.** In `plugins/core/skills/report/SKILL.md` Phase 1 (Invoke Story Generation Agents), add a fourth parallel agent (or extend section-reviewer's input) that:

   a. Lists all files under `.workaholic/concerns/` and `.workaholic/ideas/` where `status: active`.

   b. For each item, judges whether it has been resolved by inspecting the current branch's commits (`git log` since the origin PR's merge commit), modified files, and other shipped stories. Heuristics: file no longer matches the original reference, commit message mentions the concern, related ticket archived since.

   c. Emits a JSON list of `{path, verdict: still_active | resolved, resolved_by_pr?, resolved_by_commit?, rationale}`.

   d. The story-writer applies the verdicts: for `resolved`, rewrite the carry-over file with `status: resolved` and the resolving PR/commit; for `still_active`, leave it untouched.

   The new agent can reuse `work:discoverer` in a custom mode, or be a small new subagent (`work:carryover-judge`).

4. **Surface carry-overs in the story.** Extend `core:review-sections` Section 6/7 guidance so the section-reviewer:

   - Pulls carry-over items with verdict `still_active` and re-emits them at the top of section 6 / 7, annotated with their origin PR (`carried over from PR #N`).
   - Tags new items (those born of this branch) without the carry-over marker so the post-merge extractor knows what to persist.
   - Preserves the symmetric Concern N ↔ Idea N pairing across runs.

5. **Auto-create housekeeping tickets from active carry-overs.** Add a final step to the report workflow (after the story file is written, before PR creation): for each `still_active` carry-over with verdict unchanged for more than one PR cycle, emit a housekeeping ticket into `.workaholic/tickets/todo/` using the `core:create-ticket` skill format. The ticket title is the carry-over's first line; its Overview is the carry-over body; its `type` is `housekeeping`; its `depends_on` is empty.

   To avoid duplicate tickets, scan `.workaholic/tickets/todo/` first and skip any whose title matches the carry-over's slug. The hook at `plugins/work/hooks/validate-ticket.sh` already enforces that ticket files live under `.workaholic/tickets/`, so the auto-emitted file lands correctly.

6. **Update READMEs and command help text** so users discover the new directories and understand the lifecycle (`/report` reads → user merges → `/ship` writes → next `/report` re-reads and judges → housekeeping tickets appear).

7. **Migrate existing stories (optional, one-shot).** Provide a script `plugins/core/skills/ship/scripts/backfill-carryover.sh` that walks every `.workaholic/stories/*.md`, extracts sections 6/7, and seeds `.workaholic/concerns/` / `.workaholic/ideas/`. This gives the system an immediate corpus instead of waiting for new ships.

## Patches

> **Note**: These patches are speculative — they sketch the wiring points but the exact shell/parsing logic must be implemented in bundled scripts per the Shell Script Principle.

### `plugins/core/skills/ship/SKILL.md`

```diff
--- a/plugins/core/skills/ship/SKILL.md
+++ b/plugins/core/skills/ship/SKILL.md
@@ -142,7 +142,8 @@
 1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Clean up worktree.
 2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
-3. **Sync gitignored files** (if worktree exists): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-gitignored-files.sh "<worktree-path>"`. If `has_changes` is `true`, display the file list and ask via AskUserQuestion with options: **"Copy all to main worktree"**, **"Skip and erase"**. If "Copy all", run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/sync-gitignored-files.sh "<worktree-path>" "<main-repo-root>" '<files-json>'` with all file paths. If `has_changes` is `false`, proceed silently. If no worktree exists, skip this step.
+3. **Extract carry-overs**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/extract-carryover.sh "<branch>" "<pr-number>" "<pr-url>"`. Persists active Concerns/Ideas from the shipped story into `.workaholic/concerns/` and `.workaholic/ideas/`. Commits the new files with message "Carry over concerns and ideas from PR #<pr-number>".
+4. **Sync gitignored files** (if worktree exists): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-gitignored-files.sh "<worktree-path>"`. ...
```

### `plugins/core/skills/report/SKILL.md`

```diff
--- a/plugins/core/skills/report/SKILL.md
+++ b/plugins/core/skills/report/SKILL.md
@@ -98,9 +98,10 @@
 #### Phase 1: Invoke Story Generation Agents

-Invoke 3 agents in parallel via Task tool (single message with 3 tool calls):
+Invoke 4 agents in parallel via Task tool (single message with 4 tool calls):

 - **release-readiness** (`subagent_type: "work:release-readiness"`, `model: "opus"`): ...
 - **overview-writer** (`subagent_type: "work:overview-writer"`, `model: "opus"`): ...
 - **section-reviewer** (`subagent_type: "work:section-reviewer"`, `model: "opus"`): ...
+- **carryover-judge** (`subagent_type: "work:carryover-judge"`, `model: "opus"`): Reads `.workaholic/concerns/` and `.workaholic/ideas/`, returns per-item verdicts (`still_active` / `resolved`). Section-reviewer consumes these verdicts when composing sections 6 and 7.
```

### `plugins/core/skills/review-sections/SKILL.md`

```diff
--- a/plugins/core/skills/review-sections/SKILL.md
+++ b/plugins/core/skills/review-sections/SKILL.md
@@ -39,7 +39,11 @@
 ### Section 7: Concerns

-Identify risks, trade-offs, and limitations with identifiable references.
+Identify risks, trade-offs, and limitations with identifiable references. Compose
+the section from two sources:
+
+1. **Carried-over concerns** from `.workaholic/concerns/` (only items the carryover-judge marked `still_active`). Prefix each with `(carried from PR #N)`.
+2. **New concerns** discovered while implementing this branch's tickets.
```

## Considerations

- The `.workaholic/concerns/` and `.workaholic/ideas/` directories are new top-level artefacts. Update `.workaholic/README.md` and `.workaholic/guides/` so users find them (`.workaholic/README.md`, `.workaholic/guides/workflow.md`).
- The ticket validation hook rejects ticket-shaped filenames outside `.workaholic/tickets/`. Carry-over files MUST use a different naming pattern (e.g. `42-pathspec-modern-git.md`, NOT `20260519110656-pathspec.md`) to avoid hook failures (`plugins/work/hooks/validate-ticket.sh`).
- The Allowed Locations clause in `core:create-ticket` enumerates prohibited sibling directories under `.workaholic/`. The newly-added `concerns/` and `ideas/` directories should be appended to that list so future ticket-organizer runs do not accidentally treat them as ticket sinks (`plugins/core/skills/create-ticket/SKILL.md`).
- Auto-emitting housekeeping tickets risks ticket-queue spam if the judge consistently mis-classifies items as `still_active`. Mitigate via the "wait one PR cycle" gating (step 5) and dedup-by-slug; consider a per-carryover `housekeeping_ticket_emitted` boolean to make idempotency explicit.
- Carry-over status transitions (`active` → `resolved`) are written by `/report` (in the source repo, not a worktree). Ensure `/report` commits the status change in the same commit as the story to keep history coherent (`plugins/core/skills/report/SKILL.md` Phase 3).
- The carry-over judge's heuristics (commit log scan, file-path liveness check) can produce false positives. Always preserve resolved files (mark, don't delete) so the audit trail survives mistakes (`plugins/core/skills/report/SKILL.md` Phase 1).
- Symmetric pairing (Concern N ↔ Idea N) is a story-level convention enforced today only by the prompt in section-reviewer. Persisting that pairing through file references (`paired_idea:` frontmatter field) makes the relationship explicit but requires section-reviewer to emit a stable slug for both sides simultaneously (`plugins/core/skills/review-sections/SKILL.md`).
- All multi-step extraction and judgement logic must live in bundled scripts under `plugins/core/skills/ship/scripts/` and `plugins/core/skills/report/scripts/` per the Shell Script Principle in `CLAUDE.md`; do not inline parsing logic in skill or agent markdown.
- Lead Lens (Domain → `standards:leading-validity`): the carry-over schema is a small persistence layer; keep its frontmatter type-driven (explicit `status` enum, ISO 8601 timestamps) and segregate the parser (script) from the orchestrator (skill) so each layer can be tested in isolation.
- Lead Lens (Config → governing lead for the affected behaviour, here `standards:leading-validity` again because the artefacts encode workflow state): treat `.workaholic/concerns/` as the source of truth for "outstanding non-blocking debt"; downstream consumers (release-readiness, housekeeping-ticket emitter) must read this directory rather than re-parsing stories.
