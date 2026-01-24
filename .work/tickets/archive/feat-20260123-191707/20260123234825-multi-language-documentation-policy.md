# Add Multi-Language Documentation Policy

## Overview

Add a policy to the core plugin's general rules that guides how documentation should be structured when a project needs to support multiple written languages. This addresses the common scenario where `CLAUDE.md` specifies a primary language but additional translations are needed.

## Key Files

- `plugins/core/rules/general.md` - Add the multi-language documentation policy here

## Implementation Steps

1. Add a new section "Multi-Language Documentation" to `plugins/core/rules/general.md` with the following policy:

### Recommended Structure

**For root-level READMEs (suffix-based approach):**

```
README.md           # Primary language (as specified in CLAUDE.md)
README_ja.md        # Japanese translation
README_zh.md        # Chinese translation
README_ko.md        # Korean translation
```

**For documentation directories (folder-based approach):**

```
docs/
  en/               # English (or primary language)
    README.md
    getting-started.md
  ja/               # Japanese
    README.md
    getting-started.md
```

### Policy Rules

1. **Primary README stays as `README.md`** - GitHub only displays `README.md` on the repository landing page. The primary language version must be `README.md`.

2. **Use underscore separator for root files** - Use `README_<lang>.md` format (e.g., `README_ja.md`) for consistency. This is the most common pattern in popular repositories.

3. **Use ISO 639-1 language codes** - Use standard two-letter codes: `ja` (Japanese), `zh` (Chinese), `ko` (Korean), `es` (Spanish), `fr` (French), `de` (German), etc.

4. **Add language navigation badges** - Include language selection badges at the top of each README linking to all available translations:

   ```markdown
   [English](README.md) | [日本語](README_ja.md) | [中文](README_zh.md)
   ```

5. **For large documentation sites, use folder-based structure** - When a project has many documentation files (>5), organize by language folders under `docs/`:

   - `docs/en/` for English
   - `docs/ja/` for Japanese
   - Each folder mirrors the same structure

6. **Keep translations in sync** - When updating primary documentation, note which translations need updating. Consider adding a comment at the top of translated files indicating the source file's last commit hash.

7. **Respect CLAUDE.md language setting** - The language specified in `CLAUDE.md` (e.g., "Written Language: English") determines:
   - Which language `README.md` should be in
   - The primary language for commit messages and PRs
   - Translations are supplementary, not primary

## Considerations

- **GitHub limitation**: GitHub doesn't auto-detect browser language for README display. Manual navigation is required.
- **Maintenance burden**: Each translation adds maintenance overhead. Only add translations when there's genuine need.
- **Translation accuracy**: Machine-translated docs should be reviewed by native speakers when possible.
- **File discovery**: The suffix approach (`README_ja.md`) keeps all READMEs visible in the root directory, making them easier to discover than nested folders.

## References

- [Multi-language README Pattern](https://github.com/jonatasemidio/multilanguage-readme-pattern) - Reference implementation
- [GitHub Discussion on i18n](https://github.com/orgs/community/discussions/50719) - Community discussion on README localization
- Popular projects using this pattern: [standard/standard](https://github.com/standard/standard), [erg-lang/erg](https://github.com/erg-lang/erg)

## Final Report

Development completed as planned.
