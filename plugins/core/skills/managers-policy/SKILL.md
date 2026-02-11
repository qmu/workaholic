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
