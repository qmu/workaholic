---
type: enhancement
layer: Config
effort: 0.5h
commit_hash: 4958399created_at: 2026-01-31T15:05:20+09:00
category: Addedauthor: a@qmu.jp
---

# Add Structured Commit Message Format

## Overview

Enhance commit messages created during `/drive` to include structured sections beyond title and description. The new format will include UX changes (user perspective for user guide updates) and architecture changes (developer perspective for specs updates), enabling better documentation generation and clearer change communication.

## Related History

| Ticket | Relevance |
|--------|-----------|
| [auto-commit-ticket-on-creation](../archive/feat-20260124-200439/20260125113858-auto-commit-ticket-on-creation.md) | Established commit message format: present-tense verbs, no prefixes |
| [extract-drive-ticket-skills](../archive/feat-20260126-214833/20260127100902-extract-drive-ticket-skills.md) | Extracted drive-workflow skill where commit messages are specified |
| [eliminate-branch-changelogs](../archive/feat-20260124-200439/20260124223106-eliminate-branch-changelogs.md) | Moved change metadata to ticket frontmatter; commit message feeds changelog |

## Key Files

| File | Purpose |
|------|---------|
| `plugins/core/skills/archive-ticket/SKILL.md` | Documents commit message rules and description format |
| `plugins/core/skills/archive-ticket/sh/archive.sh` | Creates commits with message and Co-Authored-By footer |
| `plugins/core/skills/drive-workflow/SKILL.md` | Instructs how to prepare commit message and description |

## Implementation

### 1. Extend Commit Message Structure

Update `archive-ticket/SKILL.md` to document the new structured format:

**Current format:**
```
<title>

Co-Authored-By: Claude <noreply@anthropic.com>
```

**New format:**
```
<title>

<detail>

UX: <ux-changes>
Arch: <arch-changes>

Co-Authored-By: Claude <noreply@anthropic.com>
```

Where:
- `<title>`: Present-tense verb, what changed (50 chars max) - existing
- `<detail>`: 1-2 sentences explaining why - replaces current "description"
- `<ux-changes>`: User-facing changes, for user guide updates (1 line)
- `<arch-changes>`: Developer-facing changes, for specs updates (1 line)

### 2. Update archive.sh Script

Modify `archive-ticket/sh/archive.sh` to accept new parameters:

**Current signature:**
```bash
archive.sh <ticket-path> <commit-message> <repo-url> [description] [files...]
```

**New signature:**
```bash
archive.sh <ticket-path> <commit-message> <repo-url> [detail] [ux-changes] [arch-changes] [files...]
```

Update the commit creation (around line 60-62) to format the multi-section message.

### 3. Update drive-workflow Skill

Modify `drive-workflow/SKILL.md` section "5. Commit and Archive Using Skill":

- Document the new parameters
- Add guidance on deriving UX and architecture changes from implementation
- Provide examples of good UX/Arch descriptions

### 4. Add Guidelines for UX and Arch Descriptions

**UX Changes** (user perspective):
- What the user will see or experience differently
- New commands, options, or behaviors
- Changes to output format or error messages
- Write "None" if no user-facing changes

**Architecture Changes** (developer perspective):
- New files, components, or abstractions introduced
- Modified interfaces or data structures
- Changes to workflow or component relationships
- Write "None" if no architectural changes

### 5. Update Existing Guidelines

Ensure `archive-ticket/SKILL.md` examples reflect the new format:

```
Add structured commit message format

Enables better documentation by capturing UX and architecture changes
in each commit, making user guide and specs updates easier to derive.

UX: None
Arch: Extended archive.sh with ux-changes and arch-changes parameters

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Verification

1. Run `/drive` on a test ticket
2. Verify commit message contains all four sections (title, detail, UX, Arch)
3. Verify `git log --format="%B"` shows properly formatted messages
4. Verify empty UX/Arch values display as "None"

## Final Report

Development completed as planned.
