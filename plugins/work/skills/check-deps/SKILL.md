---
name: check-deps
description: Verify required plugin dependencies are installed.
allowed-tools: Bash
user-invocable: false
---

# Check Dependencies

Verify that required plugin dependencies (core) are installed before running commands.

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

### Output Format

```json
{"ok": true}
```

Or if missing:

```json
{"ok": false, "missing": ["core"], "message": "..."}
```

- `ok`: Boolean indicating all dependencies are satisfied
- `missing`: Array of missing plugin names
- `message`: Human-readable instruction for the user

Commands should run this check early and stop with the `message` if `ok` is `false`.
