---
created_at: 2026-02-08T13:17:51+09:00
author: a@qmu.jp
type: refactoring
layer: [UX, Domain]
effort:
commit_hash:
category:
---

# Migrate Scanner Subagent into the Scan Command

## Overview

Migrate the scanner subagent's orchestration logic directly into the `/scan` command so that users can see real-time progress of each individual documentation agent (17 agents total). Currently, the `/scan` command delegates to a single scanner subagent via one Task call, which hides all 17 parallel agent invocations from the user. By moving the orchestration into the command itself, each agent's Task call becomes visible in the user's session, providing transparency into scan progress.

## Key Files

- `plugins/core/commands/scan.md` - The scan command that currently delegates to scanner (will be expanded with full orchestration logic)
- `plugins/core/agents/scanner.md` - The scanner subagent that currently orchestrates all 17 agents (will be removed)
- `plugins/core/commands/story.md` - Also invokes scanner for partial scans (must be updated)
- `plugins/core/skills/select-scan-agents/SKILL.md` - Skill for selecting which agents to invoke based on mode
- `plugins/core/skills/select-scan-agents/sh/select.sh` - Shell script that determines agent selection
- `plugins/core/skills/validate-writer-output/SKILL.md` - Validation skill used by scanner after agent invocation
- `plugins/core/skills/gather-git-context/SKILL.md` - Git context gathering used by scanner
- `plugins/core/skills/write-spec/SKILL.md` - Spec writing guidelines referenced by scanner for index updates

## Related History

Scan infrastructure has evolved through multiple iterations, starting as a sync command and being restructured into the current subagent-based architecture.

Past tickets that touched similar areas:

- [20260127003251-sync-workaholic-subagent.md](.workaholic/tickets/archive/feat-20260126-214833/20260127003251-sync-workaholic-subagent.md) - Created the sync-workaholic subagent, predecessor to scanner (same layer: Domain)
- [20260123135431-rewrite-sync-doc-specs-command.md](.workaholic/tickets/archive/feat-20260123-032323/20260123135431-rewrite-sync-doc-specs-command.md) - Earlier rewrite of the documentation sync command (same command area)
- [20260123003750-dynamic-docs-subagent.md](.workaholic/tickets/archive/feat-20260122-210543/20260123003750-dynamic-docs-subagent.md) - Initial dynamic documentation subagent creation (same pattern)

## Implementation Steps

1. **Expand `plugins/core/commands/scan.md`** to include the full orchestration logic currently in `scanner.md`:
   - Add `skills` references: `gather-git-context`, `select-scan-agents`, `write-spec`, `validate-writer-output`
   - Phase 1: Gather git context (branch, base_branch, repo_url) using the gather-git-context skill
   - Phase 2: Get commit hash via `git rev-parse --short HEAD`
   - Phase 3: Run select-scan-agents skill with `mode: full`
   - Phase 4: Invoke all 17 selected agents in parallel via Task tool calls (each visible to user)
   - Phase 5: Validate output using validate-writer-output skill
   - Phase 6: Update index files (README.md and README_ja.md for specs and policies) following write-spec skill
   - Phase 7: Stage and commit documentation changes
   - Phase 8: Report per-agent status results

2. **Update `plugins/core/commands/story.md`** to inline partial scan orchestration:
   - Same pattern as scan command but with `mode: partial`
   - Phase 1-2: Gather context and commit hash
   - Phase 3: Run select-scan-agents with `mode: partial` and base_branch
   - Phase 4: Invoke only selected agents in parallel via Task tool calls
   - Phase 5: Validate output (only for invoked agent categories)
   - Phase 6: Skip index file updates (partial mode rule)
   - Phase 7: Stage and commit, then continue with story-writer invocation

3. **Remove `plugins/core/agents/scanner.md`** since both consumers now inline the orchestration logic.

4. **Verify skill references** - Ensure all skills previously preloaded by scanner are now preloaded by the commands that replaced it. The skills themselves (`select-scan-agents`, `validate-writer-output`, `gather-git-context`, `write-spec`) remain unchanged.

## Patches

### `plugins/core/commands/scan.md`

> **Note**: This patch is speculative - the exact content may need adjustment based on how the command markdown format handles skill preloading.

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -1,17 +1,82 @@
 ---
 name: scan
 description: Full documentation scan - update all .workaholic/ documentation (changelog, specs, terms, policies).
+skills:
+  - gather-git-context
+  - select-scan-agents
+  - write-spec
+  - validate-writer-output
 ---

 # Scan

 **Notice:** When user input contains `/scan` - whether "run /scan", "do /scan", "update /scan", or similar - they likely want this command.

