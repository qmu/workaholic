---
created_at: 2026-02-09T17:30:45+08:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Transform Data Analyst to DB-Lead Architecture

## Overview

Refactor the `data-analyst` subagent into a lead-based architecture using the `define-lead` skill. This involves creating a new `lead-db` skill that encodes the data/persistency domain knowledge in the define-lead schema format (Role, Responsibility, Goal, Default Policies), then replacing the existing subagent file with a thin `db-lead.md` orchestrator that preloads the skill and delegates to it. This lead owns responsibility for persistency and data storage concerns. This is a viewpoint analyst (specs), not a policy analyst (policies), so it uses `analyze-viewpoint` and `write-spec` skills rather than `analyze-policy`. The output is a spec document in `.workaholic/specs/data.md`.

## Key Files

- `plugins/core/agents/data-analyst.md` - Current subagent to be replaced with `db-lead.md`
- `plugins/core/skills/define-lead/SKILL.md` - Schema template and guidelines that the new lead skill must follow
- `plugins/core/skills/analyze-viewpoint/SKILL.md` - Existing viewpoint analysis framework skill (still needed by the lead)
- `plugins/core/skills/write-spec/SKILL.md` - Spec writing guidelines (still needed by the lead)
- `plugins/core/commands/scan.md` - Invokes `core:data-analyst` by subagent_type (must update reference)
- `plugins/core/skills/select-scan-agents/sh/select.sh` - References `data-analyst` in ALL_AGENTS list and in partial scan mapping (must update both references)
- `plugins/core/agents/a11y-lead.md` - Reference implementation of the lead agent pattern (policy variant)
- `plugins/core/skills/lead-a11y/SKILL.md` - Reference implementation of the lead skill pattern (policy variant)

## Related History

The define-lead skill and a11y-lead conversion established the lead pattern for policy analysts. This ticket extends that pattern to viewpoint analysts.

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead skill with schema template, guidelines, and validation checklist (direct prerequisite)
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - First lead migration: accessibility-policy-analyst to a11y-lead (reference pattern, but policy variant)
- [20260209173043-transform-infra-analyst-to-lead-architecture.md](.workaholic/tickets/todo/20260209173043-transform-infra-analyst-to-lead-architecture.md) - First viewpoint analyst to lead transformation in this batch (infra-lead)

## Implementation Steps

1. **Create the `lead-db` skill directory and SKILL.md**

   Create `plugins/core/skills/lead-db/SKILL.md` following the define-lead schema. The skill must contain:

   - Frontmatter with `name: db-lead`, `description`, and `skills: [define-lead]`, `user-invocable: false`
   - `## Role` - Define the agent as the data/persistency authority: owns data formats, frontmatter schemas, file naming conventions, and data validation. It analyzes the repository from the data viewpoint and produces spec documentation that accurately reflects how data is stored, structured, and validated.
   - `## Responsibility` - Minimum duties: ensure every scan produces accurate data documentation; ensure data formats are analyzed; ensure frontmatter schemas are documented; ensure file naming conventions are documented; ensure data validation rules are documented; ensure gaps are clearly identified as "not observed".
   - `## Goal` - Measurable completion: the `.workaholic/specs/data.md` accurately reflects all implemented data storage and persistence concerns in the repository. No fabricated claims exist, every statement is grounded in codebase evidence, and all gaps are marked as "not observed". Translations are produced only when the user's root CLAUDE.md declares translation requirements.
   - `## Default Policies` with all four subsections:
     - `### Implementation` - Rules for writing data spec documents: only document data aspects that are observable in the codebase, cite evidence for each statement, use analyze-viewpoint output template for document structure. Translation follows user policy (declared in root CLAUDE.md), not hardcoded.
     - `### Review` - Rules for reviewing data artifacts: verify every statement has codebase evidence, flag aspirational claims, check all output sections are present (Data Formats, Frontmatter Schemas, Naming Conventions, Validation Rules), verify Assumptions section is included.
     - `### Documentation` - Rules for documentation output: follow analyze-viewpoint template structure with frontmatter, language navigation links, spec sections, and Assumptions. Use the viewpoint slug "data" for filenames and frontmatter. Write full paragraphs, not bullet-point fragments. Include multiple Mermaid diagrams inline within content sections.
     - `### Execution` - Rules for execution: gather context via `bash .claude/skills/analyze-viewpoint/sh/gather.sh data main`, check overrides via `bash .claude/skills/analyze-viewpoint/sh/read-overrides.sh`, analyze codebase using the defined analysis prompts, write English spec first then produce translations per user's translation policy declared in their root CLAUDE.md.

