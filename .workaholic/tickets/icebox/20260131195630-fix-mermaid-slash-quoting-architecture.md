---
type: bugfix
effort: 0.1h
created_at: 2026-01-31T19:56:33+09:00
author: a@qmu.jp
---

# Fix Mermaid Slash Character Quoting in Architecture Diagram

## Overview

The `/story` command dependency diagram in `architecture.md` has an unquoted node label containing a forward slash, causing GitHub to fail rendering with a lexical error:

```
Lexical error on line 2. Unrecognized text.
... A[/story command] --> B[Move remaini
-----------------------^
```

The existing `diagrams.md` rule correctly specifies that labels containing `/` must be quoted, but this diagram violates that rule.

## Root Cause

In the "How It Works" section of `architecture.md`, line 315:
```mermaid
A[/story command] --> B[Move remaining tickets to icebox]
```

The `/story command` label is NOT quoted. Mermaid interprets the unquoted `/` as syntax rather than literal text.

## Solution

Quote the label containing the slash:
```mermaid
A["/story command"] --> B[Move remaining tickets to icebox]
```

Also update the Japanese translation `architecture_ja.md` with the same fix.

## Key Files

- `.workaholic/specs/architecture.md` - Line 315, unquoted `/story command` label
- `.workaholic/specs/architecture_ja.md` - Same diagram needs same fix
- `plugins/core/rules/diagrams.md` - Existing rule (lines 36-44) already correctly specifies quoting

## Implementation

1. Edit `architecture.md` line 315:
   - Change `A[/story command]` to `A["/story command"]`

2. Edit `architecture_ja.md` with the same fix

## Related History

- `20260131150915-fix-mermaid-slash-in-labels.md` - Previous fix for same issue in command dependency diagrams
- `20260129024255-fix-mermaid-diagram-in-workflow-ja.md` - Similar slash escaping fix in workflow guide
- `20260124120158-enforce-mermaid-for-diagrams.md` - Established Mermaid as the standard for all diagrams
