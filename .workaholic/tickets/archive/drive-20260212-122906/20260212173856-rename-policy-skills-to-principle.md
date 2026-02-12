---
created_at: 2026-02-12T17:38:56+08:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.25h
commit_hash: b056b1b
category: Changed
---

# Rename managers-policy and leaders-policy Skills to managers-principle and leaders-principle

## Overview

Rename the cross-cutting behavioral policy skills `managers-policy` to `managers-principle` and `leaders-policy` to `leaders-principle`. The term "policy" is already assigned to the output artifacts that leaders produce (`.workaholic/policies/` documents via the `analyze-policy` skill). Using "policy" for both the cross-cutting behavioral rules and the generated output documents creates semantic ambiguity. "Principle" more accurately describes the nature of these skills -- they encode fundamental behavioral principles (Prior Term Consistency, Vendor Neutrality, Strategic Focus) rather than enforceable policies derived from codebase evidence.

## Key Files

- `plugins/core/skills/managers-policy/SKILL.md` - Skill directory and file to rename to `managers-principle`
- `plugins/core/skills/leaders-policy/SKILL.md` - Skill directory and file to rename to `leaders-principle`
- `plugins/core/agents/project-manager.md` - References `managers-policy` in skills frontmatter
- `plugins/core/agents/architecture-manager.md` - References `managers-policy` in skills frontmatter
- `plugins/core/agents/quality-manager.md` - References `managers-policy` in skills frontmatter
- `plugins/core/agents/quality-lead.md` - References `leaders-policy` in skills frontmatter
- `plugins/core/agents/security-lead.md` - References `leaders-policy` in skills frontmatter
- `plugins/core/agents/test-lead.md` - References `leaders-policy` in skills frontmatter
- `plugins/core/agents/ux-lead.md` - References `leaders-policy` in skills frontmatter
- `plugins/core/agents/db-lead.md` - References `leaders-policy` in skills frontmatter
- `plugins/core/agents/infra-lead.md` - References `leaders-policy` in skills frontmatter
- `plugins/core/agents/delivery-lead.md` - References `leaders-policy` in skills frontmatter
- `plugins/core/agents/a11y-lead.md` - References `leaders-policy` in skills frontmatter
- `plugins/core/agents/observability-lead.md` - References `leaders-policy` in skills frontmatter
- `plugins/core/agents/recovery-lead.md` - References `leaders-policy` in skills frontmatter
- `.claude/rules/define-manager.md` - Agent template references `managers-policy` as required first skill
- `.claude/rules/define-lead.md` - Agent template references `leaders-policy` as required first skill
- `plugins/core/skills/manage-project/SKILL.md` - References `managers-policy` in text
- `plugins/core/skills/manage-architecture/SKILL.md` - References `managers-policy` in text
- `plugins/core/skills/manage-quality/SKILL.md` - References `managers-policy` in text
- `.workaholic/terms/core-concepts.md` - Term definitions for `managers-policy` and `leaders-policy`
- `.workaholic/terms/core-concepts_ja.md` - Japanese term definitions
- `.workaholic/terms/README.md` - Term index listing
- `.workaholic/terms/README_ja.md` - Japanese term index listing

## Related History

The project has a consistent pattern of renaming skills and terms when naming conventions evolve or semantic collisions arise. The recent `manage-branch` to `branching` rename followed the same pattern: a naming collision with the manager tier forced a rename to resolve ambiguity.

Past tickets that touched similar areas:

- [20260212164717-rename-manage-branch-skill.md](.workaholic/tickets/archive/drive-20260212-122906/20260212164717-rename-manage-branch-skill.md) - Renamed manage-branch to branching to resolve naming collision with manager tier (same pattern: semantic collision requiring rename)
- [20260210124953-add-leaders-policy-skill.md](.workaholic/tickets/archive/drive-20260210-121635/20260210124953-add-leaders-policy-skill.md) - Created leaders-policy skill (origin of the current name)
- [20260211170401-define-manager-tier-and-skills.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170401-define-manager-tier-and-skills.md) - Created managers-policy skill and manager tier (origin of the current name)

