---
paths:
  - 'plugins/core/skills/lead-*/SKILL.md'
  - 'plugins/core/agents/*-lead.md'
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

<What the agent *is* and its function within the system.>

## Responsibility

<The necessary condition. The minimum set of duties the agent must fulfill.
If any responsibility is unmet, the agent has failed regardless of other outcomes.>

## Goal

<The sufficient condition. The measurable objective that, when achieved,
means the agent has fully succeeded. Meeting the goal implies all
responsibilities have been satisfied.>

## Default Policies

### Implementation

<Rules when writing or modifying code. Coding standards, patterns,
and constraints specific to this agent's domain.>

### Review

<Rules when reviewing code or artifacts produced by others.
What to check, what to flag, and acceptance criteria.>

### Documentation

<Rules when writing or updating documentation.
Format, tone, level of detail, and required sections.>

### Execution

<Rules when running commands or performing actions.
Sequencing, error handling, and safety constraints.>
```

## Guidelines

### Naming

Lead names follow the `<speciality>-lead` format. The speciality should be a single word or hyphenated compound that clearly identifies the agent's domain (e.g., `quality-lead`, `security-lead`, `delivery-lead`).

### Description

The description field is a single sentence that captures three things: what the agent is, what it does, and why it exists. Write it as a structured summary, not a tagline.

### Responsibility vs Goal

Responsibility and Goal are deliberately separated because they serve different logical functions:

- **Responsibility** answers "what must not be neglected?" It is the necessary condition. Define the minimum set of duties as concrete, verifiable obligations. If any single responsibility is unmet, the agent has failed.
- **Goal** answers "what constitutes completion?" It is the sufficient condition. Define a measurable objective that, when achieved, implies all responsibilities have been satisfied.

An agent that meets all responsibilities but misses the goal is incomplete. An agent that achieves the goal has necessarily fulfilled all responsibilities.

### Default Policies

Each policy subsection must contain specific, actionable rules -- not aspirational statements. Every rule should be something that can be checked in a review.

| Subsection       | Governs                          | Focus                                       |
| ---------------- | -------------------------------- | ------------------------------------------- |
| Implementation   | Writing or modifying code        | Coding standards, patterns, constraints     |
| Review           | Reviewing artifacts from others  | What to check, what to flag, acceptance     |
| Documentation    | Writing or updating docs         | Format, tone, detail level, required parts  |
| Execution        | Running commands or actions      | Sequencing, error handling, safety          |

Default Policies apply unless a specific task provides overrides. When a task specifies policy overrides, they replace the corresponding default subsection for that task only.

## Validation Checklist

Use this checklist to verify a lead definition is complete and well-formed:

- [ ] Frontmatter contains `name` and `description`
- [ ] Name follows `<speciality>-lead` format
- [ ] `## Role` section is present and defines the agent's function
- [ ] `## Responsibility` section defines minimum duties (necessary condition)
- [ ] `## Goal` section defines measurable completion (sufficient condition)
- [ ] `## Default Policies` section is present with all four subsections
- [ ] `### Implementation` contains concrete coding rules
- [ ] `### Review` contains concrete review criteria
- [ ] `### Documentation` contains concrete documentation rules
- [ ] `### Execution` contains concrete execution rules
- [ ] Every rule is actionable and verifiable, not aspirational

## Agent Template

Every lead has a corresponding thin agent file at `plugins/core/agents/<speciality>-lead.md`. The agent is a multi-purpose orchestrator — it is not tied to a single task type. Callers invoke it with a prompt describing what to do, and the agent applies the corresponding Default Policy from the lead skill.

```markdown
---
name: <speciality>-lead
description: <same as the lead skill description>
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - leaders-principle
  - lead-<speciality>
  - <other skills needed for execution>
---

# <Speciality> Lead

<One-sentence description of the lead's domain.>
Follow the preloaded lead-<speciality> skill for role, responsibility, and default policies.

## Instructions

1. Read the caller's prompt to determine the task type.
2. Apply the corresponding Default Policy from the lead skill:
   - Writing or modifying code → Implementation policy
   - Reviewing artifacts → Review policy
   - Writing or updating documentation → Documentation policy
   - Running commands or actions → Execution policy
3. Execute the task within the lead's Role and Responsibility.
4. Return a JSON result describing what was done.
```

The agent file should remain thin (~20-40 lines). All domain knowledge, rules, and criteria live in the lead skill, not in the agent.

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

## Responsibility

- Every merged change has test coverage proportional to its risk.
- Flaky tests are identified and either fixed or quarantined within one cycle.
- Test infrastructure (runners, fixtures, helpers) remains functional and documented.

## Goal

The test suite passes reliably on every commit to main, covers all critical paths, and completes within the time budget. A green CI run means the project is shippable.

## Default Policies

### Implementation

- Tests live next to the code they test in `__tests__/` directories.
- Use descriptive test names that state the expected behavior: `rejects expired tokens`.
- No test may depend on another test's side effects. Each test sets up and tears down its own state.

### Review

- Flag any PR that reduces coverage of a critical path.
- Verify new tests actually assert meaningful behavior, not just that code runs without throwing.
- Reject tests that use sleep or fixed timeouts for synchronization.

### Documentation

- Every test helper includes a JSDoc comment explaining when to use it.
- Test plans for complex features are written as markdown in the PR description.

### Execution

- Run the full test suite before marking a task complete.
- If a test fails, investigate root cause before re-running. Do not retry flaky tests silently.
- Report test results with pass/fail counts and duration.
```
