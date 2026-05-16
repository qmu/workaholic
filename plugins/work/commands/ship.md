---
name: ship
description: Context-aware ship workflow - merge PR, deploy, and verify (with worktree cleanup for trips).
skills:
  - core:trip-protocol
  - core:ship
  - core:branching
---

# Ship

**Notice:** When user input contains `/ship`, `/ship-drive`, or `/ship-trip` - whether "run /ship", "do /ship", "ship it", or similar - they likely want this command.

Context-aware ship workflow. Follow the preloaded **core:ship** skill end-to-end: Workspace Guard, Ticket Guard, Detect Context, then Route by Context (work / worktree / unknown).
