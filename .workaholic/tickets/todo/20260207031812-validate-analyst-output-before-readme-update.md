---
created_at: 2026-02-07T03:18:12+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Validate Analyst Output Before README Index Update

## Overview

The `spec-writer` and `policy-writer` subagents both skip step 2 (invoking child analysts) and jump directly to step 3 (updating README indexes). This produces README files that link to non-existent documents. The `spec-writer` updates `.workaholic/specs/README.md` with links to 8 viewpoint files (`stakeholder.md`, `model.md`, etc.) that were never written by `architecture-analyst` subagents. The `policy-writer` updates `.workaholic/policies/README.md` with links to 7 policy files (`test.md`, `security.md`, etc.) that were never written by `policy-analyst` subagents. The root cause is that both subagent instructions lack enforcement to verify analyst invocations actually ran and produced output files before proceeding to README updates.

## Key Files

- `plugins/core/agents/spec-writer.md` - Orchestrator for 8 parallel architecture-analyst subagents; step 2 (invoke analysts) is skipped at runtime
- `plugins/core/agents/policy-writer.md` - Orchestrator for 7 parallel policy-analyst subagents; step 2 (invoke analysts) is skipped at runtime
- `plugins/core/agents/architecture-analyst.md` - Subagent that writes `.workaholic/specs/<slug>.md` and `<slug>_ja.md`; never actually invoked
- `plugins/core/agents/policy-analyst.md` - Subagent that writes `.workaholic/policies/<slug>.md` and `<slug>_ja.md`; never actually invoked
- `plugins/core/skills/write-spec/SKILL.md` - Index file update rules that spec-writer follows when writing README
- `.workaholic/specs/README.md` - Currently contains broken links to 8 non-existent viewpoint files
- `.workaholic/policies/README.md` - Currently contains broken links to 7 non-existent policy files

## Related History

The spec-writer and policy-writer were both created in the current branch as parallel orchestration subagents modeled on the scanner pattern. The filesystem validation ticket added structure-checking to the old spec-writer but did not address the analyst-invocation skipping problem, which emerged after the viewpoint-based rewrite.

Past tickets that touched similar areas:

- [20260207023921-viewpoint-based-spec-architecture.md](.workaholic/tickets/archive/drive-20260205-195920/20260207023921-viewpoint-based-spec-architecture.md) - Created spec-writer orchestration with 8 architecture-analyst subagents (same file: spec-writer.md)
- [20260207024808-add-policy-writer-subagent.md](.workaholic/tickets/archive/drive-20260205-195920/20260207024808-add-policy-writer-subagent.md) - Created policy-writer orchestration with 7 policy-analyst subagents (same file: policy-writer.md)
- [20260205203449-add-filesystem-validation-to-spec-writer.md](.workaholic/tickets/archive/drive-20260205-195920/20260205203449-add-filesystem-validation-to-spec-writer.md) - Added ACTUAL STRUCTURE validation to spec-writer (same layer: Config)
- [20260131192343-fix-write-story-performance-analyst-invocation.md](.workaholic/tickets/archive/feat-20260131-125844/20260131192343-fix-write-story-performance-analyst-invocation.md) - Fixed a similar skipped-invocation bug in story-writer (same pattern: missing subagent invocation)

## Implementation Steps

1. **Create validation skill script `plugins/core/skills/validate-writer-output/sh/validate.sh`** that accepts a directory path and a list of expected filenames, checks that each file exists and is non-empty, and outputs JSON with per-file status and an overall pass/fail result.

2. **Create skill definition `plugins/core/skills/validate-writer-output/SKILL.md`** documenting the validation script's interface, expected arguments, and output format.

3. **Update `plugins/core/agents/spec-writer.md`** to add a validation step between analyst invocation and README update:
   - Add `validate-writer-output` to the `skills` list in frontmatter
   - After step 2 (invoke 8 architecture analysts), add a new step 3: "Validate Output" that runs the validation script against `.workaholic/specs/` for all 8 expected viewpoint files
   - Add explicit instruction: "Do NOT proceed to README updates if any analyst output file is missing or empty. Report failure status instead."
   - Renumber subsequent steps accordingly

4. **Update `plugins/core/agents/policy-writer.md`** to add the same validation step:
   - Add `validate-writer-output` to the `skills` list in frontmatter
   - After step 2 (invoke 7 policy analysts), add a new step 3: "Validate Output" that runs the validation script against `.workaholic/policies/` for all 7 expected policy files
   - Add explicit instruction: "Do NOT proceed to README updates if any analyst output file is missing or empty. Report failure status instead."
   - Renumber subsequent steps accordingly

5. **Update output JSON schemas** in both `spec-writer.md` and `policy-writer.md` to include a `"validation"` field reporting which files passed/failed validation, enabling the parent scanner to detect incomplete runs.