## Implementation Steps

1. **Rename `plugins/core/skills/managers-policy/` to `plugins/core/skills/managers-principle/`**:
   - Move the directory
   - Update `SKILL.md` frontmatter `name:` from `managers-policy` to `managers-principle`
   - Update the heading from `# Managers Policy` to `# Managers Principle`
   - Update body text: change "Policies in this document" to "Principles in this document" and "these policies" to "these principles"

2. **Rename `plugins/core/skills/leaders-policy/` to `plugins/core/skills/leaders-principle/`**:
   - Move the directory
   - Update `SKILL.md` frontmatter `name:` from `leaders-policy` to `leaders-principle`
   - Update the heading from `# Leaders Policy` to `# Leaders Principle`
   - Update body text: change "Policies in this document" to "Principles in this document" and "these policies" to "these principles"

3. **Update all 3 manager agent files** (`project-manager.md`, `architecture-manager.md`, `quality-manager.md`):
   - Change `managers-policy` to `managers-principle` in skills frontmatter
   - Update instruction text references from `managers-policy` to `managers-principle`

4. **Update all 10 lead agent files** (`quality-lead.md`, `security-lead.md`, `test-lead.md`, `ux-lead.md`, `db-lead.md`, `infra-lead.md`, `delivery-lead.md`, `a11y-lead.md`, `observability-lead.md`, `recovery-lead.md`):
   - Change `leaders-policy` to `leaders-principle` in skills frontmatter

5. **Update `.claude/rules/define-manager.md`**:
   - Change `managers-policy` to `managers-principle` in the Agent Template's skills example

6. **Update `.claude/rules/define-lead.md`**:
   - Change `leaders-policy` to `leaders-principle` in the Agent Template's skills example

7. **Update all 3 manage-* skill files** (`manage-project/SKILL.md`, `manage-architecture/SKILL.md`, `manage-quality/SKILL.md`):
   - Change `managers-policy` references to `managers-principle` in Execution policy sections

8. **Update `.workaholic/terms/core-concepts.md` and `core-concepts_ja.md`**:
   - Rename `## managers-policy` heading to `## managers-principle`
   - Rename `## leaders-policy` heading to `## leaders-principle`
   - Update definition text to reflect the new names
   - Update cross-references within other term definitions that mention these names

9. **Update `.workaholic/terms/README.md` and `README_ja.md`**:
   - Change `managers-policy` to `managers-principle` and `leaders-policy` to `leaders-principle` in the term index listings

## Patches

### `plugins/core/skills/managers-policy/SKILL.md`

> **Note**: This patch shows content changes. The file must also be moved to `plugins/core/skills/managers-principle/SKILL.md`.

```diff
--- a/plugins/core/skills/managers-policy/SKILL.md
+++ b/plugins/core/skills/managers-principle/SKILL.md
@@ -1,12 +1,12 @@
 ---
-name: managers-policy
-description: Cross-cutting policies that apply to all manager sub-agents.
+name: managers-principle
+description: Cross-cutting principles that apply to all manager sub-agents.
 user-invocable: false
 ---

-# Managers Policy
+# Managers Principle

-Policies in this document apply to every manager sub-agent. Each manager MUST observe these
-policies in addition to its own domain-specific Default Policies.
+Principles in this document apply to every manager sub-agent. Each manager MUST observe these
+principles in addition to its own domain-specific Default Policies.
```

### `plugins/core/skills/leaders-policy/SKILL.md`

> **Note**: This patch shows content changes. The file must also be moved to `plugins/core/skills/leaders-principle/SKILL.md`.

