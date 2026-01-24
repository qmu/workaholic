# Split general.md by Topics

## Overview

`plugins/core/rules/general.md` (113 lines) mixes 3 unrelated topics:
1. **Git workflow** (2 rules) - commit permission, no `git -C`
2. **Multi-language documentation** (~50 lines) - file structure, policies
3. **Diagram standards** (~60 lines) - Mermaid requirements, examples

This large generic file doesn't work reliably - Claude may not load/apply all rules consistently when they're bundled together.

## Final Structure

```
plugins/core/rules/
├── general.md      # Only git rules (2 lines)
├── diagrams.md     # NEW: Mermaid requirements
├── i18n.md         # NEW: Merged multi-lang rules
└── typescript.md   # Unchanged
```

## Implementation Steps

### 1. Create `rules/diagrams.md`

Extract content from `general.md` lines 56-112 (the Diagrams section).

**Add path-specific frontmatter:**
```yaml
---
paths:
  - "**/*.md"
---
```

### 2. Create `rules/i18n.md`

Merge two sources:
- General multi-language documentation (`general.md` lines 6-54)
- `.work/` specific rules (from `i18n-work-docs.md`) with clear section header

**Add path-specific frontmatter:**
```yaml
---
paths:
  - "**/README*.md"
  - ".work/**/*.md"
  - "docs/**/*.md"
---
```

### 3. Trim `rules/general.md`

Keep only git rules with path-specific frontmatter:
```markdown
---
paths:
  - "**/*"
---

# General Rules

- **Never commit without permission** - Always ask for confirmation before creating any git commit
- **Never use `git -C`** - Run git commands from the working directory, not with `-C` flag
```

### 4. Delete `rules/i18n-work-docs.md`

Content moved to `i18n.md`.

### 5. Update `commands/sync-src-doc.md`

Line 240: change `i18n-work-docs.md` → `i18n.md`

## Verification

1. `ls plugins/core/rules/` shows: `diagrams.md`, `general.md`, `i18n.md`, `typescript.md`
2. `wc -l plugins/core/rules/general.md` shows ~5 lines
3. `grep i18n plugins/core/commands/sync-src-doc.md` references `i18n.md`

## Final Report

Implementation deviated from original plan:

- **Change**: Added path-specific frontmatter to all rule files
  **Reason**: Rules need `paths:` frontmatter to specify when they apply, following the pattern of `typescript.md`
