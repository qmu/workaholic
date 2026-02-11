---
created_at: 2026-02-11T18:34:39+08:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add Constraint-Setting Workflow to Manager Skills

## Overview

The primary concern of managers is to set "constraints" that stabilize the backbone of a project. Currently, the three manager skills (manage-project, manage-architecture, manage-quality) focus on analysis and output production but lack a defined workflow for the constraint-setting process itself. This ticket updates the `managers-policy` skill to define a shared constraint-setting workflow, and updates each manager skill's Execution section to incorporate that workflow: analyze the current situation, ask the user questions to understand intent, propose constraints, and produce directional materials (policies, guidelines, roadmaps) that leader agents and human developers can consume.

The key insight is that managers should not just observe and report -- they should actively shape the project's direction by establishing constraints that narrow the decision space for leaders. A constraint is a deliberate boundary (architectural decision, quality standard, project rule) that leaders must work within.

## Key Files

- `plugins/core/skills/managers-policy/SKILL.md` - Cross-cutting manager policy; will receive a new "Constraint Setting" section defining the shared workflow
- `plugins/core/skills/manage-project/SKILL.md` - Project manager skill; Execution section needs constraint-setting steps for business/stakeholder constraints
- `plugins/core/skills/manage-architecture/SKILL.md` - Architecture manager skill; Execution section needs constraint-setting steps for structural/design constraints
- `plugins/core/skills/manage-quality/SKILL.md` - Quality manager skill; Execution section needs constraint-setting steps for quality standard constraints
- `plugins/core/agents/project-manager.md` - Project manager agent; Instructions may need a new task type mapping for constraint-setting
- `plugins/core/agents/architecture-manager.md` - Architecture manager agent; same consideration
- `plugins/core/agents/quality-manager.md` - Quality manager agent; same consideration
- `.claude/rules/define-manager.md` - Manager schema enforcement; may need documentation of constraint-setting as a standard Execution workflow pattern

## Related History

The manager tier was recently introduced with three manager skills and a managers-policy. The Execution sections currently define a linear gather-analyze-produce workflow without interactive constraint-setting or user-facing question steps. The leaders-policy established the pattern of cross-cutting behavioral policies that this ticket extends to constraint-setting behavior.

Past tickets that touched similar areas:

- [20260211170401-define-manager-tier-and-skills.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170401-define-manager-tier-and-skills.md) - Created the manager tier, three manager skills, and managers-policy (foundation this ticket builds on)
- [20260211170402-wire-leaders-to-manager-outputs.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170402-wire-leaders-to-manager-outputs.md) - Wired leaders to consume manager outputs and established two-phase scan execution (defines the consumption side of manager outputs)
- [20260210124953-add-leaders-policy-skill.md](.workaholic/tickets/archive/drive-20260210-121635/20260210124953-add-leaders-policy-skill.md) - Added leaders-policy cross-cutting skill (established the pattern of shared behavioral policies across agent tiers)

## Implementation Steps

1. **Add "Constraint Setting" section to `plugins/core/skills/managers-policy/SKILL.md`**

   Add a new `## Constraint Setting` section after the existing `## Strategic Focus` section. This defines the shared constraint-setting workflow that all managers must follow:

   The workflow has four phases:
   - **Analyze**: Examine the current state of the project within the manager's domain. Identify areas where no constraint exists (unbounded decisions), where implicit constraints exist but are undocumented, and where existing constraints may be outdated or conflicting.
   - **Ask**: Present findings to the user and ask targeted questions to understand their intent, priorities, and non-negotiables. Questions should be concrete and decision-oriented, not open-ended. Each question should offer options grounded in the analysis.
   - **Propose**: Based on the analysis and user answers, propose a set of constraints. Each constraint must state what it bounds, why it matters, and what it enables leaders to do (or stop doing). Constraints must be falsifiable -- a leader should be able to determine whether they are operating within or outside a constraint.
   - **Produce**: Write directional materials that encode the constraints as consumable artifacts. The artifact type depends on what is being constrained:
     - **Policy**: A rule that must be followed (e.g., "All API endpoints must return JSON")
     - **Guideline**: A recommended practice with rationale (e.g., "Prefer composition over inheritance because...")
     - **Roadmap**: A sequenced plan with milestones (e.g., "Phase 1: migrate auth, Phase 2: migrate storage")
     - **Decision Record**: A captured decision with context and consequences

   Rules for the section:
   - Constraints must be grounded in evidence from the codebase or user input, not invented.
   - Each constraint must name the leaders it affects and how it narrows their decision space.
   - Directional materials must be written to paths under `.workaholic/` where leaders can find them.
   - When the user declines to set a constraint in an area, document it as "unconstrained by design" rather than leaving it implicit.

