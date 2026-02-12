---
paths:
  - 'plugins/core/skills/manage-*/SKILL.md'
  - 'plugins/core/agents/*-manager.md'
---

# Manager Agent Schema Enforcement

Schema template and authoring guidelines for defining Managing Agents (managers). A manager is an agent that produces strategic outputs that leaders depend on.

## Schema Template

Every manager skill file MUST contain the following sections in order. All sections are required and cannot be omitted.

```markdown
---
name: manage-<domain>
description: <structured summary of identity and purpose>
user-invocable: false
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

## Outputs

<The structured artifacts the manager produces that leaders consume.
Each output must be actionable by at least one leader.
Define the output format, content, and consuming leaders.>

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

Manager names follow the `manage-<domain>` format. The domain should be a single word or hyphenated compound that clearly identifies the manager's strategic scope (e.g., `manage-project`, `manage-architecture`, `manage-quality`).

### Description

The description field is a single sentence that captures three things: what the agent is, what it does, and why it exists. Write it as a structured summary, not a tagline.

### Responsibility vs Goal

Responsibility and Goal are deliberately separated because they serve different logical functions:

- **Responsibility** answers "what must not be neglected?" It is the necessary condition. Define the minimum set of duties as concrete, verifiable obligations. If any single responsibility is unmet, the agent has failed.
- **Goal** answers "what constitutes completion?" It is the sufficient condition. Define a measurable objective that, when achieved, implies all responsibilities have been satisfied.

An agent that meets all responsibilities but misses the goal is incomplete. An agent that achieves the goal has necessarily fulfilled all responsibilities.

### Outputs

The `## Outputs` section distinguishes managers from leaders. Every output must:

- Have a defined format (structured data, document, or artifact).
- Name at least one consuming leader that depends on it.
- Be actionable -- leaders can use it directly without further interpretation.

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

Use this checklist to verify a manager definition is complete and well-formed:

- [ ] Frontmatter contains `name`, `description`, and `user-invocable: false`
- [ ] Name follows `manage-<domain>` format
- [ ] `## Role` section is present and defines the agent's function
- [ ] `## Responsibility` section defines minimum duties (necessary condition)
- [ ] `## Goal` section defines measurable completion (sufficient condition)
- [ ] `## Outputs` section defines structured artifacts with consuming leaders
- [ ] Every output names at least one consuming leader
- [ ] `## Default Policies` section is present with all four subsections
- [ ] `### Implementation` contains concrete coding rules
- [ ] `### Review` contains concrete review criteria
- [ ] `### Documentation` contains concrete documentation rules
- [ ] `### Execution` contains concrete execution rules
- [ ] Every rule is actionable and verifiable, not aspirational

## Agent Template

Every manager has a corresponding thin agent file at `plugins/core/agents/<domain>-manager.md`. The agent is a multi-purpose orchestrator -- it is not tied to a single task type. Callers invoke it with a prompt describing what to do, and the agent applies the corresponding Default Policy from the manager skill.

```markdown
---
name: <domain>-manager
description: <same as the manager skill description>
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - managers-principle
  - manage-<domain>
  - <other skills needed for execution>
---

# <Domain> Manager

<One-sentence description of the manager's domain.>
Follow the preloaded manage-<domain> skill for role, responsibility, and default policies.

## Instructions

1. Read the caller's prompt to determine the task type.
2. Apply the corresponding Default Policy from the manage-<domain> skill:
   - Writing or modifying code -> Implementation policy
   - Reviewing artifacts -> Review policy
   - Writing or updating documentation -> Documentation policy
   - Running commands or actions -> Execution policy
3. Execute the task within the manager's Role and Responsibility.
4. Produce the Outputs defined in the manager skill.
5. Return a JSON result describing what was done and what outputs were produced.
```

The agent file should remain thin (~20-40 lines). All domain knowledge, rules, and criteria live in the manager skill, not in the agent.
