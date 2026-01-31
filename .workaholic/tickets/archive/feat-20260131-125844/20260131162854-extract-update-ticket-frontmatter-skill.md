---
type: refactoring
layer: Config
effort: 0.25h
commit_hash: e7d9d00created_at: 2026-01-31T16:28:57+09:00
category: Changedauthor: a@qmu.jp
---

# Extract update-ticket-frontmatter Skill

## Overview

Extract a reusable `update-ticket-frontmatter` skill that handles updating ticket YAML frontmatter fields (effort, commit_hash, category). Currently this logic is scattered across `create-ticket` (field definitions), `archive.sh` (commit_hash/category updates via sed), and `write-final-report` (effort updates). Centralizing this enables consistent frontmatter manipulation across the codebase.

## Related History

| Ticket | Relevance |
|--------|-----------|
| [allow-skill-to-skill-nesting](todo/20260131153043-allow-skill-to-skill-nesting.md) | Enables skills to preload other skills |
| [split-drive-workflow-skill](todo/20260131153736-split-drive-workflow-skill.md) | Creates write-final-report skill that updates effort |
| [extract-agent-content-to-skills](../archive/feat-20260126-214833/20260127204529-extract-agent-content-to-skills.md) | Established skill extraction pattern |

## Key Files

| File | Purpose |
|------|---------|
| `plugins/core/skills/create-ticket/SKILL.md` | Defines frontmatter field schema |
| `plugins/core/skills/archive-ticket/sh/archive.sh` | Updates commit_hash/category via sed |
| `plugins/core/skills/write-final-report/SKILL.md` | Updates effort field (pending creation) |
| `plugins/core/hooks/validate-ticket.sh` | Validates frontmatter field formats |

## Implementation

### 1. Create update-ticket-frontmatter Skill

Create `plugins/core/skills/update-ticket-frontmatter/SKILL.md`:

```yaml
---
name: update-ticket-frontmatter
description: Update ticket YAML frontmatter fields (effort, commit_hash, category).
allowed-tools: Bash
user-invocable: false
---
```

Contents:
- Field definitions from create-ticket (effort, commit_hash, category)
- Valid values and formats for each field
- Update procedures (when to update each field)

### 2. Create Shell Script for Frontmatter Updates

Create `plugins/core/skills/update-ticket-frontmatter/sh/update.sh`:

```bash
#!/bin/sh -eu
# Update ticket frontmatter fields
# Usage: update.sh <ticket-path> <field> <value>

TICKET="$1"
FIELD="$2"
VALUE="$3"

if grep -q "^${FIELD}:" "$TICKET"; then
    sed -i.bak "s/^${FIELD}:.*/${FIELD}: ${VALUE}/" "$TICKET"
else
    # Insert after effort: line for commit_hash, after commit_hash: for category
    case "$FIELD" in
        commit_hash) sed -i.bak "/^effort:/a\\
${FIELD}: ${VALUE}" "$TICKET" ;;
        category) sed -i.bak "/^commit_hash:/a\\
${FIELD}: ${VALUE}" "$TICKET" ;;
        effort) sed -i.bak "/^layer:/a\\
${FIELD}: ${VALUE}" "$TICKET" ;;
    esac
fi
rm -f "${TICKET}.bak"
```

### 3. Update archive.sh to Use the New Script

Modify `archive-ticket/sh/archive.sh` to call the update script:

```bash
# Replace lines 70-84 with:
bash .claude/skills/update-ticket-frontmatter/sh/update.sh "$ARCHIVED_TICKET" "commit_hash" "$COMMIT_HASH"
bash .claude/skills/update-ticket-frontmatter/sh/update.sh "$ARCHIVED_TICKET" "category" "$CATEGORY"
```

### 4. Update write-final-report to Reference the Skill

In `write-final-report/SKILL.md`, add preload and reference:

```yaml
skills:
  - update-ticket-frontmatter
```

Update effort instructions to reference the script:

```bash
bash .claude/skills/update-ticket-frontmatter/sh/update.sh <ticket-path> effort "1h"
```

### 5. Extract Field Definitions from create-ticket

Move the "Filled After Implementation" section from `create-ticket/SKILL.md` to `update-ticket-frontmatter/SKILL.md`:

- effort: Valid values (0.1h, 0.25h, 0.5h, 1h, 2h, 4h)
- commit_hash: Format (short git hash)
- category: Values (Added, Changed, Removed) and verb mapping

Keep only a brief reference in create-ticket pointing to update-ticket-frontmatter for post-implementation fields.

## Verification

1. Verify update.sh correctly updates each field type
2. Verify archive.sh works with the new script calls
3. Verify write-final-report can use the skill for effort updates
4. Verify validate-ticket.sh still validates the same formats

## Final Report

Development completed as planned.
