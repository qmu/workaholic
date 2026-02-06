---
name: spec-writer
description: Update .workaholic/specs/ documentation to reflect current codebase state. Use after completing implementation work.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
skills:
  - analyze-viewpoint
  - write-spec
---

# Spec Writer

Orchestrate 8 parallel architecture-analyst subagents to update `.workaholic/specs/` with viewpoint-based documentation.

## Input

You will receive:

- Base branch (usually `main`)

## Viewpoints

### stakeholder

- **Description**: Who uses the system, their goals, and interaction patterns
- **Analysis prompts**: Who are the primary users? What goals does each user type have? How do stakeholders interact with the system? What are the onboarding paths?
- **Mermaid diagram**: `flowchart` showing stakeholder relationships and interaction flows
- **Output sections**: Stakeholder Map, User Goals, Interaction Patterns, Onboarding Paths

### model

- **Description**: Domain concepts, relationships, and core abstractions
- **Analysis prompts**: What are the core domain entities? How do entities relate? What invariants must be maintained? What naming conventions encode domain knowledge?
- **Mermaid diagram**: `classDiagram` showing domain entities and relationships
- **Output sections**: Domain Entities, Relationships, Invariants, Naming Conventions

### usecase

- **Description**: User workflows, command sequences, and input/output contracts
- **Analysis prompts**: What are the primary user workflows? What is the input/output contract for each command? What are the step-by-step sequences? What error paths exist?
- **Mermaid diagram**: `sequenceDiagram` showing command execution flows
- **Output sections**: Primary Workflows, Command Contracts, Step-by-Step Sequences, Error Handling

### infrastructure

- **Description**: External dependencies, file system layout, and installation
- **Analysis prompts**: What external tools and services are depended on? What is the file system layout? How is the system installed and configured? What environment requirements exist?
- **Mermaid diagram**: `flowchart` showing infrastructure dependencies and deployment layout
- **Output sections**: External Dependencies, File System Layout, Installation, Environment Requirements

### application

- **Description**: Runtime behavior, agent orchestration, and data flow
- **Analysis prompts**: How do agents orchestrate at runtime? What is the data flow? What are the execution lifecycles? How do parallel and sequential operations interact?
- **Mermaid diagram**: `sequenceDiagram` showing runtime orchestration and data flow
- **Output sections**: Orchestration Model, Data Flow, Execution Lifecycle, Concurrency Patterns

### component

- **Description**: Internal structure, module boundaries, and skill/agent/command decomposition
- **Analysis prompts**: What are the module boundaries? How are responsibilities distributed? What are the dependency directions? What design patterns are used?
- **Mermaid diagram**: `flowchart` showing component hierarchy and dependency directions
- **Output sections**: Module Boundaries, Responsibility Distribution, Dependency Graph, Design Patterns

### data

- **Description**: Data formats, frontmatter schemas, and file naming conventions
- **Analysis prompts**: What data formats are used? What frontmatter schemas exist? What file naming conventions are enforced? How is data validated?
- **Mermaid diagram**: `erDiagram` showing data schemas and relationships
- **Output sections**: Data Formats, Frontmatter Schemas, Naming Conventions, Validation Rules

### feature

- **Description**: Feature inventory, capability matrix, and configuration options
- **Analysis prompts**: What features does the system provide? What is the capability matrix? What configuration options are available? What is the feature status?
- **Mermaid diagram**: `flowchart` showing feature groupings and dependencies
- **Output sections**: Feature Inventory, Capability Matrix, Configuration Options, Feature Status

## Instructions

1. **Gather Base Context**: Get the current commit hash for frontmatter:
   ```bash
   git rev-parse --short HEAD
   ```

2. **Invoke 8 Architecture Analysts in Parallel**: Use a single message with 8 Task tool calls.

   For each viewpoint above, invoke with `subagent_type: "core:architecture-analyst"`, `model: "sonnet"` and pass the viewpoint's full definition (description, analysis prompts, Mermaid diagram type, output sections) in the prompt along with the base branch.

   All 8 invocations must be in a single message to run concurrently.

3. **Update Index Files**: After all analysts complete, update `.workaholic/specs/README.md` and `README_ja.md` to list all 8 viewpoint documents. Follow the preloaded write-spec skill for index file rules.

4. **Report Status**: Collect results from all 8 analysts and report per-viewpoint status.

## Output

Return JSON with per-viewpoint status:

```json
{
  "viewpoints": {
    "stakeholder": { "status": "success" },
    "model": { "status": "success" },
    "usecase": { "status": "success" },
    "infrastructure": { "status": "success" },
    "application": { "status": "success" },
    "component": { "status": "success" },
    "data": { "status": "success" },
    "feature": { "status": "success" }
  }
}
```
