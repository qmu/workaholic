---
created_at: 2026-02-09T16:45:06+08:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Transform Test Policy Analyst to Lead-Based Architecture

## Overview

Refactor the `test-policy-analyst` subagent into a lead-based architecture using the `define-lead` skill. This involves creating a new `lead-test` skill that encodes the test domain knowledge in the define-lead schema format (Role, Responsibility, Goal, Default Policies), then replacing the existing subagent file with a thin `test-lead.md` orchestrator that preloads the skill and delegates to it. This follows the proven pattern from the a11y-lead conversion and the "thin orchestrators, comprehensive skills" principle.

## Key Files

- `plugins/core/agents/test-policy-analyst.md` - Current subagent to be replaced with `test-lead.md`
- `plugins/core/skills/define-lead/SKILL.md` - Schema template and guidelines that the new lead skill must follow
- `plugins/core/skills/analyze-policy/SKILL.md` - Existing policy analysis framework skill (still needed by the lead)
- `plugins/core/commands/scan.md` - Invokes `core:test-policy-analyst` by subagent_type (must update reference)
- `plugins/core/skills/select-scan-agents/sh/select.sh` - References `test-policy-analyst` in ALL_AGENTS list (must update reference)
- `plugins/core/agents/a11y-lead.md` - Reference implementation of the lead agent pattern
- `plugins/core/skills/lead-a11y/SKILL.md` - Reference implementation of the lead skill pattern

## Related History

The define-lead skill and a11y-lead conversion established the pattern that this ticket follows. This is the second application of the lead architecture to a policy analyst.

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead skill with schema template, guidelines, and validation checklist (direct prerequisite)
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - First lead migration: accessibility-policy-analyst to a11y-lead (proven pattern to follow)

## Implementation Steps

1. **Create the `lead-test` skill directory and SKILL.md**

   Create `plugins/core/skills/lead-test/SKILL.md` following the define-lead schema. The skill must contain:

   - Frontmatter with `name: test-lead`, `description`, and `skills: [define-lead]`
   - `## Role` - Define the agent as the test strategy authority: owns verification and validation strategy, testing levels, coverage targets, and processes that ensure correctness
   - `## Responsibility` - Minimum duties: ensure every policy scan produces accurate test documentation; ensure testing frameworks and levels are analyzed; ensure coverage targets are documented; ensure test organization is documented; ensure gaps are clearly identified
   - `## Goal` - Measurable completion: the `.workaholic/policies/test.md` accurately reflects all implemented testing practices, with no fabricated policies and all gaps marked as "not observed". Translations are produced only when the user's root CLAUDE.md declares translation requirements.
   - `## Default Policies` with all four subsections:
     - `### Implementation` - Rules for writing test policy documents: only document implemented practices, cite enforcement mechanisms, use analyze-policy output template. Translation follows user policy (declared in root CLAUDE.md), not hardcoded.
     - `### Review` - Rules for reviewing test artifacts: verify every statement has a codebase citation, flag aspirational claims, check all output sections are present (Testing Framework, Testing Levels, Coverage Targets, Test Organization)
     - `### Documentation` - Rules for documentation output: follow analyze-policy template structure, include Observations and Gaps sections, use the policy slug "test"
     - `### Execution` - Rules for execution: gather context via `bash .claude/skills/analyze-policy/sh/gather.sh test main`, analyze codebase using the defined analysis prompts, write English policy then produce translations per user's translation policy

2. **Replace `test-policy-analyst.md` with `test-lead.md`**

   Delete `plugins/core/agents/test-policy-analyst.md` and create `plugins/core/agents/test-lead.md` as a thin, multi-purpose orchestrator following the agent template from define-lead skill.

   - Use frontmatter: `name: test-lead`, `description`, `tools: Read, Write, Edit, Bash, Glob, Grep`, `skills: [lead-test, analyze-policy, translate]`
   - Preload the `lead-test` skill for domain knowledge and policies
   - Follow the same Instructions section pattern as `a11y-lead.md`

3. **Update scan command agent reference**

   In `plugins/core/commands/scan.md`, update the table row from `test-policy-analyst` / `core:test-policy-analyst` to `test-lead` / `core:test-lead`.

4. **Update select-scan-agents script**

   In `plugins/core/skills/select-scan-agents/sh/select.sh`, replace `test-policy-analyst` with `test-lead` in the `ALL_AGENTS` variable on line 16.

## Patches

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -48,7 +48,7 @@
 | `feature-analyst` | `core:feature-analyst` | Pass base branch |
-| `test-policy-analyst` | `core:test-policy-analyst` | Pass base branch |
+| `test-lead` | `core:test-lead` | Pass base branch |
 | `security-policy-analyst` | `core:security-policy-analyst` | Pass base branch |
```

### `plugins/core/skills/select-scan-agents/sh/select.sh`

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -13,7 +13,7 @@
 BASE_BRANCH="${2:-}"

-ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-policy-analyst quality-policy-analyst a11y-lead observability-policy-analyst delivery-policy-analyst recovery-policy-analyst changelog-writer terms-writer"
+ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-lead security-policy-analyst quality-policy-analyst a11y-lead observability-policy-analyst delivery-policy-analyst recovery-policy-analyst changelog-writer terms-writer"
```

## Considerations

- The agent name change from `test-policy-analyst` to `test-lead` affects the `subagent_type` used in scan command invocations; the scan command table and the select script must both be updated atomically (`plugins/core/commands/scan.md`, `plugins/core/skills/select-scan-agents/sh/select.sh`)
- The validation script in scan Phase 4 references `test.md` as a policy output file, which does not change since the policy slug remains "test" (`plugins/core/commands/scan.md` line 72)
- The partial scan mapping in `select.sh` references `quality-policy-analyst` on line 88 for rules changes; once quality-policy-analyst is also converted, that reference will need updating (`plugins/core/skills/select-scan-agents/sh/select.sh` line 88)
- Follow the exact structure of `plugins/core/skills/lead-a11y/SKILL.md` and `plugins/core/agents/a11y-lead.md` as reference implementations