-Run a full documentation scan by invoking the scanner subagent with all 17 agents.
+Run a full documentation scan by invoking all 17 documentation agents directly, providing real-time progress visibility for each agent.

 ## Instructions

-1. **Invoke scanner** (`subagent_type: "core:scanner"`, `model: "opus"`) with prompt: `"Scan documentation. mode: full"`
-2. **Stage and commit**: `git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ && git commit -m "Update documentation"`
-3. **Report results** from scanner output
+### Phase 1: Gather Context
+
+1. Use the preloaded gather-git-context skill to get branch, base_branch, and repo_url.
+2. Get commit hash: `git rev-parse --short HEAD`
+
+### Phase 2: Select Agents
+
+Run the preloaded select-scan-agents skill:
+
+```bash
+bash .claude/skills/select-scan-agents/sh/select.sh full
+```
+
+Parse the JSON output to get the list of all 17 agents.
+
+### Phase 3: Invoke All Agents in Parallel
+
+Invoke all 17 agents in a single message with parallel Task tool calls (each `model: "sonnet"`):
+
+| Agent slug | `subagent_type` | Prompt context |
+| --- | --- | --- |
+| `stakeholder-analyst` | `core:stakeholder-analyst` | Pass base branch |
+| `model-analyst` | `core:model-analyst` | Pass base branch |
+| `usecase-analyst` | `core:usecase-analyst` | Pass base branch |
+| `infrastructure-analyst` | `core:infrastructure-analyst` | Pass base branch |
+| `application-analyst` | `core:application-analyst` | Pass base branch |
+| `component-analyst` | `core:component-analyst` | Pass base branch |
+| `data-analyst` | `core:data-analyst` | Pass base branch |
+| `feature-analyst` | `core:feature-analyst` | Pass base branch |
+| `test-policy-analyst` | `core:test-policy-analyst` | Pass base branch |
+| `security-policy-analyst` | `core:security-policy-analyst` | Pass base branch |
+| `quality-policy-analyst` | `core:quality-policy-analyst` | Pass base branch |
+| `accessibility-policy-analyst` | `core:accessibility-policy-analyst` | Pass base branch |
+| `observability-policy-analyst` | `core:observability-policy-analyst` | Pass base branch |
+| `delivery-policy-analyst` | `core:delivery-policy-analyst` | Pass base branch |
+| `recovery-policy-analyst` | `core:recovery-policy-analyst` | Pass base branch |
+| `changelog-writer` | `core:changelog-writer` | Pass repository URL |
+| `terms-writer` | `core:terms-writer` | Pass branch name |
+
+All invocations MUST be in a single message to run concurrently.
+
+### Phase 4: Validate Output
+
+Validate viewpoint analyst output:
+
+```bash
+bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/specs stakeholder.md model.md usecase.md infrastructure.md application.md component.md data.md feature.md
+```
+
+Validate policy analyst output:
+
+```bash
+bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/policies test.md security.md quality.md accessibility.md observability.md delivery.md recovery.md
+```
+
+### Phase 5: Update Index Files
+
+- If spec validation passed: Update `.workaholic/specs/README.md` and `README_ja.md` to list all 8 viewpoint documents. Follow the preloaded write-spec skill for index file rules.
+- If policy validation passed: Update `.workaholic/policies/README.md` and `README_ja.md` to list all 7 policy documents.
+
+### Phase 6: Stage and Commit
+
+```bash
+git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ && git commit -m "Update documentation"
+```
+
+### Phase 7: Report Results
+
+Report per-agent status showing which agents succeeded, failed, or were skipped, along with validation results.
```

### `plugins/core/commands/story.md`

> **Note**: This patch is speculative - verify the exact structure matches the scan command pattern.

```diff
--- a/plugins/core/commands/story.md
+++ b/plugins/core/commands/story.md
@@ -1,18 +1,75 @@
 ---
 name: story
 description: Partial-scan documentation, generate story, and create/update PR.
+skills:
+  - gather-git-context
+  - select-scan-agents
+  - write-spec
+  - validate-writer-output
 ---

 # Story

 **Notice:** When user input contains `/story` - whether "run /story", "do /story", "update /story", or similar - they likely want this command.

-Run a partial documentation scan (only agents relevant to branch changes), then generate a story and create or update a pull request.
+Run a partial documentation scan (only agents relevant to branch changes) with visible per-agent progress, then generate a story and create or update a pull request.

 ## Instructions

