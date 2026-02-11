---
created_at: 2026-02-11T17:04:01+08:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash: 8dc1ce4
category: Changed
---

# Define Manager Tier and Create Three Manager Skills

## Overview

Introduce a "manager" tier that sits above leaders in the agent hierarchy. Managers produce higher-level strategic outputs that leaders depend on. Create three manager skills following a new `define-manager` schema: `manage-project` (business, stakeholders, timeline, issues, solutions), `manage-architecture` (software experience, system structure, components from infrastructure to application), and `manage-quality` (quality standards, assurance processes, continuous improvement). Also create a `managers-policy` cross-cutting policy skill parallel to the existing `leaders-policy`.

The current system has a flat set of 11 lead agents. This change adds a management layer that provides strategic context. Leaders consume manager outputs rather than deriving strategic context independently.

## Key Files

- `.claude/rules/define-lead.md` - Existing lead schema; reference pattern for creating `define-manager` schema
- `plugins/core/skills/leaders-policy/SKILL.md` - Cross-cutting leader policy; reference pattern for `managers-policy`
- `plugins/core/skills/lead-architecture/SKILL.md` - Architecture lead skill; will later depend on manage-architecture output
- `plugins/core/skills/lead-quality/SKILL.md` - Quality lead skill; will later depend on manage-quality output
- `plugins/core/skills/lead-delivery/SKILL.md` - Delivery lead skill; affected by manage-project output
- `plugins/core/skills/lead-security/SKILL.md` - Security lead skill; affected by manage-architecture output
- `plugins/core/skills/lead-test/SKILL.md` - Test lead skill; affected by manage-quality output
- `plugins/core/agents/architecture-lead.md` - Reference agent pattern for creating manager agents
- `plugins/core/commands/scan.md` - Scan command that invokes all agents; will need to invoke managers before leaders

## Related History

The project recently completed a migration from flat analysts to a lead-based agent hierarchy, and added cross-cutting policies via the `leaders-policy` skill. This ticket extends that hierarchy with a management tier.

- [20260210124953-add-leaders-policy-skill.md](.workaholic/tickets/archive/drive-20260210-121635/20260210124953-add-leaders-policy-skill.md) - Added leaders-policy as a cross-cutting behavioral policy for all leads (establishes the pattern for managers-policy)
- [20260209175934-consolidate-viewpoint-analysts-into-architecture-lead.md](.workaholic/tickets/archive/drive-20260208-131649/20260209175934-consolidate-viewpoint-analysts-into-architecture-lead.md) - Consolidated four analysts into architecture-lead (established the current lead hierarchy)
- [20260209181813-move-define-lead-to-claude-rules.md](.workaholic/tickets/archive/drive-20260208-131649/20260209181813-move-define-lead-to-claude-rules.md) - Moved define-lead to `.claude/rules/` for path-scoped enforcement (pattern for define-manager placement)

## Implementation Steps

1. **Create `.claude/rules/define-manager.md` schema enforcement rule**

   Follow the same structure as `.claude/rules/define-lead.md` but adapted for manager skills. Path scope: `plugins/core/skills/manage-*/SKILL.md` and `plugins/core/agents/*-manager.md`.

   Manager schema differences from lead schema:
   - Name format: `manage-<domain>` (not `<speciality>-lead`)
   - Agent name format: `<domain>-manager` (not `<speciality>-lead`)
   - Sections: Role, Responsibility, Goal, Outputs, Default Policies
   - The `## Outputs` section is new -- it defines the structured artifacts the manager produces that leaders consume
   - Default Policies subsections remain the same: Implementation, Review, Documentation, Execution

2. **Create `plugins/core/skills/managers-policy/SKILL.md`**

   Cross-cutting behavioral policy for all manager agents, parallel to `leaders-policy`. Managers should observe:
   - **Prior Term Consistency** (same as leaders-policy -- reuse the exact same rules)
   - **Vendor Neutrality** (same as leaders-policy -- reuse the exact same rules)
   - **Strategic Focus** (new, manager-specific): Managers define strategic direction. Their outputs must be actionable by leaders, not aspirational. Every output artifact must be consumable as input by at least one leader.

3. **Create `plugins/core/skills/manage-project/SKILL.md`**

   Manager skill following the define-manager schema:
   - **Role**: The project manager owns business context, stakeholder relationships, timeline, issues, and solutions for the project.
   - **Responsibility**: Maintain accurate business context. Identify stakeholders and their concerns. Track timeline and milestones. Surface issues and propose solutions.
   - **Goal**: Leaders have the strategic context they need to make domain-specific decisions without duplicating business analysis.
   - **Outputs**: `project-context.json` or equivalent structured output containing business domain, stakeholder map, timeline status, active issues, and proposed solutions.
   - **Default Policies**: Implementation (analyze codebase for business context evidence), Review (verify stakeholder claims are grounded), Documentation (structured output format), Execution (gather context, analyze, produce outputs).

