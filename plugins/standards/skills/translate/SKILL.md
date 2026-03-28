---
name: translate
description: Translation policies for converting English markdown files to other languages (primarily Japanese). Use when translating documentation or README files.
user-invocable: false
---

# Translation Policies

Guidelines for translating English markdown files to other languages while preserving formatting, code blocks, and technical terminology.

## Supported Languages

| Code | Language |
| ---- | -------- |
| ja   | Japanese |
| zh   | Chinese  |
| ko   | Korean   |
| de   | German   |
| fr   | French   |
| es   | Spanish  |

## Preservation Rules

**Preserve unchanged:**

- All code blocks (fenced and inline)
- Code comments inside code blocks
- Frontmatter keys (translate values only)
- File paths and URLs
- Markdown structure (headings, lists, tables)
- HTML tags and attributes

**Translate:**

- Prose content (paragraphs, list items)
- Frontmatter values (title, description)
- Table cell content (except code)
- Image alt text

## Technical Terms

**For developer documentation**: Keep technical terms in English without translation:

- plugin, command, skill, rule, ticket, workflow
- repository, branch, commit, merge, pull request
- Any programming concepts (function, class, module, etc.)

**For user-facing documentation**: May add annotations on first occurrence if it improves clarity:

```markdown
The plugin（プラグイン）system allows...
```

## Output Naming

Two patterns available:

1. **Suffix pattern**: `README.ja.md` (same directory)
2. **Directory pattern**: `ja/README.md` (parallel structure)

Default recommendation: suffix pattern for single files, directory pattern for multiple related files.

## Style Guide

**Tone:**

- Use formal/polite tone (です/ます for Japanese)
- Match the tone of the original document
- Documentation style, not conversational

**Accuracy:**

- Preserve original meaning over literal translation
- Technical accuracy is paramount
- When in doubt, keep English term with annotation

## Terms to Keep in English

These terms should remain in English (not translated) for developer documentation:

- **Core concepts**: plugin, command, skill, rule, ticket, workflow
- **Git terms**: repository, branch, commit, merge, pull request
- **Programming**: function, class, module, component, API, endpoint

## Example

Input (`README.md`):

```markdown
# My Plugin

This plugin provides workflow automation.

## Installation

Run the following command:

\`\`\`bash
npm install my-plugin
\`\`\`
```

Output (`README.ja.md`) for developer documentation:

```markdown
# My Plugin

この plugin は workflow の自動化を提供します。

## インストール

以下の command を実行してください：

\`\`\`bash
npm install my-plugin
\`\`\`
```

## .workaholic/ Translation Requirements

**CRITICAL RULE**: When creating or editing any `.md` file in `.workaholic/`, you MUST check the consumer project's root CLAUDE.md to determine the primary written language for `.workaholic/`, then produce translations accordingly.

**Decision logic:**

- If the primary language is English (or bilingual English/Japanese): produce `_ja.md` translations as counterparts
- If the primary language is Japanese only: do NOT produce `_ja.md` files (this would duplicate the primary content). Instead, produce `_en.md` translations if a secondary language is declared, or skip translations entirely
- If the primary language is another language: produce translations for declared secondary languages using the appropriate suffix

### File Naming for .workaholic/ (default: English primary)

Use suffix-based naming for translations:

```
.workaholic/specs/user-guide/
  commands.md           # Primary language
  commands_ja.md        # Japanese translation (when primary is English)
  README.md             # Primary language index
  README_ja.md          # Japanese index (when primary is English)
```

### Mirror README Link Structure

Each language's README must link to documents in the same language:

```
README.md:                              README_ja.md:
- [Getting Started](getting-started.md) - [はじめに](getting-started_ja.md)
- [Commands](commands.md)               - [コマンド](commands_ja.md)
```

### Workflow for .workaholic/

1. Create or update the primary language document first
2. Create or update the translation counterpart (if applicable per decision logic above)
3. Update all README files to maintain parallel link structure

### Enforcement

This is not optional. Every document change in `.workaholic/` requires its translation counterpart — when a translation target exists per the decision logic above.
