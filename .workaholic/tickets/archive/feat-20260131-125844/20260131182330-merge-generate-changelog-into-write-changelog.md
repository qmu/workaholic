---
type: refactoring
layer: Config
effort: 0.5h
commit_hash: ca9c772created_at: 2026-01-31T18:23:34+09:00
category: Changedauthor: a@qmu.jp
---

# Merge generate-changelog into write-changelog

## Overview

Consolidate the `generate-changelog` skill into `write-changelog` to reduce skill fragmentation. Currently these two skills are always used together (write-changelog references generate-changelog's script), and the changelog-writer agent preloads both. Merging them follows the established pattern of consolidating 1:1 paired skills into single comprehensive skills.

## Related History

| Ticket | Relevance |
|--------|-----------|
| [merge-enforce-i18n-into-translate](../archive/feat-20260128-001720/20260128002918-merge-enforce-i18n-into-translate.md) | Same pattern: merging related skills to reduce fragmentation |
| [extract-agent-content-to-skills](../archive/feat-20260126-214833/20260127204529-extract-agent-content-to-skills.md) | Created both skills; established comprehensive skill pattern |
| [extract-changelog-skill](../archive/feat-20260126-214833/20260127020640-extract-changelog-skill.md) | Original extraction of generate-changelog skill |

## Key Files

| File | Purpose |
|------|---------|
| `plugins/core/skills/generate-changelog/SKILL.md` | Entry generation skill (to be merged) |
| `plugins/core/skills/generate-changelog/sh/generate.sh` | Script to move |
| `plugins/core/skills/write-changelog/SKILL.md` | Target skill for merge |
| `plugins/core/agents/changelog-writer.md` | Agent preloading both (to update) |

## Implementation

### 1. Move generate.sh to write-changelog

Move the bash script:
```bash
mv plugins/core/skills/generate-changelog/sh/ plugins/core/skills/write-changelog/
```

### 2. Merge Content into write-changelog/SKILL.md

Expand `write-changelog/SKILL.md` to include all content from both skills:

```yaml
---
name: write-changelog
description: Generate changelog entries from archived tickets and update CHANGELOG.md.
allowed-tools: Bash
user-invocable: false
---
```

Sections:
1. Generate Entries (run the script, output format, entry format details)
2. Derive Issue URL (from branch name)
3. Update CHANGELOG.md (section structure, linking)
4. Verify Structure (proper formatting)

Update script path reference:
```bash
bash .claude/skills/write-changelog/sh/generate.sh <branch-name> <repo-url>
```

### 3. Delete generate-changelog Skill

Remove the entire directory:
```bash
rm -rf plugins/core/skills/generate-changelog/
```

### 4. Update changelog-writer Agent

Modify `plugins/core/agents/changelog-writer.md` frontmatter:

**Before:**
```yaml
skills:
  - write-changelog
  - generate-changelog
```

**After:**
```yaml
skills:
  - write-changelog
```

### 5. Update Documentation

Update any references in `.workaholic/specs/` that mention generate-changelog:
- `architecture.md` dependency diagram
- `command-flows.md` component tables

## Verification

1. Verify generate-changelog directory is deleted
2. Verify write-changelog contains merged content and generate.sh script
3. Verify changelog-writer agent only preloads write-changelog
4. Run `/story` to verify changelog generation still works
