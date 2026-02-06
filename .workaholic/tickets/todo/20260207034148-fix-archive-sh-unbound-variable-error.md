---
created_at: 2026-02-07T03:41:48+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category:
---

# Fix archive.sh unbound variable error on missing arguments

## Overview

`archive.sh` crashes with a cryptic `set -u` error (`$2: unbound variable` / `$2: 未割り当ての変数です`) when invoked with only the ticket path and without the other required positional arguments. The root cause is that lines 7-8 assign `$2` and `$3` directly under `set -eu` before the usage validation on line 14 can run. The fix is to use `${N:-}` default syntax for all positional parameters (matching the pattern already used in `commit.sh`), so that missing arguments produce the existing user-friendly usage message instead of a raw shell error.

Additionally, `update-ticket-frontmatter/sh/update.sh` has the same vulnerability on lines 7-9 and should be fixed in the same pass.

## Key Files

- `plugins/core/skills/archive-ticket/sh/archive.sh` - Primary bug: bare `$2`/`$3` assignments on lines 7-8 crash before usage check on line 14
- `plugins/core/skills/update-ticket-frontmatter/sh/update.sh` - Same pattern: bare `$1`/`$2`/`$3` on lines 7-9 crash before usage check on line 11
- `plugins/core/skills/commit/sh/commit.sh` - Reference implementation: already uses `${1:-}`/`${2:-}` pattern correctly on lines 20-23
- `plugins/core/skills/archive-ticket/SKILL.md` - Documents the expected 6-argument invocation

## Related History

Archive.sh has been a frequent source of invocation bugs, with multiple past tickets fixing path references and argument hallucinations.

Past tickets that touched similar areas:

- [20260131225833-fix-archive-script-invocation-hallucination.md](.workaholic/tickets/archive/drive-20260131-223656/20260131225833-fix-archive-script-invocation-hallucination.md) - Fixed Claude hallucinating wrong invocation paths for archive.sh (same script)
- [20260204180858-create-commit-skill.md](.workaholic/tickets/archive/drive-20260204-160722/20260204180858-create-commit-skill.md) - Extracted commit.sh from archive.sh, which established the correct `${N:-}` pattern (same layer)
- [20260129101447-fix-archive-script-path-reference.md](.workaholic/tickets/archive/main/20260129101447-fix-archive-script-path-reference.md) - Fixed archive.sh path reference in drive-workflow (same script)
- [20260131145539-structured-commit-messages.md](.workaholic/tickets/archive/feat-20260131-125844/20260131145539-structured-commit-messages.md) - Added motivation/ux-change/arch-change parameters to archive.sh (same script parameters)

## Implementation Steps

1. In `archive.sh`, change lines 6-8 from bare positional assignments to `${N:-}` defaults:
   - `TICKET="${1:-}"` (line 6 already correct: `TICKET="$1"` would fail but `$1` is always passed; still best practice to use `${1:-}`)
   - `COMMIT_MSG="${2:-}"` (line 7: this is the crash site)
   - `REPO_URL="${3:-}"` (line 8: also crashes when missing)

2. Extend the existing usage check on line 14 to also validate `REPO_URL`:
   - Currently checks `TICKET` and `COMMIT_MSG` but not `REPO_URL`
   - Add `REPO_URL` to the condition for a complete guard

3. In `update.sh`, apply the same fix to lines 7-9:
   - `TICKET="${1:-}"`, `FIELD="${2:-}"`, `VALUE="${3:-}"`
   - The existing check on line 11 already validates all three, so just the assignment lines need changing

4. Verify no other shell scripts in `plugins/core/skills/*/sh/*.sh` have the same bare-assignment pattern under `set -eu`

## Patches

### `plugins/core/skills/archive-ticket/sh/archive.sh`

```diff
--- a/plugins/core/skills/archive-ticket/sh/archive.sh
+++ b/plugins/core/skills/archive-ticket/sh/archive.sh
@@ -3,13 +3,13 @@

 set -eu

-TICKET="$1"
-COMMIT_MSG="$2"
-REPO_URL="$3"
+TICKET="${1:-}"
+COMMIT_MSG="${2:-}"
+REPO_URL="${3:-}"
 MOTIVATION="${4:-}"
 UX_CHANGE="${5:-None}"
 ARCH_CHANGE="${6:-None}"
 shift 6 2>/dev/null || true

-if [ -z "$TICKET" ] || [ -z "$COMMIT_MSG" ]; then
+if [ -z "$TICKET" ] || [ -z "$COMMIT_MSG" ] || [ -z "$REPO_URL" ]; then
     echo "Usage: archive.sh <ticket-path> <commit-message> <repo-url> [motivation] [ux-change] [arch-change] [files...]"
```

### `plugins/core/skills/update-ticket-frontmatter/sh/update.sh`

```diff
--- a/plugins/core/skills/update-ticket-frontmatter/sh/update.sh
+++ b/plugins/core/skills/update-ticket-frontmatter/sh/update.sh
@@ -4,9 +4,9 @@

 set -eu

-TICKET="$1"
-FIELD="$2"
-VALUE="$3"
+TICKET="${1:-}"
+FIELD="${2:-}"
+VALUE="${3:-}"

 if [ -z "$TICKET" ] || [ -z "$FIELD" ] || [ -z "$VALUE" ]; then
     echo "Usage: update.sh <ticket-path> <field> <value>"
```

## Considerations

- The `#!/bin/sh -eu` shebang on line 1 of `archive.sh` and `update.sh` redundantly sets `-eu` before the explicit `set -eu` on line 4; this is harmless but worth noting (`plugins/core/skills/archive-ticket/sh/archive.sh` line 1)
- `commit.sh` already handles this correctly via `${1:-}` pattern, confirming this is the established codebase convention (`plugins/core/skills/commit/sh/commit.sh` lines 20-23)
- Other scripts like `check.sh` and `gather.sh` do not take user-supplied positional args so are not affected by this class of bug (`plugins/core/skills/manage-branch/sh/check.sh`)
