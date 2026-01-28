---
created_at: 2026-01-28T22:28:43+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.25h
commit_hash: 09e00b0
category: Changed
---

# Rewrite README with TiDD Philosophy

## Overview

Rewrite the README.md to remove "AI-powered" marketing language and reframe Workaholic as an in-repository Ticket-Driven Development (TiDD) system that preserves project history and cultivates semantics.

## Key Files

- `README.md` - Main project documentation to be rewritten

## Related History

No directly related tickets found for README content changes.

## Implementation Steps

1. Remove "AI-powered" language from the tagline (line 3)
2. Replace the tagline with a paragraph describing:
   - Workaholic as a redefined TiDD (Ticket-Driven Development) approach
   - In-repository style: tickets live alongside code, not in external tools
   - Shared history: the full development history is accessible to all collaborators
   - Semantic cultivation: decisions, context, and rationale are preserved
3. Merge the Motivation section viewpoints into the new introductory paragraph:
   - Backlog as Historical Assets (tickets in repo, searchable history, git-tracked artifacts)
   - Parallel Generation, Serial Execution (multiple sessions create tickets, one implements)
   - Explanations via `/report` (commit messages, docs, PR descriptions)
   - Cultivating Semantics (intuitive commands, consistency, "why" captured, small dense commits)
4. Consider restructuring the Motivation section or removing it if fully merged

## Considerations

- The tone should be technical and factual, not marketing-speak
- Since this is a Claude Code plugin, the context already implies Claude assistance
- Focus on the methodology (TiDD) and the value of in-repository history
- Keep the Quick Start and other sections intact - only change the opening sections

## Final Report

Implementation deviated from original plan:

- **Change**: Split introduction into two paragraphs instead of one
  **Reason**: User requested better readability and smoother logic flow between sentences

- **Change**: Rewrote `/ticket` description from "Write implementation spec" to "Plan a change with context and steps"
  **Reason**: User clarified tickets are not specs—they capture all information around planned and implemented changes

- **Change**: Expanded Typical Session to show realistic development flow
  **Reason**: User noted real development involves ticketing throughout (not just at start), driving multiple times, and reporting when ready to deliver
