---
created_at: 2026-01-27T10:20:07+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash: 39afac2
category: Changed
---

# Rename scripts/ to sh/ in skills for brevity

## Overview

Rename the `scripts/` subdirectory to `sh/` in all skills for brevity and consistency. Also extract any inline shell commands from SKILL.md files into actual shell scripts to maintain reproducible manipulation.

Current structure: `plugins/core/skills/<name>/scripts/*.sh`
New structure: `plugins/core/skills/<name>/sh/*.sh`

## Key Files

- `plugins/core/skills/archive-ticket/scripts/` → `sh/`
- `plugins/core/skills/changelog/scripts/` → `sh/`
- `plugins/core/skills/story-metrics/scripts/` → `sh/`
- `plugins/core/skills/spec-context/scripts/` → `sh/`
- `plugins/core/skills/pr-ops/scripts/` → `sh/`

## Implementation Steps

1. Rename directories in each skill:
   ```bash
   git mv plugins/core/skills/archive-ticket/scripts plugins/core/skills/archive-ticket/sh
   git mv plugins/core/skills/changelog/scripts plugins/core/skills/changelog/sh
   git mv plugins/core/skills/story-metrics/scripts plugins/core/skills/story-metrics/sh
   git mv plugins/core/skills/spec-context/scripts plugins/core/skills/spec-context/sh
   git mv plugins/core/skills/pr-ops/scripts plugins/core/skills/pr-ops/sh
   ```

2. Update all references in SKILL.md files:
   - Change `scripts/archive.sh` → `sh/archive.sh`
   - Change `scripts/generate.sh` → `sh/generate.sh`
   - etc.

3. Update references in command files:
   - `plugins/core/commands/drive.md` references `archive-ticket/scripts/archive.sh`
   - Update path to `archive-ticket/sh/archive.sh`

4. Update references in `.workaholic/specs/developer-guide/architecture.md`:
   - Directory layout section shows `scripts/` subdirectories
   - Update to `sh/`

5. Update Japanese translation in `architecture_ja.md`

## Considerations

- The `.claude/` symlink path also changes (synced from plugins/)
- All 5 skills with scripts need updating
- Skills without scripts (translate, command-prohibition) are unaffected
- The naming `sh/` is shorter and clearly indicates shell scripts
