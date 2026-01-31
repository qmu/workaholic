---
name: archive-ticket
description: Complete commit workflow - format, archive, update changelog, and commit in one operation.
allowed-tools: Bash
user-invocable: false
---

# Archive Ticket

Complete commit workflow after user approves implementation. Always use this script - never manually move tickets.

## Usage

```bash
bash .claude/skills/archive-ticket/sh/archive.sh \
  <ticket-path> "<title>" <repo-url> "<motivation>" "<ux-change>" "<arch-change>"
```

## Commit Message Format

```
<title>

Motivation: <why this change was needed>

UX Change: <what changed for the user>

Arch Change: <what changed for the developer>

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Title

Present-tense verb, what changed (50 chars max). No prefixes like `feat:` or `[fix]`.

### Motivation

Why this change was needed. Extract from ticket Overview. More than a sentence, but not a paragraph.

### UX Change

What users will experience differently. New commands, options, output changes. Write "None" if internal only.

### Arch Change

What developers need to know. New files, modified interfaces, workflow changes. Write "None" if no structural changes.

## Example

```
Add structured commit message format

Motivation: Commit messages lacked structured sections for UX and architecture changes, making it harder to generate documentation and understand impact at a glance.

UX Change: None

Arch Change: Extended archive.sh to accept motivation, ux-change, and arch-change parameters. Commit messages now include labeled sections.

Co-Authored-By: Claude <noreply@anthropic.com>
```