6. **Fix broken README files** by removing the links to non-existent files from `.workaholic/specs/README.md` and `.workaholic/policies/README.md`, restoring them to only link to documents that actually exist on disk.

## Patches

### `plugins/core/agents/spec-writer.md`

```diff
--- a/plugins/core/agents/spec-writer.md
+++ b/plugins/core/agents/spec-writer.md
@@ -4,6 +4,7 @@ tools: Read, Write, Edit, Bash, Glob, Grep, Task
 skills:
   - analyze-viewpoint
   - write-spec
+  - validate-writer-output
 ---
```

```diff
--- a/plugins/core/agents/spec-writer.md
+++ b/plugins/core/agents/spec-writer.md
@@ -89,7 +89,15 @@

    All 8 invocations must be in a single message to run concurrently.

-3. **Update Index Files**: After all analysts complete, update `.workaholic/specs/README.md` and `README_ja.md` to list all 8 viewpoint documents. Follow the preloaded write-spec skill for index file rules.
+3. **Validate Output**: After all analysts complete, verify that each expected output file exists and is non-empty:
+   ```bash
+   bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/specs stakeholder.md model.md usecase.md infrastructure.md application.md component.md data.md feature.md
+   ```
+   Parse the JSON result. If any file is missing or empty, do NOT proceed to step 4. Instead, report failure status with the list of missing files.

-4. **Report Status**: Collect results from all 8 analysts and report per-viewpoint status.
+4. **Update Index Files**: Only after validation passes, update `.workaholic/specs/README.md` and `README_ja.md` to list all 8 viewpoint documents. Follow the preloaded write-spec skill for index file rules.
+
+5. **Report Status**: Collect results from all 8 analysts and report per-viewpoint status. Include validation results.
```

### `plugins/core/agents/policy-writer.md`

```diff
--- a/plugins/core/agents/policy-writer.md
+++ b/plugins/core/agents/policy-writer.md
@@ -5,6 +5,7 @@ tools: Read, Write, Edit, Bash, Glob, Grep, Task
 skills:
   - gather-git-context
   - analyze-policy
+  - validate-writer-output
 ---
```

```diff
--- a/plugins/core/agents/policy-writer.md
+++ b/plugins/core/agents/policy-writer.md
@@ -72,7 +72,15 @@

    All 7 invocations must be in a single message to run concurrently.

-3. **Update Index Files**: After all analysts complete, update `.workaholic/policies/README.md` and `README_ja.md` to list all 7 policy documents.
+3. **Validate Output**: After all analysts complete, verify that each expected output file exists and is non-empty:
+   ```bash
+   bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/policies test.md security.md quality.md accessibility.md observability.md delivery.md recovery.md
+   ```
+   Parse the JSON result. If any file is missing or empty, do NOT proceed to step 4. Instead, report failure status with the list of missing files.

-4. **Report Status**: Collect results from all 7 analysts and report per-domain status.
+4. **Update Index Files**: Only after validation passes, update `.workaholic/policies/README.md` and `README_ja.md` to list all 7 policy documents.
+
+5. **Report Status**: Collect results from all 7 analysts and report per-domain status. Include validation results.
```

> **Note**: These patches are speculative - verify current file content before applying, particularly the exact line numbers around steps 2-4.

## Considerations

- The validation script must follow the shell script principle from CLAUDE.md: all conditional logic belongs in the script, not inline in subagent markdown (`plugins/core/skills/validate-writer-output/sh/validate.sh`)
- The validation step adds latency between analyst completion and README update, but this is negligible since it only checks file existence (`plugins/core/agents/spec-writer.md`, `plugins/core/agents/policy-writer.md`)
- The broken README files should be fixed in this ticket rather than waiting for a subsequent `/scan` run, because the current state will cause confusion for anyone browsing `.workaholic/` (`plugins/core/agents/spec-writer.md` lines 91-92)
- The validation script should also check for the `_ja.md` translation files alongside the primary files, since both spec-writer and policy-writer expect bilingual output (`plugins/core/skills/validate-writer-output/sh/validate.sh`)
- Consider whether partial success should be allowed (e.g., 6 of 8 analysts succeed and README links only the 6 that exist), or if all-or-nothing is preferred. The initial implementation should require all files to exist, with partial success as a future enhancement (`plugins/core/agents/spec-writer.md`)
- The existing `write-spec` skill's "No orphan documents" critical rule already implies this validation should happen, but it was not enforced procedurally (`plugins/core/skills/write-spec/SKILL.md` line 173)
- A similar skipped-invocation bug was fixed previously in story-writer (`20260131192343`), suggesting this is a recurring pattern that the validation skill can address generically across all writer subagents (`plugins/core/agents/scanner.md`)
