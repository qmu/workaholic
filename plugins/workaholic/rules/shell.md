---
paths:
  - '**/*.sh'
---

# Shell Script Conventions

- Use POSIX sh, not bash
  - Shebang must be `#!/bin/sh -eu` (strict mode: -e exits on error, -u errors on undefined vars)
  - Do not use bash-specific features (arrays, `[[ ]]`, `declare`, etc.)
  - This ensures scripts run on Alpine Linux containers which lack bash
- Use `set -eu` explicitly as fallback
  - Some environments may strip shebang flags

## Enforcement

This convention is machine-checked, so it cannot silently regress:

- **Lint:** `sh ${CLAUDE_PLUGIN_ROOT}/hooks/posix-lint.sh` audits every `*.sh` under
  `plugins/workaholic/` for a non-`#!/bin/sh` shebang or a bash-only construct
  (`[[ ]]`, `=~`, `<<<`, `${BASH_SOURCE}`, `BASH_REMATCH`, `declare`, statement-position
  `local`, array expansion). It emits JSON findings and exits non-zero on any violation.
  Read-only; point it at another directory with `sh hooks/posix-lint.sh <dir>`.
- **POSIX runner:** `node scripts/test-workflow-scripts.mjs` runs the scripts under the
  strictest available POSIX shell (`dash` when present, else `sh`) and asserts the lint
  reports zero findings against the real tree — so a developer and CI run the identical
  check, and a reintroduced bashism fails the suite instead of passing under a permissive bash.
