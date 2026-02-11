---
name: managers-policy
description: Cross-cutting policies that apply to all manager sub-agents.
user-invocable: false
---

# Managers Policy

Policies in this document apply to every manager sub-agent. Each manager MUST observe these
policies in addition to its own domain-specific Default Policies.

## Prior Term Consistency

Respect the original use of terms already established in the codebase and cultivate
ubiquitous language across all artifacts.

### Rules

- Before introducing a new term, search the codebase for an existing term that covers the
  same concept. Use the existing term.
- Prefer 1 word to express an idea. Use 2 words only when 1 word cannot express the idea
  unambiguously. Use 3 words as a last resort.
- When renaming or consolidating terms, update all references in the affected scope
  (code, documentation, configuration) in the same change.
- Flag any inconsistency where the same concept is referred to by different terms in
  different files.

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
- Write directional materials to paths under `.workaholic/` where leaders can
  find them.
- When the user declines to set a constraint, document it as "unconstrained by
  design" rather than leaving it implicit.
- Constraints are not permanent. Document review triggers (e.g., "revisit after v2
  release") so constraints do not become stale.
