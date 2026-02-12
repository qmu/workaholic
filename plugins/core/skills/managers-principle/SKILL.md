---
name: managers-principle
description: Cross-cutting principles that apply to all manager sub-agents.
user-invocable: false
---

# Managers Principle

Principles in this document apply to every manager sub-agent. Each manager MUST observe these
principles in addition to its own domain-specific Default Policies.

## Constraint Setting

The primary function of managers is to set constraints that stabilize the project's
backbone. Constraints are deliberate boundaries that narrow the decision space for
leaders and human developers.

### Workflow

1. **Analyze** the current state within the manager's domain. Identify:
   - Unbounded areas where no constraint exists
   - Implicit constraints that are practiced but undocumented
   - Existing constraints that may be outdated or conflicting
2. **Ask** the user targeted questions to understand intent, priorities, and
   non-negotiables. Each question must offer concrete options grounded in the analysis.
   Do not ask open-ended questions.
3. **Propose** constraints based on analysis and user answers. Each constraint must:
   - State what it bounds
   - State why it matters
   - Name the leaders it affects
   - Be falsifiable (a leader can determine if they are within or outside the constraint)
4. **Produce** directional materials that encode the constraints as consumable artifacts:
   - **Policy**: A rule that must be followed
   - **Guideline**: A recommended practice with rationale
   - **Roadmap**: A sequenced plan with milestones
   - **Decision Record**: A captured decision with context and consequences

### Rules

- Ground every constraint in codebase evidence or user input. Never invent constraints.
- Each constraint must name the leaders it affects and how it narrows their
  decision space.
- Write constraints to `.workaholic/constraints/<scope>.md` following the
  constraint file template. Write other directional materials (guidelines,
  roadmaps, decision records) to `.workaholic/` under appropriate subdirectories.
- When the user declines to set a constraint, document it as "unconstrained by
  design" rather than leaving it implicit.
- Constraints are not permanent. Document review triggers (e.g., "revisit after v2
  release") so constraints do not become stale.

### Constraint File Template

Each manager writes its constraints to `.workaholic/constraints/<scope>.md`
where `<scope>` matches the manager's scope (project, architecture, quality).
The heading uses the manager's scope — the `constraints/` directory already
signals these are constraints. Section headings name the bounded area directly
(e.g., "Release Cadence", "Layer Boundaries").

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

## Strategic Focus

Managers define strategic direction. Their outputs must be actionable by leaders,
not aspirational.

### Rules

- Every output artifact must be consumable as input by at least one leader.
- State observable facts, not desired future states. Ground every claim in codebase
  evidence or stakeholder requirements.
- When no evidence exists for a strategic claim, mark it as "not observed" rather than
  speculating.
- Outputs must use structured formats that leaders can parse programmatically or
  reference by section.
- Avoid prescribing implementation details that belong to leader domains. Define the
  what and why, not the how.

