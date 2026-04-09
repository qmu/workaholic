---
created_at: 2026-04-09T20:25:44+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add Practices and Standards Sections to Lead Schema

## Overview

Update `.claude/rules/define-lead.md` to extend the lead skill schema with two new optional sections after Policies: "## Practices" and "## Standards". This introduces a three-tier structure: Policies (abstract principles) -> Practices (concrete, actionable implementations of policies) -> Standards (specific, measurable criteria that codify practices). The new sections are optional -- not all leads will have them immediately -- but the schema should document them as expected sections.

## Key Files

- `.claude/rules/define-lead.md` - The lead schema enforcement rule containing the template, guidelines, validation checklist, and example that all need updating
- `plugins/standards/skills/lead-security/SKILL.md` - Example lead skill with populated Policies section (shows current structure that new sections extend)
- `plugins/standards/skills/lead-quality/SKILL.md` - Example lead skill with empty Policies section (shows minimal current structure)
- `plugins/standards/agents/lead.md` - Parameterized lead agent referencing "role, responsibility, and policies" in instructions
- `plugins/standards/skills/leaders-principle/SKILL.md` - Cross-cutting principle skill referencing "domain-specific Policies"

## Related History

The define-lead schema has undergone several structural evolutions: creation as a skill, migration to a path-scoped rule, heading hierarchy restructuring, and renaming Default Policies to Policies. This ticket extends that schema with two additional content tiers.

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the original define-lead skill with schema template (same file being modified)
- [20260209181813-move-define-lead-to-claude-rules.md](.workaholic/tickets/archive/drive-20260208-131649/20260209181813-move-define-lead-to-claude-rules.md) - Moved define-lead to `.claude/rules/` for automatic path-scoped enforcement (same file being modified)
- [20260219165413-restructure-role-responsibility-goal-headings.md](.workaholic/tickets/archive/drive-20260213-131416/20260219165413-restructure-role-responsibility-goal-headings.md) - Restructured Role/Goal/Responsibility headings in schema and all skills (precedent for schema-wide structural change)
- [20260404002424-reset-lead-skill-policies.md](.workaholic/tickets/archive/drive-20260403-230430/20260404002424-reset-lead-skill-policies.md) - Renamed "Default Policies" to "Policies" and reset all policy content (most recent schema modification)

## Implementation Steps

1. **Update the Schema Template in `define-lead.md`**

   Add `## Practices` and `## Standards` sections after `## Policies` in the fenced code block template. Include descriptive placeholders explaining each section's purpose and mark them as optional:

   - `## Practices` - Concrete, actionable practices that implement the abstract policies. Each practice should be directly executable and traceable to one or more policies.
   - `## Standards` - Specific, measurable standards that codify the practices. Each standard should define a pass/fail criterion that can be verified in a review.

2. **Update the Guidelines section**

   Add a new subsection after the existing "### Policies" guideline that explains the three-tier structure:

   - **Policies** are abstract principles -- they state *what* matters and *why*.
   - **Practices** are concrete actions -- they state *how* to implement the policies.
   - **Standards** are measurable criteria -- they state *what specifically* must be true, with pass/fail thresholds.

   Explain that the tiers are ordered from abstract to concrete: Policies -> Practices -> Standards. Document that Practices and Standards are optional sections (a lead may have only Policies initially, then add Practices and Standards as the domain matures).

3. **Update the Validation Checklist**

   Add two new optional checklist items after the Policies item:

   - `## Practices` section, if present, contains concrete actionable items traceable to policies
   - `## Standards` section, if present, contains measurable pass/fail criteria traceable to practices

   These should be marked as conditional (only validated if present), unlike Policies which is required.

4. **Update the Example section**

   Extend the `testing-lead` example to include sample Practices and Standards sections that demonstrate the three-tier relationship:

   - Practices should show concrete testing actions derived from the example policies
   - Standards should show measurable criteria derived from the example practices

5. **Verify no agent file changes are needed**

   The `lead.md` agent references "role, responsibility, and policies" in step 2 of its instructions. Since Practices and Standards are optional extensions of the domain content (not new workflow steps), the agent instructions should not require modification. Verify this is the case.

## Patches

### `.claude/rules/define-lead.md`

```diff
--- a/.claude/rules/define-lead.md
+++ b/.claude/rules/define-lead.md
@@ -39,6 +39,14 @@
 ## Policies
 
 <Freeform policy content. Rules, constraints, and guidelines
 specific to this agent's domain. No fixed subsection structure required.>
+
+## Practices
+
+<Optional. Concrete, actionable practices that implement the abstract policies.
+Each practice should be directly executable and traceable to one or more policies.>
+
+## Standards
+
+<Optional. Specific, measurable standards that codify the practices.
+Each standard should define a pass/fail criterion verifiable in a review.>
 ```
