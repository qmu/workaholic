---
created_at: 2026-02-01T10:07:37+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Reject Anthropic Email in Ticket Author Field

## Overview

Despite previous fixes to the `create-ticket` skill with explicit instructions to run `git config user.email`, Claude still occasionally uses `noreply@anthropic.com` as the author field. The current validation hook only checks for valid email format, which `noreply@anthropic.com` passes. Need to add explicit rejection of this email to force Claude to use the actual user's git email.

## Key Files

- `plugins/core/hooks/validate-ticket.sh` - Lines 97-109 validate author as email format but don't reject anthropic.com
- `plugins/core/skills/create-ticket/SKILL.md` - Already has explicit instructions (Step 1) but Claude ignores them

## Related History

Previous fix attempted to make instructions more explicit but didn't solve the underlying issue because format validation still passes.

Past tickets that touched similar areas:

- [20260131142943-use-git-email-for-ticket-author.md](.workaholic/tickets/archive/feat-20260131-125844/20260131142943-use-git-email-for-ticket-author.md) - Added explicit Step 1 instructions (same issue, incomplete fix)
- [20260131162854-extract-update-ticket-frontmatter-skill.md](.workaholic/tickets/archive/feat-20260131-125844/20260131162854-extract-update-ticket-frontmatter-skill.md) - Ticket frontmatter manipulation utilities

## Implementation

1. **Update validate-ticket.sh** to explicitly reject anthropic.com emails:
   - After line 104's email format validation passes, add a check
   - If author contains `@anthropic.com`, fail with error message
   - Error message: "Error: author must be your actual email from 'git config user.email', not noreply@anthropic.com"

2. **Implementation detail**:
   ```bash
   # After email format validation (around line 109)
   if [[ "$author" =~ @anthropic\.com$ ]]; then
     echo "Error: author must be your actual email from 'git config user.email'" >&2
     echo "Rejected: $author (run 'git config user.email' and use that value)" >&2
     print_skill_reference
     exit 2
   fi
   ```

## Considerations

- This is a blocklist approach - if there are other common AI placeholder emails, they could be added later
- Could alternatively use an allowlist approach requiring the email to match `git config user.email`, but that's more complex and may fail in edge cases
- The blocklist is simpler and directly addresses the known problem
