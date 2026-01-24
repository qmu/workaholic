# Enforce Mermaid for Diagrams

## Overview

Add a rule to prevent ASCII-style diagrams in documentation and code comments, requiring Mermaid syntax instead. ASCII diagrams are difficult to maintain, render inconsistently across platforms, and lack interactivity. Mermaid provides a standardized, version-controllable, and renderable alternative that works in GitHub, VS Code, and most documentation systems.

## Key Files

- `plugins/core/rules/general.md` - General rules file where this diagram policy should be added

## Implementation Steps

1. Add a new section to `plugins/core/rules/general.md` titled "## Diagrams"

2. Include the following rules:
   - Prohibit ASCII art diagrams (box-drawing characters, arrow combinations like `-->`, `|`, `+--+`)
   - Require Mermaid syntax for all diagrams (flowcharts, sequence diagrams, class diagrams, etc.)
   - Provide examples of common diagram types in Mermaid

3. Add guidance for when diagrams are appropriate:
   - Architecture overviews
   - Data flow illustrations
   - State machines
   - Sequence diagrams for API interactions

## Considerations

- **Existing ASCII diagrams**: This rule applies to new content; existing ASCII diagrams should be converted opportunistically
- **Inline code comments**: Very simple arrows in code comments (like `// A -> B`) may still be acceptable for quick explanations
- **Mermaid limitations**: Some complex diagrams may need external tools; note this as an exception

## Final Report

Development completed as planned.