2. **Replace `data-analyst.md` with `db-lead.md`**

   Delete `plugins/core/agents/data-analyst.md` and create `plugins/core/agents/db-lead.md` as a thin, multi-purpose orchestrator following the agent template from define-lead skill.

   - Use frontmatter: `name: db-lead`, `description`, `tools: Read, Write, Edit, Bash, Glob, Grep`, `skills: [lead-db, analyze-viewpoint, write-spec, translate]`
   - Preload the `lead-db` skill for domain knowledge and policies
   - Follow the same Instructions section pattern as `a11y-lead.md`, adapted for viewpoint context

3. **Update scan command agent reference**

   In `plugins/core/commands/scan.md`, update the table row from `data-analyst` / `core:data-analyst` to `db-lead` / `core:db-lead`.

4. **Update select-scan-agents script**

   In `plugins/core/skills/select-scan-agents/sh/select.sh`, replace `data-analyst` with `db-lead` in the `ALL_AGENTS` variable on line 16. Also update the partial scan mapping on lines 93-97 where `.workaholic/tickets/*` changes trigger `data-analyst` -- replace with `db-lead`.

## Patches

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -44,7 +44,7 @@
 | `component-analyst` | `core:component-analyst` | Pass base branch |
-| `data-analyst` | `core:data-analyst` | Pass base branch |
+| `db-lead` | `core:db-lead` | Pass base branch |
 | `feature-analyst` | `core:feature-analyst` | Pass base branch |
```

### `plugins/core/skills/select-scan-agents/sh/select.sh`

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -14,7 +14,7 @@
 BASE_BRANCH="${2:-}"

-ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst data-analyst feature-analyst test-lead security-lead quality-lead a11y-lead observability-lead delivery-lead recovery-lead changelog-writer terms-writer"
+ALL_AGENTS="stakeholder-analyst model-analyst usecase-analyst infrastructure-analyst application-analyst component-analyst db-lead feature-analyst test-lead security-lead quality-lead a11y-lead observability-lead delivery-lead recovery-lead changelog-writer terms-writer"
```

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -92,7 +92,7 @@
   case "$path" in
     .workaholic/tickets/*)
-      touch "$TMPDIR_SEL/data-analyst"
+      touch "$TMPDIR_SEL/db-lead"
       touch "$TMPDIR_SEL/model-analyst"
       ;;
   esac
```

## Considerations

- The agent name change from `data-analyst` to `db-lead` affects the `subagent_type` used in scan command invocations; the scan command table and the select script must both be updated atomically (`plugins/core/commands/scan.md`, `plugins/core/skills/select-scan-agents/sh/select.sh`)
- Unlike policy-analyst leads that use `analyze-policy`, this viewpoint lead must use `analyze-viewpoint` and `write-spec` skills (`plugins/core/skills/analyze-viewpoint/SKILL.md`, `plugins/core/skills/write-spec/SKILL.md`)
- The viewpoint slug remains "data" even though the lead name is "db-lead"; the output file stays `.workaholic/specs/data.md` to maintain backward compatibility with the validation script (`plugins/core/commands/scan.md` line 67)
- The partial scan mapping in `select.sh` references `data-analyst` on line 94 for `.workaholic/tickets/*` changes; this must be updated to `db-lead` (`plugins/core/skills/select-scan-agents/sh/select.sh` lines 92-97)
- The db-lead name reflects this agent's ownership of persistency/data storage concerns, which is a broader framing than the original "data-analyst" name
- Cross-reference: the infra-lead and communication-lead tickets also transform viewpoint analysts in this same batch
