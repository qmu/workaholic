---
name: archive-ticket
description: Archive ticket workflow - move ticket, delegate commit to commit skill, update frontmatter.
skills:
  - commit
allowed-tools: Bash
user-invocable: false
---

# Archive Ticket

Complete commit workflow after user approves implementation. Always use this script - never manually move tickets.

## Prerequisites

**CRITICAL**: Before calling the archive script, verify that all required frontmatter fields have been successfully updated:

1. **Verify effort field**: The ticket MUST have a valid `effort:` value (e.g., `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`)
2. **Abort on failure**: If frontmatter update failed (e.g., Edit tool error), **DO NOT proceed with archiving**
3. **Report the error**: Inform the user that frontmatter update failed and the ticket cannot be archived

**Never archive a ticket without all required frontmatter fields.**

## Usage

```bash
bash plugins/core/skills/archive-ticket/sh/archive.sh \
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