2. **Update Execution section in `plugins/core/skills/manage-project/SKILL.md`**

   Extend the existing Execution steps to incorporate constraint-setting. The current steps (gather, analyze, produce, report confidence) remain as the foundation. Add constraint-setting steps that produce project-level directional materials:

   After the current gather/analyze steps, add:
   - Identify areas where project constraints are missing or implicit (e.g., release cadence undocumented, stakeholder priorities unranked, scope boundaries undefined).
   - Ask the user targeted questions about business priorities, stakeholder rankings, timeline commitments, and scope boundaries.
   - Propose project constraints (e.g., "Release weekly on Fridays", "Feature X is out of scope for v2", "Stakeholder A's concerns take priority over Stakeholder B's").
   - Produce directional materials: project roadmap, stakeholder priority matrix, scope boundary document, or timeline commitments -- written to `.workaholic/policies/` or `.workaholic/` as appropriate.

3. **Update Execution section in `plugins/core/skills/manage-architecture/SKILL.md`**

   Extend the existing Execution steps to incorporate constraint-setting for architectural decisions:

   After the current gather/analyze steps (viewpoint gathering, override checking), add:
   - Identify areas where architectural constraints are missing or implicit (e.g., no documented layer boundary rules, no component naming convention, no dependency direction policy).
   - Ask the user targeted questions about architectural preferences, technology choices, performance requirements, and structural boundaries.
   - Propose architectural constraints (e.g., "Skills must not import from agents", "All external integrations go through an adapter layer", "Maximum 3 levels of directory nesting").
   - Produce directional materials: architecture decision records, structural guidelines, layer boundary policies -- written to `.workaholic/policies/` as appropriate.

4. **Update Execution section in `plugins/core/skills/manage-quality/SKILL.md`**

   Extend the existing Execution steps to incorporate constraint-setting for quality standards:

   After the current gather/analyze/cross-reference steps, add:
   - Identify areas where quality constraints are missing or implicit (e.g., no minimum test coverage threshold, no documentation completeness standard, no performance budget).
   - Ask the user targeted questions about quality priorities, acceptable trade-offs, enforcement preferences, and improvement goals.
   - Propose quality constraints (e.g., "All new code must have accompanying tests", "Documentation must be updated in the same commit as code changes", "No lint warnings allowed in CI").
   - Produce directional materials: quality standards document, assurance process definitions, improvement roadmap -- written to `.workaholic/policies/` as appropriate.

5. **Update manager agent Instructions to recognize constraint-setting task type**

   In each of the three manager agent files (`project-manager.md`, `architecture-manager.md`, `quality-manager.md`), update the Instructions section to add a fifth task type mapping:

   - Setting constraints or defining direction -> Constraint Setting workflow (from managers-policy) + Execution policy

   This ensures that when a caller asks a manager to "set constraints" or "define direction", the agent knows to follow the constraint-setting workflow.

## Patches

### `plugins/core/skills/managers-policy/SKILL.md`

