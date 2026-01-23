# Add Cross-Cutting Documentation to sync-doc-specs

## Overview

The `/sync-doc-specs` command currently updates documentation on a file-by-file basis, reflecting what changed in individual tickets. However, documentation should also capture the **big picture** - cross-cutting concerns that span multiple files, directories, and architectural layers.

When multiple tickets modify related components, the cumulative effect creates patterns that aren't visible in any single file's documentation. For example, three tickets might each touch authentication (middleware, API routes, and database models), but no single doc explains how authentication flows across these layers. The command should synthesize these cross-cutting insights.

## Key Files

- `plugins/tdd/commands/sync-doc-specs.md` - Add instructions for identifying and documenting cross-cutting concerns
- `plugins/tdd/rules/doc-specs.md` - Add guidance for cross-cutting documentation style
- `doc/specs/developer-guide/architecture.md` - Example of where cross-cutting docs might live

## Implementation Steps

1. **Update `plugins/tdd/commands/sync-doc-specs.md`** to add a new step between "Plan Documentation Updates" and "Execute Updates":

   ### New Step: Identify Cross-Cutting Concerns

   After gathering ticket context and before updating individual docs, analyze changes for patterns that span multiple components:

   - **Data flow paths**: How data moves through layers (e.g., request → middleware → handler → database)
   - **Shared concepts**: Abstractions used across multiple files (e.g., error handling patterns, validation approaches)
   - **Integration points**: Where different subsystems connect
   - **Architectural patterns**: Design decisions that affect multiple areas

   For each cross-cutting concern identified:

   - Check if `doc/specs/` already has a document covering this concept
   - If not, consider whether it warrants a new document or a section in `architecture.md`
   - If yes, update the existing document to reflect the current state

2. **Update `plugins/tdd/rules/doc-specs.md`** to add guidance:

   ### Cross-Cutting Documentation

   Documentation should explain concepts that span multiple files:

   - **Prefer prose over file listings** - Explain how components work together, not just what each file does
   - **Use diagrams for flows** - Mermaid sequence diagrams show interactions between layers
   - **Document the "why"** - Explain design decisions, not just implementation details
   - **Think like a new developer** - What would someone need to understand before diving into individual files?

3. **Update the "Philosophy" section** in both files to emphasize:

   > Documentation serves two audiences: someone looking up a specific file, and someone trying to understand how the system works. The former needs file-level docs; the latter needs cross-cutting docs that explain flows, patterns, and architectural decisions.

## Considerations

- Cross-cutting docs risk becoming stale faster than file-level docs since they cover more ground
- The command should prompt Claude to think about the "why" behind multiple changes, not just catalog them
- Avoid creating too many small documents - prefer extending `architecture.md` over creating new files for minor patterns
- Mermaid diagrams (flowcharts, sequence diagrams) are effective for showing cross-layer interactions

## Final Report

Development completed as planned.
