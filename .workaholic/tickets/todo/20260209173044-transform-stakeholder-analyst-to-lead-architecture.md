---
created_at: 2026-02-09T17:30:44+08:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Transform Stakeholder Analyst to Communication-Lead Architecture

## Overview

Refactor the `stakeholder-analyst` subagent into a lead-based architecture using the `define-lead` skill. This involves creating a new `lead-communication` skill that encodes the stakeholder/communication domain knowledge in the define-lead schema format (Role, Responsibility, Goal, Default Policies), then replacing the existing subagent file with a thin `communication-lead.md` orchestrator that preloads the skill and delegates to it. This is a viewpoint analyst (specs), not a policy analyst (policies), so it uses `analyze-viewpoint` and `write-spec` skills rather than `analyze-policy`. The output is a spec document in `.workaholic/specs/stakeholder.md`.

## Key Files

- `plugins/core/agents/stakeholder-analyst.md` - Current subagent to be replaced with `communication-lead.md`
- `plugins/core/skills/define-lead/SKILL.md` - Schema template and guidelines that the new lead skill must follow
- `plugins/core/skills/analyze-viewpoint/SKILL.md` - Existing viewpoint analysis framework skill (still needed by the lead)
- `plugins/core/skills/write-spec/SKILL.md` - Spec writing guidelines (still needed by the lead)
- `plugins/core/commands/scan.md` - Invokes `core:stakeholder-analyst` by subagent_type (must update reference)
- `plugins/core/skills/select-scan-agents/sh/select.sh` - References `stakeholder-analyst` in ALL_AGENTS list and in partial scan mapping (must update both references)
- `plugins/core/agents/a11y-lead.md` - Reference implementation of the lead agent pattern (policy variant)
- `plugins/core/skills/lead-a11y/SKILL.md` - Reference implementation of the lead skill pattern (policy variant)

## Related History

The define-lead skill and a11y-lead conversion established the lead pattern for policy analysts. This ticket extends that pattern to viewpoint analysts.

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead skill with schema template, guidelines, and validation checklist (direct prerequisite)
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - First lead migration: accessibility-policy-analyst to a11y-lead (reference pattern, but policy variant)
- [20260209173043-transform-infra-analyst-to-lead-architecture.md](.workaholic/tickets/todo/20260209173043-transform-infra-analyst-to-lead-architecture.md) - First viewpoint analyst to lead transformation in this batch (infra-lead)

## Implementation Steps

1. **Create the `lead-communication` skill directory and SKILL.md**

   Create `plugins/core/skills/lead-communication/SKILL.md` following the define-lead schema. The skill must contain:

   - Frontmatter with `name: communication-lead`, `description`, and `skills: [define-lead]`, `user-invocable: false`
   - `## Role` - Define the agent as the stakeholder communication authority: owns stakeholder mapping, user goals, interaction patterns, and onboarding paths. It analyzes the repository from the stakeholder viewpoint and produces spec documentation that accurately reflects who uses the system and how.
   - `## Responsibility` - Minimum duties: ensure every scan produces accurate stakeholder documentation; ensure primary users and user types are identified; ensure user goals are analyzed; ensure interaction patterns are documented; ensure onboarding paths are documented; ensure gaps are clearly identified as "not observed".
   - `## Goal` - Measurable completion: the `.workaholic/specs/stakeholder.md` accurately reflects all stakeholder relationships, user goals, and interaction patterns in the repository. No fabricated claims exist, every statement is grounded in codebase evidence, and all gaps are marked as "not observed". Translations are produced only when the user's root CLAUDE.md declares translation requirements.
   - `## Default Policies` with all four subsections:
     - `### Implementation` - Rules for writing stakeholder spec documents: only document stakeholder aspects that are observable in the codebase, cite evidence for each statement, use analyze-viewpoint output template for document structure. Translation follows user policy (declared in root CLAUDE.md), not hardcoded.
     - `### Review` - Rules for reviewing stakeholder artifacts: verify every statement has codebase evidence, flag aspirational claims, check all output sections are present (Stakeholder Map, User Goals, Interaction Patterns, Onboarding Paths), verify Assumptions section is included.
     - `### Documentation` - Rules for documentation output: follow analyze-viewpoint template structure with frontmatter, language navigation links, spec sections, and Assumptions. Use the viewpoint slug "stakeholder" for filenames and frontmatter. Write full paragraphs, not bullet-point fragments. Include multiple Mermaid diagrams inline within content sections.
     - `### Execution` - Rules for execution: gather context via `bash .claude/skills/analyze-viewpoint/sh/gather.sh stakeholder main`, check overrides via `bash .claude/skills/analyze-viewpoint/sh/read-overrides.sh`, analyze codebase using the defined analysis prompts, write English spec first then produce translations per user's translation policy declared in their root CLAUDE.md.

