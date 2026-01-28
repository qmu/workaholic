---
created_at: 2026-01-29T02:42:55+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.25h
commit_hash: 016f4c5
category: Changed
---

# Fix Mermaid Diagram in workflow_ja.md

## Overview

The Mermaid diagram in `.workaholic/guides/workflow_ja.md` fails to render on GitHub with a lexical error. The error occurs because forward slashes (`/`) in node labels (representing slash commands like `/branch`, `/ticket`, `/drive`) are interpreted as special Mermaid syntax characters.

## Problem

GitHub reports:
```
Lexical error on line 2. Unrecognized text.
...[機能開始] --> B[/branch] B --> C[/ticke
-----------------------^
```

The `/` character inside square brackets is being parsed as Mermaid's special syntax rather than literal text.

## Solution

Escape or quote the slash command text in node labels. Mermaid supports using quotes inside brackets to treat content as literal text:

```mermaid
A["機能開始"] --> B["/branch"]
```

Alternatively, use HTML entities or different bracket styles that Mermaid handles better.

## Key Files

| File | Action |
|------|--------|
| `.workaholic/guides/workflow_ja.md` | Update Mermaid diagram node labels |

## Implementation Steps

1. Open `.workaholic/guides/workflow_ja.md`
2. Locate the Mermaid flowchart (lines 23-35)
3. Wrap node labels containing `/` in double quotes:
   - `B[/branch]` → `B["/branch"]`
   - `C[/ticket description]` → `C["/ticket description"]`
   - `E[/drive]` → `E["/drive"]`
   - `G[/report]` → `G["/report"]`
4. Also quote Japanese text nodes to ensure consistency:
   - `A[機能開始]` → `A["機能開始"]`
   - `D{仕様レビュー}` → `D{"仕様レビュー"}`
   - `F{チケット追加?}` → `F{"チケット追加?"}`
   - `H[コードレビュー]` → `H["コードレビュー"]`
   - `I[マージ]` → `I["マージ"]`
5. Verify the diagram renders correctly

## Testing

- View the file on GitHub to confirm the Mermaid diagram renders without errors
- Alternatively, use a local Mermaid preview tool or VS Code extension

## Related History

Historical tickets reveal Mermaid diagrams are enforced as the standard for all diagrams in this project. A previous ticket simplified topic tree diagrams from complex mindmap syntax to basic flowcharts for better maintainability. The documentation structure was recently flattened, moving user guides to `.workaholic/guides/`.

Key references:
- `enforce-mermaid-for-diagrams.md`: Foundational policy requiring Mermaid for all diagrams
- `simplify-topic-tree-as-journey-reference.md`: Demonstrates Mermaid simplification practices
- `flatten-specs-directory-structure.md`: Moved workflow guides to current location

## Final Report

Fixed both workflow.md and workflow_ja.md diagrams. Also added Node Labels section to diagrams rule documenting the quoting requirement.
