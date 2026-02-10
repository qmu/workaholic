---
created_at: 2026-02-09T16:45:08+08:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: 29acdde
category:
---

# Transform Quality Policy Analyst to Lead-Based Architecture

## Overview

Refactor the `quality-policy-analyst` subagent into a lead-based architecture using the `define-lead` skill. This involves creating a new `lead-quality` skill that encodes the quality domain knowledge in the define-lead schema format (Role, Responsibility, Goal, Default Policies), then replacing the existing subagent file with a thin `quality-lead.md` orchestrator that preloads the skill and delegates to it. This follows the proven pattern from the a11y-lead conversion.

## Key Files

- `plugins/core/agents/quality-policy-analyst.md` - Current subagent to be replaced with `quality-lead.md`
- `plugins/core/skills/define-lead/SKILL.md` - Schema template and guidelines that the new lead skill must follow
- `plugins/core/skills/analyze-policy/SKILL.md` - Existing policy analysis framework skill (still needed by the lead)
- `plugins/core/commands/scan.md` - Invokes `core:quality-policy-analyst` by subagent_type (must update reference)
- `plugins/core/skills/select-scan-agents/sh/select.sh` - References `quality-policy-analyst` in ALL_AGENTS list and in partial scan mapping (must update both references)
- `plugins/core/agents/a11y-lead.md` - Reference implementation of the lead agent pattern
- `plugins/core/skills/lead-a11y/SKILL.md` - Reference implementation of the lead skill pattern

## Related History

The define-lead skill and a11y-lead conversion established the pattern that this ticket follows.

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead skill with schema template, guidelines, and validation checklist (direct prerequisite)
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - First lead migration: accessibility-policy-analyst to a11y-lead (proven pattern to follow)

## Implementation Steps

1. **Create the `lead-quality` skill directory and SKILL.md**

   Create `plugins/core/skills/lead-quality/SKILL.md` following the define-lead schema. The skill must contain:

   - Frontmatter with `name: quality-lead`, `description`, and `skills: [define-lead]`
   - `## Role` - Define the agent as the quality authority: owns code quality standards, linting rules, review processes, and metrics used to maintain maintainability
   - `## Responsibility` - Minimum duties: ensure every policy scan produces accurate quality documentation; ensure linting and formatting tools are analyzed; ensure code review processes are documented; ensure quality metrics and thresholds are documented; ensure type safety enforcement is documented; ensure gaps are clearly identified
   - `## Goal` - Measurable completion: the `.workaholic/policies/quality.md` accurately reflects all implemented quality practices, with no fabricated policies and all gaps marked as "not observed". Translations are produced only when the user's root CLAUDE.md declares translation requirements.
   - `## Default Policies` with all four subsections:
     - `### Implementation` - Rules for writing quality policy documents: only document implemented practices, cite enforcement mechanisms, use analyze-policy output template. Translation follows user policy (declared in root CLAUDE.md), not hardcoded.
     - `### Review` - Rules for reviewing quality artifacts: verify every statement has a codebase citation, flag aspirational claims, check all output sections are present (Linting and Formatting, Code Review, Quality Metrics, Type Safety)
     - `### Documentation` - Rules for documentation output: follow analyze-policy template structure, include Observations and Gaps sections, use the policy slug "quality"
     - `### Execution` - Rules for execution: gather context via `bash .claude/skills/analyze-policy/sh/gather.sh quality main`, analyze codebase using the defined analysis prompts, write English policy then produce translations per user's translation policy

2. **Replace `quality-policy-analyst.md` with `quality-lead.md`**

   Delete `plugins/core/agents/quality-policy-analyst.md` and create `plugins/core/agents/quality-lead.md` as a thin, multi-purpose orchestrator following the agent template from define-lead skill.

   - Use frontmatter: `name: quality-lead`, `description`, `tools: Read, Write, Edit, Bash, Glob, Grep`, `skills: [lead-quality, analyze-policy, translate]`
   - Preload the `lead-quality` skill for domain knowledge and policies
   - Follow the same Instructions section pattern as `a11y-lead.md`

3. **Update scan command agent reference**

   In `plugins/core/commands/scan.md`, update the table row from `quality-policy-analyst` / `core:quality-policy-analyst` to `quality-lead` / `core:quality-lead`.

4. **Update select-scan-agents script**

   In `plugins/core/skills/select-scan-agents/sh/select.sh`, replace `quality-policy-analyst` with `quality-lead` in the `ALL_AGENTS` variable on line 16. Also update the partial scan mapping on line 88 where `plugins/core/rules/*` changes trigger `quality-policy-analyst` -- replace with `quality-lead`.

## Patches

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -50,7 +50,7 @@
 | `security-policy-analyst` | `core:security-policy-analyst` | Pass base branch |
-| `quality-policy-analyst` | `core:quality-policy-analyst` | Pass base branch |
+| `quality-lead` | `core:quality-lead` | Pass base branch |
 | `a11y-lead` | `core:a11y-lead` | Pass base branch |
```

### `plugins/core/skills/select-scan-agents/sh/select.sh`

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -13,7 +13,7 @@
 BASE_BRANCH="${2:-}"

-ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-policy-analyst quality-policy-analyst a11y-lead observability-policy-analyst delivery-policy-analyst recovery-policy-analyst changelog-writer terms-writer"
+ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-policy-analyst quality-lead a11y-lead observability-policy-analyst delivery-policy-analyst recovery-policy-analyst changelog-writer terms-writer"
```

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -85,7 +85,7 @@
   case "$path" in
     plugins/core/rules/*)
-      touch "$TMPDIR_SEL/quality-policy-analyst"
+      touch "$TMPDIR_SEL/quality-lead"
       touch "$TMPDIR_SEL/component-analyst"
       ;;
   esac
```

## Considerations

- The agent name change from `quality-policy-analyst` to `quality-lead` affects the `subagent_type` used in scan command invocations; the scan command table and the select script must both be updated atomically (`plugins/core/commands/scan.md`, `plugins/core/skills/select-scan-agents/sh/select.sh`)
- The partial scan mapping in `select.sh` on line 88 also references `quality-policy-analyst` for `plugins/core/rules/*` changes; this must be updated to `quality-lead` (`plugins/core/skills/select-scan-agents/sh/select.sh` lines 85-90)
- The validation script in scan Phase 4 references `quality.md` as a policy output file, which does not change since the policy slug remains "quality" (`plugins/core/commands/scan.md` line 72)
- Follow the exact structure of `plugins/core/skills/lead-a11y/SKILL.md` and `plugins/core/agents/a11y-lead.md` as reference implementations

## Final Report

All four implementation steps completed as specified:

1. Created `plugins/core/skills/lead-quality/SKILL.md` with Role, Responsibility, Goal, and Default Policies (Implementation, Review, Documentation, Execution) following the define-lead schema and mirroring the lead-a11y reference.
2. Deleted `plugins/core/agents/quality-policy-analyst.md` and created `plugins/core/agents/quality-lead.md` as a thin orchestrator preloading lead-quality, analyze-policy, and translate skills.
3. Updated `plugins/core/commands/scan.md` table row from `quality-policy-analyst`/`core:quality-policy-analyst` to `quality-lead`/`core:quality-lead`.
4. Updated `plugins/core/skills/select-scan-agents/sh/select.sh` ALL_AGENTS variable and partial scan mapping (`plugins/core/rules/*` trigger), replacing `quality-policy-analyst` with `quality-lead`.