2. **Replace `stakeholder-analyst.md` with `communication-lead.md`**

   Delete `plugins/core/agents/stakeholder-analyst.md` and create `plugins/core/agents/communication-lead.md` as a thin, multi-purpose orchestrator following the agent template from define-lead skill.

   - Use frontmatter: `name: communication-lead`, `description`, `tools: Read, Write, Edit, Bash, Glob, Grep`, `skills: [lead-communication, analyze-viewpoint, write-spec, translate]`
   - Preload the `lead-communication` skill for domain knowledge and policies
   - Follow the same Instructions section pattern as `a11y-lead.md`, adapted for viewpoint context

3. **Update scan command agent reference**

   In `plugins/core/commands/scan.md`, update the table row from `stakeholder-analyst` / `core:stakeholder-analyst` to `communication-lead` / `core:communication-lead`.

4. **Update select-scan-agents script**

   In `plugins/core/skills/select-scan-agents/sh/select.sh`, replace `stakeholder-analyst` with `communication-lead` in the `ALL_AGENTS` variable on line 16. Also update the partial scan mapping on line 114 where `README.md|CLAUDE.md` changes trigger `stakeholder-analyst` -- replace with `communication-lead`.

## Patches

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -38,7 +38,7 @@
 | Agent slug | `subagent_type` | Prompt context |
 | --- | --- | --- |
-| `stakeholder-analyst` | `core:stakeholder-analyst` | Pass base branch |
+| `communication-lead` | `core:communication-lead` | Pass base branch |
 | `model-analyst` | `core:model-analyst` | Pass base branch |
```

### `plugins/core/skills/select-scan-agents/sh/select.sh`

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -14,7 +14,7 @@
 BASE_BRANCH="${2:-}"

-ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-lead security-lead quality-lead a11y-lead observability-lead delivery-lead recovery-lead changelog-writer terms-writer"
+ALL_AGENTS="communication-lead model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-lead security-lead quality-lead a11y-lead observability-lead delivery-lead recovery-lead changelog-writer terms-writer"
```

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -112,7 +112,7 @@
   case "$path" in
     README.md|CLAUDE.md)
-      touch "$TMPDIR_SEL/stakeholder-analyst"
+      touch "$TMPDIR_SEL/communication-lead"
       touch "$TMPDIR_SEL/feature-analyst"
       ;;
   esac
```

## Considerations

- The agent name change from `stakeholder-analyst` to `communication-lead` affects the `subagent_type` used in scan command invocations; the scan command table and the select script must both be updated atomically (`plugins/core/commands/scan.md`, `plugins/core/skills/select-scan-agents/sh/select.sh`)
- Unlike policy-analyst leads that use `analyze-policy`, this viewpoint lead must use `analyze-viewpoint` and `write-spec` skills (`plugins/core/skills/analyze-viewpoint/SKILL.md`, `plugins/core/skills/write-spec/SKILL.md`)
- The viewpoint slug remains "stakeholder" even though the lead name is "communication-lead"; the output file stays `.workaholic/specs/stakeholder.md` to maintain backward compatibility with the validation script (`plugins/core/commands/scan.md` line 67)
- The partial scan mapping in `select.sh` references `stakeholder-analyst` on line 114 for `README.md|CLAUDE.md` changes; this must be updated to `communication-lead` (`plugins/core/skills/select-scan-agents/sh/select.sh` lines 112-117)
- Cross-reference: the infra-lead and db-lead tickets also transform viewpoint analysts in this same batch