```diff
--- a/plugins/core/skills/managers-policy/SKILL.md
+++ b/plugins/core/skills/managers-policy/SKILL.md
@@ -42,3 +42,43 @@
 - Outputs must use structured formats that leaders can parse programmatically or
   reference by section.
 - Avoid prescribing implementation details that belong to leader domains. Define the
   what and why, not the how.
+
+## Constraint Setting
+
+The primary function of managers is to set constraints that stabilize the project's
+backbone. Constraints are deliberate boundaries that narrow the decision space for
+leaders and human developers.
+
+### Workflow
+
+1. **Analyze** the current state within the manager's domain. Identify:
+   - Unbounded areas where no constraint exists
+   - Implicit constraints that are practiced but undocumented
+   - Existing constraints that may be outdated or conflicting
+2. **Ask** the user targeted questions to understand intent, priorities, and
+   non-negotiables. Each question must offer concrete options grounded in the analysis.
+   Do not ask open-ended questions.
+3. **Propose** constraints based on analysis and user answers. Each constraint must:
+   - State what it bounds
+   - State why it matters
+   - Name the leaders it affects
+   - Be falsifiable (a leader can determine if they are within or outside the constraint)
+4. **Produce** directional materials that encode the constraints as consumable artifacts:
+   - **Policy**: A rule that must be followed
+   - **Guideline**: A recommended practice with rationale
+   - **Roadmap**: A sequenced plan with milestones
+   - **Decision Record**: A captured decision with context and consequences
+
+### Rules
+
+- Ground every constraint in codebase evidence or user input. Never invent constraints.
+- Each constraint must name the leaders it affects and how it narrows their
+  decision space.
+- Write directional materials to paths under `.workaholic/` where leaders can
+  find them.
+- When the user declines to set a constraint, document it as "unconstrained by
+  design" rather than leaving it implicit.
+- Constraints are not permanent. Document review triggers (e.g., "revisit after v2
+  release") so constraints do not become stale.
```

> **Note**: This patch is speculative - verify exact trailing content before applying.

### `plugins/core/skills/manage-project/SKILL.md`

```diff
--- a/plugins/core/skills/manage-project/SKILL.md
+++ b/plugins/core/skills/manage-project/SKILL.md
@@ -61,3 +61,8 @@
 - Analyze gathered context against the Outputs structure.
 - Produce the project context output document.
 - Report confidence level (high/medium/low) for each section based on evidence quality.
+- Follow the Constraint Setting workflow from managers-policy:
+  - Identify missing or implicit project constraints (release cadence, stakeholder priorities, scope boundaries, timeline commitments).
+  - Ask the user targeted questions about business priorities, stakeholder rankings, and scope decisions.
+  - Propose project constraints grounded in gathered evidence and user answers.
+  - Produce directional materials (roadmap, stakeholder priority matrix, scope boundary document) to `.workaholic/policies/` or `.workaholic/`.
```

### `plugins/core/skills/manage-architecture/SKILL.md`

```diff
--- a/plugins/core/skills/manage-architecture/SKILL.md
+++ b/plugins/core/skills/manage-architecture/SKILL.md
@@ -77,3 +77,8 @@
 - Write all four viewpoint specs (application.md, component.md, feature.md, usecase.md) to `.workaholic/specs/`.
 - Write the English specs first, then produce translations per the user's translation policy declared in their root CLAUDE.md.
+- Follow the Constraint Setting workflow from managers-policy:
+  - Identify missing or implicit architectural constraints (layer boundary rules, component naming conventions, dependency direction policies, technology choices).
+  - Ask the user targeted questions about architectural preferences, structural boundaries, and technology decisions.
+  - Propose architectural constraints grounded in gathered evidence and user answers.
+  - Produce directional materials (architecture decision records, structural guidelines, layer boundary policies) to `.workaholic/policies/`.
```

### `plugins/core/skills/manage-quality/SKILL.md`

