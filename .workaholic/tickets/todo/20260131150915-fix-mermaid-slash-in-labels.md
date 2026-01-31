---
type: bugfix
layer: Config
effort: 0.25h
created_at: 2026-01-31T15:09:27+09:00
author: a@qmu.jp
---

# Fix Mermaid Slash Character in Node Labels

## Overview

GitHub's Mermaid renderer fails to parse node labels containing `/` characters. The dependency graph in `architecture.md` uses labels like `story[/story]` which causes a lexical error on GitHub. Fix by quoting the labels to escape the special character.

## Related History

| Ticket | Relevance |
|--------|-----------|
| [fix-mermaid-diagram-in-workflow-ja](../archive/feat-20260129-023941/20260129024255-fix-mermaid-diagram-in-workflow-ja.md) | Previously fixed Mermaid escaping issues in Japanese workflow guide |

## Key Files

| File | Purpose |
|------|---------|
| `.workaholic/specs/architecture.md` | Contains dependency graph with `/story`, `/drive`, `/ticket` labels |
| `.workaholic/specs/architecture_ja.md` | Japanese translation with same diagram |

## Implementation

### 1. Fix Node Labels in architecture.md

Change unquoted labels to quoted labels in the dependency graph (around line 159-161):

**Before:**
```mermaid
subgraph Commands
    story[/story]
    drive[/drive]
    ticket[/ticket]
end
```

**After:**
```mermaid
subgraph Commands
    story["/story"]
    drive["/drive"]
    ticket["/ticket"]
end
```

### 2. Apply Same Fix to architecture_ja.md

Apply identical changes to the Japanese translation.

## Verification

1. View the raw markdown on GitHub
2. Confirm the Mermaid diagram renders without lexical errors
3. Verify node labels display correctly with the `/` prefix
