---
created_at: 2026-06-13T09:02:09+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Config]
effort:
commit_hash:
category:
depends_on:
---

# Per-User Subdirectories Under tickets/todo

## Overview

Partition the active ticket queue by developer: new tickets are written to `.workaholic/tickets/todo/<user>/` instead of the flat `todo/` root, where `<user>` is a filesystem-safe slug derived from `git config user.email`. During ticket creation (and at the start of `/drive`), any leftover tickets sitting directly at the `todo/` root are swept into a user subdirectory — routed by each stray ticket's `author:` frontmatter, so another developer's stranded tickets land in *their* subdirectory, not the current user's.

This fixes a multi-developer leak: developers merge branches into main with unarchived tickets still in `todo/`, and the next developer who branches from main inherits those tickets and `/drive` processes them again. The current workaround — manually moving strays to the icebox — is exactly the bad DX this removes (and git history shows repeated "Move remaining tickets to icebox" commits). With per-user subdirectories, `/drive` and the `/ship` todo-clean guard scope to the current user's subdirectory only, so other developers' leftovers are invisible rather than something to clean up.

Design decisions (derived from the request's rationale):

- **Stray routing is by `author:` frontmatter**, falling back to the current user's subdirectory when the field is missing or unparseable. Routing strays into the *current* user's subdirectory would re-create the leak the feature exists to fix.
- **`/drive`'s queue scan and `/ship`'s guard see only `todo/<current-user>/`.** Without this scoping, recursive scans would still pick up other users' tickets and nothing is solved.
- **The icebox stays flat.** The request targets `todo/` only; icebox tickets are deliberately parked and carry no same-branch double-processing risk. `promote-icebox.sh` promotes into the current user's `todo/<user>/`.
- **The user slug is the full email, lowercased, with every non-`[a-z0-9]` character replaced by `-`** (e.g. `a@qmu.jp` → `a-qmu-jp`). Using the full email instead of the local part avoids collisions between `a@qmu.jp` and `a@example.com`.

## Key Files

- `plugins/core/skills/gather/scripts/ticket-metadata.sh` - Already emits `author`; add a `user_slug` field so create-ticket can build the write path.
- `plugins/core/skills/gather/scripts/user-slug.sh` - **New** shared slug derivation (`user-slug.sh [email]`, defaults to `git config user.email`); called by every script below the way `archive.sh` already calls the cross-skill `commit.sh`.
- `plugins/core/skills/create-ticket/SKILL.md` - Write path and Allowed Locations change to `todo/<user>/`; new workflow step invoking the sweep.
- `plugins/core/skills/create-ticket/scripts/sweep-todo.sh` - **New** sweep: move each root-level `todo/*.md` into `todo/<author-slug>/`, git-staging every move immediately.
- `plugins/core/skills/drive/scripts/list-todo.sh` - `find todo -maxdepth 1` must become a scan of `todo/<current-user>/`; today it would silently miss nested tickets.
- `plugins/core/skills/drive/scripts/archive.sh` - `TICKETS_ROOT` derivation (`sed 's|/todo$||'`) breaks on `todo/<user>/` paths; must strip the optional user segment. Archive destination stays flat at `archive/<branch>/`.
- `plugins/core/skills/drive/scripts/promote-icebox.sh` - Destination becomes the current user's `todo/<user>/`.
- `plugins/core/skills/drive/SKILL.md` - Phase 1 runs the sweep before listing; prose references to the flat queue updated.
- `plugins/core/skills/ship/scripts/check-todo.sh` - Pre-merge guard currently recurses over all of `todo/`; scope the blocking check to `todo/<current-user>/` (root-level strays may be reported informationally but no longer block).
- `plugins/core/skills/ship/SKILL.md` - Ticket Guard prose updated to the per-user semantics.
- `plugins/core/skills/branching/scripts/detect-context.sh` - `detect_mode()` counts todo tickets recursively; scope the count to the current user's subdirectory so another user's leftovers don't flip mode detection.
- `plugins/work/hooks/validate-ticket.sh` - `^todo/` prefix check already admits `todo/<user>/x.md`; optionally tighten to at most one subdirectory level and update the error/doc wording.
- `plugins/work/commands/ticket.md` - Guardrail prose ("ONLY under `.workaholic/tickets/todo/`...") updated to mention the user subdirectory and sweep.
- `plugins/work/README.md` - Directory-structure documentation (lines ~85-87) updated to show `todo/<user>/`.
- `plugins/work/rules/workaholic.md` - `.workaholic/` structure description updated.
- `scripts/test-workflow-scripts.mjs` - Smoke tests assert the flat layout (archive test places the ticket at `todo/<ts>-smoke-ticket.md`); update and add coverage for slug, sweep, scoped list, and nested archive.
- `dist/workflows/` - Generated copies of the drive/ticket/ship skills and their scripts; regenerate with `node scripts/build-plugins/build.mjs`, never hand-edit.

## Related History

The current `todo/`/`icebox/`/`archive/<branch>/` layout, the ship guard, and the hook were each introduced by past tickets that also fixed the same classes of follow-on bugs this change risks (unstaged moves, scanners missing tickets); git history's repeated "Move remaining tickets to icebox" commits are the manual workaround this ticket retires.

Past tickets that touched similar areas:

- [20260127103311-move-tickets-to-todo.md](.workaholic/tickets/archive/feat-20260126-214833/20260127103311-move-tickets-to-todo.md) - Established the current directory layout and updated every scanner; directly precedes this nesting (same files)
- [20260518235327-prohibit-tickets-outside-tickets-dir.md](.workaholic/tickets/archive/work-20260518-235327/20260518235327-prohibit-tickets-outside-tickets-dir.md) - Tightened validate-ticket.sh allowed locations; the same hook and Allowed Locations prose change here (same file)
- [20260404014405-block-ship-when-todo-tickets-remain.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014405-block-ship-when-todo-tickets-remain.md) - Added the `/ship` todo-clean guard for the same multi-developer leakage scenario; its scope changes to per-user (same file)
- [20260125114643-require-approval-for-icebox-moves.md](.workaholic/tickets/archive/feat-20260124-200439/20260125114643-require-approval-for-icebox-moves.md) - Hard rule that agents never autonomously move tickets to icebox; the sweep must move sideways within todo/, never to icebox (same constraint)
- [20260212221342-stage-icebox-to-todo-move-in-git.md](.workaholic/tickets/archive/drive-20260212-122906/20260212221342-stage-icebox-to-todo-move-in-git.md) - Established that every ticket `mv` is git-staged immediately; the sweep must follow the same discipline (same pattern)
- [20260219195953-fix-unstaged-ticket-deletions-after-drive.md](.workaholic/tickets/archive/drive-20260213-131416/20260219195953-fix-unstaged-ticket-deletions-after-drive.md) - Same class of unstaged-deletion bug for todo-to-archive moves (same pattern)

## Implementation Steps

1. Add `plugins/core/skills/gather/scripts/user-slug.sh` (POSIX sh, `set -eu`): take an optional email argument, default to `git config user.email`, emit the slug (lowercase, non-`[a-z0-9]` → `-`). This is the single canonical slug rule.
2. Extend `ticket-metadata.sh` to call it and add `"user_slug"` to its JSON output.
3. Add `plugins/core/skills/create-ticket/scripts/sweep-todo.sh`: for each `*.md` directly under `.workaholic/tickets/todo/` (depth 1 only), read the `author:` frontmatter line, slug it via `user-slug.sh <email>` (fallback to the current user's slug when missing/invalid), `mkdir -p` the target subdirectory, `mv`, and `git add` both paths immediately. Emit a JSON summary of moves so the calling agent can report them.
4. Update `core:create-ticket` SKILL.md: Step 1 captures `user_slug`; a new step runs the sweep; the write path and Allowed Locations become `.workaholic/tickets/todo/<user_slug>/` (icebox unchanged); filename convention unchanged; Output Contract examples show the nested path.
5. Scope `list-todo.sh` to `.workaholic/tickets/todo/$(user-slug)/` (keep `-maxdepth 1` within the subdirectory; resolve the slug via the shared script using the `$(dirname "$0")/../../gather/scripts/` pattern `archive.sh` already uses for `commit.sh`).
6. Fix `archive.sh`'s `TICKETS_ROOT` derivation to strip an optional trailing user segment from both `todo` and `icebox` forms (see Patches); archive destination remains flat `archive/<branch>/`.
7. Point `promote-icebox.sh` at the current user's `todo/<user>/` and `mkdir -p` it.
8. Update `core:drive` SKILL.md Phase 1 to run `sweep-todo.sh` before `list-todo.sh` (so strays are routed even when `/drive` runs before any `/ticket`), and update flat-path prose. Note: sweep moves staged mid-drive ride along into the next archive commit, which already runs `git add -A`.
9. Scope `check-todo.sh`'s blocking count to the current user's subdirectory; ship SKILL prose follows. Root-level strays may be listed as non-blocking information.
10. Scope `detect-context.sh`'s `detect_mode()` todo count to the current user's subdirectory.
11. Update `validate-ticket.sh` location wording and (optionally) tighten `^todo/` to `^todo/([^/]+/)?[^/]+$` so deeper nesting is still rejected; mirror for `icebox/` only if kept permissive deliberately.
12. Update prose/docs: `plugins/work/commands/ticket.md` guardrails, `plugins/work/README.md` structure, `plugins/work/rules/workaholic.md`.
13. Update `scripts/test-workflow-scripts.mjs`: archive test uses a `todo/<user>/` path and asserts the archive lands flat in `archive/<branch>/`; add hermetic tests for `user-slug.sh` (incl. sanitization), `sweep-todo.sh` (author routing, fallback, git staging), scoped `list-todo.sh`, and `promote-icebox.sh`'s new destination.
14. Regenerate artifacts and verify: `node scripts/build-plugins/build.mjs`, `node scripts/build-plugins/verify.mjs`, `node scripts/build-plugins/validate-metadata.mjs`, `node scripts/test-workflow-scripts.mjs`.

## Patches

> **Note**: These patches are speculative — the slug-resolution wiring depends on step 1's final script interface; verify before applying.

### `plugins/core/skills/gather/scripts/ticket-metadata.sh`

```diff
--- a/plugins/core/skills/gather/scripts/ticket-metadata.sh
+++ b/plugins/core/skills/gather/scripts/ticket-metadata.sh
@@ -7,12 +7,15 @@ set -eu
 CREATED_AT=$(date -Iseconds)
 AUTHOR=$(git config user.email)
 FILENAME_TS=$(date +%Y%m%d%H%M%S)
+SCRIPT_DIR=$(dirname "$0")
+USER_SLUG=$(sh "${SCRIPT_DIR}/user-slug.sh")
 
 cat <<EOF
 {
   "created_at": "${CREATED_AT}",
   "author": "${AUTHOR}",
-  "filename_timestamp": "${FILENAME_TS}"
+  "filename_timestamp": "${FILENAME_TS}",
+  "user_slug": "${USER_SLUG}"
 }
 EOF
```

### `plugins/core/skills/drive/scripts/list-todo.sh`

```diff
--- a/plugins/core/skills/drive/scripts/list-todo.sh
+++ b/plugins/core/skills/drive/scripts/list-todo.sh
@@ -1,12 +1,14 @@
 #!/bin/sh -eu
-# List ticket files in the todo queue, one path per line (empty output if none).
+# List the current user's ticket files in the todo queue, one path per line.
 
 set -eu
 
-DIR=".workaholic/tickets/todo"
+SCRIPT_DIR=$(dirname "$0")
+USER_SLUG=$(sh "${SCRIPT_DIR}/../../gather/scripts/user-slug.sh")
+DIR=".workaholic/tickets/todo/${USER_SLUG}"
 
 if [ ! -d "$DIR" ]; then
     exit 0
 fi
 
 find "$DIR" -maxdepth 1 -name '*.md' -type f | sort
```

### `plugins/core/skills/drive/scripts/archive.sh`

```diff
--- a/plugins/core/skills/drive/scripts/archive.sh
+++ b/plugins/core/skills/drive/scripts/archive.sh
@@ -30,7 +30,8 @@ fi
 
 TICKET_DIR=$(dirname "$TICKET")
-TICKETS_ROOT=$(echo "$TICKET_DIR" | sed 's|/todo$||; s|/icebox$||')
+# Strip /todo, /icebox, or their per-user form /todo/<user> to find the tickets root
+TICKETS_ROOT=$(echo "$TICKET_DIR" | sed 's|/todo/[^/]*$||; s|/icebox/[^/]*$||; s|/todo$||; s|/icebox$||')
 # Sanitize branch name: replace / with - for flat archive directory naming
 # e.g. trip/my-feature -> trip-my-feature (consistent with drive-* convention)
 SAFE_BRANCH=$(echo "$BRANCH" | tr '/' '-')
```

### `plugins/core/skills/drive/scripts/promote-icebox.sh`

```diff
--- a/plugins/core/skills/drive/scripts/promote-icebox.sh
+++ b/plugins/core/skills/drive/scripts/promote-icebox.sh
@@ -16,11 +16,13 @@ if [ ! -f "$SRC" ]; then
     exit 1
 fi
 
 FILENAME=$(basename "$SRC")
-DEST=".workaholic/tickets/todo/${FILENAME}"
+SCRIPT_DIR=$(dirname "$0")
+USER_SLUG=$(sh "${SCRIPT_DIR}/../../gather/scripts/user-slug.sh")
+DEST=".workaholic/tickets/todo/${USER_SLUG}/${FILENAME}"
 
-mkdir -p .workaholic/tickets/todo
+mkdir -p ".workaholic/tickets/todo/${USER_SLUG}"
 mv "$SRC" "$DEST"
 git add "$SRC" "$DEST"
 
 echo "$DEST"
```

## Considerations

- **Never route strays to the icebox.** A prior ticket established that agents must not autonomously move tickets to icebox; the sweep moves sideways within `todo/` only, and that constraint should be restated in the sweep script's header and the create-ticket SKILL prose (`plugins/core/skills/create-ticket/scripts/sweep-todo.sh`).
- **Every move must be git-staged in the same script that performs it** — two prior tickets fixed dangling unstaged deletions from ticket moves; `sweep-todo.sh` must `git add` old and new paths per move, like `promote-icebox.sh` does (`plugins/core/skills/create-ticket/scripts/sweep-todo.sh`).
- **`/ship` guard semantics change deliberately**: other users' tickets (in their subdirectories, or unswept at the root) no longer block a merge. This is the requested DX — but it means stray root tickets can reach main and persist until any user's next `/ticket`/`/drive` sweeps them. If that lag is unacceptable, have `check-todo.sh` emit a non-blocking warning listing root strays (`plugins/core/skills/ship/scripts/check-todo.sh`).
- **Shell Script Principle**: all slug derivation, sweep conditionals, and globbing live in bundled POSIX-sh scripts (`#!/bin/sh -eu`, no bash-isms — Alpine targets); command/skill markdown only invokes them via `${CLAUDE_PLUGIN_ROOT}` paths (`plugins/work/rules/shell.md`).
- **Cross-skill script reference must survive the dist build**: `list-todo.sh`/`promote-icebox.sh` calling `../../gather/scripts/user-slug.sh` relies on the build's script-closure copying, the same mechanism `archive.sh` uses for `commit.sh`. Confirm `verify.mjs` passes; if the closure does not cover gather from drive, inline the slug derivation in each script instead (`scripts/build-plugins/verify.mjs`).
- **Regenerate `dist/workflows/` in the same commit** — the Dist Freshness CI workflow fails on any drift between `plugins/core` workflow skills and the committed artifacts (`scripts/build-plugins/build.mjs`).
- **Slug collisions and stability**: the full-email slug makes collisions implausible, but a developer changing their git email orphans their old subdirectory. The author-frontmatter-routed sweep self-heals only root-level strays, not renamed subdirectories; acceptable, but worth a line in the README (`plugins/work/README.md`).
- **Mixed-layout transition is self-healing**: branches created before this change still carry flat tickets; the sweep at `/ticket` and `/drive` migrates them on first contact, routed to their authors. No one-shot migration script is needed.
- **`discover/scripts/search.sh` and `gather/scripts/git-context.sh` need no changes** — recursive grep and archive-only globs respectively — but history-mode duplicate detection now sees all users' tickets, which is correct (a duplicate is a duplicate regardless of owner) (`plugins/core/skills/discover/scripts/search.sh`).
- **Hook already admits nested paths** (`^todo/` is a prefix match), so the feature cannot be blocked by the hook even if step 11 is deferred; the tightening is hygiene, not a prerequisite (`plugins/work/hooks/validate-ticket.sh` lines 46-57).
