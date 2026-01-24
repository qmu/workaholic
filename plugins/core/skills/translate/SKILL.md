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
