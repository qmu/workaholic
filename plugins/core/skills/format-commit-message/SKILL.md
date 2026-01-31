---
name: format-commit-message
description: Structured commit message format with title, motivation, UX, and architecture sections.
user-invocable: false
---

# Format Commit Message

Structured commit message format for all commits.

## Format

```
<title>

Motivation: <why this change was needed>

UX Change: <what changed for the user>

Arch Change: <what changed for the developer>

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Title

Present-tense verb, what changed (50 chars max). No prefixes like `feat:` or `[fix]`.

Examples:
- Add session-based authentication
- Fix Mermaid slash character in labels
- Remove unused RegisterTool type

## Motivation

Why this change was needed. More than a sentence, but not a paragraph. Extract from ticket Overview.

## UX Change

What users will experience differently:
- New commands, options, or behaviors
- Changes to output format or error messages
- Write "None" if internal only

## Arch Change

What developers need to know:
- New files, components, or abstractions
- Modified interfaces or data structures
- Changes to workflow or component relationships
- Write "None" if no structural changes
