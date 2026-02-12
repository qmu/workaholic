---
created_at: 2026-02-12T16:57:28+08:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: 5fc8981
category:
---

# Let Managers Generate Structured Constraint Files

## Overview

Managers currently produce "directional materials" to loosely-specified paths under `.workaholic/` (e.g., `.workaholic/policies/` or just `.workaholic/`). The constraint-setting workflow in `managers-policy` defines four artifact types (Policy, Guideline, Roadmap, Decision Record) but provides no structured output path convention for constraints themselves. This ticket introduces a dedicated `.workaholic/constraints/` directory with three files -- `project.md`, `architecture.md`, and `quality.md` -- one per manager domain. Each manager generates its constraint file during the "Produce" phase of the constraint-setting workflow.

This gives constraints a stable, predictable location that leaders can reference programmatically, separating constraints (boundaries that narrow decision space) from policies (domain-specific documentation produced by leaders). The distinction matters: `.workaholic/policies/` contains leader-generated observational documentation of current practices, while `.workaholic/constraints/` contains manager-generated prescriptive boundaries that leaders must operate within.

## Key Files

- `plugins/core/skills/managers-policy/SKILL.md` - Constraint Setting workflow; needs to specify `.workaholic/constraints/` as the output path convention and define the file structure template
- `plugins/core/skills/manage-project/SKILL.md` - Project manager Execution section; currently says "Produce directional materials ... to `.workaholic/`", needs to specify `.workaholic/constraints/project.md`
- `plugins/core/skills/manage-architecture/SKILL.md` - Architecture manager Execution section; currently says "Produce directional materials ... to `.workaholic/`", needs to specify `.workaholic/constraints/architecture.md`
- `plugins/core/skills/manage-quality/SKILL.md` - Quality manager Execution section; currently says "Produce directional materials ... to `.workaholic/`", needs to specify `.workaholic/constraints/quality.md`
- `.workaholic/README.md` - Working artifacts index; needs to list the new `constraints/` directory
- `.workaholic/README_ja.md` - Japanese translation of the index; same update needed
- `plugins/core/commands/scan.md` - Scan command; may need to stage `.workaholic/constraints/` in the commit step and validate constraint output
- `plugins/core/skills/select-scan-agents/SKILL.md` - Agent selection skill; may reference output directories that need updating

## Related History

The constraint-setting workflow was recently added to all three managers, but it left the output location vague. The managers-policy defines what constraints are and how to create them, but not where to store them. The existing `.workaholic/policies/` directory is owned by leader agents (test, security, quality, etc.), creating a semantic collision when managers also write there.

Past tickets that touched similar areas:

- [20260211183439-add-constraint-setting-workflow-to-managers.md](.workaholic/tickets/archive/drive-20260210-121635/20260211183439-add-constraint-setting-workflow-to-managers.md) - Added the Constraint Setting section to managers-policy and extended all three manager Execution sections (direct foundation for this ticket)
- [20260211170401-define-manager-tier-and-skills.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170401-define-manager-tier-and-skills.md) - Created the manager tier with three manager skills and managers-policy (established the manager layer this ticket builds on)
- [20260211170402-wire-leaders-to-manager-outputs.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170402-wire-leaders-to-manager-outputs.md) - Wired leaders to consume manager outputs (established the manager-to-leader data flow pattern)

## Implementation Steps

1. **Define the constraint file template in `plugins/core/skills/managers-policy/SKILL.md`**

   Add an "Output Convention" subsection under `## Constraint Setting` that specifies:
   - Constraint files are written to `.workaholic/constraints/<domain>.md` where `<domain>` matches the manager's domain (project, architecture, quality).
   - Each constraint file uses a standard structure with frontmatter and sections for each constraint.
   - The template includes: frontmatter (manager name, last_updated timestamp), a summary section, and individual constraint entries. Each constraint entry states what it bounds, why it matters, which leaders it affects, the falsifiability criterion, and any review trigger.

   The template uses the manager's scope as the heading (not "Constraints" — the directory already conveys that). Each section heading names the bounded area directly (e.g., "Release Cadence", "Layer Boundaries"), not "Constraint Name":

   ```markdown
   ---
   manager: <scope>-manager
   last_updated: <ISO 8601 timestamp>
   ---

   # <Scope>

   <1-2 sentence summary of the manager's strategic territory.>

   ## <Bounded Area>

   **Bounds**: <What this limits>
   **Rationale**: <Why this exists>
   **Affects**: <Leader agents this narrows>
   **Criterion**: <How to verify compliance -- must be falsifiable>
   **Review trigger**: <When to revisit>
   ```

2. **Update the Constraint Setting rules in `plugins/core/skills/managers-policy/SKILL.md`**

   In the `### Rules` subsection, change the vague "Write directional materials to paths under `.workaholic/`" to the specific convention: "Write constraints to `.workaholic/constraints/<domain>.md` following the constraint file template. Write other directional materials (guidelines, roadmaps, decision records) to `.workaholic/` under appropriate subdirectories."

