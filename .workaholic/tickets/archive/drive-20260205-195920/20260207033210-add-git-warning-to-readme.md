---
created_at: 2026-02-07T03:32:10+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.1h
commit_hash: a52e0a8
category: Added
---

# Add Git Manipulation Warning to Root README

## Overview

Add a prominent warning notice to the root README.md informing users that this plugin is designed for Claude Code to manipulate git fundamentally. Users should understand before installing that Workaholic will create branches, stage files, commit, amend commits, push, and create pull requests on their behalf -- all driven by AI through Claude Code.

## Key Files

- `README.md` - Add warning notice after the opening description, before Quick Start
- `plugins/core/skills/manage-branch/sh/create.sh` - Creates branches via `git checkout -b`
- `plugins/core/skills/commit/sh/commit.sh` - Stages files and commits with structured messages
- `plugins/core/skills/archive-ticket/sh/archive.sh` - Moves files, stages with `git add -A`, commits, and amends
- `plugins/core/skills/create-pr/sh/create-or-update.sh` - Pushes branches and creates/updates GitHub PRs

## Related History

Past tickets have modified the root README multiple times, adding sections for user onboarding, SDD explanation, and motivation -- but none have addressed the need to warn users about the fundamental git operations performed by the plugin.

Past tickets that touched similar areas:

- [20260129100732-add-sdd-info-card-to-readme.md](.workaholic/tickets/archive/feat-20260129-023941/20260129100732-add-sdd-info-card-to-readme.md) - Added SDD info card using GitHub alert syntax (same file, same position area)
- [20260128012123-add-motivation-section-to-readme.md](.workaholic/tickets/archive/feat-20260128-012023/20260128012123-add-motivation-section-to-readme.md) - Added motivation section to README (same file: README.md)
- [20260127210804-update-readme-for-users.md](.workaholic/tickets/archive/feat-20260126-214833/20260127210804-update-readme-for-users.md) - Rewrote README for end users (same file: README.md)

## Implementation Steps

1. Add a `> [!WARNING]` GitHub alert block to `README.md` after the opening paragraph (line 3) and before the existing `> [!NOTE]` block about SDD.

2. The warning should clearly state:
   - This plugin is designed for Claude Code to manipulate git fundamentally
   - Specific operations: branch creation, file staging, committing, amending, pushing, and PR creation
   - Users should understand this before installing

3. Keep the warning concise -- 2-3 sentences maximum. The goal is informed consent, not deterrence.

## Patches

### `README.md`

```diff
--- a/README.md
+++ b/README.md
@@ -1,5 +1,10 @@
 # Workaholic

 Claude Code plugin aiming at in-repository ticket-driven development (TiDD). It stores project context in `.workaholic/` for better AI decisions, enabling fast serial development without worktree or multi-repo overhead.

+> [!WARNING]
+> **This plugin manipulates git fundamentally.** Workaholic is designed for Claude Code to create branches, stage and commit files, amend commits, push to remotes, and create pull requests -- all autonomously as part of its workflow. Make sure you understand these operations before installing.
+
 ## Quick Start
```

## Considerations

- Use `[!WARNING]` alert type (yellow/orange accent on GitHub) rather than `[!NOTE]` (blue) to visually distinguish the severity (`README.md` line 3-4 area)
- Position the warning before the SDD `[!NOTE]` block so users see it first when scanning the README (`README.md` lines 39-48)
- The existing SDD info card uses `[!NOTE]` -- using `[!WARNING]` here creates clear visual hierarchy between informational and cautionary content
- Keep wording neutral and factual rather than alarming -- this is a feature disclosure, not a danger warning (`README.md`)

## Final Report

Added a `[!WARNING]` alert block to `README.md` between the opening description and `## Quick Start`. The wording was refined during review to be more natural: "This plugin drives git on your behalf" with a concise list of autonomous operations and a pointer to the command table below.
