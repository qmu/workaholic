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

> **CRITICAL: NEVER manually archive tickets.** Do not use `mv` + `git add` + `git commit` to move
> tickets from `todo/` to `archive/`. The `archive.sh` script is the ONLY authorized method.
> Manual moves cause unstaged deletions because agents forget to stage the old path.

## Prerequisites

**CRITICAL**: Before calling the archive script, verify that all required frontmatter fields have been successfully updated:

1. **Verify effort field**: The ticket MUST have a valid `effort:` value (e.g., `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`)
2. **Abort on failure**: If frontmatter update failed (e.g., Edit tool error), **DO NOT proceed with archiving**
3. **Report the error**: Inform the user that frontmatter update failed and the ticket cannot be archived

**Never archive a ticket without all required frontmatter fields.**

## Usage

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/archive-ticket/sh/archive.sh \
  <ticket-path> "<title>" <repo-url> "<description>" "<changes>" "<test-plan>" "<release-prep>"
```

Follow the **commit** skill's Message Format section for message format.

## Example

```
Add structured commit message format

Description: Commit messages lacked structured sections for downstream lead agents, making it harder to generate documentation and understand impact at a glance. Lead agents (test-lead, delivery-lead, security-lead) need to judge what is required to ship each change without reading the full diff. Restructured the format from three sections (Motivation, UX Change, Arch Change) to five well-scoped sections that give each lead enough signal to act.

Changes: None -- this is an internal change to commit message format templates. The CLI behavior, command interfaces, and user-facing output remain identical.

Test Planning: Verified commit.sh produces correctly labeled sections with all five parameters by running the script with sample inputs. Confirmed empty description fields are handled gracefully (Description section omitted when empty). Checked that archive.sh passes all seven positional arguments correctly to commit.sh.

Release Preparation: None -- backward-compatible change to message format. Existing lead agents consume commit messages as free text and will parse the new section labels automatically.

Co-Authored-By: Claude <noreply@anthropic.com>
```