3. **Update `plugins/core/skills/manage-project/SKILL.md` Execution section**

   Change the current:
   ```
   - Produce directional materials (roadmap, stakeholder priority matrix, scope boundary document) to `.workaholic/`.
   ```
   To:
   ```
   - Produce constraints to `.workaholic/constraints/project.md` following the constraint file template from managers-policy.
   - Produce other directional materials (roadmap, stakeholder priority matrix) to `.workaholic/` as appropriate.
   ```

4. **Update `plugins/core/skills/manage-architecture/SKILL.md` Execution section**

   Change the current:
   ```
   - Produce directional materials (architecture decision records, structural guidelines, layer boundary policies) to `.workaholic/`.
   ```
   To:
   ```
   - Produce constraints to `.workaholic/constraints/architecture.md` following the constraint file template from managers-policy.
   - Produce other directional materials (decision records, structural guidelines) to `.workaholic/` as appropriate.
   ```

5. **Update `plugins/core/skills/manage-quality/SKILL.md` Execution section**

   Change the current:
   ```
   - Produce directional materials (quality standards document, assurance process definitions, improvement roadmap) to `.workaholic/`.
   ```
   To:
   ```
   - Produce constraints to `.workaholic/constraints/quality.md` following the constraint file template from managers-policy.
   - Produce other directional materials (assurance process definitions, improvement roadmap) to `.workaholic/` as appropriate.
   ```

6. **Update `.workaholic/README.md` and `.workaholic/README_ja.md`**

   Add `constraints/` to the directory listing between existing entries. No README files inside `.workaholic/constraints/` are needed since the directory contains only three well-named files.

7. **Update `plugins/core/commands/scan.md` commit step**

   Add `.workaholic/constraints/` to the `git add` command so constraint files are included in the scan commit:
   ```bash
   git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ .workaholic/constraints/ && git commit -m "Update documentation"
   ```

## Patches

### `plugins/core/skills/managers-policy/SKILL.md`

```diff
--- a/plugins/core/skills/managers-policy/SKILL.md
+++ b/plugins/core/skills/managers-policy/SKILL.md
@@ -37,9 +37,36 @@

 ### Rules

 - Ground every constraint in codebase evidence or user input. Never invent constraints.
 - Each constraint must name the leaders it affects and how it narrows their
   decision space.
-- Write directional materials to paths under `.workaholic/` where leaders can
-  find them.
+- Write constraints to `.workaholic/constraints/<domain>.md` following the
+  constraint file template. Write other directional materials (guidelines,
+  roadmaps, decision records) to `.workaholic/` under appropriate subdirectories.
 - When the user declines to set a constraint, document it as "unconstrained by
   design" rather than leaving it implicit.
 - Constraints are not permanent. Document review triggers (e.g., "revisit after v2
   release") so constraints do not become stale.
+
+### Constraint File Template
+
+Each manager writes its constraints to `.workaholic/constraints/<domain>.md`
+where `<domain>` matches the manager's domain (project, architecture, quality).
+
+```markdown
+---
+manager: <domain>-manager
+last_updated: <ISO 8601 timestamp>
+---
+
+# <Domain> Constraints
+
+<1-2 sentence summary of the constraint landscape.>
+
+## <Constraint Name>
+
+**Bounds**: <What this constraint limits>
+**Rationale**: <Why this constraint exists>
+**Affects**: <Leader agents this narrows>
+**Criterion**: <How to verify compliance -- must be falsifiable>
+**Review trigger**: <When to revisit this constraint>
+
+---
+```
```

### `plugins/core/skills/manage-project/SKILL.md`

```diff
--- a/plugins/core/skills/manage-project/SKILL.md
+++ b/plugins/core/skills/manage-project/SKILL.md
@@ -66,4 +66,5 @@
   - Identify missing or implicit project constraints (release cadence, stakeholder priorities, scope boundaries, timeline commitments).
   - Ask the user targeted questions about business priorities, stakeholder rankings, and scope decisions.
   - Propose project constraints grounded in gathered evidence and user answers.
-  - Produce directional materials (roadmap, stakeholder priority matrix, scope boundary document) to `.workaholic/`.
+  - Produce constraints to `.workaholic/constraints/project.md` following the constraint file template from managers-policy.
+  - Produce other directional materials (roadmap, stakeholder priority matrix) to `.workaholic/` as appropriate.
```

### `plugins/core/skills/manage-architecture/SKILL.md`

