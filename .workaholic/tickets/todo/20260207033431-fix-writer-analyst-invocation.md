---
created_at: 2026-02-07T03:34:31+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Fix spec-writer and policy-writer to Actually Invoke Analyst Subagents

## Overview

The `/scan` command's `spec-writer` and `policy-writer` subagents never invoke their child analyst subagents (`architecture-analyst` x8 and `policy-analyst` x7) at runtime. Both writers have `Task` in their tools list and contain explicit step 2 instructions to invoke analysts in parallel, yet the invocations are skipped. The spec-writer proceeds directly to validation (step 3) and README update (step 4), while the policy-writer does the same. The result is that `.workaholic/specs/` contains only legacy documents (`architecture.md`, `command-flows.md`, `contributing.md`) with no viewpoint files (`stakeholder.md`, `model.md`, etc.), and `.workaholic/policies/` contains only `README.md` and `README_ja.md` with no domain files (`test.md`, `security.md`, etc.). The validate-writer-output skill (added in commit d5001a0) correctly catches the missing files but cannot fix the root cause: the Task tool invocations for analyst subagents are never executed.

## Key Files

- `plugins/core/agents/spec-writer.md` - Orchestrator that should invoke 8 `architecture-analyst` subagents via Task tool in step 2; instructions are present but skipped at runtime
- `plugins/core/agents/policy-writer.md` - Orchestrator that should invoke 7 `policy-analyst` subagents via Task tool in step 2; instructions are present but skipped at runtime
- `plugins/core/agents/architecture-analyst.md` - Subagent that writes `.workaholic/specs/<slug>.md` and `<slug>_ja.md`; never actually invoked
- `plugins/core/agents/policy-analyst.md` - Subagent that writes `.workaholic/policies/<slug>.md` and `<slug>_ja.md`; never actually invoked
- `plugins/core/agents/story-writer.md` - Working reference: successfully invokes 4+2 subagents using Phase-based structure with explicit prompts
- `plugins/core/agents/scanner.md` - Parent orchestrator that invokes spec-writer and policy-writer (this level of invocation works correctly)

## Related History

The spec-writer and policy-writer were both created in the current branch to replace ad-hoc spec generation with systematic parallel-analyst orchestration. A validation skill was added after discovering broken README links, but the underlying invocation problem was not resolved. A similar skipped-invocation bug was previously fixed in the story-writer workflow, suggesting this is a recurring pattern with multi-level Task tool orchestration.

Past tickets that touched similar areas:

- [20260207031812-validate-analyst-output-before-readme-update.md](.workaholic/tickets/archive/drive-20260205-195920/20260207031812-validate-analyst-output-before-readme-update.md) - Added validation gates but did not fix the root cause of skipped invocations (same files: spec-writer.md, policy-writer.md)
- [20260207023921-viewpoint-based-spec-architecture.md](.workaholic/tickets/archive/drive-20260205-195920/20260207023921-viewpoint-based-spec-architecture.md) - Created spec-writer orchestration with 8 architecture-analyst subagents (same file: spec-writer.md)
- [20260207024808-add-policy-writer-subagent.md](.workaholic/tickets/archive/drive-20260205-195920/20260207024808-add-policy-writer-subagent.md) - Created policy-writer orchestration with 7 policy-analyst subagents (same file: policy-writer.md)
- [20260131192343-fix-write-story-performance-analyst-invocation.md](.workaholic/tickets/archive/feat-20260131-125844/20260131192343-fix-write-story-performance-analyst-invocation.md) - Fixed a previous skipped-invocation bug in story-writer (same pattern: missing subagent invocation)

## Implementation Steps

1. **Diagnose the root cause** by comparing `spec-writer.md` and `policy-writer.md` against `story-writer.md` (which works). The key structural differences are:

   - `story-writer.md` uses Phase-based headings (`### Phase 1: ...`) that create clear execution boundaries
   - `spec-writer.md` and `policy-writer.md` use a flat numbered list without phase headings
   - `story-writer.md` has concise, action-oriented invocation instructions with explicit `subagent_type` and `model` on each bullet
   - `spec-writer.md` embeds all 8 viewpoint definitions (descriptions, analysis prompts, Mermaid diagram types, output sections) inline before the invocation instruction, creating a large block of reference material that separates the "invoke" instruction from the viewpoint context the model needs to pass
   - `policy-writer.md` has the same structural issue with 7 inline policy domain definitions

