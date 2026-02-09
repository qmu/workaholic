---
created_at: 2026-02-09T16:22:49+08:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.5h
commit_hash: 5a6b50a
category: Changed
---

# Transform Accessibility Policy Analyst to Lead-Based Architecture

## Overview

Refactor the `accessibility-policy-analyst` subagent into a lead-based architecture using the `define-lead` skill. This involves creating a new `lead-a11y` skill that encodes the accessibility domain knowledge in the define-lead schema format (Role, Responsibility, Goal, Default Policies), then replacing the existing subagent file with a thin `a11y-lead.md` orchestrator that preloads the skill and delegates to it. This follows the "thin orchestrators, comprehensive skills" principle from the project architecture policy.

## Key Files

- `plugins/core/agents/accessibility-policy-analyst.md` - Current subagent to be replaced with `a11y-lead.md`
- `plugins/core/skills/define-lead/SKILL.md` - Schema template and guidelines that the new lead skill must follow
- `plugins/core/skills/analyze-policy/SKILL.md` - Existing policy analysis framework skill (still needed by the lead)
- `plugins/core/commands/scan.md` - Invokes `core:accessibility-policy-analyst` by subagent_type (must update reference)
- `plugins/core/skills/select-scan-agents/sh/select.sh` - References `accessibility-policy-analyst` in ALL_AGENTS list (must update reference)

## Related History

The define-lead skill was recently created to standardize lead agent definitions, and this ticket is the first application of that schema to an existing subagent.

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead skill with schema template, guidelines, and validation checklist (direct prerequisite)
- [20260207035026-flatten-scan-writer-nesting.md](.workaholic/tickets/archive/drive-20260205-195920/20260207035026-flatten-scan-writer-nesting.md) - Created all policy analyst subagents as flat dedicated agents including accessibility-policy-analyst (created the file being refactored)

## Implementation Steps

1. **Create the `lead-a11y` skill directory and SKILL.md**

   Create `plugins/core/skills/lead-a11y/SKILL.md` following the define-lead schema. The skill must contain:

   - Frontmatter with `name: a11y-lead`, `description`, and `skills: [define-lead]`
   - `## Role` - Define the agent as the accessibility authority: owns compliance targets, i18n support, assistive technology considerations, and inclusive design practices for the project
   - `## Responsibility` - Minimum duties: ensure every policy scan produces accurate accessibility documentation; ensure i18n/l10n support is analyzed; ensure accessibility testing is documented; ensure gaps are clearly identified
   - `## Goal` - Measurable completion: the `.workaholic/policies/accessibility.md` accurately reflects all implemented accessibility practices, with no fabricated policies and all gaps marked as "not observed". Translations are produced only when the user's root CLAUDE.md declares translation requirements.
   - `## Default Policies` with all four subsections:
     - `### Implementation` - Rules for writing accessibility policy documents: only document implemented practices, cite enforcement mechanisms, use analyze-policy output template. Translation follows user policy (declared in root CLAUDE.md), not hardcoded.
     - `### Review` - Rules for reviewing accessibility artifacts: verify every statement has a codebase citation, flag aspirational claims, check all output sections are present (Internationalization, Supported Languages, Translation Workflow, Accessibility Testing)
     - `### Documentation` - Rules for documentation output: follow analyze-policy template structure, include Observations and Gaps sections, use the policy slug "accessibility"
     - `### Execution` - Rules for execution: gather context via `bash .claude/skills/analyze-policy/sh/gather.sh accessibility main`, analyze codebase using the defined analysis prompts, write English policy then produce translations per user's translation policy

2. **Replace `accessibility-policy-analyst.md` with `a11y-lead.md`**

   Delete `plugins/core/agents/accessibility-policy-analyst.md` and create `plugins/core/agents/a11y-lead.md` as a thin, multi-purpose orchestrator. The agent is not limited to policy analysis — it can be invoked for any task within its domain (implementation, review, documentation, execution). It reads the task from the caller's prompt and applies the corresponding Default Policy from the lead-a11y skill.

   - Use frontmatter: `name: a11y-lead`, `description`, `tools: Read, Write, Edit, Bash, Glob, Grep`, `skills: [lead-a11y, analyze-policy, translate]`
   - Preload the `lead-a11y` skill for domain knowledge and policies
   - Determine which Default Policy applies based on the caller's prompt
   - Execute the task following the lead's Role, Responsibility, and applicable policy

