---
created_at: 2026-02-19T16:54:13+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Restructure Role/Responsibility/Goal Heading Hierarchy

## Overview

Restructure the heading hierarchy in `define-manager.md`, `define-lead.md`, and all skill files that follow these schemas. Currently `## Role`, `## Responsibility`, and `## Goal` are independent Level 2 sections. The new structure makes `## Role` the overarching concept with `### Goal` and `### Responsibility` as subsections. The conceptual model is: "Role" contains both "Goal" (what the subject owes to achieve -- positive obligation) and "Responsibility" (what the subject owes to avoid -- negative obligation).

## Key Files

- `.claude/rules/define-manager.md` - Manager schema enforcement rule; defines the template, guidelines, validation checklist, and agent template for managers
- `.claude/rules/define-lead.md` - Lead schema enforcement rule; defines the template, guidelines, validation checklist, agent template, and example for leads
- `plugins/core/skills/manage-project/SKILL.md` - Manager skill using the schema (## Role, ## Responsibility, ## Goal)
- `plugins/core/skills/manage-architecture/SKILL.md` - Manager skill using the schema
- `plugins/core/skills/manage-quality/SKILL.md` - Manager skill using the schema
- `plugins/core/skills/lead-a11y/SKILL.md` - Lead skill using the schema
- `plugins/core/skills/lead-db/SKILL.md` - Lead skill using the schema
- `plugins/core/skills/lead-delivery/SKILL.md` - Lead skill using the schema
- `plugins/core/skills/lead-infra/SKILL.md` - Lead skill using the schema
- `plugins/core/skills/lead-observability/SKILL.md` - Lead skill using the schema
- `plugins/core/skills/lead-quality/SKILL.md` - Lead skill using the schema
- `plugins/core/skills/lead-recovery/SKILL.md` - Lead skill using the schema
- `plugins/core/skills/lead-security/SKILL.md` - Lead skill using the schema
- `plugins/core/skills/lead-test/SKILL.md` - Lead skill using the schema
- `plugins/core/skills/lead-ux/SKILL.md` - Lead skill using the schema
- `plugins/core/agents/project-manager.md` - Agent referencing "Role and Responsibility" in instructions
- `plugins/core/agents/architecture-manager.md` - Agent referencing "Role and Responsibility" in instructions
- `plugins/core/agents/quality-manager.md` - Agent referencing "Role and Responsibility" in instructions
- `plugins/core/agents/a11y-lead.md` - Agent referencing "Role and Responsibility" in instructions
- `plugins/core/agents/db-lead.md` - Agent referencing "Role and Responsibility" in instructions
- `plugins/core/agents/delivery-lead.md` - Agent referencing "Role and Responsibility" in instructions
- `plugins/core/agents/infra-lead.md` - Agent referencing "Role and Responsibility" in instructions
- `plugins/core/agents/observability-lead.md` - Agent referencing "Role and Responsibility" in instructions
- `plugins/core/agents/quality-lead.md` - Agent referencing "Role and Responsibility" in instructions
- `plugins/core/agents/recovery-lead.md` - Agent referencing "Role and Responsibility" in instructions
- `plugins/core/agents/security-lead.md` - Agent referencing "Role and Responsibility" in instructions
- `plugins/core/agents/test-lead.md` - Agent referencing "Role and Responsibility" in instructions
- `plugins/core/agents/ux-lead.md` - Agent referencing "Role and Responsibility" in instructions

## Related History

The define-manager and define-lead schemas were established in recent branches, with define-lead originally created as a skill then moved to `.claude/rules/` for automatic enforcement, and define-manager created later following the same pattern.

- [20260211170401-define-manager-tier-and-skills.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170401-define-manager-tier-and-skills.md) - Created define-manager schema and three manager skills (established the current ## Role / ## Responsibility / ## Goal structure for managers)
- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created define-lead skill with the original schema template (established the current heading structure for leads)
- [20260209181813-move-define-lead-to-claude-rules.md](.workaholic/tickets/archive/drive-20260208-131649/20260209181813-move-define-lead-to-claude-rules.md) - Moved define-lead to `.claude/rules/` for path-scoped enforcement

## Implementation Steps

1. **Update `.claude/rules/define-manager.md` Schema Template**

   In the Schema Template fenced code block, change the heading structure from:
   ```
   ## Role
   ## Responsibility
   ## Goal
   ```
   to:
   ```
   ## Role
   ### Goal
   ### Responsibility
   ```

   Update the content descriptions accordingly. The `## Role` section description now encompasses the identity plus both Goal and Responsibility as subsections. `### Goal` describes what the subject owes to achieve (positive obligation). `### Responsibility` describes what the subject owes to avoid (negative obligation).

2. **Update `.claude/rules/define-manager.md` Guidelines section**

   Update the "Responsibility vs Goal" guideline subsection to reflect the new hierarchy. Explain that Role is the overarching concept containing Goal (positive obligation) and Responsibility (negative obligation). The logical relationship remains the same (necessary vs sufficient conditions), but the structural relationship is now explicit: both live under Role.

3. **Update `.claude/rules/define-manager.md` Validation Checklist**

   Change the checklist items from:
   - `## Role` section is present and defines the agent's function
   - `## Responsibility` section defines minimum duties (necessary condition)
   - `## Goal` section defines measurable completion (sufficient condition)

   To:
   - `## Role` section is present and defines the agent's function
   - `### Goal` subsection under Role defines measurable completion (sufficient condition)
   - `### Responsibility` subsection under Role defines minimum duties (necessary condition)

4. **Update `.claude/rules/define-manager.md` Agent Template**

   Update the instruction text in the agent template code block. Change "Execute the task within the manager's Role and Responsibility" to reflect the new structure (Role now contains Responsibility as a subsection, so "within the manager's Role" is sufficient, or keep "Role and Responsibility" as natural language since it still makes sense conceptually).

5. **Update `.claude/rules/define-lead.md` Schema Template**

   Apply the same heading restructuring as step 1: `## Role` remains Level 2, `## Responsibility` and `## Goal` become `### Responsibility` and `### Goal` under Role.

6. **Update `.claude/rules/define-lead.md` Guidelines section**

   Apply the same guideline updates as step 2.

7. **Update `.claude/rules/define-lead.md` Validation Checklist**

   Apply the same checklist updates as step 3.

8. **Update `.claude/rules/define-lead.md` Agent Template**

   Apply the same agent template updates as step 4.

9. **Update `.claude/rules/define-lead.md` Example section**

   The example `testing-lead` definition at the bottom of define-lead.md has `## Role`, `## Responsibility`, and `## Goal` as Level 2 headings. Change `## Responsibility` to `### Responsibility` and `## Goal` to `### Goal`.

10. **Update all 3 manager skill files**

    In each of the following files, change `## Responsibility` to `### Responsibility` and `## Goal` to `### Goal`, keeping `## Role` as-is:
    - `plugins/core/skills/manage-project/SKILL.md`
    - `plugins/core/skills/manage-architecture/SKILL.md`
    - `plugins/core/skills/manage-quality/SKILL.md`

11. **Update all 10 lead skill files**

    In each of the following files, change `## Responsibility` to `### Responsibility` and `## Goal` to `### Goal`, keeping `## Role` as-is:
    - `plugins/core/skills/lead-a11y/SKILL.md`
    - `plugins/core/skills/lead-db/SKILL.md`
    - `plugins/core/skills/lead-delivery/SKILL.md`
    - `plugins/core/skills/lead-infra/SKILL.md`
    - `plugins/core/skills/lead-observability/SKILL.md`
    - `plugins/core/skills/lead-quality/SKILL.md`
    - `plugins/core/skills/lead-recovery/SKILL.md`
    - `plugins/core/skills/lead-security/SKILL.md`
    - `plugins/core/skills/lead-test/SKILL.md`
    - `plugins/core/skills/lead-ux/SKILL.md`

12. **Verify agent files require no structural changes**

    The 13 agent files (3 manager + 10 lead) reference "role, responsibility, and default policies" in lowercase prose and "Role and Responsibility" in instruction steps. These are natural-language references, not markdown heading references. Review each to confirm no changes are needed, or adjust phrasing if it becomes misleading under the new structure. The phrase "Role and Responsibility" still works because Role now contains Responsibility.

## Patches

### `.claude/rules/define-manager.md`

```diff
--- a/.claude/rules/define-manager.md
+++ b/.claude/rules/define-manager.md
@@ -21,15 +21,17 @@

 ## Role

-<What the agent *is* and its function within the system.>
+<What the agent *is* and its function within the system.
+Role is the overarching concept that contains both Goal and Responsibility.>

-## Responsibility
+### Goal

-<The necessary condition. The minimum set of duties the agent must fulfill.
-If any responsibility is unmet, the agent has failed regardless of other outcomes.>
+<The sufficient condition. The measurable objective that, when achieved,
+means the agent has fully succeeded. Meeting the goal implies all
+responsibilities have been satisfied.>

-## Goal
+### Responsibility

-<The sufficient condition. The measurable objective that, when achieved,
-means the agent has fully succeeded. Meeting the goal implies all
-responsibilities have been satisfied.>
+<The necessary condition. The minimum set of duties the agent must fulfill.
+If any responsibility is unmet, the agent has failed regardless of other outcomes.>
```

> **Note**: This patch is speculative -- verify the exact line numbers and context before applying.

### `.claude/rules/define-manager.md` (Validation Checklist)

```diff
--- a/.claude/rules/define-manager.md
+++ b/.claude/rules/define-manager.md
@@ -111,9 +111,9 @@
 - [ ] Frontmatter contains `name`, `description`, and `user-invocable: false`
 - [ ] Name follows `manage-<domain>` format
-- [ ] `## Role` section is present and defines the agent's function
-- [ ] `## Responsibility` section defines minimum duties (necessary condition)
-- [ ] `## Goal` section defines measurable completion (sufficient condition)
+- [ ] `## Role` section is present and defines the agent's function, containing Goal and Responsibility subsections
+- [ ] `### Goal` subsection under Role defines measurable completion (sufficient condition, positive obligation)
+- [ ] `### Responsibility` subsection under Role defines minimum duties (necessary condition, negative obligation)
 - [ ] `## Outputs` section defines structured artifacts with consuming leaders
```

> **Note**: This patch is speculative -- verify the exact line numbers and context before applying.

### `.claude/rules/define-lead.md` (Schema Template)

```diff
--- a/.claude/rules/define-lead.md
+++ b/.claude/rules/define-lead.md
@@ -20,15 +20,17 @@

 ## Role

-<What the agent *is* and its function within the system.>
+<What the agent *is* and its function within the system.
+Role is the overarching concept that contains both Goal and Responsibility.>

-## Responsibility
+### Goal

-<The necessary condition. The minimum set of duties the agent must fulfill.
-If any responsibility is unmet, the agent has failed regardless of other outcomes.>
+<The sufficient condition. The measurable objective that, when achieved,
+means the agent has fully succeeded. Meeting the goal implies all
+responsibilities have been satisfied.>

-## Goal
+### Responsibility

-<The sufficient condition. The measurable objective that, when achieved,
-means the agent has fully succeeded. Meeting the goal implies all
-responsibilities have been satisfied.>
+<The necessary condition. The minimum set of duties the agent must fulfill.
+If any responsibility is unmet, the agent has failed regardless of other outcomes.>
```

> **Note**: This patch is speculative -- verify the exact line numbers and context before applying.

### `.claude/rules/define-lead.md` (Validation Checklist)

```diff
--- a/.claude/rules/define-lead.md
+++ b/.claude/rules/define-lead.md
@@ -96,9 +96,9 @@
 - [ ] Frontmatter contains `name` and `description`
 - [ ] Name follows `<speciality>-lead` format
-- [ ] `## Role` section is present and defines the agent's function
-- [ ] `## Responsibility` section defines minimum duties (necessary condition)
-- [ ] `## Goal` section defines measurable completion (sufficient condition)
+- [ ] `## Role` section is present and defines the agent's function, containing Goal and Responsibility subsections
+- [ ] `### Goal` subsection under Role defines measurable completion (sufficient condition, positive obligation)
+- [ ] `### Responsibility` subsection under Role defines minimum duties (necessary condition, negative obligation)
 - [ ] `## Default Policies` section is present with all four subsections
```

> **Note**: This patch is speculative -- verify the exact line numbers and context before applying.

### `.claude/rules/define-lead.md` (Example)

```diff
--- a/.claude/rules/define-lead.md
+++ b/.claude/rules/define-lead.md
@@ -152,17 +152,17 @@

 ## Role

 The testing lead owns the project's test strategy. It decides what gets tested, how tests are structured, and what coverage thresholds apply. It is the authority on test quality and reliability.

-## Responsibility
+### Goal
+
+The test suite passes reliably on every commit to main, covers all critical paths, and completes within the time budget. A green CI run means the project is shippable.
+
+### Responsibility

 - Every merged change has test coverage proportional to its risk.
 - Flaky tests are identified and either fixed or quarantined within one cycle.
 - Test infrastructure (runners, fixtures, helpers) remains functional and documented.
-
-## Goal
-
-The test suite passes reliably on every commit to main, covers all critical paths, and completes within the time budget. A green CI run means the project is shippable.

 ## Default Policies
```

> **Note**: This patch is speculative -- verify the exact line numbers and context before applying.

### `plugins/core/skills/manage-project/SKILL.md` (representative of all skill files)

```diff
--- a/plugins/core/skills/manage-project/SKILL.md
+++ b/plugins/core/skills/manage-project/SKILL.md
@@ -9,13 +9,13 @@
 ## Role

 The project manager owns the business context surrounding the project. It identifies stakeholders and their concerns, tracks timeline and milestones, surfaces issues, and proposes solutions. It provides the strategic context that leaders need to make domain-specific decisions.

-## Responsibility
+### Goal
+
+Leaders have the strategic context they need to make domain-specific decisions without duplicating business analysis. Every leader can reference the project context output to understand stakeholder expectations, timeline pressure, and active issues relevant to their domain.
+
+### Responsibility

 - Maintain an accurate map of business context derived from observable project artifacts (README, CLAUDE.md, package metadata, issue trackers, PR history).
 - Identify all stakeholders and document their concerns and priorities.
@@ -21,8 +21,6 @@
 - Surface active issues (open bugs, blocked work, dependency risks) with supporting evidence.
 - Propose solutions grounded in project constraints, not aspirational recommendations.
-
-## Goal
-
-Leaders have the strategic context they need to make domain-specific decisions without duplicating business analysis. Every leader can reference the project context output to understand stakeholder expectations, timeline pressure, and active issues relevant to their domain.

 ## Outputs
```

> **Note**: This patch is speculative -- verify the exact line numbers and context before applying. Apply the same pattern (## Goal -> ### Goal, ## Responsibility -> ### Responsibility, reorder Goal before Responsibility) to all 13 skill files.

## Considerations

- The heading order under `## Role` should be `### Goal` first, then `### Responsibility`. This matches the conceptual model: Goal is the positive obligation (what to achieve) and comes first as the forward-looking target; Responsibility is the negative obligation (what to avoid) and serves as the guardrails. (`.claude/rules/define-manager.md`, `.claude/rules/define-lead.md`)
- The "Responsibility vs Goal" guideline subsection in both schema files should be renamed or reframed as "Role: Goal and Responsibility" to reflect that these are now subsections of Role rather than peer sections. The content about necessary/sufficient conditions remains valid. (`.claude/rules/define-manager.md` lines 78-85, `.claude/rules/define-lead.md` lines 71-78)
- Agent files use the phrase "role, responsibility, and default policies" in their one-line descriptions and "Role and Responsibility" in step 3 of instructions. These are natural language, not heading references. Since Role now structurally contains Responsibility, the phrase "Role and Responsibility" is slightly redundant but not incorrect. Consider simplifying to "Role" in step 3, but this is a stylistic choice. (`plugins/core/agents/*.md`)
- This change touches 2 schema files + 13 skill files = 15 files minimum. The changes are mechanical (heading level changes) so the risk of semantic errors is low, but verify each file compiles against the updated validation checklist after changes. (All files listed in Key Files)
- The `managers-principle` and `leaders-principle` skills do not reference these heading levels and need no changes. (`plugins/core/skills/managers-principle/SKILL.md`, `plugins/core/skills/leaders-principle/SKILL.md`)
