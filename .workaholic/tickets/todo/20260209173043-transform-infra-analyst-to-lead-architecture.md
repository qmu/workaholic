---
created_at: 2026-02-09T17:30:43+08:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Transform Infrastructure Analyst to Infra-Lead Architecture

## Overview

Refactor the `infrastructure-analyst` subagent into a lead-based architecture using the `define-lead` skill. This involves creating a new `lead-infra` skill that encodes the infrastructure domain knowledge in the define-lead schema format (Role, Responsibility, Goal, Default Policies), then replacing the existing subagent file with a thin `infra-lead.md` orchestrator that preloads the skill and delegates to it. Unlike the prior policy-analyst conversions, this is a viewpoint analyst and uses `analyze-viewpoint` and `write-spec` skills rather than `analyze-policy`. The output is a spec document in `.workaholic/specs/infrastructure.md`, not a policy.

## Key Files

- `plugins/core/agents/infrastructure-analyst.md` - Current subagent to be replaced with `infra-lead.md`
- `plugins/core/skills/define-lead/SKILL.md` - Schema template and guidelines that the new lead skill must follow
- `plugins/core/skills/analyze-viewpoint/SKILL.md` - Existing viewpoint analysis framework skill (still needed by the lead)
- `plugins/core/skills/write-spec/SKILL.md` - Spec writing guidelines (still needed by the lead)
- `plugins/core/commands/scan.md` - Invokes `core:infrastructure-analyst` by subagent_type (must update reference)
- `plugins/core/skills/select-scan-agents/sh/select.sh` - References `infrastructure-analyst` in ALL_AGENTS list and in partial scan mapping (must update both references)
- `plugins/core/agents/a11y-lead.md` - Reference implementation of the lead agent pattern (policy variant)
- `plugins/core/skills/lead-a11y/SKILL.md` - Reference implementation of the lead skill pattern (policy variant)

## Related History

The define-lead skill and a11y-lead conversion established the lead pattern for policy analysts. This ticket extends that pattern to viewpoint analysts, which use analyze-viewpoint instead of analyze-policy.

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead skill with schema template, guidelines, and validation checklist (direct prerequisite)
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - First lead migration: accessibility-policy-analyst to a11y-lead (reference pattern, but policy variant)
- [20260209164506-transform-test-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209164506-transform-test-analyst-to-lead-architecture.md) - Test policy analyst to test-lead (same structural transformation)

## Implementation Steps

1. **Create the `lead-infra` skill directory and SKILL.md**

   Create `plugins/core/skills/lead-infra/SKILL.md` following the define-lead schema. The skill must contain:

   - Frontmatter with `name: infra-lead`, `description`, and `skills: [define-lead]`, `user-invocable: false`
   - `## Role` - Define the agent as the infrastructure authority: owns external dependencies, file system layout, installation procedures, and environment requirements. It analyzes the repository from the infrastructure viewpoint and produces spec documentation that accurately reflects what is implemented.
   - `## Responsibility` - Minimum duties: ensure every scan produces accurate infrastructure documentation; ensure external dependencies are analyzed; ensure file system layout is documented; ensure installation and configuration procedures are documented; ensure environment requirements are documented; ensure gaps are clearly identified as "not observed".
   - `## Goal` - Measurable completion: the `.workaholic/specs/infrastructure.md` accurately reflects all implemented infrastructure concerns in the repository. No fabricated claims exist, every statement is grounded in codebase evidence, and all gaps are marked as "not observed". Translations are produced only when the user's root CLAUDE.md declares translation requirements.
   - `## Default Policies` with all four subsections:
     - `### Implementation` - Rules for writing infrastructure spec documents: only document infrastructure aspects that are observable in the codebase, cite evidence for each statement, use analyze-viewpoint output template for document structure. Translation follows user policy (declared in root CLAUDE.md), not hardcoded.
     - `### Review` - Rules for reviewing infrastructure artifacts: verify every statement has codebase evidence, flag aspirational claims, check all output sections are present (External Dependencies, File System Layout, Installation, Environment Requirements), verify Assumptions section is included.
     - `### Documentation` - Rules for documentation output: follow analyze-viewpoint template structure with frontmatter, language navigation links, spec sections, and Assumptions. Use the viewpoint slug "infrastructure" for filenames and frontmatter. Write full paragraphs, not bullet-point fragments. Include multiple Mermaid diagrams inline within content sections.
     - `### Execution` - Rules for execution: gather context via `bash .claude/skills/analyze-viewpoint/sh/gather.sh infrastructure main`, check overrides via `bash .claude/skills/analyze-viewpoint/sh/read-overrides.sh`, analyze codebase using the defined analysis prompts, write English spec first then produce translations per user's translation policy declared in their root CLAUDE.md.

