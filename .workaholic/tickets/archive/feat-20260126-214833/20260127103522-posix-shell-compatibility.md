---
created_at: 2026-01-27T10:35:22+09:00
author: a@qmu.jp
type: refactoring
layer: [Config, Infrastructure]
effort: 0.25h
commit_hash: 9ba1cf6
category: Changed
---

# Convert shell scripts to POSIX sh for Alpine Docker compatibility

## Overview

Modify all shell scripts to use `#!/bin/sh -eu` shebang and POSIX-compliant syntax instead of bash. This prepares for running Claude Code inside Docker containers where Alpine Linux (which lacks bash by default) may be used. Also create a rule file to enforce this convention for future scripts.

## Key Files

- `plugins/core/rules/shell.md` - New rule file for shell script conventions (create)
- `plugins/core/skills/archive-ticket/sh/archive.sh` - Convert from bash to POSIX sh
- `plugins/core/skills/changelog/sh/generate.sh` - Convert from bash to POSIX sh (has arrays)
- `plugins/core/skills/story-metrics/sh/calculate.sh` - Convert from bash to POSIX sh
- `plugins/core/skills/spec-context/sh/gather.sh` - Convert from bash to POSIX sh
- `plugins/core/skills/pr-ops/sh/create-or-update.sh` - Convert from bash to POSIX sh

## Related History

Past tickets that touched similar areas:

- `20260127020640-extract-changelog-skill.md` - Created changelog/sh/generate.sh (same file)
- `20260127021000-extract-story-skill.md` - Created story-metrics/sh/calculate.sh (same file)
- `20260127021024-extract-pr-skill.md` - Created pr-ops/sh/create-or-update.sh (same file)

## Implementation Steps

1. Create `plugins/core/rules/shell.md` with path pattern `**/*.sh`:

   ```markdown
   ---
   paths:
     - '**/*.sh'
   ---

   # Shell Script Conventions

   - Use POSIX sh, not bash
     - Shebang must be `#!/bin/sh -eu` (strict mode: -e exits on error, -u errors on undefined vars)
     - Do not use bash-specific features (arrays, `[[ ]]`, `declare`, etc.)
     - This ensures scripts run on Alpine Linux containers which lack bash
   - Use `set -e` explicitly if shebang flags are stripped
     - Some environments may strip shebang flags, so add `set -eu` as fallback
   ```

2. Update each shell script:

   **For all scripts:**
   - Change shebang from `#!/bin/bash` to `#!/bin/sh -eu`
   - Remove `set -e` (now in shebang, but can keep as fallback)

   **For `archive.sh`:**
   - Replace `FILES=("$@")` with direct `$@` usage or file-by-file processing

   **For `generate.sh` (most complex - uses bash arrays):**
   - Replace `declare -a ADDED=()` etc. with temporary files or string accumulation
   - Option A: Use temp files for each category
   - Option B: Use newline-separated strings and process with `printf`/`echo`
   - Replace `${#ARRAY[@]}` length checks with `[ -n "$VAR" ]`
   - Replace `for entry in "${ARRAY[@]}"` with `echo "$VAR" | while read`

   **For `calculate.sh`:**
   - Replace `(( ))` arithmetic with `[ ]` and `expr` or `$((  ))`
   - The `$((  ))` arithmetic expansion is POSIX compliant
   - `bc` usage is fine (external command)

3. Test each script manually to ensure functionality is preserved

## Considerations

- `generate.sh` will need the most work due to bash array usage - consider rewriting the logic
- POSIX sh lacks arrays, so use temp files or newline-delimited strings
- `$((  ))` arithmetic is POSIX compliant and can remain
- `bc` is an external command and works on Alpine (may need to `apk add bc`)
- The `-eu` flags provide similar safety to `set -eu` but in shebang form
- Keep scripts simple - if a script becomes too complex for POSIX sh, consider rewriting in a different language

## Final Report

Development completed as planned.
