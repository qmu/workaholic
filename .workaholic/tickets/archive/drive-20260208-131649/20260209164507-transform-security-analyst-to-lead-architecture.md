---
created_at: 2026-02-09T16:45:07+08:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: ff55028
category:
---

# Transform Security Policy Analyst to Lead-Based Architecture

## Overview

Refactor the `security-policy-analyst` subagent into a lead-based architecture using the `define-lead` skill. This involves creating a new `lead-security` skill that encodes the security domain knowledge in the define-lead schema format (Role, Responsibility, Goal, Default Policies), then replacing the existing subagent file with a thin `security-lead.md` orchestrator that preloads the skill and delegates to it. This follows the proven pattern from the a11y-lead conversion.

## Key Files

- `plugins/core/agents/security-policy-analyst.md` - Current subagent to be replaced with `security-lead.md`
- `plugins/core/skills/define-lead/SKILL.md` - Schema template and guidelines that the new lead skill must follow
- `plugins/core/skills/analyze-policy/SKILL.md` - Existing policy analysis framework skill (still needed by the lead)
- `plugins/core/commands/scan.md` - Invokes `core:security-policy-analyst` by subagent_type (must update reference)
- `plugins/core/skills/select-scan-agents/sh/select.sh` - References `security-policy-analyst` in ALL_AGENTS list and in partial scan mapping (must update both references)
- `plugins/core/agents/a11y-lead.md` - Reference implementation of the lead agent pattern
- `plugins/core/skills/lead-a11y/SKILL.md` - Reference implementation of the lead skill pattern

## Related History

The define-lead skill and a11y-lead conversion established the pattern that this ticket follows.

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead skill with schema template, guidelines, and validation checklist (direct prerequisite)
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - First lead migration: accessibility-policy-analyst to a11y-lead (proven pattern to follow)

## Implementation Steps

1. **Create the `lead-security` skill directory and SKILL.md**

   Create `plugins/core/skills/lead-security/SKILL.md` following the define-lead schema. The skill must contain:

   - Frontmatter with `name: security-lead`, `description`, and `skills: [define-lead]`
   - `## Role` - Define the agent as the security authority: owns the assets worth protecting, threat model, authentication/authorization boundaries, and safeguards in the project
   - `## Responsibility` - Minimum duties: ensure every policy scan produces accurate security documentation; ensure authentication mechanisms are analyzed; ensure authorization boundaries are documented; ensure secrets management practices are documented; ensure input validation is documented; ensure gaps are clearly identified
   - `## Goal` - Measurable completion: the `.workaholic/policies/security.md` accurately reflects all implemented security practices, with no fabricated policies and all gaps marked as "not observed". Translations are produced only when the user's root CLAUDE.md declares translation requirements.
   - `## Default Policies` with all four subsections:
     - `### Implementation` - Rules for writing security policy documents: only document implemented practices, cite enforcement mechanisms, use analyze-policy output template. Translation follows user policy (declared in root CLAUDE.md), not hardcoded.
     - `### Review` - Rules for reviewing security artifacts: verify every statement has a codebase citation, flag aspirational claims, check all output sections are present (Authentication, Authorization, Secrets Management, Input Validation)
     - `### Documentation` - Rules for documentation output: follow analyze-policy template structure, include Observations and Gaps sections, use the policy slug "security"
     - `### Execution` - Rules for execution: gather context via `bash .claude/skills/analyze-policy/sh/gather.sh security main`, analyze codebase using the defined analysis prompts, write English policy then produce translations per user's translation policy

2. **Replace `security-policy-analyst.md` with `security-lead.md`**

   Delete `plugins/core/agents/security-policy-analyst.md` and create `plugins/core/agents/security-lead.md` as a thin, multi-purpose orchestrator following the agent template from define-lead skill.

   - Use frontmatter: `name: security-lead`, `description`, `tools: Read, Write, Edit, Bash, Glob, Grep`, `skills: [lead-security, analyze-policy, translate]`
   - Preload the `lead-security` skill for domain knowledge and policies
   - Follow the same Instructions section pattern as `a11y-lead.md`

3. **Update scan command agent reference**

   In `plugins/core/commands/scan.md`, update the table row from `security-policy-analyst` / `core:security-policy-analyst` to `security-lead` / `core:security-lead`.

4. **Update select-scan-agents script**

   In `plugins/core/skills/select-scan-agents/sh/select.sh`, replace `security-policy-analyst` with `security-lead` in the `ALL_AGENTS` variable on line 16. Also update the partial scan mapping on line 122 where `.github/*` changes trigger `security-policy-analyst` -- replace with `security-lead`.

## Patches

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -49,7 +49,7 @@
 | `test-policy-analyst` | `core:test-policy-analyst` | Pass base branch |
-| `security-policy-analyst` | `core:security-policy-analyst` | Pass base branch |
+| `security-lead` | `core:security-lead` | Pass base branch |
 | `quality-policy-analyst` | `core:quality-policy-analyst` | Pass base branch |
```

### `plugins/core/skills/select-scan-agents/sh/select.sh`

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -13,7 +13,7 @@
 BASE_BRANCH="${2:-}"

-ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-policy-analyst quality-policy-analyst a11y-lead observability-policy-analyst delivery-policy-analyst recovery-policy-analyst changelog-writer terms-writer"
+ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-policy-analyst security-lead quality-policy-analyst a11y-lead observability-policy-analyst delivery-policy-analyst recovery-policy-analyst changelog-writer terms-writer"
```

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -119,7 +119,7 @@
   case "$path" in
     .github/*)
       touch "$TMPDIR_SEL/delivery-policy-analyst"
-      touch "$TMPDIR_SEL/security-policy-analyst"
+      touch "$TMPDIR_SEL/security-lead"
       ;;
   esac
```

## Considerations

- The agent name change from `security-policy-analyst` to `security-lead` affects the `subagent_type` used in scan command invocations; the scan command table and the select script must both be updated atomically (`plugins/core/commands/scan.md`, `plugins/core/skills/select-scan-agents/sh/select.sh`)
- The partial scan mapping in `select.sh` on line 122 also references `security-policy-analyst` for `.github/*` changes; this must be updated to `security-lead` (`plugins/core/skills/select-scan-agents/sh/select.sh` lines 119-124)
- The validation script in scan Phase 4 references `security.md` as a policy output file, which does not change since the policy slug remains "security" (`plugins/core/commands/scan.md` line 72)
- Follow the exact structure of `plugins/core/skills/lead-a11y/SKILL.md` and `plugins/core/agents/a11y-lead.md` as reference implementations

## Final Report

All four implementation steps completed as specified:

1. Created `plugins/core/skills/lead-security/SKILL.md` with Role, Responsibility, Goal, and Default Policies (Implementation, Review, Documentation, Execution) following the define-lead schema and mirroring the lead-a11y reference.
2. Deleted `plugins/core/agents/security-policy-analyst.md` and created `plugins/core/agents/security-lead.md` as a thin orchestrator preloading lead-security, analyze-policy, and translate skills.
3. Updated `plugins/core/commands/scan.md` table row from `security-policy-analyst`/`core:security-policy-analyst` to `security-lead`/`core:security-lead`.
4. Updated `plugins/core/skills/select-scan-agents/sh/select.sh` ALL_AGENTS variable and partial scan mapping (`.github/*` trigger), replacing `security-policy-analyst` with `security-lead`.
