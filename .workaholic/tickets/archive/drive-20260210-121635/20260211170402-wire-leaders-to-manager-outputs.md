---
created_at: 2026-02-11T17:04:02+08:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 2h
commit_hash: 24632f3
category: Changed
---

# Wire Leaders to Depend on Manager Outputs

## Overview

Update the 10 existing leader skills and the scan command so that leaders consume outputs produced by the three manager agents (project-manager, architecture-manager, quality-manager). Establish a two-phase scan execution: managers run first in parallel, then leaders run in parallel with manager outputs available. Also resolve whether `lead-communication` should become `lead-ux` as indicated in the memo.

The target leader list from the memo: lead-ux, lead-a11y, lead-infra, lead-db, lead-security, lead-test, lead-quality, lead-delivery, lead-observability, lead-recovery. Note that `lead-architecture` is not in this list -- its concerns are absorbed by `manage-architecture` at the manager tier.

## Key Files

- `plugins/core/commands/scan.md` - Scan command; must add manager phase before leader phase
- `plugins/core/skills/select-scan-agents/sh/select.sh` - Agent selection script; must add manager agents
- `plugins/core/skills/select-scan-agents/SKILL.md` - Agent selection documentation; must document manager tier
- `plugins/core/skills/lead-a11y/SKILL.md` - Will consume manage-quality outputs
- `plugins/core/skills/lead-infra/SKILL.md` - Will consume manage-architecture outputs
- `plugins/core/skills/lead-db/SKILL.md` - Will consume manage-architecture outputs
- `plugins/core/skills/lead-security/SKILL.md` - Will consume manage-architecture outputs
- `plugins/core/skills/lead-test/SKILL.md` - Will consume manage-quality outputs
- `plugins/core/skills/lead-quality/SKILL.md` - Will consume manage-quality outputs
- `plugins/core/skills/lead-delivery/SKILL.md` - Will consume manage-project outputs
- `plugins/core/skills/lead-observability/SKILL.md` - Will consume manage-architecture outputs
- `plugins/core/skills/lead-recovery/SKILL.md` - Will consume manage-architecture outputs
- `plugins/core/skills/lead-communication/SKILL.md` - Candidate for rename to `lead-ux`
- `plugins/core/skills/lead-architecture/SKILL.md` - May be removed or merged into manage-architecture
- `plugins/core/agents/architecture-lead.md` - May be removed or repurposed
- `plugins/core/agents/communication-lead.md` - May be renamed to ux-lead
- `.claude/rules/define-lead.md` - Lead schema; may need update for manager dependency declaration

## Related History

The project recently added the `leaders-policy` cross-cutting skill and completed the analyst-to-lead migration. The first ticket in this series creates the manager tier; this ticket completes the integration.

- [20260211170401-define-manager-tier-and-skills.md](.workaholic/tickets/todo/20260211170401-define-manager-tier-and-skills.md) - Foundation ticket: creates manager schema, 3 manager skills, managers-policy, and 3 manager agents
- [20260210124953-add-leaders-policy-skill.md](.workaholic/tickets/archive/drive-20260210-121635/20260210124953-add-leaders-policy-skill.md) - Added leaders-policy cross-cutting skill; established the pattern of shared behavioral policies
- [20260209175934-consolidate-viewpoint-analysts-into-architecture-lead.md](.workaholic/tickets/archive/drive-20260208-131649/20260209175934-consolidate-viewpoint-analysts-into-architecture-lead.md) - Consolidated four viewpoint analysts into architecture-lead; this lead may now be absorbed by the manager tier

## Implementation Steps

1. **Define manager-to-leader dependency mapping**

   Establish which leaders consume which manager outputs:

   | Manager | Leader consumers |
   | --- | --- |
   | manage-project | lead-delivery, lead-ux (all leaders benefit, but these are primary) |
   | manage-architecture | lead-infra, lead-db, lead-security, lead-observability, lead-recovery |
   | manage-quality | lead-quality, lead-test, lead-a11y |

2. **Resolve lead-communication to lead-ux rename**

   The memo specifies `lead-ux` but the current codebase has `lead-communication`. Determine the correct resolution:
   - If renaming: rename `plugins/core/skills/lead-communication/` to `plugins/core/skills/lead-ux/`, update SKILL.md name/description, rename `plugins/core/agents/communication-lead.md` to `plugins/core/agents/ux-lead.md`, update all references in scan.md and select-scan-agents
   - If keeping both: create `lead-ux` as a new skill alongside `lead-communication`
   - The memo lists only `lead-ux` with no `lead-communication`, suggesting a rename

3. **Resolve architecture-lead fate**

   The memo lists 10 leaders without `lead-architecture`. The `manage-architecture` manager absorbs the strategic architectural concerns. Determine:
   - Remove `architecture-lead` agent and `lead-architecture` skill entirely (manager replaces it)
   - Or keep `architecture-lead` as a leader that consumes `manage-architecture` outputs for detailed spec production

   If removing: delete `plugins/core/agents/architecture-lead.md` and `plugins/core/skills/lead-architecture/SKILL.md`, update scan.md agent count and table, update select-scan-agents

4. **Update scan command for two-phase execution**

   Modify `plugins/core/commands/scan.md`:
   - Add Phase 3a: Invoke 3 manager agents in parallel (project-manager, architecture-manager, quality-manager)
   - Wait for all managers to complete
   - Phase 3b: Invoke all leader agents in parallel (with manager outputs available)
   - Update agent count (currently 14; will change based on adds/removes)

