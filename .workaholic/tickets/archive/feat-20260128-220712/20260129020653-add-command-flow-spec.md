---
created_at: 2026-01-29T02:06:53+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.5h
commit_hash: 260e317
category: Added
---

# Add Command Flow Specification Document

## Overview

Create a new spec document `.workaholic/specs/command-flows.md` that describes how agents and skills interact when users execute each command. Include Mermaid flowcharts for each command (`/ticket`, `/drive`, `/story`) showing the complete execution flow with skills and subagents.

## Key Files

- `.workaholic/specs/command-flows.md` - New spec document (create)
- `.workaholic/specs/command-flows_ja.md` - Japanese translation (create)
- `.workaholic/specs/README.md` - Add link to new spec
- `.workaholic/specs/README_ja.md` - Add link to new spec

## Related History

The architecture.md already contains a dependency graph and documentation enforcement flowchart, but lacks per-command detail.

Past tickets that touched similar areas:

- [20260127101756-add-dependency-graph.md](.workaholic/tickets/archive/feat-20260126-214833/20260127101756-add-dependency-graph.md) - Added dependency graph to architecture (same file area)

## Implementation Steps

1. Create `.workaholic/specs/command-flows.md` with:

   **Frontmatter:**
   ```yaml
   ---
   title: Command Execution Flows
   description: How commands invoke agents and skills
   category: developer
   modified_at: <current timestamp>
   commit_hash: <leave empty - filled by spec-writer>
   ---
   ```

   **Content structure:**
   - Introduction explaining command → skill → agent relationships
   - One section per command with:
     - Brief description of what the command does
     - Mermaid flowchart showing execution flow
     - Table listing skills and agents invoked
     - Notes on parallel vs sequential execution

2. `/ticket` command flow:
   ```mermaid
   flowchart TD
       A[User: /ticket] --> B{On main branch?}
       B -->|Yes| C[Ask for prefix]
       C --> D[create-branch skill]
       D --> E[Create topic branch]
       B -->|No| F[Parse request]
       E --> F
       F --> G[history-discoverer agent]
       G --> H[discover-history skill]
       H --> I[Search archived tickets]
       I --> J[Return related tickets]
       J --> K[create-ticket skill]
       K --> L[Explore codebase]
       L --> M[Write ticket file]
       M --> N[Commit ticket]
   ```

3. `/drive` command flow:
   ```mermaid
   flowchart TD
       A[User: /drive] --> B[List tickets in todo/]
       B --> C{Tickets found?}
       C -->|No| D[Report: no tickets]
       C -->|Yes| E[For each ticket]
       E --> F[drive-workflow skill]
       F --> G[Read ticket]
       G --> H[Implement changes]
       H --> I[Ask for approval]
       I -->|Approve| J[Update effort + Final Report]
       I -->|Abandon| K[Discard changes]
       K --> L[Write Failure Analysis]
       L --> M[Move to fail/]
       J --> N[archive-ticket skill]
       N --> O[Archive + Commit]
       O --> P{More tickets?}
       M --> P
       P -->|Yes| E
       P -->|No| Q[Report summary]
   ```

4. `/story` command flow:
   ```mermaid
   flowchart TD
       A[User: /story] --> B[Check branch]
       B --> C{Tickets in todo?}
       C -->|Yes| D[Move to icebox + commit]
       C -->|No| E[Phase 1: Parallel agents]
       D --> E

       subgraph Phase1[Phase 1 - Parallel]
           F[changelog-writer]
           G[spec-writer]
           H[terms-writer]
           I[release-readiness]
       end

       E --> F & G & H & I

       F --> F1[generate-changelog skill]
       F --> F2[write-changelog skill]
       G --> G1[write-spec skill]
       G --> G2[translate skill]
       H --> H1[write-terms skill]
       H --> H2[translate skill]
       I --> I1[assess-release-readiness skill]

       F1 & F2 & G1 & G2 & H1 & H2 & I1 --> J[Phase 2: story-writer]

       J --> J1[write-story skill]
       J --> J2[translate skill]
       J --> J3[performance-analyst agent]
       J3 --> J4[analyze-performance skill]

       J1 & J2 & J4 --> K[Commit docs]
       K --> L[Push branch]
       L --> M[pr-creator agent]
       M --> M1[create-pr skill]
       M1 --> N[Create/Update PR]
       N --> O[Display PR URL]
   ```

5. Add table for each command listing:
   | Component | Type | Purpose |
   |-----------|------|---------|
   | create-branch | Skill | Creates timestamped branch |
   | history-discoverer | Agent | Finds related tickets |
   | ... | ... | ... |

6. Create Japanese translation `.workaholic/specs/command-flows_ja.md`

7. Update `.workaholic/specs/README.md`:
   - Add link: `- [Command Flows](command-flows.md) - How commands invoke agents and skills`

8. Update `.workaholic/specs/README_ja.md`:
   - Add link: `- [コマンドフロー](command-flows_ja.md) - コマンドがエージェントとスキルを呼び出す方法`

## Considerations

- Flowcharts should match current command implementations
- Note that `/ticket` now includes auto-branch and history-discoverer (per recent changes)
- Keep flowcharts readable - use subgraphs for parallel execution
- This complements architecture.md (high-level) with command-specific detail
- Update when command implementations change

## Final Report

Development completed as planned.