2. **Restructure `plugins/core/agents/spec-writer.md`** to follow the working story-writer pattern:

   - Convert flat numbered steps to Phase-based headings (`### Phase 1: Gather Context`, `### Phase 2: Invoke Architecture Analysts`, `### Phase 3: Validate Output`, `### Phase 4: Update Index Files`, `### Phase 5: Report Status`)
   - Move the 8 viewpoint definitions into a reference section above the Instructions (already done -- they are in `## Viewpoints`), and in Phase 2 explicitly reference them: "For each viewpoint defined in the Viewpoints section above, invoke..."
   - In Phase 2, list all 8 invocations as explicit bullet points with `subagent_type`, `model`, and what to pass -- mirroring story-writer's format
   - Add explicit "Wait for all 8 analysts to complete" instruction after the bullet list
   - Ensure Phase 3 (validate) and Phase 4 (update index) cannot proceed until Phase 2 completes

3. **Restructure `plugins/core/agents/policy-writer.md`** with the same Phase-based pattern:

   - Convert flat numbered steps to Phase-based headings (`### Phase 1: Gather Context`, `### Phase 2: Invoke Policy Analysts`, `### Phase 3: Validate Output`, `### Phase 4: Update Index Files`, `### Phase 5: Report Status`)
   - In Phase 2, list all 7 invocations as explicit bullet points
   - Add explicit "Wait for all 7 analysts to complete" instruction
   - Same gating rules as spec-writer

4. **Add explicit invocation examples** in both writers. For each analyst invocation bullet, specify:
   - The `subagent_type` string (e.g., `"core:architecture-analyst"`)
   - The `model` string (e.g., `"sonnet"`)
   - Exactly what to pass in the prompt: the viewpoint/policy slug, its full definition from the reference section, and the base branch
   - Example: `- **stakeholder** (subagent_type: "core:architecture-analyst", model: "sonnet"): Pass viewpoint slug "stakeholder", its full definition (description, analysis prompts, Mermaid diagram type, output sections) from the Viewpoints section above, and the base branch.`

5. **Verify the fix** by running `/scan` and confirming:
   - All 8 viewpoint files are created in `.workaholic/specs/` (stakeholder.md, model.md, usecase.md, infrastructure.md, application.md, component.md, data.md, feature.md)
   - All 7 policy files are created in `.workaholic/policies/` (test.md, security.md, quality.md, accessibility.md, observability.md, delivery.md, recovery.md)
   - Japanese translations are created for each file
   - README index files are updated with valid links
   - The validate-writer-output step reports `"pass": true`

## Patches

### `plugins/core/agents/spec-writer.md`

> **Note**: This patch is speculative - verify current file content before applying. The key change is converting the Instructions section from flat numbered steps to Phase-based headings.