5. **Update each leader skill's Execution policy**

   For each leader, add a step to read the relevant manager output before performing domain-specific analysis. In the `### Execution` section of each lead skill:
   - Add instruction to read the relevant manager output file(s)
   - Use manager context to inform domain-specific analysis
   - The manager output serves as strategic input, not a replacement for codebase analysis

6. **Update leader agent files**

   Each leader agent that depends on manager outputs should document this dependency in its description or instructions. The agent still preloads its lead skill and leaders-policy; the manager output is consumed as data, not as a preloaded skill.

7. **Update select-scan-agents**

   Update `plugins/core/skills/select-scan-agents/sh/select.sh`:
   - Add 3 manager agents to ALL_AGENTS
   - Add partial scan mapping for managers (managers triggered broadly since they provide strategic context)

   Update `plugins/core/skills/select-scan-agents/SKILL.md`:
   - Document manager tier in the agent count and categories
   - Update partial scan mapping table

## Considerations

- Two-phase scan execution means managers must complete before leaders start. This is a sequential dependency that prevents fully parallel execution. However, managers can run in parallel with each other, and leaders can run in parallel with each other, so the impact is limited to the inter-phase wait. (`plugins/core/commands/scan.md`)
- If `architecture-lead` is removed, the four spec documents it produces (application.md, component.md, feature.md, usecase.md) need a new owner. The `architecture-manager` could produce these, or they could be distributed among remaining leaders. This decision affects the scan Phase 4 validation. (`plugins/core/skills/lead-architecture/SKILL.md`, `plugins/core/commands/scan.md` lines 62-65)
- The manager output format (JSON, markdown, or other) needs to be defined in the first ticket's `## Outputs` section. Leaders need to know where to find and how to parse manager outputs. A convention like `.workaholic/manager-outputs/<domain>.json` would work. (`plugins/core/skills/manage-project/SKILL.md`)
- Renaming `lead-communication` to `lead-ux` changes the viewpoint slug from "stakeholder" to something UX-focused. This affects the spec filename in `.workaholic/specs/`. Existing `stakeholder.md` would need to be renamed or the slug kept for backward compatibility. (`plugins/core/skills/lead-communication/SKILL.md`)
- The `leaders-policy` skill reference in define-lead Agent Template should be verified to still be correct after the manager tier is added. Managers use `managers-policy`; leaders use `leaders-policy`. These are distinct and should not be cross-wired. (`.claude/rules/define-lead.md`, `.claude/rules/define-manager.md`)
- Cross-reference: This ticket depends on [20260211170401-define-manager-tier-and-skills.md](.workaholic/tickets/todo/20260211170401-define-manager-tier-and-skills.md) which creates the manager tier foundation.

## Final Report

### Changes Made

| File | Action |
| ---- | ------ |
| `plugins/core/skills/lead-ux/SKILL.md` | Created -- renamed from lead-communication, slug changed from "stakeholder" to "ux" |
| `plugins/core/agents/ux-lead.md` | Created -- renamed from communication-lead |
| `plugins/core/skills/lead-communication/SKILL.md` | Deleted -- replaced by lead-ux |
| `plugins/core/agents/communication-lead.md` | Deleted -- replaced by ux-lead |
| `plugins/core/skills/lead-architecture/SKILL.md` | Deleted -- absorbed by manage-architecture |
| `plugins/core/agents/architecture-lead.md` | Deleted -- absorbed by architecture-manager |
| `plugins/core/skills/manage-architecture/SKILL.md` | Updated -- added viewpoint spec production (4 specs), updated consuming leaders list |
| `plugins/core/agents/architecture-manager.md` | Updated -- added analyze-viewpoint skill |
| `plugins/core/commands/scan.md` | Updated -- two-phase execution (Phase 3a: managers, Phase 3b: leaders/writers), updated agent table and validation |
| `plugins/core/skills/select-scan-agents/SKILL.md` | Updated -- documented manager tier, updated agent lists and partial scan mapping |
| `plugins/core/skills/select-scan-agents/sh/select.sh` | Updated -- added managers JSON output, updated agent list, updated partial scan triggers |
| `plugins/core/skills/lead-delivery/SKILL.md` | Updated -- Execution reads manage-project output |
| `plugins/core/skills/lead-infra/SKILL.md` | Updated -- Execution reads manage-architecture output |
| `plugins/core/skills/lead-db/SKILL.md` | Updated -- Execution reads manage-architecture output |
| `plugins/core/skills/lead-security/SKILL.md` | Updated -- Execution reads manage-architecture output |
| `plugins/core/skills/lead-test/SKILL.md` | Updated -- Execution reads manage-quality output |
| `plugins/core/skills/lead-quality/SKILL.md` | Updated -- Execution reads manage-quality output |
| `plugins/core/skills/lead-a11y/SKILL.md` | Updated -- Execution reads manage-quality output |
| `plugins/core/skills/lead-observability/SKILL.md` | Updated -- Execution reads manage-architecture output |
| `plugins/core/skills/lead-recovery/SKILL.md` | Updated -- Execution reads manage-architecture output |

### Deviations

- **Spec slug rename**: Changed viewpoint slug from "stakeholder" to "ux" to match the new lead-ux identity. The scan validation command was updated accordingly (stakeholder.md -> ux.md).
- **Architecture-lead removed**: The 4 viewpoint specs (application.md, component.md, feature.md, usecase.md) are now produced by architecture-manager, which has analyze-viewpoint skill added.
- **Manager output convention**: Leaders read manager outputs from `.workaholic/specs/` and `.workaholic/policies/` (the spec/policy documents managers produce) rather than a separate `.workaholic/manager-outputs/` directory.
