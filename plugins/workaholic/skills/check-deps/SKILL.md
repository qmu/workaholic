---
name: check-deps
description: Verify required plugin dependencies are installed.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Check Dependencies

Workaholic is a **single plugin** (`dependencies: []`), so there are no external
plugin dependencies to verify. This check is a trivially-satisfied guard kept for
command-flow compatibility — `/ticket` and `/drive` call it as an early pre-check.

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

### Output Format

```json
{"ok": true}
```

- `ok`: Boolean indicating dependencies are satisfied (always `true` for the
  single-plugin layout).

Commands run this check early and stop with a message if `ok` is ever `false`.
