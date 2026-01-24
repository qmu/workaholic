# i18n Documentation in .work/

Rules for maintaining i18n (internationalized) documentation within the `.work/` directory.

**Applies to:** `.work/` directory only

## Mirror README Link Structure

Each language's README must link to documents in the same language:

- If `README.md` links to `getting-started.md`, then `README_ja.md` must link to `getting-started_ja.md`
- When creating a translated document, ALWAYS update the corresponding language README
- The link structure must be identical between READMEs (same sections, same order)

Example parallel structure:

```
README.md:                              README_ja.md:
- [Getting Started](getting-started.md) - [はじめに](getting-started_ja.md)
- [Commands](commands.md)               - [コマンド](commands_ja.md)
```

## File Naming

Use suffix-based naming for translations within `.work/`:

```
.work/specs/user-guide/
  commands.md           # English
  commands_ja.md        # Japanese translation
  README.md             # English index
  README_ja.md          # Japanese index
```

## Workflow

When creating or updating documentation in `.work/`:

1. Create/update the primary language document
2. If a translated version exists, update it too (or mark as needing update)
3. Update BOTH language READMEs to maintain parallel link structure