```

> **Note**: This patch is speculative -- verify the exact line numbers and context before applying.

### `.claude/rules/define-lead.md` (Guidelines)

```diff
--- a/.claude/rules/define-lead.md
+++ b/.claude/rules/define-lead.md
@@ -64,6 +64,12 @@
 ### Policies
 
 Policies are freeform. They should contain specific, actionable rules -- not aspirational statements. Every rule should be something that can be checked in a review. No fixed subsection structure is required.
+
+### Practices and Standards
+
+Practices and Standards are optional sections that extend Policies into a three-tier structure, ordered from abstract to concrete:
+
+- **Policies** (required) state *what* matters and *why*. Abstract principles and constraints.
+- **Practices** (optional) state *how* to implement the policies. Concrete, executable actions traceable to one or more policies.
+- **Standards** (optional) state *what specifically* must be true. Measurable pass/fail criteria traceable to practices.
+
+Not all leads will have Practices or Standards immediately. A lead may start with only Policies and add the other tiers as the domain matures. When present, every Practice should trace to a Policy, and every Standard should trace to a Practice.
```

> **Note**: This patch is speculative -- verify the exact line numbers and context before applying.

### `.claude/rules/define-lead.md` (Validation Checklist)

```diff
--- a/.claude/rules/define-lead.md
+++ b/.claude/rules/define-lead.md
@@ -76,6 +76,8 @@
 - [ ] `### Responsibility` subsection under Role defines minimum duties (necessary condition, negative obligation)
 - [ ] `## Policies` section is present with freeform, actionable rules
 - [ ] Every rule is actionable and verifiable, not aspirational
+- [ ] `## Practices` section, if present, contains concrete actionable items traceable to policies
+- [ ] `## Standards` section, if present, contains measurable pass/fail criteria traceable to practices
```

> **Note**: This patch is speculative -- verify the exact line numbers and context before applying.

### `.claude/rules/define-lead.md` (Example)

```diff
--- a/.claude/rules/define-lead.md
+++ b/.claude/rules/define-lead.md
@@ -119,4 +119,20 @@
 - No test may depend on another test's side effects. Each test sets up and tears down its own state.
 - Flag any PR that reduces coverage of a critical path.
 - Run the full test suite before marking a task complete.
+
+## Practices
+
+- Write tests before or alongside the code they verify, not after.
+- Run the full test suite locally before pushing to CI.
+- Quarantine flaky tests into a dedicated suite within 24 hours of detection.
+- Review test coverage diff on every PR -- reject if critical paths lose coverage.
+
+## Standards
+
+- Every PR touching business logic includes at least one new or updated test.
+- Critical path coverage never drops below 90%.
+- No flaky test remains in the main suite for more than one development cycle.
+- Full test suite completes in under 5 minutes on CI.
+- Every quarantined test has a linked tracking issue.
 ```
```

> **Note**: This patch is speculative -- verify the exact line numbers and context before applying.

## Considerations

- The Practices and Standards sections are explicitly optional to avoid forcing all 10 existing lead skills to be updated in this ticket. Existing leads with only a `## Policies` section remain valid. (`plugins/standards/skills/lead-*/SKILL.md`)
- The `leaders-principle` skill references "domain-specific Policies" but does not need updating since Practices and Standards are domain-specific extensions, not cross-cutting principles. (`plugins/standards/skills/leaders-principle/SKILL.md`)
- The lead agent instructions in step 3 reference "the matching Policy" for task routing. Since Practices and Standards do not change the task routing mechanism, no agent file changes are needed. (`plugins/standards/agents/lead.md` lines 27-31)
- Future tickets may populate Practices and Standards in individual lead skills, following the same incremental pattern used when Policies were initially empty after the reset. (`plugins/standards/skills/lead-*/SKILL.md`)
- The `define-manager.md` schema is out of scope for this ticket. If the three-tier structure proves useful for leads, a separate ticket should extend it to managers. (`.claude/rules/define-manager.md`)
- The `paths:` frontmatter in `define-lead.md` targets `plugins/standards/skills/lead-*/SKILL.md` and `plugins/standards/agents/lead.md`, so the updated schema will automatically apply when editing any lead skill file. (`.claude/rules/define-lead.md` lines 2-4)
