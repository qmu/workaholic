---
created_at: 2026-01-27T21:08:05+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.1h
commit_hash: fc7257e
category: Changed
---

# Update root README.md for end users

## Overview

The current README.md is outdated and doesn't reflect the latest implementation:

- References old commands (`/commit`, `/pull-request`) that no longer exist
- Lists separate `core` and `tdd` plugins (now merged into just `core`)
- Missing the modern 4-command workflow
- Too verbose for quick start

The new README should be a concise sales pitch that gets users started fast, with links to `.workaholic/` for deep dives.

**Sales points to emphasize:**
1. Only 4 commands to remember
2. Ergonomic workflow for unlocking the ultra power of a cracked engineer
3. Rich documentation in `.workaholic/`

## Key Files

- `README.md` - Main file to rewrite

## Related History

Past tickets that touched similar areas:

- `20260123005524-add-development-routine-section.md` - Added workflow section (same file)
- `20260124001231-merge-core-and-tdd-plugins.md` - Merged plugins (outdated info)

## Implementation Steps

1. **Rewrite README.md** with this structure:

   ```markdown
   # Workaholic

   [One-liner tagline about AI-powered development workflow]

   ## Why Workaholic?

   [2-3 sentences: ergonomic workflow, unlock ultra productivity, AI pair programming]

   ## Installation

   ```bash
   claude
   /plugin marketplace add qmu/workaholic
   ```

   ## Quick Start

   | Command   | What it does                      |
   | --------- | --------------------------------- |
   | `/branch` | Create timestamped topic branch   |
   | `/ticket` | Write implementation spec with AI |
   | `/drive`  | Implement specs one by one        |
   | `/report` | Generate docs and create PR       |

   ### Typical Session

   ```bash
   /branch                           # feat-20260127-210800
   /ticket add user authentication   # AI explores, writes spec
   /drive                            # implement, commit, repeat
   /report                           # changelog, story, PR
   ```

   ## Documentation

   Deep dives and working artifacts live in [.workaholic/](.workaholic/README.md):

   - **specs/** - Current state reference
   - **stories/** - Development narratives per branch
   - **terms/** - Consistent terminology
   - **tickets/** - Work queue and archives

   ## Author

   tamurayoshiya <a@qmu.jp>
   ```

2. **Remove outdated content**:
   - Delete separate plugin sections (core, tdd)
   - Delete old command table with `/commit`, `/pull-request`
   - Delete verbose "Development Routine" prose (move to `.workaholic/` if needed)

3. **Keep it scannable**:
   - Use tables for commands
   - Minimal prose, maximum utility
   - Link to `.workaholic/README.md` for details

## Considerations

- The "cracked engineer" phrasing is informal - consider alternatives like "10x developer" or "high-velocity development"
- Don't duplicate content that's already in `.workaholic/README.md` - just link to it
- Installation instructions should be minimal - just the two commands

## Final Report

Development completed as planned.