-1. **Invoke scanner** (`subagent_type: "core:scanner"`, `model: "opus"`) with prompt: `"Scan documentation. mode: partial"`
-2. **Stage and commit**: `git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ && git commit -m "Update documentation"`
-3. **Invoke story-writer** (`subagent_type: "core:story-writer"`, `model: "opus"`)
-4. **Display PR URL** from story-writer result (mandatory)
+### Phase 1: Gather Context
+
+1. Use the preloaded gather-git-context skill to get branch, base_branch, and repo_url.
+2. Get commit hash: `git rev-parse --short HEAD`
+
+### Phase 2: Select Agents
+
+Run the preloaded select-scan-agents skill:
+
+```bash
+bash .claude/skills/select-scan-agents/sh/select.sh partial <base_branch>
+```
+
+Parse the JSON output to get the list of selected agents.
+
+### Phase 3: Invoke Selected Agents in Parallel
+
+Invoke all selected agents in a single message with parallel Task tool calls. Use the agent registry below (each `model: "sonnet"`):
+
+| Agent slug | `subagent_type` | Prompt context |
+| --- | --- | --- |
+| `stakeholder-analyst` | `core:stakeholder-analyst` | Pass base branch |
+| `model-analyst` | `core:model-analyst` | Pass base branch |
+| `usecase-analyst` | `core:usecase-analyst` | Pass base branch |
+| `infrastructure-analyst` | `core:infrastructure-analyst` | Pass base branch |
+| `application-analyst` | `core:application-analyst` | Pass base branch |
+| `component-analyst` | `core:component-analyst` | Pass base branch |
+| `data-analyst` | `core:data-analyst` | Pass base branch |
+| `feature-analyst` | `core:feature-analyst` | Pass base branch |
+| `test-policy-analyst` | `core:test-policy-analyst` | Pass base branch |
+| `security-policy-analyst` | `core:security-policy-analyst` | Pass base branch |
+| `quality-policy-analyst` | `core:quality-policy-analyst` | Pass base branch |
+| `accessibility-policy-analyst` | `core:accessibility-policy-analyst` | Pass base branch |
+| `observability-policy-analyst` | `core:observability-policy-analyst` | Pass base branch |
+| `delivery-policy-analyst` | `core:delivery-policy-analyst` | Pass base branch |
+| `recovery-policy-analyst` | `core:recovery-policy-analyst` | Pass base branch |
+| `changelog-writer` | `core:changelog-writer` | Pass repository URL |
+| `terms-writer` | `core:terms-writer` | Pass branch name |
+
+Only invoke agents that appear in the selected agents list. All invocations MUST be in a single message to run concurrently.
+
+### Phase 4: Validate Output
+
+Only validate output for agent categories that had invoked agents. Build file lists from only the invoked agents.
+
+If any viewpoint analysts were invoked:
+```bash
+bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/specs <invoked_spec_files...>
+```
+
+If any policy analysts were invoked:
+```bash
+bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/policies <invoked_policy_files...>
+```
+
+Skip validation for categories with no invoked agents.
+
+### Phase 5: Stage and Commit
+
+```bash
+git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ && git commit -m "Update documentation"
+```
+
+### Phase 6: Generate Story and PR
+
+1. **Invoke story-writer** (`subagent_type: "core:story-writer"`, `model: "opus"`)
+2. **Display PR URL** from story-writer result (mandatory)
```

## Considerations

- The `/story` command also uses the scanner subagent for partial scans, so both commands must be updated in tandem (`plugins/core/commands/story.md`)
- The scan command will grow from ~17 lines to ~80+ lines, which exceeds the typical command size guideline of 50-100 lines. However, this is justified because the orchestration logic cannot be delegated to a subagent without losing the user-visible progress benefit (`plugins/core/commands/scan.md`)
- The scanner subagent's Phase 5 (index file updates) requires the write-spec skill. The scan command must preload this skill to maintain index update capability (`plugins/core/skills/write-spec/SKILL.md`)
- The `select-scan-agents` skill and its shell script remain unchanged -- they are used the same way whether called from scanner or directly from the command (`plugins/core/skills/select-scan-agents/sh/select.sh`)
- Removing scanner.md means one fewer subagent nesting level -- agents are invoked directly by the command instead of through an intermediary, which simplifies the architecture (`plugins/core/agents/scanner.md`)
- Partial mode in the story command skips index file updates per existing scanner logic -- this behavior must be preserved when inlining (`plugins/core/commands/story.md` lines 14-15)
