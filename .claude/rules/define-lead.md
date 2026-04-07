---
paths:
  - 'plugins/standards/skills/lead-*/SKILL.md'
  - 'plugins/standards/agents/lead.md'
---

# Lead Agent Schema Enforcement

Schema template and authoring guidelines for defining Leading Agents (leads). A lead is an agent that takes primary responsibility for a specific aspect of the project.

## Schema Template

Every lead skill file MUST contain the following sections in order. All sections are required and cannot be omitted.

```markdown
---
name: <speciality>-lead
description: <structured summary of identity and purpose>
---

# <Name>

## Role

<What the agent *is* and its function within the system.
Role is the overarching concept that contains both Goal and Responsibility.>

### Goal

<The sufficient condition as a bullet list. Each item is a measurable objective
that, when achieved, means the agent has fully succeeded. Meeting all goals
implies all responsibilities have been satisfied.>

### Responsibility

<The necessary condition as a bullet list. Each item is a duty the agent must fulfill.
If any responsibility is unmet, the agent has failed regardless of other outcomes.>

## Policies

<Freeform policy content. Rules, constraints, and guidelines
specific to this agent's domain. No fixed subsection structure required.>
```

## Guidelines

### Naming

Lead names follow the `<speciality>-lead` format. The speciality should be a single word or hyphenated compound that clearly identifies the agent's domain (e.g., `quality-lead`, `security-lead`, `delivery-lead`).

### Description

The description field is a single sentence that captures three things: what the agent is, what it does, and why it exists. Write it as a structured summary, not a tagline.

### Role: Goal and Responsibility

Role is the overarching concept that contains both Goal (positive obligation) and Responsibility (negative obligation):

- **Goal** answers "what must be achieved?" It is the sufficient condition. Define a measurable objective that, when achieved, implies all responsibilities have been satisfied. Goal represents what the agent owes to achieve.
- **Responsibility** answers "what must not be neglected?" It is the necessary condition. Define the minimum set of duties as concrete, verifiable obligations. If any single responsibility is unmet, the agent has failed. Responsibility represents what the agent owes to avoid.

An agent that meets all responsibilities but misses the goal is incomplete. An agent that achieves the goal has necessarily fulfilled all responsibilities.

### Policies

Policies are freeform. They should contain specific, actionable rules — not aspirational statements. Every rule should be something that can be checked in a review. No fixed subsection structure is required.

## Validation Checklist

Use this checklist to verify a lead definition is complete and well-formed:

- [ ] Frontmatter contains `name` and `description`
- [ ] Name follows `<speciality>-lead` format
- [ ] `## Role` section is present and defines the agent's function, containing Goal and Responsibility subsections
- [ ] `### Goal` subsection under Role defines measurable completion (sufficient condition, positive obligation)
- [ ] `### Responsibility` subsection under Role defines minimum duties (necessary condition, negative obligation)
- [ ] `## Policies` section is present with freeform, actionable rules
- [ ] Every rule is actionable and verifiable, not aspirational

## Agent

All 10 lead domains share a single parameterized agent at `plugins/standards/agents/lead.md`. The agent preloads all domain skills and both analysis frameworks. Callers pass the domain as a prompt parameter (e.g., `"Domain: security."`), and the agent applies the matching `lead-<domain>` skill.

There are no per-domain agent files. All domain knowledge lives in the lead skills, not in the agent.

## Example

A minimal but complete lead definition:

```markdown
---
name: testing-lead
description: Leads test strategy, coverage standards, and test infrastructure for the project.
---

# Testing Lead

## Role

The testing lead owns the project's test strategy. It decides what gets tested, how tests are structured, and what coverage thresholds apply. It is the authority on test quality and reliability.

### Goal

- The test suite passes reliably on every commit to main.
- All critical paths are covered.
- Tests complete within the time budget.
- A green CI run means the project is shippable.

### Responsibility

- Every merged change has test coverage proportional to its risk.
- Flaky tests are identified and either fixed or quarantined within one cycle.
- Test infrastructure (runners, fixtures, helpers) remains functional and documented.

## Policies

- Tests live next to the code they test in `__tests__/` directories.
- Use descriptive test names that state the expected behavior: `rejects expired tokens`.
- No test may depend on another test's side effects. Each test sets up and tears down its own state.
- Flag any PR that reduces coverage of a critical path.
- Run the full test suite before marking a task complete.
```