```diff
--- a/plugins/core/skills/leaders-policy/SKILL.md
+++ b/plugins/core/skills/leaders-principle/SKILL.md
@@ -1,12 +1,12 @@
 ---
-name: leaders-policy
-description: Cross-cutting policies that apply to all lead sub-agents.
+name: leaders-principle
+description: Cross-cutting principles that apply to all lead sub-agents.
 user-invocable: false
 ---

-# Leaders Policy
+# Leaders Principle

-Policies in this document apply to every lead sub-agent. Each lead MUST observe these
-policies in addition to its own domain-specific Default Policies.
+Principles in this document apply to every lead sub-agent. Each lead MUST observe these
+principles in addition to its own domain-specific Default Policies.
```

### `plugins/core/agents/project-manager.md`

```diff
--- a/plugins/core/agents/project-manager.md
+++ b/plugins/core/agents/project-manager.md
@@ -4,7 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - managers-policy
+  - managers-principle
   - manage-project
   - write-spec
   - translate
@@ -22,7 +22,7 @@
    - Reviewing artifacts -> Review policy
    - Writing or updating documentation -> Documentation policy
    - Running commands or actions -> Execution policy
-   - Setting constraints or defining direction -> Constraint Setting workflow (managers-policy) + Execution policy
+   - Setting constraints or defining direction -> Constraint Setting workflow (managers-principle) + Execution policy
```

### `plugins/core/agents/architecture-manager.md`

```diff
--- a/plugins/core/agents/architecture-manager.md
+++ b/plugins/core/agents/architecture-manager.md
@@ -4,7 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - managers-policy
+  - managers-principle
   - manage-architecture
   - analyze-viewpoint
   - write-spec
@@ -23,7 +23,7 @@
    - Reviewing artifacts -> Review policy
    - Writing or updating documentation -> Documentation policy
    - Running commands or actions -> Execution policy
-   - Setting constraints or defining direction -> Constraint Setting workflow (managers-policy) + Execution policy
+   - Setting constraints or defining direction -> Constraint Setting workflow (managers-principle) + Execution policy
```

### `plugins/core/agents/quality-manager.md`

```diff
--- a/plugins/core/agents/quality-manager.md
+++ b/plugins/core/agents/quality-manager.md
@@ -4,7 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - managers-policy
+  - managers-principle
   - manage-quality
   - write-spec
   - translate
@@ -22,7 +22,7 @@
    - Reviewing artifacts -> Review policy
    - Writing or updating documentation -> Documentation policy
    - Running commands or actions -> Execution policy
-   - Setting constraints or defining direction -> Constraint Setting workflow (managers-policy) + Execution policy
+   - Setting constraints or defining direction -> Constraint Setting workflow (managers-principle) + Execution policy
```

### `plugins/core/agents/quality-lead.md`

```diff
--- a/plugins/core/agents/quality-lead.md
+++ b/plugins/core/agents/quality-lead.md
@@ -5,7 +5,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - leaders-policy
+  - leaders-principle
   - lead-quality
```

### `.claude/rules/define-manager.md`

```diff
--- a/.claude/rules/define-manager.md
+++ b/.claude/rules/define-manager.md
@@ -135,7 +135,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - managers-policy
+  - managers-principle
   - manage-<domain>
```

### `.claude/rules/define-lead.md`

```diff
--- a/.claude/rules/define-lead.md
+++ b/.claude/rules/define-lead.md
@@ -118,7 +118,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - leaders-policy
+  - leaders-principle
   - lead-<speciality>
```

### `plugins/core/skills/manage-project/SKILL.md`

```diff
--- a/plugins/core/skills/manage-project/SKILL.md
+++ b/plugins/core/skills/manage-project/SKILL.md
@@ -65,7 +65,7 @@
-- Follow the Constraint Setting workflow from managers-policy:
+- Follow the Constraint Setting workflow from managers-principle:
   - Identify missing or implicit project constraints (release cadence, stakeholder priorities, scope boundaries, timeline commitments).
   - Ask the user targeted questions about business priorities, stakeholder rankings, and scope decisions.
   - Propose project constraints grounded in gathered evidence and user answers.
-  - Produce constraints to `.workaholic/constraints/project.md` following the constraint file template from managers-policy.
+  - Produce constraints to `.workaholic/constraints/project.md` following the constraint file template from managers-principle.
```