3. **Update define-lead skill with Agent Template section**

   Add an Agent Template section to `plugins/core/skills/define-lead/SKILL.md` that provides the thin, multi-purpose agent pattern for leads. The agent template should show how to create a generic orchestrator that routes to the correct Default Policy based on the caller's prompt.

4. **Update scan command agent reference**

   In `plugins/core/commands/scan.md`, update the table row from `accessibility-policy-analyst` / `core:accessibility-policy-analyst` to `a11y-lead` / `core:a11y-lead`.

4. **Update select-scan-agents script**

   In `plugins/core/skills/select-scan-agents/sh/select.sh`, replace `accessibility-policy-analyst` with `a11y-lead` in the `ALL_AGENTS` variable on line 16.

## Patches

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -48,7 +48,7 @@
 | `quality-policy-analyst` | `core:quality-policy-analyst` | Pass base branch |
-| `accessibility-policy-analyst` | `core:accessibility-policy-analyst` | Pass base branch |
+| `a11y-lead` | `core:a11y-lead` | Pass base branch |
 | `observability-policy-analyst` | `core:observability-policy-analyst` | Pass base branch |
```

### `plugins/core/skills/select-scan-agents/sh/select.sh`

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -13,7 +13,7 @@
 BASE_BRANCH="${2:-}"

-ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-policy-analyst quality-policy-analyst accessibility-policy-analyst observability-policy-analyst delivery-policy-analyst recovery-policy-analyst changelog-writer terms-writer"
+ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-policy-analyst quality-policy-analyst a11y-lead observability-policy-analyst delivery-policy-analyst recovery-policy-analyst changelog-writer terms-writer"

 if [ -z "$MODE" ]; then
```

## Considerations

- The agent name change from `accessibility-policy-analyst` to `a11y-lead` affects the `subagent_type` used in scan command invocations; the scan command table and the select script must both be updated atomically (`plugins/core/commands/scan.md`, `plugins/core/skills/select-scan-agents/sh/select.sh`)
- The validation script in scan Phase 4 references `accessibility.md` as a policy output file, which does not change since the policy slug remains "accessibility" (`plugins/core/commands/scan.md` line 72)
- Several `.workaholic/specs/` files reference `accessibility-policy-analyst` in their documentation; these will be regenerated by the next `/scan` run and do not need manual updating (`.workaholic/specs/component.md`, `.workaholic/specs/feature.md`, `.workaholic/specs/model.md`)
- This is the first lead migration for a policy analyst; the pattern established here should be followed when migrating other policy analysts (e.g., `quality-policy-analyst`, `security-policy-analyst`) to lead architecture in the future
- The `lead-a11y` skill name follows the `lead-<speciality>` naming for skills, while the agent file uses `<speciality>-lead` naming per the define-lead schema; this distinguishes the skill directory from the agent file (`plugins/core/skills/lead-a11y/` vs `plugins/core/agents/a11y-lead.md`)

## Final Report

Transformed the accessibility-policy-analyst into a lead-based architecture across 4 files. Created `plugins/core/skills/lead-a11y/SKILL.md` following the define-lead schema with Role, Responsibility, Goal, and Default Policies (Implementation, Review, Documentation, Execution). Translation is not hardcoded — defers to the user's root CLAUDE.md. Replaced `accessibility-policy-analyst.md` with `a11y-lead.md` as a thin multi-purpose orchestrator (25 lines) that routes to the correct Default Policy based on the caller's prompt. Updated `define-lead/SKILL.md` with an Agent Template section documenting this multi-purpose thin agent pattern. Updated scan.md and select.sh references from `accessibility-policy-analyst` to `a11y-lead`.