4. **Create `plugins/core/skills/manage-architecture/SKILL.md`**

   Manager skill following the define-manager schema:
   - **Role**: The architecture manager owns the software experience definition, system structure, and component taxonomy from infrastructure to application layer.
   - **Responsibility**: Define the system's architectural boundaries. Map components across all layers (infrastructure, middleware, application). Maintain structural coherence across the system.
   - **Goal**: Leaders (especially infra-lead, db-lead, security-lead, architecture-lead) receive a consistent structural context for their domain-specific work.
   - **Outputs**: Structured architectural context including system boundary definitions, layer taxonomy (infrastructure through application), component inventory, and cross-cutting concerns.
   - **Default Policies**: Implementation (derive structure from observable codebase), Review (verify structural claims match implementation), Documentation (layer-by-layer structure documentation), Execution (analyze repository structure, produce outputs).

5. **Create `plugins/core/skills/manage-quality/SKILL.md`**

   Manager skill following the define-manager schema:
   - **Role**: The quality manager owns quality standards, assurance processes, and continuous improvement practices for the project.
   - **Responsibility**: Define quality standards across all dimensions. Establish assurance processes. Drive continuous improvement through metrics and feedback loops.
   - **Goal**: Leaders (especially quality-lead, test-lead, a11y-lead) receive quality standards and assurance context for their domain-specific enforcement.
   - **Outputs**: Structured quality context including quality dimensions and standards, assurance process definitions, improvement metrics, and feedback loop specifications.
   - **Default Policies**: Implementation (document only observable quality practices), Review (verify quality claims cite enforcement mechanisms), Documentation (structured quality framework), Execution (analyze quality infrastructure, produce outputs).

6. **Create three manager agent files**

   Create thin agent orchestrators following the define-manager agent template:
   - `plugins/core/agents/project-manager.md` - Skills: `managers-policy`, `manage-project`
   - `plugins/core/agents/architecture-manager.md` - Skills: `managers-policy`, `manage-architecture`
   - `plugins/core/agents/quality-manager.md` - Skills: `managers-policy`, `manage-quality`

   Each agent follows the same thin orchestrator pattern as lead agents (~20-40 lines).

## Considerations

- The `define-manager` schema adds an `## Outputs` section that does not exist in `define-lead`. This is the key structural difference: managers produce artifacts that leaders consume, while leaders produce domain-specific documentation. The output contract between managers and leaders needs to be well-defined so leaders know exactly what to expect. (`.claude/rules/define-manager.md`)
- The `managers-policy` skill should share the same Prior Term Consistency and Vendor Neutrality rules as `leaders-policy`. Consider whether these should be extracted into a shared base or simply duplicated. Duplication is simpler and avoids skill-to-skill dependency complications since skills cannot invoke other skills via frontmatter. (`plugins/core/skills/managers-policy/SKILL.md`, `plugins/core/skills/leaders-policy/SKILL.md`)
- The naming convention `manage-<domain>` for skills and `<domain>-manager` for agents parallels `lead-<speciality>` for skills and `<speciality>-lead` for agents. This maintains the existing naming pattern symmetry. (`plugins/core/skills/manage-*/SKILL.md`, `plugins/core/agents/*-manager.md`)
- The memo lists `lead-ux` in the leaders list, but no `lead-ux` skill or UX lead agent currently exists. The `lead-communication` skill covers some UX-adjacent concerns (stakeholder mapping, user goals, interaction patterns). The second ticket (wiring leaders to managers) should address whether `lead-communication` should be renamed to `lead-ux` or if a separate `lead-ux` is needed. (`plugins/core/skills/lead-communication/SKILL.md`)
- Manager agents will need to be invoked before leaders in the scan command, since leaders depend on manager outputs. This ordering change belongs in the second ticket. (`plugins/core/commands/scan.md`)
- Cross-reference: The second ticket [20260211170402-wire-leaders-to-manager-outputs.md](.workaholic/tickets/todo/20260211170402-wire-leaders-to-manager-outputs.md) handles wiring leaders to consume manager outputs and updating the scan command invocation order.

## Final Report

### Changes Made

| File | Action |
| ---- | ------ |
| `.claude/rules/define-manager.md` | Created -- manager schema enforcement rule with explicit path scoping to avoid matching `manage-branch` |
| `plugins/core/skills/managers-policy/SKILL.md` | Created -- cross-cutting policy with Prior Term Consistency and Strategic Focus (Vendor Neutrality omitted per feedback) |
| `plugins/core/skills/manage-project/SKILL.md` | Created -- project manager skill (business, stakeholders, timeline, issues, solutions) |
| `plugins/core/skills/manage-architecture/SKILL.md` | Created -- architecture manager skill (system structure, layers, components, cross-cutting concerns) |
| `plugins/core/skills/manage-quality/SKILL.md` | Created -- quality manager skill (standards, assurance processes, metrics, gaps, feedback loops) |
| `plugins/core/agents/project-manager.md` | Created -- thin agent orchestrator |
| `plugins/core/agents/architecture-manager.md` | Created -- thin agent orchestrator |
| `plugins/core/agents/quality-manager.md` | Created -- thin agent orchestrator |

### Deviations

- **Path scoping**: Used explicit paths in `define-manager.md` instead of `manage-*/SKILL.md` glob to avoid matching the pre-existing `manage-branch` utility skill.
- **Vendor Neutrality omitted**: Removed from `managers-policy` per user feedback. Only Prior Term Consistency and Strategic Focus remain.
