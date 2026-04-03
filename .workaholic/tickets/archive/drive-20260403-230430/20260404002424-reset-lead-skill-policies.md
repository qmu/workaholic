---
created_at: 2026-04-04T00:24:24+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.5h
commit_hash: 52e04b0
category: Changed
---

# Reset All Lead Skill Policies

## Overview

Rename "Default Policies" to "Policies" and erase all policy content across the 10 lead skills in the standards plugin. The Role section (Goal and Responsibility) in each skill remains untouched. Update the schema enforcement rule and all agent files that reference "Default Policies" to use the new "Policies" heading.

## Key Files

- `plugins/standards/skills/lead-a11y/SKILL.md` - Lead skill with policies to reset
- `plugins/standards/skills/lead-db/SKILL.md` - Lead skill with policies to reset
- `plugins/standards/skills/lead-delivery/SKILL.md` - Lead skill with policies to reset
- `plugins/standards/skills/lead-infra/SKILL.md` - Lead skill with policies to reset
- `plugins/standards/skills/lead-observability/SKILL.md` - Lead skill with policies to reset
- `plugins/standards/skills/lead-quality/SKILL.md` - Lead skill with policies to reset
- `plugins/standards/skills/lead-recovery/SKILL.md` - Lead skill with policies to reset
- `plugins/standards/skills/lead-security/SKILL.md` - Lead skill with policies to reset
- `plugins/standards/skills/lead-test/SKILL.md` - Lead skill with policies to reset
- `plugins/standards/skills/lead-ux/SKILL.md` - Lead skill with policies to reset
- `.claude/rules/define-lead.md` - Schema enforcement rule referencing "Default Policies"
- `plugins/standards/agents/a11y-lead.md` - Agent referencing "Default Policy"
- `plugins/standards/agents/db-lead.md` - Agent referencing "Default Policy"
- `plugins/standards/agents/delivery-lead.md` - Agent referencing "Default Policy"
- `plugins/standards/agents/infra-lead.md` - Agent referencing "Default Policy"
- `plugins/standards/agents/observability-lead.md` - Agent referencing "Default Policy"
- `plugins/standards/agents/quality-lead.md` - Agent referencing "Default Policy"
- `plugins/standards/agents/recovery-lead.md` - Agent referencing "Default Policy"
- `plugins/standards/agents/security-lead.md` - Agent referencing "Default Policy"
- `plugins/standards/agents/test-lead.md` - Agent referencing "Default Policy"
- `plugins/standards/agents/ux-lead.md` - Agent referencing "Default Policy"
- `plugins/standards/skills/leaders-principle/SKILL.md` - Principle skill referencing "Default Policies"

## Related History

The lead architecture was established in a dedicated drive branch that created the define-lead schema and transformed all analyst agents into the lead pattern with Default Policies sections.

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead schema with Default Policies section (same schema being modified)
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - Transformed a11y analyst to lead pattern (same files being modified)
- [20260209164507-transform-security-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209164507-transform-security-analyst-to-lead-architecture.md) - Transformed security analyst to lead pattern (same files being modified)
- [20260219165413-restructure-role-responsibility-goal-headings.md](.workaholic/tickets/archive/drive-20260213-131416/20260219165413-restructure-role-responsibility-goal-headings.md) - Restructured Role/Responsibility/Goal headings in lead skills (precedent for schema-wide structural change)
- [20260212173856-rename-policy-skills-to-principle.md](.workaholic/tickets/archive/drive-20260212-122906/20260212173856-rename-policy-skills-to-principle.md) - Renamed policy skills to principle (precedent for terminology rename across all files)

## Implementation Steps

1. **Reset policy content in all 10 lead SKILL.md files**

   For each of the 10 lead skills under `plugins/standards/skills/lead-*/SKILL.md`:
   - Rename `## Default Policies` to `## Policies`
   - Keep the four subsection headers: `### Implementation`, `### Review`, `### Documentation`, `### Execution`
   - Erase all bullet points and content beneath each subsection header
   - Leave the Role section (including Goal and Responsibility) completely unchanged

   The resulting Policies section in each file should look like:

   ```markdown
   ## Policies

   ### Implementation

   ### Review

   ### Documentation

   ### Execution
   ```

2. **Update the schema enforcement rule**

   In `.claude/rules/define-lead.md`:
   - Rename all occurrences of `## Default Policies` to `## Policies` in the schema template (line 39) and example (line 173)
   - Rename `### Default Policies` to `### Policies` in the guidelines section (line 81)
   - Update the text "Default Policies apply unless..." to "Policies apply unless..." (line 92)
   - Update the validation checklist item from `## Default Policies` to `## Policies` (line 103)
   - Update agent template references from "Default Policy" to "Policy" (lines 112, 133)

3. **Update all 10 lead agent files**

   In each `plugins/standards/agents/*-lead.md`:
   - Update the description line from "default policies" to "policies" (e.g., "Follow the preloaded lead-security skill for role, responsibility, and policies.")
   - Update the instruction from "Apply the corresponding Default Policy from the lead-* skill" to "Apply the corresponding Policy from the lead-* skill"

4. **Update the leaders-principle skill**

   In `plugins/standards/skills/leaders-principle/SKILL.md`:
   - Update "domain-specific Default Policies" to "domain-specific Policies" (line 10)

## Considerations

- The rename from "Default Policies" to "Policies" cascades across 22+ files; all references must be updated atomically to avoid inconsistency (`plugins/standards/` and `.claude/rules/define-lead.md`)
- The manager-tier skills (`manage-architecture`, `manage-project`, `manage-quality`) and `managers-principle` also use "Default Policies" but are explicitly out of scope for this ticket -- only lead skills are reset (`plugins/standards/skills/manage-*/SKILL.md`)
- The `define-manager.md` rule at `.claude/rules/define-manager.md` also references "Default Policies" but is out of scope since only leads are being reset (`.claude/rules/define-manager.md`)
- After this reset, the policy subsection headers will be empty placeholders; the user plans to manually repopulate them with new content
- The `.workaholic/specs/` and `.workaholic/terms/` files that mention "Default Policies" are generated documentation and will be refreshed on the next `/scan` run -- no manual update needed

## Final Report

### Changes

- Renamed `## Default Policies` to `## Policies` and erased all policy content and subsection headers in 10 lead SKILL.md files (lead-a11y, lead-db, lead-delivery, lead-infra, lead-observability, lead-quality, lead-recovery, lead-security, lead-test, lead-ux) — each now ends with just `## Policies`
- Updated `.claude/rules/define-lead.md` schema rule: renamed all "Default Policies" references to "Policies" across template, guidelines, validation checklist, agent template, and example sections
- Updated 10 lead agent files to reference "policies" instead of "default policies" in descriptions and instructions
- Updated `plugins/standards/skills/leaders-principle/SKILL.md` to reference "domain-specific Policies"

### Test Plan

- [x] Verified no remaining "Default Polic" references in `plugins/standards/` or `.claude/rules/define-lead.md` (only manager-tier files remain, which are out of scope)
- [x] Verified sample file (lead-security) has correct structure: Role preserved, Policies section with empty subsection headers

### Release Prep

- None — configuration-only change, no runtime impact
