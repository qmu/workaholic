---
name: archive-ticket
description: Complete commit workflow - format, archive, update changelog, and commit in one operation.
skills:
  - format-commit-message
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

Follow the preloaded **format-commit-message** skill for message format.

## Example

```
Add structured commit message format

Motivation: Commit messages lacked structured sections for UX and architecture changes, making it harder to generate documentation and understand impact at a glance.

UX Change: None

Arch Change: Extended archive.sh to accept motivation, ux-change, and arch-change parameters. Commit messages now include labeled sections.

Co-Authored-By: Claude <noreply@anthropic.com>
```
