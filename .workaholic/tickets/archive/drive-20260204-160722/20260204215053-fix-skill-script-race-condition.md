---
created_at: 2026-02-04T21:50:53+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash: bebb0a5
category: Changed
---

# Fix Skill Shell Script Path References

## Overview

Skill script invocations use relative `plugins/core/skills/` paths which fail intermittently because Claude Code may not resolve them correctly. The fix is to use the full marketplace plugin path: `~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/`.

## Key Files

- `plugins/core/commands/drive.md` - References archive-ticket script
- `plugins/core/skills/archive-ticket/SKILL.md` - References archive.sh script
- `plugins/core/skills/drive-approval/SKILL.md` - References commit.sh and archive-ticket scripts
- `plugins/core/skills/commit/SKILL.md` - References commit.sh script

## Implementation Steps

1. Update all skill script path references from `plugins/core/skills/` to `~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/`
2. Use the full path pattern: `bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/<skill-name>/sh/<script>.sh`

## Considerations

- The `~/.claude/plugins/marketplaces/workaholic/` path points to the installed marketplace plugin location
- This avoids relative path resolution issues by using an absolute path from home directory

## Final Report

Development completed as planned. Updated 4 files to use the full marketplace plugin path for skill script references.
