---
created_at: 2026-02-01T10:19:50+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: 360f49e
category: Changed
---

# Halt workflow when ticket frontmatter update fails

## Overview

The drive workflow must halt when ticket frontmatter update fails. Currently, if the Edit tool fails (e.g., PostToolUse hook error), the workflow continues to archive and commit the ticket without the required frontmatter updates.

## Key Files

- `plugins/core/skills/archive-ticket/SKILL.md` - Archive workflow that needs the guard

## Observed Behavior

1. Edit tool attempted to add `effort: small` to ticket frontmatter
2. Edit failed with "PostToolUse:Edit hook error"
3. Workflow ignored the failure and continued
4. Ticket was moved to archived/ without the effort field
5. Commit was created with incomplete ticket metadata

## Expected Behavior

1. Edit tool fails
2. Workflow detects the failure
3. Workflow halts and reports the error to user
4. User can fix the issue and retry
5. No archiving or committing until frontmatter update succeeds

## Implementation Steps

1. Update archive-ticket skill to explicitly verify Edit success before proceeding
2. Add instruction: if frontmatter update fails, abort and report error
3. Add instruction: never move ticket to archived/ unless all required fields are set
