---
created_at: 2026-02-09T16:45:11+08:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Transform Recovery Policy Analyst to Lead-Based Architecture

## Overview

Refactor the `recovery-policy-analyst` subagent into a lead-based architecture using the `define-lead` skill. This involves creating a new `lead-recovery` skill that encodes the recovery domain knowledge in the define-lead schema format (Role, Responsibility, Goal, Default Policies), then replacing the existing subagent file with a thin `recovery-lead.md` orchestrator that preloads the skill and delegates to it. This follows the proven pattern from the a11y-lead conversion.

## Key Files

- `plugins/core/agents/recovery-policy-analyst.md` - Current subagent to be replaced with `recovery-lead.md`
- `plugins/core/skills/define-lead/SKILL.md` - Schema template and guidelines that the new lead skill must follow
- `plugins/core/skills/analyze-policy/SKILL.md` - Existing policy analysis framework skill (still needed by the lead)
- `plugins/core/commands/scan.md` - Invokes `core:recovery-policy-analyst` by subagent_type (must update reference)
- `plugins/core/skills/select-scan-agents/sh/select.sh` - References `recovery-policy-analyst` in ALL_AGENTS list (must update reference)
- `plugins/core/agents/a11y-lead.md` - Reference implementation of the lead agent pattern
- `plugins/core/skills/lead-a11y/SKILL.md` - Reference implementation of the lead skill pattern

## Related History

The define-lead skill and a11y-lead conversion established the pattern that this ticket follows.

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead skill with schema template, guidelines, and validation checklist (direct prerequisite)
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - First lead migration: accessibility-policy-analyst to a11y-lead (proven pattern to follow)

## Implementation Steps

1. **Create the `lead-recovery` skill directory and SKILL.md**

   Create `plugins/core/skills/lead-recovery/SKILL.md` following the define-lead schema. The skill must contain:

   - Frontmatter with `name: recovery-lead`, `description`, and `skills: [define-lead]`
   - `## Role` - Define the agent as the recovery authority: owns data backup schedules, retention policies, disaster recovery procedures, and RTO/RPO targets
   - `## Responsibility` - Minimum duties: ensure every policy scan produces accurate recovery documentation; ensure data persistence mechanisms are analyzed; ensure backup and snapshot capabilities are documented; ensure migration strategies are documented; ensure recovery procedures are documented; ensure gaps are clearly identified
   - `## Goal` - Measurable completion: the `.workaholic/policies/recovery.md` accurately reflects all implemented recovery practices, with no fabricated policies and all gaps marked as "not observed". Translations are produced only when the user's root CLAUDE.md declares translation requirements.
   - `## Default Policies` with all four subsections:
     - `### Implementation` - Rules for writing recovery policy documents: only document implemented practices, cite enforcement mechanisms, use analyze-policy output template. Translation follows user policy (declared in root CLAUDE.md), not hardcoded.
     - `### Review` - Rules for reviewing recovery artifacts: verify every statement has a codebase citation, flag aspirational claims, check all output sections are present (Data Persistence, Backup Strategy, Migration Procedures, Recovery Plan)
     - `### Documentation` - Rules for documentation output: follow analyze-policy template structure, include Observations and Gaps sections, use the policy slug "recovery"
     - `### Execution` - Rules for execution: gather context via `bash .claude/skills/analyze-policy/sh/gather.sh recovery main`, analyze codebase using the defined analysis prompts, write English policy then produce translations per user's translation policy

2. **Replace `recovery-policy-analyst.md` with `recovery-lead.md`**

   Delete `plugins/core/agents/recovery-policy-analyst.md` and create `plugins/core/agents/recovery-lead.md` as a thin, multi-purpose orchestrator following the agent template from define-lead skill.

   - Use frontmatter: `name: recovery-lead`, `description`, `tools: Read, Write, Edit, Bash, Glob, Grep`, `skills: [lead-recovery, analyze-policy, translate]`
   - Preload the `lead-recovery` skill for domain knowledge and policies
   - Follow the same Instructions section pattern as `a11y-lead.md`

3. **Update scan command agent reference**

   In `plugins/core/commands/scan.md`, update the table row from `recovery-policy-analyst` / `core:recovery-policy-analyst` to `recovery-lead` / `core:recovery-lead`.

4. **Update select-scan-agents script**

   In `plugins/core/skills/select-scan-agents/sh/select.sh`, replace `recovery-policy-analyst` with `recovery-lead` in the `ALL_AGENTS` variable on line 16.

## Patches

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -54,7 +54,7 @@
 | `delivery-policy-analyst` | `core:delivery-policy-analyst` | Pass base branch |
-| `recovery-policy-analyst` | `core:recovery-policy-analyst` | Pass base branch |
+| `recovery-lead` | `core:recovery-lead` | Pass base branch |
 | `changelog-writer` | `core:changelog-writer` | Pass repository URL |
```

### `plugins/core/skills/select-scan-agents/sh/select.sh`

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -13,7 +13,7 @@
 BASE_BRANCH="${2:-}"

-ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-policy-analyst quality-policy-analyst a11y-lead observability-policy-analyst delivery-policy-analyst recovery-policy-analyst changelog-writer terms-writer"
+ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-policy-analyst quality-policy-analyst a11y-lead observability-policy-analyst delivery-policy-analyst recovery-lead changelog-writer terms-writer"
```

## Considerations

- The agent name change from `recovery-policy-analyst` to `recovery-lead` affects the `subagent_type` used in scan command invocations; the scan command table and the select script must both be updated atomically (`plugins/core/commands/scan.md`, `plugins/core/skills/select-scan-agents/sh/select.sh`)
- The validation script in scan Phase 4 references `recovery.md` as a policy output file, which does not change since the policy slug remains "recovery" (`plugins/core/commands/scan.md` line 72)
- No partial scan mapping references `recovery-policy-analyst` in the current `select.sh`, so only the ALL_AGENTS line needs updating (`plugins/core/skills/select-scan-agents/sh/select.sh` line 16)
- This is the last of the 6 policy analyst conversions; after all 6 are complete plus the already-done a11y-lead, all 7 policy agents will use the lead architecture
- Follow the exact structure of `plugins/core/skills/lead-a11y/SKILL.md` and `plugins/core/agents/a11y-lead.md` as reference implementations