```diff
--- a/plugins/core/agents/spec-writer.md
+++ b/plugins/core/agents/spec-writer.md
@@ -79,18 +79,42 @@

 ## Instructions

-1. **Gather Base Context**: Get the current commit hash for frontmatter:
+### Phase 1: Gather Base Context
+
+Get the current commit hash for frontmatter:
    ```bash
    git rev-parse --short HEAD
    ```

-2. **Invoke 8 Architecture Analysts in Parallel**: Use a single message with 8 Task tool calls.
+### Phase 2: Invoke Architecture Analysts
+
+Invoke all 8 architecture analysts in parallel. Use a single message with 8 Task tool calls.
+
+For each viewpoint defined in the Viewpoints section above, invoke with `subagent_type: "core:architecture-analyst"`, `model: "sonnet"`. Pass the viewpoint slug, its full definition (description, analysis prompts, Mermaid diagram type, output sections), and the base branch.

-   For each viewpoint above, invoke with `subagent_type: "core:architecture-analyst"`, `model: "sonnet"` and pass the viewpoint's full definition (description, analysis prompts, Mermaid diagram type, output sections) in the prompt along with the base branch.
+- **stakeholder** (`subagent_type: "core:architecture-analyst"`, `model: "sonnet"`): Pass slug "stakeholder", definition from Viewpoints section, base branch.
+- **model** (`subagent_type: "core:architecture-analyst"`, `model: "sonnet"`): Pass slug "model", definition from Viewpoints section, base branch.
+- **usecase** (`subagent_type: "core:architecture-analyst"`, `model: "sonnet"`): Pass slug "usecase", definition from Viewpoints section, base branch.
+- **infrastructure** (`subagent_type: "core:architecture-analyst"`, `model: "sonnet"`): Pass slug "infrastructure", definition from Viewpoints section, base branch.
+- **application** (`subagent_type: "core:architecture-analyst"`, `model: "sonnet"`): Pass slug "application", definition from Viewpoints section, base branch.
+- **component** (`subagent_type: "core:architecture-analyst"`, `model: "sonnet"`): Pass slug "component", definition from Viewpoints section, base branch.
+- **data** (`subagent_type: "core:architecture-analyst"`, `model: "sonnet"`): Pass slug "data", definition from Viewpoints section, base branch.
+- **feature** (`subagent_type: "core:architecture-analyst"`, `model: "sonnet"`): Pass slug "feature", definition from Viewpoints section, base branch.

-   All 8 invocations must be in a single message to run concurrently.
+All 8 invocations MUST be in a single message to run concurrently. Wait for all 8 analysts to complete before proceeding.

-3. **Validate Output**: After all analysts complete, verify that each expected output file exists and is non-empty:
+### Phase 3: Validate Output
+
+After all analysts complete, verify that each expected output file exists and is non-empty:
    ```bash
    bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/specs stakeholder.md model.md usecase.md infrastructure.md application.md component.md data.md feature.md
    ```
    Parse the JSON result. If `pass` is `false`, do NOT proceed to Phase 4. Instead, report failure status with the list of missing/empty files.

-4. **Update Index Files**: Only after validation passes, update `.workaholic/specs/README.md` and `README_ja.md` to list all 8 viewpoint documents. Follow the preloaded write-spec skill for index file rules.
+### Phase 4: Update Index Files
+
+Only after validation passes, update `.workaholic/specs/README.md` and `README_ja.md` to list all 8 viewpoint documents. Follow the preloaded write-spec skill for index file rules.

-5. **Report Status**: Collect results from all 8 analysts and report per-viewpoint status. Include validation results.
+### Phase 5: Report Status
+
+Collect results from all 8 analysts and report per-viewpoint status. Include validation results.
```

### `plugins/core/agents/policy-writer.md`

> **Note**: This patch is speculative - verify current file content before applying.

