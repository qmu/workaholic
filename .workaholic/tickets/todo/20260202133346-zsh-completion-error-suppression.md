---
created_at: 2026-02-02T13:33:46+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category:
---

# Suppress zsh completion errors in non-interactive shell contexts

## Overview

When Claude Code executes shell commands via the Bash tool, zsh completion functions (like `compdef`) output error messages such as "command not found: compdef". This clutters command output and can cause confusion. A shell script wrapper will suppress these errors while preserving actual command output.

## Key Files

- `plugins/core/rules/shell.md` - POSIX sh conventions for scripts
- `plugins/core/skills/create-pr/sh/create-or-update.sh` - Example shell script pattern
- `plugins/core/skills/archive-ticket/sh/archive.sh` - Example shell script calling git
- `plugins/core/skills/discover-history/sh/search.sh` - Example shell script invoked by commands

## Related History

Past tickets reveal shell scripts in this project follow POSIX sh conventions (not bash) for Alpine Linux compatibility. No prior work on completion error suppression was found.

- [20260127005601-pr-creator-subagent.md](.workaholic/tickets/archive/feat-20260126-214833/20260127005601-pr-creator-subagent.md) - Extracted shell-based PR creation (same layer: Config/Infrastructure)

## Implementation Steps

1. **Create wrapper script** at `plugins/core/sh/run-silent.sh`:
   ```sh
   #!/bin/sh -eu
   # Suppress zsh completion errors in non-interactive contexts
   # Usage: run-silent.sh <command> [args...]

   set -eu

   if [ $# -eq 0 ]; then
       echo "Usage: run-silent.sh <command> [args...]"
       exit 1
   fi

   # Redirect stderr through filter to suppress compdef errors
   "$@" 2>&1 | grep -v "command not found: compdef" || true
   ```

2. **Alternative approach** - Create a minimal shell profile:
   ```sh
   #!/bin/sh -eu
   # Wrapper that unsets ZDOTDIR to prevent zsh config loading

   set -eu

   if [ $# -eq 0 ]; then
       echo "Usage: run-silent.sh <command> [args...]"
       exit 1
   fi

   ZDOTDIR=/nonexistent "$@"
   ```

3. **Choose implementation**: The `ZDOTDIR` approach is cleaner as it prevents the error at source rather than filtering output. However, if the error comes from parent shell initialization (before our script runs), use the grep filter approach.

4. **Document usage** in `plugins/core/rules/shell.md`:
   - Add guidance for commands that may encounter completion errors
   - Reference the wrapper script for git operations in non-interactive contexts

## Considerations

- **POSIX compatibility**: Must use `/bin/sh`, not bash, per project conventions
- **Error preservation**: Must not suppress legitimate errors, only completion-related messages
- **Performance**: The grep filter adds minimal overhead; ZDOTDIR unset has no overhead
- **Root cause**: The error appears when zsh's `.zshrc` defines `compdef` completion but the completion system is not initialized in non-interactive mode. This is a zsh configuration issue on the host system, not fixable within the project.
- **Alternative**: Could document that users should add `command -v compdef >/dev/null || compdef() { :; }` to their `.zshrc` to suppress the error system-wide
