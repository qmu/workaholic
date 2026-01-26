---
created_at: 2026-01-27T01:39:42+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
---

# Remove /commit command

## Overview

Remove the standalone `/commit` command from the core plugin. Running `/commit` during a `/drive` session flushes context, disrupting the workflow. Additionally, the command encourages ad-hoc commits without tickets, undermining the ticket-driven development philosophy where every change should be documented and tracked through a ticket.

## Key Files

- `plugins/core/commands/commit.md` - The command to be deleted
- `plugins/core/README.md` - Documents /commit in the commands table
- `plugins/core/rules/general.md` - References `/commit` in the commit rule
- `CLAUDE.md` - Lists /commit in the Commands table and project structure

## Implementation Steps

1. Delete `plugins/core/commands/commit.md`
2. Update `plugins/core/README.md` - Remove /commit from the Commands table
3. Update `plugins/core/rules/general.md` - Revise the commit rule to remove `/commit` reference, keeping the principle that commits only happen through commands with built-in commit steps (`/drive`, `/pull-request`)
4. Update `CLAUDE.md` - Remove /commit from Commands table and project structure comment

## Considerations

- Users who relied on `/commit` for ad-hoc commits will need to use `/ticket` + `/drive` workflow instead
- This change reinforces the core philosophy: all changes should flow through tickets for proper documentation
- The general rule about "never commit without explicit request" remains valid but should reference `/drive` and `/pull-request` instead of `/commit`
