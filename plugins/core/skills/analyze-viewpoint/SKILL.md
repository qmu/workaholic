---
name: analyze-viewpoint
description: Generic framework for viewpoint-based architecture analysis. Provides output templates, assumption rules, and context gathering scripts.
allowed-tools: Bash
skills:
  - write-spec
  - translate
user-invocable: false
---

# Analyze Viewpoint

Generic framework for analyzing a repository from a specific architectural viewpoint. Viewpoint definitions (prompts, diagram types, sections) are provided by the caller.

## Gather Context

Run the bundled script to collect viewpoint-specific information:

```bash
bash .claude/skills/analyze-viewpoint/sh/gather.sh <viewpoint-slug> [base-branch]
```

Default base branch is `main`.

### Check for Overrides

Run the override reader to check for user-defined viewpoint customizations:

```bash
bash .claude/skills/analyze-viewpoint/sh/read-overrides.sh
```

If overrides exist, merge them with the viewpoint definition received from the caller.

## Output Template

Each viewpoint produces a spec document following this structure:

```markdown
---
title: <Viewpoint Name> Viewpoint
description: <viewpoint description>
category: developer
modified_at: <ISO 8601 datetime>
commit_hash: <from context>
---

[English](<slug>.md) | [Japanese](<slug>_ja.md)

# <Viewpoint Name> Viewpoint

<introductory paragraph explaining the viewpoint's scope>

## <Section 1 from viewpoint definition>

<content with analysis>

## <Section 2 from viewpoint definition>

<content with analysis>

...

## Diagram

<Mermaid diagram of the appropriate type>

## Assumptions

<clearly mark inferred vs explicit knowledge>
```

## Mermaid Node Label Quoting (REQUIRED)

When generating Mermaid diagrams, **MUST quote labels** containing special characters (`/`, `{`, `}`, `[`, `]`):

- `A[/command]` -- WRONG, causes GitHub lexical error
- `A["/command"]` -- CORRECT
- `B{Decision?}` -- acceptable (no special chars inside braces)
- `C["path/to/file"]` -- CORRECT for paths with slashes

This is especially common for slash-command labels like `/ticket`, `/drive`, `/scan`, `/report`.

## Assumption Section Rules

Every viewpoint spec must include an Assumptions section at the end:

- **Explicit**: Facts directly observed in code, configuration, or documentation
- **Inferred**: Conclusions drawn from patterns, naming conventions, or structural analysis
- Prefix each assumption with `[Explicit]` or `[Inferred]`
- When the codebase has no explicit information for a topic, state what was inferred and why

## Comprehensiveness Policy

- Document everything observable in the codebase
- Do not judge any aspect as "not worth documenting"
- Small details and edge cases are valuable
- When in doubt, include rather than exclude

## Inference Baseline Guidelines

When the codebase provides no explicit information:

- Analyze naming conventions, file structure, and patterns
- State conclusions as inferences, not facts
- Provide the reasoning chain that led to the inference
- Flag areas where explicit documentation would improve clarity

## Cross-Viewpoint References

Viewpoint specs should reference each other when topics overlap:

- Use relative links: `See [Component Viewpoint](component.md) for module boundaries`
- Avoid duplicating content that belongs primarily in another viewpoint
- Each viewpoint owns its primary topics; other viewpoints reference, not repeat
