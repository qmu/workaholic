---
created_at: 2026-05-14T15:47:17+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Thin work-side report umbrella into core:report skill

## Overview

The "report umbrella" — six work-side agents and the `/report` command that all orbit `core:report` — currently carries 419 lines of procedural content (77 + 37 + 43 + 58 + 52 + 75 + 77) outside the skill itself. The skill is 425 lines and already owns most of the canonical templates and field mappings.

This is a **refactor toward "thin agents/commands as aliases of skills."** Each agent post-migration is ~5-10 body lines stating an I/O contract; the command is ~5-10 body lines stating a workflow entry. All procedural steps, decision logic, AskUserQuestion text, script invocations, subagent dispatch lists, and prose explanations move verbatim into `plugins/core/skills/report/SKILL.md`.

**Current behavior must be preserved exactly.** Every step that ran before still runs. Every prompt to the user still appears. Every script invocation still happens with the same arguments. Every parallel `Task` launch in `story-writer` still happens with the same `subagent_type` list. The order of operations is unchanged.

**Migration choice (per user's dependency rules):**
- `core` cannot hard-depend on `standards`, but `core` CAN soft-depend on `standards` (skill preloads OK).
- `core` cannot depend on `work`.
- Today neither the six agents nor the `/report` command in the report umbrella preload any `standards:leading-*` skill (confirmed via `grep -rn "leading-" plugins/work/agents/{story-writer,pr-creator,release-readiness,overview-writer,section-reviewer,release-note-writer}.md plugins/work/commands/report.md plugins/core/skills/report/SKILL.md` returns zero matches). This refactor adds the soft preloads on `core:report` itself so they remain available to the thinned agents that preload `core:report`.

## Key Files

### Migration sources (thinned in this ticket)

- `plugins/work/agents/story-writer.md` (77 lines) — Orchestrates parallel agents. Currently contains: Phase 0 (gather context), Phase 1 (parallel Task dispatch list: release-readiness, overview-writer, section-reviewer), Phase 2 (write story file: read archived tickets, follow report skill, update index), Phase 3 (commit/push story), Phase 4 (sequential pr-creator then release-note-writer), Phase 5 (commit/push release notes), and the full JSON output schema. **Special: orchestrates other agents — the parallel-Task list moves into the skill verbatim.**
- `plugins/work/agents/pr-creator.md` (37 lines) — Reads story file, derives title, runs `gh` CLI ops. Currently delegates most logic to skill via "Follow the preloaded report skill (Create PR section)". Body already minimal but Input/Output sections can collapse.
- `plugins/work/agents/release-readiness.md` (43 lines) — Currently runs `git diff main..HEAD` and delegates to skill's "Assess Release Readiness". The Instructions section repeats analysis steps already in the skill; can collapse to I/O contract.
- `plugins/work/agents/overview-writer.md` (58 lines) — Already minimized in the recent `merge-write-overview-into-report` ticket. Its content (Collect Commits, Analyze, Generate, Extract Highlights, Write Motivation, Create Journey, full JSON schema) already has a counterpart in the skill's "Overview Generation" section (added in commit feb977c). Agent body collapses to I/O contract.
- `plugins/work/agents/section-reviewer.md` (52 lines) — Preloads `core:review-sections` (a separate skill, not `core:report`). Body contains Instructions (read archived tickets, analyze, generate, return JSON) and JSON output schema. **Decision: keep `core:review-sections` preload as-is — section-reviewer's content already lives in a dedicated skill, not in `core:report`. This file shrinks only modestly; the rules of the migration apply: I/O contract only.**
- `plugins/work/agents/release-note-writer.md` (75 lines) — Preloads `core:write-release-note` (separate skill). Body contains Step 1-4 (read story, generate note, write file, update index) plus JSON output. **Decision: keep `core:write-release-note` preload as-is.** Body shrinks to I/O contract since steps are already prescribed in `write-release-note`.
- `plugins/work/commands/report.md` (77 lines) — Workspace Guard, context detection, drive/trip/hybrid routing, version bump, story-writer invocation, story display, PR URL display, worktree handling, unknown context handling. **All of this orchestration moves into the skill's new "Run Workflow" section.**

### Migration destination

- `plugins/core/skills/report/SKILL.md` (425 lines) — Receives migrated content under three umbrella sections:
  - **New "## Run Workflow" section** (or similar top-level): absorbs `commands/report.md` body — Workspace Guard, Detect Context, Route by Context (Work/Worktree/Unknown), Work mode subroutes (Drive/Trip/Hybrid).
  - **Existing "## Write Story" section**: gains an "### Orchestration" subsection that absorbs `story-writer.md` Phases 0-5 (gather context, parallel Task dispatch list, write story file, commit/push, sequential pr-creator → release-note-writer, push release notes) and the story-writer JSON output schema.
  - **Existing "## Create PR" section**: absorbs `pr-creator.md` Input/Instructions content.
  - **Existing "## Assess Release Readiness" section**: absorbs `release-readiness.md` Input/Instructions content.
  - The "Overview Generation" subsection already mirrors `overview-writer.md`; only confirm coverage and remove duplication.
  - Section-reviewer and release-note-writer point at sibling skills (`core:review-sections`, `core:write-release-note`); their JSON schemas optionally relocate to `core:report` under "### Agent Output Mapping" expansion, or stay in their respective skills. Recommend: leave schemas in the sibling skills to avoid bloating `report/SKILL.md`. Re-document the *mapping* in `report/SKILL.md`.
  - **New frontmatter preloads**: add `standards:leading-accessibility`, `standards:leading-validity`, `standards:leading-security`, `standards:leading-availability` to the `skills:` list. Soft references — `core` does not declare a hard dependency on `standards`.

### Adjacent files (read-only context; not modified)

- `plugins/core/skills/report/scripts/collect-commits.sh` — Referenced by overview-writer / Overview Generation section. Path stable.
- `plugins/core/skills/report/scripts/create-or-update.sh` — Referenced by pr-creator / Create PR section. Path stable.
- `plugins/core/skills/report/scripts/strip-frontmatter.sh` — Referenced by Create PR section. Path stable.
- `plugins/core/skills/review-sections/SKILL.md` — Preloaded by section-reviewer. Unchanged.
- `plugins/core/skills/write-release-note/SKILL.md` — Preloaded by release-note-writer. Unchanged.
- `plugins/core/skills/gather/SKILL.md` — Preloaded by story-writer (for `git-context.sh`). Stays preloaded on story-writer.
- `plugins/core/skills/branching/scripts/{check-workspace,detect-context,list-worktrees,check-version-bump}.sh` — All script paths referenced by `commands/report.md` remain at identical paths after migration into the skill.
- `plugins/core/skills/trip-protocol/SKILL.md` — Currently preloaded by `commands/report.md`. After thinning, `core:report` itself absorbs `core:trip-protocol` and `core:branching` as preloads, so the thin command can drop them.
- `CLAUDE.md` — Project Structure section lists `core/skills/` and `work/agents/`. No structural skill renames; no edits required unless the agent/skill counts change. Verify and update if needed.

## Related History

The repository has run an extended "thin orchestration, fat skills" refactor across many components in the past three months: skills have repeatedly absorbed their consumers' content (write-overview → report, gather-* → gather, ticket-organizer split, story-moderator extraction, approval-flow merge). The closest precedent is the `merge-write-overview-into-report` ticket, which already established the pattern of absorbing a single-consumer skill into `core:report` as a sibling section. This ticket extends that same pattern: instead of absorbing a *peer skill*, it absorbs *consumer agents and a consumer command*.

Past tickets that touched similar areas:

- [20260514150414-merge-write-overview-into-report.md](.workaholic/tickets/archive/work-20260417-092936/20260514150414-merge-write-overview-into-report.md) - Most recent precedent; absorbed `write-overview` skill into `core:report` as a sibling section. This ticket extends the same pattern to consumer agents.
- [20260202200553-reorganize-story-agent-hierarchy.md](.workaholic/tickets/archive/drive-20260202-134332/20260202200553-reorganize-story-agent-hierarchy.md) - Reorganized the story-writer/overview-writer/section-reviewer hierarchy this ticket now thins.
- [20260202181348-add-overview-writer-subagent.md](.workaholic/tickets/archive/drive-20260202-134332/20260202181348-add-overview-writer-subagent.md) - Original introduction of overview-writer; relevant for verifying behavior preservation.
- [20260202201519-add-section-reviewer-subagent.md](.workaholic/tickets/archive/drive-20260202-134332/20260202201519-add-section-reviewer-subagent.md) - Original introduction of section-reviewer.
- [20260204201108-add-release-note-writer-to-report.md](.workaholic/tickets/archive/drive-20260204-160722/20260204201108-add-release-note-writer-to-report.md) - Introduced release-note-writer and wired it into report.
- [20260127211737-invoke-release-readiness-in-parallel.md](.workaholic/tickets/archive/feat-20260128-001720/20260127211737-invoke-release-readiness-in-parallel.md) - Established the parallel-Task dispatch pattern in story-writer that must be preserved verbatim.
- [20260129023435-pragmatic-release-readiness.md](.workaholic/tickets/archive/feat-20260129-023941/20260129023435-pragmatic-release-readiness.md) - Defined the "What NOT to Flag" content already in the skill; confirms the skill (not the agent) owns the analysis policy.
- [20260202184602-merge-approval-flow-skills.md](.workaholic/tickets/archive/drive-20260202-134332/20260202184602-merge-approval-flow-skills.md) - Same refactoring pattern: collapsing peripheral content into a central skill.
- [20260509001216-wire-leads-into-work-flows.md](.workaholic/tickets/archive/work-20260417-092936/20260509001216-wire-leads-into-work-flows.md) - Established the pattern of preloading `standards:leading-*` skills onto orchestration components. This ticket extends that pattern to `core:report` via soft preload.

## Implementation Steps

1. **Read every file end-to-end** to establish a verbatim baseline:
   - `plugins/work/agents/story-writer.md` (77 lines)
   - `plugins/work/agents/pr-creator.md` (37 lines)
   - `plugins/work/agents/release-readiness.md` (43 lines)
   - `plugins/work/agents/overview-writer.md` (58 lines)
   - `plugins/work/agents/section-reviewer.md` (52 lines)
   - `plugins/work/agents/release-note-writer.md` (75 lines)
   - `plugins/work/commands/report.md` (77 lines)
   - `plugins/core/skills/report/SKILL.md` (425 lines)
   Build a mental cross-reference: every section in each work-side file maps to an intended destination section in the skill.

2. **Map content to skill destinations**. Concretely:
   - `story-writer.md` Phases 0-5 → new `## Write Story` → `### Orchestration` subsection in `core:report` (placed near top of Write Story, before Agent Output Mapping).
   - `story-writer.md` Output JSON schema → `### Story-Writer Output Schema` subsection under Write Story.
   - `commands/report.md` body (Workspace Guard, context detection, Drive/Trip/Hybrid/Worktree/Unknown routing) → new top-level `## Run Workflow` section in `core:report`.
   - `pr-creator.md` Instructions → already covered by `## Create PR` section. Verify; add Input subsection if missing.
   - `release-readiness.md` Instructions → already covered by `## Assess Release Readiness`. Verify; add Input subsection if missing.
   - `overview-writer.md` Instructions → already covered by `### Overview Generation` (added in commit feb977c). Verify; no migration needed.
   - `section-reviewer.md` Instructions → already covered by `core:review-sections`. Verify; no migration into `core:report` needed (cross-reference instead).
   - `release-note-writer.md` Step 1-4 → already covered by `core:write-release-note`. Verify; no migration into `core:report` needed.

3. **Add new sections to `plugins/core/skills/report/SKILL.md`**:
   - Insert `## Run Workflow` as the new first procedural section (after introduction, before `## Write Story`). Body contains, verbatim, the orchestration from `commands/report.md`: Step 0 Workspace Guard with AskUserQuestion options ("Ignore and proceed" / "Stop"), Step 1 Detect Context, Step 2 Route by Context with all five subcases (Drive Mode / Trip Mode / Hybrid Mode / Worktree Context / Unknown Context). All `${CLAUDE_PLUGIN_ROOT}/../core/...` script paths must be rewritten to `${CLAUDE_PLUGIN_ROOT}/...` since the file now lives in `core/skills/report/SKILL.md` (one directory deeper, same plugin root resolution).
   - Insert `### Orchestration` as the first subsection under `## Write Story`. Body contains, verbatim, story-writer Phases 0-5 with all parallel-Task dispatch identifiers (`work:release-readiness`, `work:overview-writer`, `work:section-reviewer`, `work:pr-creator`, `work:release-note-writer`) preserved exactly.

4. **Add soft preloads to `core:report` frontmatter**. Update `plugins/core/skills/report/SKILL.md` frontmatter `skills:` list (or add it if absent) to include:
   ```yaml
   skills:
     - core:trip-protocol
     - core:branching
     - core:gather
     - standards:leading-accessibility
     - standards:leading-validity
     - standards:leading-security
     - standards:leading-availability
   ```
   `core:trip-protocol` and `core:branching` currently live on `commands/report.md` and migrate up. `core:gather` migrates up from `story-writer.md`. The `leading-*` entries are net-new soft references documenting that the skill applies lead policies.

5. **Thin `plugins/work/commands/report.md`** to ~10-15 lines. Frontmatter retains `name`, `description`, `allowed-tools`, and `skills: [core:report]` (drop `core:trip-protocol` and `core:branching` since `core:report` now preloads them). Body becomes:
   ```markdown
   # Report

   **Notice:** When user input contains `/report`, `/report-drive`, or `/report-trip` - whether "run /report", "do /report", "create report", or similar - they likely want this command.

   This command runs the preloaded `core:report` skill. Follow the Run Workflow section.
   ```

6. **Thin `plugins/work/agents/story-writer.md`** to ~15-20 lines. Frontmatter retains `name`, `description`, `tools`, `skills: [core:report]` (drop `core:gather` since `core:report` now preloads it). Body becomes:
   ```markdown
   # Story Writer

   ## Input

   - Branch name
   - Base branch

   ## Instructions

   Follow the preloaded `core:report` skill — Write Story → Orchestration subsection.

   ## Output

   Return the JSON described in the skill's Story-Writer Output Schema section.
   ```

7. **Thin `plugins/work/agents/pr-creator.md`** to ~10-15 lines. Frontmatter keeps `tools: Read, Bash, Glob` and `skills: [core:report]`. Body becomes:
   ```markdown
   # PR Creator

   ## Input

   - Branch name
   - Base branch (usually `main`)

   ## Instructions

   Follow the preloaded `core:report` skill — Create PR section.

   ## Output

   Return the script output exactly as printed (`PR created: <URL>` or `PR updated: <URL>`).
   ```

8. **Thin `plugins/work/agents/release-readiness.md`** to ~10-15 lines. Frontmatter keeps `tools: Read, Bash, Glob, Grep` and `skills: [core:report]`. Body becomes:
   ```markdown
   # Release Readiness

   ## Input

   - Branch name
   - Base branch (usually `main`)
   - List of archived tickets for the branch

   ## Instructions

   Follow the preloaded `core:report` skill — Assess Release Readiness section.

   ## Output

   Return the release-readiness JSON described in the skill.
   ```

9. **Thin `plugins/work/agents/overview-writer.md`** to ~10-15 lines. Frontmatter keeps `tools: Read, Bash, Glob, Grep`, `model: haiku`, `skills: [core:report]`. Body becomes:
   ```markdown
   # Overview Writer

   ## Input

   - Branch name
   - Base branch (usually `main`)

   ## Instructions

   Follow the preloaded `core:report` skill — Overview Generation subsection.

   ## Output

   Return the overview JSON described in the skill. Return JSON only; do not commit or modify files.
   ```

10. **Thin `plugins/work/agents/section-reviewer.md`** to ~10-15 lines. Frontmatter keeps `tools: Read, Glob, Grep`, `model: haiku`, `skills: [core:review-sections]` (unchanged — separate skill owns this content). Body becomes:
    ```markdown
    # Section Reviewer

    ## Input

    - Branch name
    - List of archived ticket paths (or Glob pattern)

    ## Instructions

    Follow the preloaded `core:review-sections` skill.

    ## Output

    Return the sections-4-through-8 JSON described in the skill.
    ```

11. **Thin `plugins/work/agents/release-note-writer.md`** to ~10-15 lines. Frontmatter keeps `tools: Read, Write, Glob, Grep`, `skills: [core:write-release-note]` (unchanged). Body becomes:
    ```markdown
    # Release Note Writer

    ## Input

    - Branch name
    - PR URL (passed by story-writer in the invocation prompt)

    ## Instructions

    Follow the preloaded `core:write-release-note` skill.

    ## Output

    Return the release-note JSON described in the skill.
    ```

12. **Narrow tool lists**. Review each thinned agent's `tools:` list:
    - `story-writer.md`: keeps `Read, Write, Edit, Bash, Glob, Grep, Task` — all still used by the skill's orchestration (Write/Edit for story file, Bash for git commits/push, Task for parallel subagent dispatch).
    - `pr-creator.md`: keeps `Read, Bash, Glob`. No `Edit` or `Write` (skill scripts handle file writes).
    - `release-readiness.md`: keeps `Read, Bash, Glob, Grep`. No `Write` (returns JSON only).
    - `overview-writer.md`: keeps `Read, Bash, Glob, Grep`. No `Write`.
    - `section-reviewer.md`: keeps `Read, Glob, Grep`. No `Bash` or `Write`.
    - `release-note-writer.md`: keeps `Read, Write, Glob, Grep`. `Write` is required for the release-note file.

13. **Verification — content preservation**. Run grep audits against the post-migration tree:
    ```bash
    # Every script path that ran before still appears somewhere
    grep -rn "check-workspace.sh\|detect-context.sh\|list-worktrees.sh\|check-version-bump.sh\|collect-commits.sh\|create-or-update.sh\|strip-frontmatter.sh\|git-context.sh" plugins/

    # Every AskUserQuestion text still appears
    grep -rn "Ignore and proceed\|Could not determine development context\|Found worktree" plugins/

    # Every subagent_type identifier still appears
    grep -rn "work:release-readiness\|work:overview-writer\|work:section-reviewer\|work:pr-creator\|work:release-note-writer\|work:story-writer" plugins/

    # Every commit message template still appears
    grep -rn "Add branch story for\|Add release notes for\|Bump version" plugins/
    ```
    Each pattern must appear in at least one post-migration file. Confirm none were lost in the thinning.

14. **Verification — line count check**. After migration:
    ```bash
    wc -l plugins/work/agents/{story-writer,pr-creator,release-readiness,overview-writer,section-reviewer,release-note-writer}.md plugins/work/commands/report.md plugins/core/skills/report/SKILL.md
    ```
    Expect each thinned file at ≤20 lines and the skill grown by roughly the sum of body content moved in (story-writer Phases 0-5 ~50 lines + report command body ~60 lines ≈ +110 lines into the skill).

15. **Functional smoke test**. From a branch with archived tickets, run `/report` and confirm:
    - Workspace guard prompt appears for a dirty workspace.
    - Context is detected.
    - Drive mode bumps version, invokes story-writer, displays the story file, displays the PR URL.
    - story-writer dispatches three parallel agents (release-readiness, overview-writer, section-reviewer).
    - story file is committed and pushed.
    - pr-creator runs, then release-note-writer runs.
    - Final JSON output matches the documented schema.

## Patches

> **Note**: The skill diff is large; the patches below show key insertion anchors and the verbatim thinning of each work-side file. Some hunks (especially the skill body insertions) are speculative — verify exact anchor lines before applying.

### `plugins/core/skills/report/SKILL.md` (preload list update + new sections)

```diff
--- a/plugins/core/skills/report/SKILL.md
+++ b/plugins/core/skills/report/SKILL.md
@@ -1,7 +1,15 @@
 ---
 name: report
 description: Story writing, PR creation, and release readiness assessment for branch reporting.
 allowed-tools: Bash
 user-invocable: false
+skills:
+  - core:trip-protocol
+  - core:branching
+  - core:gather
+  - standards:leading-accessibility
+  - standards:leading-validity
+  - standards:leading-security
+  - standards:leading-availability
 ---

 # Report
@@ -8,6 +16,68 @@

 Guidelines for generating branch stories, creating pull requests, and assessing release readiness.

+## Run Workflow
+
+Context-aware report orchestration. Auto-detects whether the caller is in a drive or trip workflow and routes accordingly.
+
+### Step 0: Workspace Guard
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-workspace.sh
+```
+
+Parse the JSON output. If `clean` is `true`, proceed silently to Step 1.
+
+If `clean` is `false`, display the `summary` to the user and ask via AskUserQuestion with selectable options:
+- **"Ignore and proceed"** - Continue with the report workflow. The unrelated changes will remain in the workspace after the command completes.
+- **"Stop"** - Halt the command so you can handle the changes first.
+
+If the user selects "Stop", end the command immediately.
+
+### Step 1: Detect Context
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/detect-context.sh
+```
+
+Parse the JSON output. Route to the appropriate workflow based on `context`.
+
+### Step 2: Route by Context
+
+[verbatim content from commands/report.md Step 2 — Drive/Trip/Hybrid/Worktree/Unknown subcases]
+
 ## Write Story
```

### `plugins/core/skills/report/SKILL.md` (insert Orchestration subsection)

```diff
@@ -12,6 +82,40 @@
 ## Write Story

 Generate a branch story that serves as the single source of truth for PR content.

+### Orchestration
+
+Generate the story file, then create the PR and release note.
+
+#### Phase 0: Gather Context
+
+Gather all context using the preloaded gather skill — run `git-context.sh`. Returns: branch, base_branch, repo_url, archived_tickets, git_log.
+
+#### Phase 1: Invoke Story Generation Agents
+
+Invoke 3 agents in parallel via Task tool (single message with 3 tool calls):
+- **release-readiness** (`subagent_type: "work:release-readiness"`, `model: "opus"`)
+- **overview-writer** (`subagent_type: "work:overview-writer"`, `model: "opus"`)
+- **section-reviewer** (`subagent_type: "work:section-reviewer"`, `model: "opus"`)
+
+Wait for all 3 agents to complete.
+
+#### Phase 2: Write Story File
+
+1. Gather Source Data: Read archived tickets via Glob `.workaholic/tickets/archive/<branch-name>/*.md`. Extract frontmatter (`commit_hash`, `category`) and content (Overview, Final Report).
+2. Write Story: Follow Story Content Structure below.
+3. Update Index: Add entry to `.workaholic/stories/README.md`.
+
+#### Phase 3: Commit and Push Story
+
+1. `git add .workaholic/stories/`
+2. `git commit -m "Add branch story for <branch-name>"`
+3. `git push -u origin <branch-name>`
+
+#### Phase 4: Create PR and Generate Release Note
+
+Sequential: invoke `work:pr-creator` first (capture PR URL), then invoke `work:release-note-writer` with the PR URL.
+
+#### Phase 5: Commit and Push Release Notes
+
+1. `git add .workaholic/release-notes/`
+2. `git commit -m "Add release notes for <branch-name>"`
+3. `git push`
+
 ### Agent Output Mapping
```

### `plugins/work/commands/report.md` (full thinning)

```diff
--- a/plugins/work/commands/report.md
+++ b/plugins/work/commands/report.md
@@ -1,77 +1,13 @@
 ---
 name: report
 description: Context-aware report generation and PR creation for drive and trip workflows.
 skills:
-  - core:trip-protocol
-  - core:branching
+  - core:report
 ---

 # Report

 **Notice:** When user input contains `/report`, `/report-drive`, or `/report-trip` - whether "run /report", "do /report", "create report", or similar - they likely want this command.

-Context-aware report command that auto-detects whether you are in a drive or trip workflow and generates the appropriate report.
-
-## Instructions
-
-### Step 0: Workspace Guard
-
-```bash
-bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-workspace.sh
-```
-
-Parse the JSON output. If `clean` is `true`, proceed silently to Step 1.
-
-... [remaining ~60 lines deleted] ...
+This command runs the preloaded `core:report` skill. Follow the Run Workflow section.
```

### `plugins/work/agents/story-writer.md` (full thinning)

```diff
--- a/plugins/work/agents/story-writer.md
+++ b/plugins/work/agents/story-writer.md
@@ -1,77 +1,18 @@
 ---
 name: story-writer
 description: Generate branch story for PR description and create/update the pull request.
 tools: Read, Write, Edit, Bash, Glob, Grep, Task
 skills:
-  - core:gather
   - core:report
 ---

 # Story Writer

-Generate a branch story in `.workaholic/stories/<branch-name>.md` and create/update the pull request.
+## Input
+
+- Branch name
+- Base branch
+
+## Instructions
+
+Follow the preloaded `core:report` skill — Write Story → Orchestration subsection.
+
+## Output
+
+Return the JSON described in the skill's Story-Writer Output Schema section.
-
-... [remaining ~60 lines deleted] ...
```

### `plugins/work/agents/pr-creator.md` (full thinning)

```diff
--- a/plugins/work/agents/pr-creator.md
+++ b/plugins/work/agents/pr-creator.md
@@ -1,37 +1,17 @@
 ---
 name: pr-creator
 description: Create or update GitHub PR from story file. Handles PR existence check, title derivation, and gh CLI operations.
 tools: Read, Bash, Glob
 skills:
   - core:report
 ---

 # PR Creator

-Create or update a GitHub pull request using the story file as PR content.
-
-## Input
+## Input
-
-You will receive:
-
-- Branch name
+- Branch name
 - Base branch (usually `main`)

 ## Instructions

-1. Read `.workaholic/stories/<branch-name>.md` to extract the PR title.
-2. Follow the preloaded report skill (Create PR section) for title derivation and PR creation.
+Follow the preloaded `core:report` skill — Create PR section.

 ## Output

-Return the script output exactly as-is:
-
-```
-PR created: <URL>
-```
-
-or
-
-```
-PR updated: <URL>
-```
+Return the script output exactly as printed (`PR created: <URL>` or `PR updated: <URL>`).
```

### `plugins/work/agents/release-readiness.md` (full thinning)

```diff
--- a/plugins/work/agents/release-readiness.md
+++ b/plugins/work/agents/release-readiness.md
@@ -1,43 +1,16 @@
 ---
 name: release-readiness
 description: Analyze branch changes for release readiness, identifying concerns and special instructions.
 tools: Read, Bash, Glob, Grep
 skills:
   - core:report
 ---

 # Release Readiness

-Analyze a branch to determine if it's ready for release.
-
 ## Input
-
-You will receive:
-
 - Branch name
 - Base branch (usually `main`)
 - List of archived tickets for the branch

 ## Instructions

-1. **Analyze changes**: Run `git diff main..HEAD` to review actual code changes.
-
-2. **Check for issues**: Follow the preloaded report skill (Assess Release Readiness section) for analysis tasks.
-
-3. **Generate verdict**: Determine if branch is releasable based on analysis.
+Follow the preloaded `core:report` skill — Assess Release Readiness section.

 ## Output

-Return JSON with releasability verdict, concerns, and instructions:
-
-```json
-{
-  "releasable": true/false,
-  "verdict": "Ready for release" / "Needs attention before release",
-  "concerns": [],
-  "instructions": {
-    "pre_release": [],
-    "post_release": []
-  }
-}
-```
+Return the release-readiness JSON described in the skill.
```

### `plugins/work/agents/overview-writer.md` (full thinning)

```diff
--- a/plugins/work/agents/overview-writer.md
+++ b/plugins/work/agents/overview-writer.md
@@ -1,58 +1,15 @@
 ---
 name: overview-writer
 description: Generate overview content for story by analyzing commit history.
 tools: Read, Bash, Glob, Grep
 model: haiku
 skills:
   - core:report
 ---

 # Overview Writer

-Analyze commit history to generate structured overview content for the story file.
-
 ## Input
-
-You will receive:
-
 - Branch name
 - Base branch (usually `main`)

 ## Instructions

-1. **Collect Commits**: Run the report skill's collect-commits script ...
-... [remaining ~35 lines deleted] ...
+Follow the preloaded `core:report` skill — Overview Generation subsection.

 ## Output

-Return JSON:
-
-```json
-{
-  "overview": "2-3 sentence summary capturing the branch essence",
-  ...
-}
-```
-
-**CRITICAL**: Return JSON only. Do not commit or modify files.
+Return the overview JSON described in the skill. Return JSON only; do not commit or modify files.
```

### `plugins/work/agents/section-reviewer.md` (full thinning)

```diff
--- a/plugins/work/agents/section-reviewer.md
+++ b/plugins/work/agents/section-reviewer.md
@@ -1,52 +1,14 @@
 ---
 name: section-reviewer
 description: Generate story sections 4-8 (Outcome, Historical Analysis, Concerns, Ideas, Successful Development Patterns) by analyzing archived tickets.
 tools: Read, Glob, Grep
 model: haiku
 skills:
   - core:review-sections
 ---

 # Section Reviewer

-Generate content for story sections 4-8 by analyzing archived tickets for the branch.
-
 ## Input
-
-You will receive:
-
 - Branch name
 - List of archived ticket paths (or Glob pattern to find them)

 ## Instructions

-1. **Read all archived tickets** using Glob pattern ...
-... [remaining ~30 lines deleted] ...
+Follow the preloaded `core:review-sections` skill.

 ## Output

-Return JSON in this format:
-
-```json
-{
-  "outcome": "...",
-  ...
-}
-```
-
-Each field should be markdown-formatted, ready for direct insertion into the story file.
+Return the sections-4-through-8 JSON described in the skill.
```

### `plugins/work/agents/release-note-writer.md` (full thinning)

```diff
--- a/plugins/work/agents/release-note-writer.md
+++ b/plugins/work/agents/release-note-writer.md
@@ -1,75 +1,15 @@
 ---
 name: release-note-writer
 description: Generate release notes from branch story for GitHub Releases.
 tools: Read, Write, Glob, Grep
 skills:
   - core:write-release-note
 ---

 # Release Note Writer

-Generate concise release notes from a branch story.
-
-## Instructions
-
-### Step 1: Read Story File
-
-... [remaining ~55 lines deleted] ...
+## Input
+- Branch name
+- PR URL (passed by story-writer in the invocation prompt)
+
+## Instructions
+
+Follow the preloaded `core:write-release-note` skill.
+
+## Output
+
+Return the release-note JSON described in the skill.
```

## Considerations

- **Behavior preservation is the success criterion** (`plugins/core/skills/report/SKILL.md`, all seven thinned files). The verification grep audits in step 13 are non-optional — every script path, AskUserQuestion option, subagent_type identifier, and commit message template that ran before must still appear in some post-migration file.
- **Skill script path resolution** (`plugins/core/skills/report/SKILL.md`). When orchestration content from `commands/report.md` moves into `core/skills/report/SKILL.md`, all `${CLAUDE_PLUGIN_ROOT}/../core/skills/...` paths must be rewritten to `${CLAUDE_PLUGIN_ROOT}/skills/...` because the file is now inside the same plugin (one level deeper than commands). Failing this produces exit code 127 at runtime per the CLAUDE.md "Skill Script Path Rule".
- **No inline shell logic** (`plugins/core/skills/report/SKILL.md` Run Workflow section). The Workspace Guard / Detect Context routing logic is conditional (`if clean is true ...`). Per CLAUDE.md's Shell Script Principle, conditional logic must not be introduced as inline `if`/`case` in the skill — but the existing report/SKILL.md and commands/report.md already pattern-match: the *script* returns JSON, the *prose* describes how to interpret that JSON. Maintain this pattern; do not introduce inline conditionals.
- **Soft preload of `standards:leading-*` from `core:report`** (`plugins/core/skills/report/SKILL.md` frontmatter). This is the new dependency edge. Soft references (per CLAUDE.md "Plugin Dependencies") are explicitly allowed: core has a documented soft reference to work via `/report` already; adding a soft reference to standards is analogous. Verify the `core/plugin.json` does not require a declared hard dependency on `standards` after this change (it should not, since these are skill-preload references).
- **`leading-*` viewpoint application** (across the skill content). Per the Lead Lens table, the report umbrella's `layer: Config` means apply whichever lead governs the affected behavior. The skill content already encodes accessibility-adjacent practices (AskUserQuestion text, "Ignore and proceed" / "Stop" options favor modeless interaction), validity practices (typed JSON contracts between agents, layer segregation between domain orchestration and vendor `gh` CLI), and availability practices (CI/CD automation, version bumping). The added preloads document these lenses; no policy violations are introduced.
- **Tool-list narrowing is a behavior-affecting change** (each agent's frontmatter). Removing `Edit` or `Write` from an agent's tools list means that agent can no longer perform those operations even if a future skill change asks it to. Verify by tracing each removed tool to confirm no skill instruction depends on it.
- **`story-writer` orchestrates other agents** (`plugins/work/agents/story-writer.md`, parallel-Task block). Its `Task` tool is essential and must remain. The `subagent_type` identifiers (`work:release-readiness`, `work:overview-writer`, `work:section-reviewer`, `work:pr-creator`, `work:release-note-writer`) appear only in the skill's new Orchestration subsection after migration — they must be preserved letter-perfect.
- **`section-reviewer` and `release-note-writer` keep their existing preloads** (`plugins/core/skills/review-sections/SKILL.md`, `plugins/core/skills/write-release-note/SKILL.md`). These are dedicated sibling skills; absorbing them into `core:report` would re-bloat the skill. The decision keeps them as cross-references in the Agent Output Mapping table.
- **CLAUDE.md may need an edit** (`/home/ec2-user/projects/workaholic/CLAUDE.md` Project Structure block). If the work plugin's listed agents change in count or naming, the comment line that enumerates work-side agents should reflect that. Current listing reads "drive-navigator, story-writer, planner, architect, constructor, etc." — no rename, so likely no edit needed; verify before closing.
- **Codex-spec compatibility (user's stated goal)** (`plugins/work/agents/*.md`, `plugins/work/commands/report.md`). The thinned files satisfy the "agents/commands as thin aliases of skills" pattern, which matches the Codex-spec model where the skill is the unit of capability and the agent/command is a typed entry point. Verify the post-migration line counts hold: agents ≤20 lines, command ≤15 lines.
- **Effort estimate ~1.5h** — the heaviest of the current batch of five tickets because six agents plus one command must each be touched verbatim and the skill must absorb two non-trivial sections (Run Workflow + Orchestration) without losing fidelity.