```diff
--- a/plugins/core/skills/manage-quality/SKILL.md
+++ b/plugins/core/skills/manage-quality/SKILL.md
@@ -63,3 +63,8 @@
 - Produce the quality context output document.
 - Cross-reference quality dimensions against assurance processes to identify gaps.
+- Follow the Constraint Setting workflow from managers-policy:
+  - Identify missing or implicit quality constraints (test coverage thresholds, documentation completeness standards, performance budgets, lint strictness levels).
+  - Ask the user targeted questions about quality priorities, acceptable trade-offs, and enforcement preferences.
+  - Propose quality constraints grounded in gathered evidence and user answers.
+  - Produce directional materials (quality standards document, assurance process definitions, improvement roadmap) to `.workaholic/policies/`.
```

### `plugins/core/agents/project-manager.md`

```diff
--- a/plugins/core/agents/project-manager.md
+++ b/plugins/core/agents/project-manager.md
@@ -19,6 +19,7 @@
    - Writing or modifying code -> Implementation policy
    - Reviewing artifacts -> Review policy
    - Writing or updating documentation -> Documentation policy
    - Running commands or actions -> Execution policy
+   - Setting constraints or defining direction -> Constraint Setting workflow (managers-policy) + Execution policy
 3. Execute the task within the manager's Role and Responsibility.
```

### `plugins/core/agents/architecture-manager.md`

```diff
--- a/plugins/core/agents/architecture-manager.md
+++ b/plugins/core/agents/architecture-manager.md
@@ -19,6 +19,7 @@
    - Writing or modifying code -> Implementation policy
    - Reviewing artifacts -> Review policy
    - Writing or updating documentation -> Documentation policy
    - Running commands or actions -> Execution policy
+   - Setting constraints or defining direction -> Constraint Setting workflow (managers-policy) + Execution policy
 3. Execute the task within the manager's Role and Responsibility.
```

### `plugins/core/agents/quality-manager.md`

```diff
--- a/plugins/core/agents/quality-manager.md
+++ b/plugins/core/agents/quality-manager.md
@@ -19,6 +19,7 @@
    - Writing or modifying code -> Implementation policy
    - Reviewing artifacts -> Review policy
    - Writing or updating documentation -> Documentation policy
    - Running commands or actions -> Execution policy
+   - Setting constraints or defining direction -> Constraint Setting workflow (managers-policy) + Execution policy
 3. Execute the task within the manager's Role and Responsibility.
```

## Considerations

- The constraint-setting workflow introduces user interaction (the "Ask" phase) into what was previously a non-interactive analysis pipeline. During `/scan`, managers run as sub-agents that may not have direct user interaction capability. The constraint-setting workflow may need to be a separate invocation mode (e.g., called directly by the user or by a command) rather than running automatically in every scan. Consider whether the Execution section should conditionally apply constraint-setting only when explicitly requested, or always. (`plugins/core/commands/scan.md`, `plugins/core/skills/managers-policy/SKILL.md`)
- The "Produce" phase outputs directional materials to `.workaholic/`. The existing scan workflow already writes to `.workaholic/specs/` and `.workaholic/policies/`. New artifact types like roadmaps and decision records may need new directories (e.g., `.workaholic/decisions/`, `.workaholic/roadmaps/`) or can be placed under `.workaholic/policies/` with appropriate naming. This needs a convention decision. (`.workaholic/`)
- The `define-manager.md` schema currently defines Execution as "Rules when running commands or performing actions." The constraint-setting workflow is broader than this -- it includes user interaction. Consider whether to update the schema's Execution description or to document constraint-setting as a separate workflow that supplements Execution. (`.claude/rules/define-manager.md` lines 64-66)
- Leaders currently consume manager outputs as read-only context. Constraints add a new semantic: outputs that leaders must comply with, not just reference. The leaders-policy or individual leader Execution sections may eventually need a "Check constraints" step, but that is out of scope for this ticket. (`plugins/core/skills/leaders-policy/SKILL.md`)
- The four artifact types (Policy, Guideline, Roadmap, Decision Record) overlap with existing concepts. Policies already exist in `.workaholic/policies/`. Guidelines and decision records are new artifact types that may warrant their own write skills or templates in a follow-up ticket. (`plugins/core/skills/analyze-policy/SKILL.md`)