2. **Replace `infrastructure-analyst.md` with `infra-lead.md`**

   Delete `plugins/core/agents/infrastructure-analyst.md` and create `plugins/core/agents/infra-lead.md` as a thin, multi-purpose orchestrator following the agent template from define-lead skill.

   - Use frontmatter: `name: infra-lead`, `description`, `tools: Read, Write, Edit, Bash, Glob, Grep`, `skills: [lead-infra, analyze-viewpoint, write-spec, translate]`
   - Preload the `lead-infra` skill for domain knowledge and policies
   - Follow the same Instructions section pattern as `a11y-lead.md`, adapted for viewpoint context

3. **Update scan command agent reference**

   In `plugins/core/commands/scan.md`, update the table row from `infrastructure-analyst` / `core:infrastructure-analyst` to `infra-lead` / `core:infra-lead`.

4. **Update select-scan-agents script**

   In `plugins/core/skills/select-scan-agents/sh/select.sh`, replace `infrastructure-analyst` with `infra-lead` in the `ALL_AGENTS` variable on line 16. Also update the partial scan mapping on line 107 where `.claude-plugin/*` changes trigger `infrastructure-analyst` -- replace with `infra-lead`.

## Patches

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -40,7 +40,7 @@
 | `usecase-analyst` | `core:usecase-analyst` | Pass base branch |
-| `infrastructure-analyst` | `core:infrastructure-analyst` | Pass base branch |
+| `infra-lead` | `core:infra-lead` | Pass base branch |
 | `application-analyst` | `core:application-analyst` | Pass base branch |
```

### `plugins/core/skills/select-scan-agents/sh/select.sh`

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -14,7 +14,7 @@
 BASE_BRANCH="${2:-}"

-ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-lead security-lead quality-lead a11y-lead observability-lead delivery-lead recovery-lead changelog-writer terms-writer"
+ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infra-lead application-analyst component-analyst data-analyst feature-analyst test-lead security-lead quality-lead a11y-lead observability-lead delivery-lead recovery-lead changelog-writer terms-writer"
```

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -105,7 +105,7 @@
   case "$path" in
     .claude-plugin/*|plugins/*/.claude-plugin/*)
-      touch "$TMPDIR_SEL/infrastructure-analyst"
+      touch "$TMPDIR_SEL/infra-lead"
       touch "$TMPDIR_SEL/delivery-lead"
       ;;
   esac
```

## Considerations

- The agent name change from `infrastructure-analyst` to `infra-lead` affects the `subagent_type` used in scan command invocations; the scan command table and the select script must both be updated atomically (`plugins/core/commands/scan.md`, `plugins/core/skills/select-scan-agents/sh/select.sh`)
- Unlike policy-analyst leads that use `analyze-policy`, this viewpoint lead must use `analyze-viewpoint` and `write-spec` skills (`plugins/core/skills/analyze-viewpoint/SKILL.md`, `plugins/core/skills/write-spec/SKILL.md`)
- The validation script in scan Phase 4 references `infrastructure.md` as a viewpoint spec output file, which does not change since the viewpoint slug remains "infrastructure" (`plugins/core/commands/scan.md` line 67)
- The partial scan mapping in `select.sh` references `infrastructure-analyst` on line 107 for `.claude-plugin/*` changes; this must be updated to `infra-lead` (`plugins/core/skills/select-scan-agents/sh/select.sh` lines 105-110)
- Cross-reference: the communication-lead and db-lead tickets also transform viewpoint analysts in this same batch
