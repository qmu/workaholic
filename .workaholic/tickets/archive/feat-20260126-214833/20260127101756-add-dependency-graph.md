---
created_at: 2026-01-27T10:17:56+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash: 29fe43b
category: Added
---

# Add dependency graph to developer guide

## Overview

Add a mermaid diagram to `.workaholic/specs/developer-guide/architecture.md` showing how commands, agents, and skills reference each other. This helps developers understand the plugin dependency structure at a glance.

## Key Files

- `.workaholic/specs/developer-guide/architecture.md` - English version
- `.workaholic/specs/developer-guide/architecture_ja.md` - Japanese version

## Implementation Steps

1. Add a new "## Dependency Graph" section after "## Plugin Types" in architecture.md

2. Create a mermaid flowchart showing:

   **Commands → Agents**:
   - `/report` → changelog-writer, story-writer, spec-writer, terms-writer, pr-creator

   **Commands → Skills**:
   - `/drive` → archive-ticket

   **Agents → Skills**:
   - changelog-writer → changelog
   - story-writer → story-metrics
   - spec-writer → spec-context
   - pr-creator → pr-ops

   **Agents → Agents**:
   - story-writer → performance-analyst

3. Example diagram structure:
   ```mermaid
   flowchart LR
       subgraph Commands
           report[/report]
           drive[/drive]
           ticket[/ticket]
           branch[/branch]
       end

       subgraph Agents
           cw[changelog-writer]
           sw[story-writer]
           spw[spec-writer]
           tw[terms-writer]
           pc[pr-creator]
           pa[performance-analyst]
       end

       subgraph Skills
           at[archive-ticket]
           cl[changelog]
           sm[story-metrics]
           sc[spec-context]
           po[pr-ops]
       end

       report --> cw & sw & spw & tw & pc
       drive --> at

       cw --> cl
       sw --> sm
       sw --> pa
       spw --> sc
       pc --> po
   ```

4. Add Japanese translation to architecture_ja.md

## Considerations

- Keep diagram readable - don't include rules or standalone skills like translate/command-prohibition
- Focus on runtime invocation relationships, not documentation references
- Use consistent node naming (short but recognizable)
