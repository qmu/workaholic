---
created_at: 2026-01-26T13:23:22+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Enforce Work Directory Structure

## Overview

Add a rule to the core plugin that restricts the `.work/` (or `.workaholic/`) directory to only contain designated subdirectories. This prevents both users and Claude from accidentally creating non-standard directories that would fragment the artifact organization.

## Key Files

- `plugins/core/rules/general.md` - Add the directory structure enforcement rule with path restriction

## Implementation Steps

1. Add a new rule section to `plugins/core/rules/general.md` titled "Work Directory Structure"

2. The rule should specify:
   - Only these directories are allowed under `.work/` (or `.workaholic/`):
     - `specs/` - Current state reference documentation
     - `stories/` - Development narratives per branch
     - `terminology/` - Term definitions
     - `tickets/` - Implementation work queue and archives
   - README files at the root level are allowed (`README.md`, `README_ja.md`, etc.)

3. The rule should instruct Claude to:
   - Never create directories outside the allowed list
   - If a user requests creating a new directory, explain the allowed structure and suggest the appropriate existing directory
   - Map common requests to existing directories (e.g., "docs" → `specs/`, "archive" → `tickets/archive/`)

4. Update the `paths` frontmatter to target `.work/**/*` so it triggers when working in that directory

## Considerations

- This is a preventive rule, not a cleanup rule - it doesn't remove existing non-standard directories
- The rule applies to both `.work/` and `.workaholic/` to handle pre/post migration
- Users can still override by explicitly asking, but Claude should explain the convention first
