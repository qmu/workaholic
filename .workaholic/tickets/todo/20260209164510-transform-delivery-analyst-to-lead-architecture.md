---
created_at: 2026-02-09T16:45:10+08:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Transform Delivery Policy Analyst to Lead-Based Architecture

## Overview

Refactor the `delivery-policy-analyst` subagent into a lead-based architecture using the `define-lead` skill. This involves creating a new `lead-delivery` skill that encodes the delivery domain knowledge in the define-lead schema format (Role, Responsibility, Goal, Default Policies), then replacing the existing subagent file with a thin `delivery-lead.md` orchestrator that preloads the skill and delegates to it. This follows the proven pattern from the a11y-lead conversion.

## Key Files

- `plugins/core/agents/delivery-policy-analyst.md` - Current subagent to be replaced with `delivery-lead.md`
- `plugins/core/skills/define-lead/SKILL.md` - Schema template and guidelines that the new lead skill must follow
- `plugins/core/skills/analyze-policy/SKILL.md` - Existing policy analysis framework skill (still needed by the lead)
- `plugins/core/commands/scan.md` - Invokes `core:delivery-policy-analyst` by subagent_type (must update reference)
- `plugins/core/skills/select-scan-agents/sh/select.sh` - References `delivery-policy-analyst` in ALL_AGENTS list and in partial scan mapping (must update both references)
- `plugins/core/agents/a11y-lead.md` - Reference implementation of the lead agent pattern
- `plugins/core/skills/lead-a11y/SKILL.md` - Reference implementation of the lead skill pattern

## Related History

The define-lead skill and a11y-lead conversion established the pattern that this ticket follows.

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead skill with schema template, guidelines, and validation checklist (direct prerequisite)
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - First lead migration: accessibility-policy-analyst to a11y-lead (proven pattern to follow)

## Implementation Steps

1. **Create the `lead-delivery` skill directory and SKILL.md**

   Create `plugins/core/skills/lead-delivery/SKILL.md` following the define-lead schema. The skill must contain:

   - Frontmatter with `name: delivery-lead`, `description`, and `skills: [define-lead]`
   - `## Role` - Define the agent as the delivery authority: owns the CI/CD pipeline stages, deployment strategies, and artifact promotion flow from source to production
   - `## Responsibility` - Minimum duties: ensure every policy scan produces accurate delivery documentation; ensure CI/CD pipelines are analyzed; ensure build steps are documented; ensure deployment strategies are documented; ensure release processes are documented; ensure gaps are clearly identified
   - `## Goal` - Measurable completion: the `.workaholic/policies/delivery.md` accurately reflects all implemented delivery practices, with no fabricated policies and all gaps marked as "not observed". Translations are produced only when the user's root CLAUDE.md declares translation requirements.
   - `## Default Policies` with all four subsections:
     - `### Implementation` - Rules for writing delivery policy documents: only document implemented practices, cite enforcement mechanisms, use analyze-policy output template. Translation follows user policy (declared in root CLAUDE.md), not hardcoded.
     - `### Review` - Rules for reviewing delivery artifacts: verify every statement has a codebase citation, flag aspirational claims, check all output sections are present (CI/CD Pipeline, Build Process, Deployment Strategy, Release Process)
     - `### Documentation` - Rules for documentation output: follow analyze-policy template structure, include Observations and Gaps sections, use the policy slug "delivery"
     - `### Execution` - Rules for execution: gather context via `bash .claude/skills/analyze-policy/sh/gather.sh delivery main`, analyze codebase using the defined analysis prompts, write English policy then produce translations per user's translation policy

2. **Replace `delivery-policy-analyst.md` with `delivery-lead.md`**

   Delete `plugins/core/agents/delivery-policy-analyst.md` and create `plugins/core/agents/delivery-lead.md` as a thin, multi-purpose orchestrator following the agent template from define-lead skill.

   - Use frontmatter: `name: delivery-lead`, `description`, `tools: Read, Write, Edit, Bash, Glob, Grep`, `skills: [lead-delivery, analyze-policy, translate]`
   - Preload the `lead-delivery` skill for domain knowledge and policies
   - Follow the same Instructions section pattern as `a11y-lead.md`

3. **Update scan command agent reference**

   In `plugins/core/commands/scan.md`, update the table row from `delivery-policy-analyst` / `core:delivery-policy-analyst` to `delivery-lead` / `core:delivery-lead`.

4. **Update select-scan-agents script**

   In `plugins/core/skills/select-scan-agents/sh/select.sh`, replace `delivery-policy-analyst` with `delivery-lead` in the `ALL_AGENTS` variable on line 16. Also update the partial scan mapping on lines 107 and 122 where `.claude-plugin/*` and `.github/*` changes trigger `delivery-policy-analyst` -- replace with `delivery-lead`.

## Patches

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -53,7 +53,7 @@
 | `observability-policy-analyst` | `core:observability-policy-analyst` | Pass base branch |
-| `delivery-policy-analyst` | `core:delivery-policy-analyst` | Pass base branch |
+| `delivery-lead` | `core:delivery-lead` | Pass base branch |
 | `recovery-policy-analyst` | `core:recovery-policy-analyst` | Pass base branch |
```

### `plugins/core/skills/select-scan-agents/sh/select.sh`

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -13,7 +13,7 @@
 BASE_BRANCH="${2:-}"

-ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-policy-analyst quality-policy-analyst a11y-lead observability-policy-analyst delivery-policy-analyst recovery-policy-analyst changelog-writer terms-writer"
+ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-policy-analyst quality-policy-analyst a11y-lead observability-policy-analyst delivery-lead recovery-policy-analyst changelog-writer terms-writer"
```

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -105,7 +105,7 @@
   case "$path" in
     .claude-plugin/*|plugins/*/.claude-plugin/*)
       touch "$TMPDIR_SEL/infrastructure-analyst"
-      touch "$TMPDIR_SEL/delivery-policy-analyst"
+      touch "$TMPDIR_SEL/delivery-lead"
       ;;
   esac
```

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -119,7 +119,7 @@
   case "$path" in
     .github/*)
-      touch "$TMPDIR_SEL/delivery-policy-analyst"
+      touch "$TMPDIR_SEL/delivery-lead"
       touch "$TMPDIR_SEL/security-policy-analyst"
       ;;
   esac
```

## Considerations

- The agent name change from `delivery-policy-analyst` to `delivery-lead` affects the `subagent_type` used in scan command invocations; the scan command table and the select script must both be updated atomically (`plugins/core/commands/scan.md`, `plugins/core/skills/select-scan-agents/sh/select.sh`)
- The partial scan mapping in `select.sh` references `delivery-policy-analyst` in two places: line 107 for `.claude-plugin/*` changes and line 122 for `.github/*` changes; both must be updated to `delivery-lead` (`plugins/core/skills/select-scan-agents/sh/select.sh` lines 105-110, 119-124)
- The validation script in scan Phase 4 references `delivery.md` as a policy output file, which does not change since the policy slug remains "delivery" (`plugins/core/commands/scan.md` line 72)
- Follow the exact structure of `plugins/core/skills/lead-a11y/SKILL.md` and `plugins/core/agents/a11y-lead.md` as reference implementations
