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
