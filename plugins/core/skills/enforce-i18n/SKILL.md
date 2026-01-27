---
name: enforce-i18n
description: i18n requirements for .workaholic/ documentation.
user-invocable: false
---

# i18n for .workaholic/

**CRITICAL RULE**: When creating or editing any `.md` file in `.workaholic/`, you MUST also create or update the corresponding `_ja.md` translation.

## File Naming

Use suffix-based naming for translations:

```
.workaholic/specs/user-guide/
  commands.md           # English
  commands_ja.md        # Japanese translation
  README.md             # English index
  README_ja.md          # Japanese index
```

## Mirror README Link Structure

Each language's README must link to documents in the same language:

```
README.md:                              README_ja.md:
- [Getting Started](getting-started.md) - [はじめに](getting-started_ja.md)
- [Commands](commands.md)               - [コマンド](commands_ja.md)
```

## Workflow

1. Create or update the English document first
2. Create or update the Japanese translation (`_ja.md`)
3. Update BOTH README.md and README_ja.md to maintain parallel link structure

## Enforcement

This is not optional. Every document change in `.workaholic/` requires its translation counterpart.