```diff
--- a/plugins/core/agents/policy-writer.md
+++ b/plugins/core/agents/policy-writer.md
@@ -65,18 +65,40 @@

 ## Instructions

-1. **Gather Context**: Use the preloaded gather-git-context skill to get branch and base branch info.
+### Phase 1: Gather Context
+
+Use the preloaded gather-git-context skill to get branch and base branch info.

-2. **Invoke 7 Policy Analysts in Parallel**: Use a single message with 7 Task tool calls.
+### Phase 2: Invoke Policy Analysts
+
+Invoke all 7 policy analysts in parallel. Use a single message with 7 Task tool calls.
+
+For each policy domain defined in the Policy Domains section above, invoke with `subagent_type: "core:policy-analyst"`, `model: "sonnet"`. Pass the policy slug, its full definition (description, analysis prompts, output sections), and the base branch.

-   For each policy domain above, invoke with `subagent_type: "core:policy-analyst"`, `model: "sonnet"` and pass the domain's full definition (description, analysis prompts, output sections) in the prompt along with the base branch.
+- **test** (`subagent_type: "core:policy-analyst"`, `model: "sonnet"`): Pass slug "test", definition from Policy Domains section, base branch.
+- **security** (`subagent_type: "core:policy-analyst"`, `model: "sonnet"`): Pass slug "security", definition from Policy Domains section, base branch.
+- **quality** (`subagent_type: "core:policy-analyst"`, `model: "sonnet"`): Pass slug "quality", definition from Policy Domains section, base branch.
+- **accessibility** (`subagent_type: "core:policy-analyst"`, `model: "sonnet"`): Pass slug "accessibility", definition from Policy Domains section, base branch.
+- **observability** (`subagent_type: "core:policy-analyst"`, `model: "sonnet"`): Pass slug "observability", definition from Policy Domains section, base branch.
+- **delivery** (`subagent_type: "core:policy-analyst"`, `model: "sonnet"`): Pass slug "delivery", definition from Policy Domains section, base branch.
+- **recovery** (`subagent_type: "core:policy-analyst"`, `model: "sonnet"`): Pass slug "recovery", definition from Policy Domains section, base branch.

-   All 7 invocations must be in a single message to run concurrently.
+All 7 invocations MUST be in a single message to run concurrently. Wait for all 7 analysts to complete before proceeding.

-3. **Validate Output**: After all analysts complete, verify that each expected output file exists and is non-empty:
+### Phase 3: Validate Output
+
+After all analysts complete, verify that each expected output file exists and is non-empty:
    ```bash
    bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/policies test.md security.md quality.md accessibility.md observability.md delivery.md recovery.md
    ```
    Parse the JSON result. If `pass` is `false`, do NOT proceed to Phase 4. Instead, report failure status with the list of missing/empty files.

-4. **Update Index Files**: Only after validation passes, update `.workaholic/policies/README.md` and `README_ja.md` to list all 7 policy documents.
+### Phase 4: Update Index Files
+
+Only after validation passes, update `.workaholic/policies/README.md` and `README_ja.md` to list all 7 policy documents.

-5. **Report Status**: Collect results from all 7 analysts and report per-domain status. Include validation results.
+### Phase 5: Report Status
+
+Collect results from all 7 analysts and report per-domain status. Include validation results.
```

## Considerations

- **Root cause hypothesis**: The flat numbered-list instruction format appears to cause the model to "absorb" the viewpoint/policy reference material as context without recognizing step 2 as an actionable Task tool invocation. The story-writer (which works) uses Phase-based headings that create stronger execution boundaries. This is a prompt engineering issue, not a missing-capability issue (`plugins/core/agents/spec-writer.md`, `plugins/core/agents/policy-writer.md`)
- **Explicit bullet list vs generic "for each"**: The current instructions say "For each viewpoint above, invoke with..." which requires the model to enumerate and loop. Listing each invocation explicitly as a bullet point (mirroring story-writer) removes ambiguity about what Task tool calls to make (`plugins/core/agents/spec-writer.md` lines 86-90)
- **Legacy spec files**: After the fix, `.workaholic/specs/` will contain both legacy files (`architecture.md`, `command-flows.md`, `contributing.md`) and new viewpoint files. Consider whether legacy files should be removed or kept as references. The spec-writer currently does not delete legacy files (`plugins/core/agents/spec-writer.md`)
- **Validation gate already exists**: The validate-writer-output skill and validation step 3 are already in place from commit d5001a0. This fix addresses the step before validation -- actually producing the files that validation checks for (`plugins/core/skills/validate-writer-output/sh/validate.sh`)
- **Model parameter**: Both writers specify `model: "sonnet"` for analysts. If sonnet-level models have trouble with the analysis depth required, consider upgrading to `model: "opus"` after initial testing (`plugins/core/agents/spec-writer.md` line 88, `plugins/core/agents/policy-writer.md` line 71)
- **Token budget**: Invoking 8+7 = 15 parallel subagents from a single scan operation generates substantial token usage. The Phase-based structure should not increase token costs beyond the existing (non-working) instructions since the content is the same, just restructured (`plugins/core/agents/scanner.md`)
- **Recurring pattern**: This is the second skipped-invocation bug (after story-writer fix in 20260131192343). Consider whether a generic "invocation checklist" pattern should be documented as a design guideline for all orchestrator subagents (`plugins/core/agents/story-writer.md`)