### `plugins/core/skills/manage-architecture/SKILL.md`

```diff
--- a/plugins/core/skills/manage-architecture/SKILL.md
+++ b/plugins/core/skills/manage-architecture/SKILL.md
@@ -80,9 +80,9 @@
-- Follow the Constraint Setting workflow from managers-policy:
+- Follow the Constraint Setting workflow from managers-principle:
   - Identify missing or implicit architectural constraints (layer boundary rules, component naming conventions, dependency direction policies, technology choices).
   - Ask the user targeted questions about architectural preferences, structural boundaries, and technology decisions.
   - Propose architectural constraints grounded in gathered evidence and user answers.
-  - Produce constraints to `.workaholic/constraints/architecture.md` following the constraint file template from managers-policy.
+  - Produce constraints to `.workaholic/constraints/architecture.md` following the constraint file template from managers-principle.
```

### `plugins/core/skills/manage-quality/SKILL.md`

```diff
--- a/plugins/core/skills/manage-quality/SKILL.md
+++ b/plugins/core/skills/manage-quality/SKILL.md
@@ -66,7 +66,7 @@
-- Follow the Constraint Setting workflow from managers-policy:
+- Follow the Constraint Setting workflow from managers-principle:
   - Identify missing or implicit quality constraints (test coverage thresholds, documentation completeness standards, performance budgets, lint strictness levels).
   - Ask the user targeted questions about quality priorities, acceptable trade-offs, and enforcement preferences.
   - Propose quality constraints grounded in gathered evidence and user answers.
-  - Produce constraints to `.workaholic/constraints/quality.md` following the constraint file template from managers-policy.
+  - Produce constraints to `.workaholic/constraints/quality.md` following the constraint file template from managers-principle.
```

## Considerations

- The word "policy" inside the skill content (e.g., "Default Policies" subsection headings in manager and lead schemas) should NOT be renamed. "Default Policies" refers to the agent's own behavioral rules, which is a different usage from the skill name. The rename targets only the skill name and its direct references. (`plugins/core/skills/managers-principle/SKILL.md`, `.claude/rules/define-manager.md`)
- The `managers-policy` SKILL.md contains "Produce directional materials... Policy: A rule that must be followed" -- this use of "Policy" refers to the output artifact type (what leaders generate into `.workaholic/policies/`) and must remain unchanged. This is precisely the semantic collision being resolved. (`plugins/core/skills/managers-principle/SKILL.md` line 33)
- Spec documents under `.workaholic/specs/` contain extensive references to `managers-policy` and `leaders-policy` (found in model.md, infrastructure.md, component.md, feature.md, data.md, application.md, usecase.md, ux.md and their Japanese translations). These should be updated on the next `/scan` run rather than manually, since they are generated documentation. (`.workaholic/specs/`)
- Story files and archived tickets reference `managers-policy` and `leaders-policy` historically. These should NOT be updated since they document what happened at the time. (`.workaholic/stories/`, `.workaholic/tickets/archive/`)
- The CHANGELOG.md reference to `leaders-policy` is historical and should not be updated. (`CHANGELOG.md` line 12)
- The `scan.md` command file references `.workaholic/policies/` for validation output paths -- these are unrelated to this rename and must not be changed. (`plugins/core/commands/scan.md`)
- The 10 lead agent files that need updating are: quality-lead, security-lead, test-lead, ux-lead, db-lead, infra-lead, delivery-lead, a11y-lead, observability-lead, recovery-lead. Each has `leaders-policy` as the first entry in its skills list. (`plugins/core/agents/*-lead.md`)

## Final Report

All 9 implementation steps completed. Renamed both skill directories via `git mv`, updated SKILL.md frontmatter/headings/body text in both skills, updated all 3 manager agent files (frontmatter + instruction text), all 10 lead agent files (frontmatter), both rule template files, all 3 manage-* skill files, and all 4 term files (English + Japanese definitions and indexes). Verified zero remaining references to old names in active files. Historical references in archives, stories, specs, and changelog left untouched as specified.