```diff
--- a/plugins/core/skills/manage-architecture/SKILL.md
+++ b/plugins/core/skills/manage-architecture/SKILL.md
@@ -81,4 +81,5 @@
   - Identify missing or implicit architectural constraints (layer boundary rules, component naming conventions, dependency direction policies, technology choices).
   - Ask the user targeted questions about architectural preferences, structural boundaries, and technology decisions.
   - Propose architectural constraints grounded in gathered evidence and user answers.
-  - Produce directional materials (architecture decision records, structural guidelines, layer boundary policies) to `.workaholic/`.
+  - Produce constraints to `.workaholic/constraints/architecture.md` following the constraint file template from managers-policy.
+  - Produce other directional materials (decision records, structural guidelines) to `.workaholic/` as appropriate.
```

### `plugins/core/skills/manage-quality/SKILL.md`

```diff
--- a/plugins/core/skills/manage-quality/SKILL.md
+++ b/plugins/core/skills/manage-quality/SKILL.md
@@ -67,4 +67,5 @@
   - Identify missing or implicit quality constraints (test coverage thresholds, documentation completeness standards, performance budgets, lint strictness levels).
   - Ask the user targeted questions about quality priorities, acceptable trade-offs, and enforcement preferences.
   - Propose quality constraints grounded in gathered evidence and user answers.
-  - Produce directional materials (quality standards document, assurance process definitions, improvement roadmap) to `.workaholic/`.
+  - Produce constraints to `.workaholic/constraints/quality.md` following the constraint file template from managers-policy.
+  - Produce other directional materials (assurance process definitions, improvement roadmap) to `.workaholic/` as appropriate.
```

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -89,7 +89,7 @@

 ### Phase 6: Stage and Commit

 ```bash
-git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ && git commit -m "Update documentation"
+git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ .workaholic/constraints/ && git commit -m "Update documentation"
 ```
```

## Considerations

- The `.workaholic/policies/` directory is produced by leader agents (test-lead, security-lead, etc.) and documents current practices observationally. The new `.workaholic/constraints/` directory is produced by manager agents and contains prescriptive boundaries. This semantic distinction should be clear to contributors. If the distinction is unclear in practice, consider adding a one-line comment at the top of each constraint file noting it is manager-generated. (`plugins/core/skills/managers-policy/SKILL.md`)
- The constraint-setting workflow includes an interactive "Ask" phase. During `/scan`, managers run as subagents that can prompt the user for input. However, if the user wants non-interactive constraint generation (e.g., auto-generating from existing codebase evidence without asking), the workflow may need a `--non-interactive` mode that skips the Ask phase and produces constraints from analysis alone. This is out of scope for this ticket but worth noting. (`plugins/core/commands/scan.md`)
- Leaders currently read manager outputs from `.workaholic/policies/` (e.g., `lead-test` reads "manage-quality output from `.workaholic/policies/`"). After this change, leaders that want to check constraints should read from `.workaholic/constraints/` instead. Updating leader Execution sections to read constraints is a follow-up concern, not addressed here. (`plugins/core/skills/lead-test/SKILL.md`, `plugins/core/skills/lead-quality/SKILL.md`, `plugins/core/skills/lead-a11y/SKILL.md`)
- The constraint file template uses a `---` horizontal rule between constraint entries. This is a convention choice for readability. If the project later needs machine-parseable constraint files (e.g., for automated compliance checking), the format may need to evolve to structured YAML or JSON. The current markdown format prioritizes human readability. (`plugins/core/skills/managers-policy/SKILL.md`)
- The `select-scan-agents` skill references output directories at `plugins/core/skills/select-scan-agents/SKILL.md` line 45. If it has an exclusion list for output directories, `.workaholic/constraints/` should be added. Verify during implementation. (`plugins/core/skills/select-scan-agents/SKILL.md`)
- Translation of constraint files (e.g., `project_ja.md`) follows the same pattern as specs and policies -- produce English first, then translate per the user's CLAUDE.md translation policy. This is already handled by the managers-policy and does not need special treatment, but the constraint file template should be English-only in the skill definition. (`.workaholic/constraints/`)

## Final Report

Introduced `.workaholic/constraints/` directory with structured constraint file template. Updated managers-policy with output convention and template (using scope-based headings, not "Constraints" labels). Updated all three manager Execution sections to produce to specific constraint file paths. Added `constraints/` to README indexes and scan commit step.

1. `plugins/core/skills/managers-policy/SKILL.md` — Added constraint file template and updated Rules to specify `.workaholic/constraints/<scope>.md` output path
2. `plugins/core/skills/manage-project/SKILL.md` — Execution produces to `.workaholic/constraints/project.md`
3. `plugins/core/skills/manage-architecture/SKILL.md` — Execution produces to `.workaholic/constraints/architecture.md`
4. `plugins/core/skills/manage-quality/SKILL.md` — Execution produces to `.workaholic/constraints/quality.md`
5. `.workaholic/README.md` / `README_ja.md` — Listed `constraints/` directory
6. `plugins/core/commands/scan.md` — Added `.workaholic/constraints/` to git add in Phase 6
