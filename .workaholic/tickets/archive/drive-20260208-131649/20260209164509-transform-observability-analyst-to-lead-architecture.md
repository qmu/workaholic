---
created_at: 2026-02-09T16:45:09+08:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: eede80c
category:
---

# Transform Observability Policy Analyst to Lead-Based Architecture

## Overview

Refactor the `observability-policy-analyst` subagent into a lead-based architecture using the `define-lead` skill. This involves creating a new `lead-observability` skill that encodes the observability domain knowledge in the define-lead schema format (Role, Responsibility, Goal, Default Policies), then replacing the existing subagent file with a thin `observability-lead.md` orchestrator that preloads the skill and delegates to it. This follows the proven pattern from the a11y-lead conversion.

## Key Files

- `plugins/core/agents/observability-policy-analyst.md` - Current subagent to be replaced with `observability-lead.md`
- `plugins/core/skills/define-lead/SKILL.md` - Schema template and guidelines that the new lead skill must follow
- `plugins/core/skills/analyze-policy/SKILL.md` - Existing policy analysis framework skill (still needed by the lead)
- `plugins/core/commands/scan.md` - Invokes `core:observability-policy-analyst` by subagent_type (must update reference)
- `plugins/core/skills/select-scan-agents/sh/select.sh` - References `observability-policy-analyst` in ALL_AGENTS list (must update reference)
- `plugins/core/agents/a11y-lead.md` - Reference implementation of the lead agent pattern
- `plugins/core/skills/lead-a11y/SKILL.md` - Reference implementation of the lead skill pattern

## Related History

The define-lead skill and a11y-lead conversion established the pattern that this ticket follows.

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead skill with schema template, guidelines, and validation checklist (direct prerequisite)
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - First lead migration: accessibility-policy-analyst to a11y-lead (proven pattern to follow)

## Implementation Steps

1. **Create the `lead-observability` skill directory and SKILL.md**

   Create `plugins/core/skills/lead-observability/SKILL.md` following the define-lead schema. The skill must contain:

   - Frontmatter with `name: observability-lead`, `description`, and `skills: [define-lead]`
   - `## Role` - Define the agent as the observability authority: owns the observability strategy including metrics collection, logging practices, tracing implementation, and alerting thresholds
   - `## Responsibility` - Minimum duties: ensure every policy scan produces accurate observability documentation; ensure logging practices are analyzed; ensure metrics collection is documented; ensure tracing and monitoring tools are documented; ensure alerting thresholds are documented; ensure gaps are clearly identified
   - `## Goal` - Measurable completion: the `.workaholic/policies/observability.md` accurately reflects all implemented observability practices, with no fabricated policies and all gaps marked as "not observed". Translations are produced only when the user's root CLAUDE.md declares translation requirements.
   - `## Default Policies` with all four subsections:
     - `### Implementation` - Rules for writing observability policy documents: only document implemented practices, cite enforcement mechanisms, use analyze-policy output template. Translation follows user policy (declared in root CLAUDE.md), not hardcoded.
     - `### Review` - Rules for reviewing observability artifacts: verify every statement has a codebase citation, flag aspirational claims, check all output sections are present (Logging Practices, Metrics Collection, Tracing and Monitoring, Alerting)
     - `### Documentation` - Rules for documentation output: follow analyze-policy template structure, include Observations and Gaps sections, use the policy slug "observability"
     - `### Execution` - Rules for execution: gather context via `bash .claude/skills/analyze-policy/sh/gather.sh observability main`, analyze codebase using the defined analysis prompts, write English policy then produce translations per user's translation policy

2. **Replace `observability-policy-analyst.md` with `observability-lead.md`**

   Delete `plugins/core/agents/observability-policy-analyst.md` and create `plugins/core/agents/observability-lead.md` as a thin, multi-purpose orchestrator following the agent template from define-lead skill.

   - Use frontmatter: `name: observability-lead`, `description`, `tools: Read, Write, Edit, Bash, Glob, Grep`, `skills: [lead-observability, analyze-policy, translate]`
   - Preload the `lead-observability` skill for domain knowledge and policies
   - Follow the same Instructions section pattern as `a11y-lead.md`

3. **Update scan command agent reference**

   In `plugins/core/commands/scan.md`, update the table row from `observability-policy-analyst` / `core:observability-policy-analyst` to `observability-lead` / `core:observability-lead`.

4. **Update select-scan-agents script**

   In `plugins/core/skills/select-scan-agents/sh/select.sh`, replace `observability-policy-analyst` with `observability-lead` in the `ALL_AGENTS` variable on line 16.

## Patches

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -52,7 +52,7 @@
 | `a11y-lead` | `core:a11y-lead` | Pass base branch |
-| `observability-policy-analyst` | `core:observability-policy-analyst` | Pass base branch |
+| `observability-lead` | `core:observability-lead` | Pass base branch |
 | `delivery-policy-analyst` | `core:delivery-policy-analyst` | Pass base branch |
```

### `plugins/core/skills/select-scan-agents/sh/select.sh`

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -13,7 +13,7 @@
 BASE_BRANCH="${2:-}"

-ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-policy-analyst quality-policy-analyst a11y-lead observability-policy-analyst delivery-policy-analyst recovery-policy-analyst changelog-writer terms-writer"
+ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-policy-analyst quality-policy-analyst a11y-lead observability-lead delivery-policy-analyst recovery-policy-analyst changelog-writer terms-writer"
```

## Considerations

- The agent name change from `observability-policy-analyst` to `observability-lead` affects the `subagent_type` used in scan command invocations; the scan command table and the select script must both be updated atomically (`plugins/core/commands/scan.md`, `plugins/core/skills/select-scan-agents/sh/select.sh`)
- The validation script in scan Phase 4 references `observability.md` as a policy output file, which does not change since the policy slug remains "observability" (`plugins/core/commands/scan.md` line 72)
- No partial scan mapping references `observability-policy-analyst` in the current `select.sh`, so only the ALL_AGENTS line needs updating (`plugins/core/skills/select-scan-agents/sh/select.sh` line 16)
- Follow the exact structure of `plugins/core/skills/lead-a11y/SKILL.md` and `plugins/core/agents/a11y-lead.md` as reference implementations

## Final Report

All four implementation steps completed as specified:

1. Created `plugins/core/skills/lead-observability/SKILL.md` with Role, Responsibility, Goal, and Default Policies (Implementation, Review, Documentation, Execution) following the define-lead schema and mirroring the lead-a11y reference.
2. Deleted `plugins/core/agents/observability-policy-analyst.md` and created `plugins/core/agents/observability-lead.md` as a thin orchestrator preloading lead-observability, analyze-policy, and translate skills.
3. Updated `plugins/core/commands/scan.md` table row from `observability-policy-analyst`/`core:observability-policy-analyst` to `observability-lead`/`core:observability-lead`.
4. Updated `plugins/core/skills/select-scan-agents/sh/select.sh` ALL_AGENTS variable, replacing `observability-policy-analyst` with `observability-lead`.
