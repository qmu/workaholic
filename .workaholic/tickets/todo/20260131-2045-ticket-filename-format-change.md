---
created_at: 2026-01-31T20:45:00+09:00
author: tamurayoshiya@gmail.com
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Change Ticket Filename Convention to YYYYMMDD-HHMM Format

## Overview

Change the ticket filename convention from `YYYYMMDDHHmmss-name.md` (14 digits) to `YYYYMMDD-HHMM-name.md` (8+4 digits with hyphens). The new format is more readable while maintaining chronological sorting.

## Motivation

Current format `20260131204500-add-feature.md` is hard to parse visually. The proposed format `20260131-2045-add-feature.md` separates date from time with a hyphen, making it easier to identify when a ticket was created at a glance.

## Key Files

- `plugins/core/hooks/validate-ticket.sh` - Update regex pattern (line 43)
- `plugins/core/skills/create-ticket/SKILL.md` - Update filename convention documentation

## Related History

- [20260128002853-extract-create-ticket-skill.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002853-extract-create-ticket-skill.md) - Established current filename convention

## Implementation

### 1. Update Validation Hook

Modify `plugins/core/hooks/validate-ticket.sh` line 43:

```bash
# Old pattern: 14 digits
if [[ ! "$filename" =~ ^[0-9]{14}-.*\.md$ ]]; then

# New pattern: 8 digits, hyphen, 4 digits, hyphen
if [[ ! "$filename" =~ ^[0-9]{8}-[0-9]{4}-.*\.md$ ]]; then
```

Update error message (line 44-45):
```bash
echo "Error: Ticket filename must match YYYYMMDD-HHMM-*.md pattern" >&2
```

### 2. Update Create-Ticket Skill

Modify `plugins/core/skills/create-ticket/SKILL.md`:

**Filename Convention section** (~line 77-83):
```markdown
## Filename Convention

Format: `YYYYMMDD-HHMM-<short-description>.md`

Use current timestamp: `date +%Y%m%d-%H%M`

Example: `20260131-2045-add-dark-mode.md`
```

**File Structure example** (~line 85-96):
Update example filename in the template to use new format.

### 3. Update Frontmatter Script (if needed)

If `plugins/core/skills/create-ticket/sh/frontmatter.sh` outputs filename suggestions, update to use new format.

## Verification

1. Create a new ticket and verify filename matches `YYYYMMDD-HHMM-*.md`
2. Verify validation hook accepts new format
3. Verify validation hook rejects old 14-digit format

## Notes

- Existing tickets with old format remain valid in archive (no migration needed)
- This ticket itself uses the new format as proof of concept
