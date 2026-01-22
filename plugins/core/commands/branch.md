---
name: branch
description: Create a topic branch with timestamp (e.g., feat-20260120-205418)
---

# Branch

Create a new topic branch with a timestamp-based name.

## Instructions

1. Ask the user to select a branch prefix:

   - **feat** - New feature
   - **fix** - Bug fix
   - **refact** - Refactoring

2. Generate timestamp in format `YYYYMMDD-HHMMSS` (e.g., `20260120-205418`)

3. Create and checkout the branch:
   ```bash
   git checkout -b <prefix>-<timestamp>
   ```

## Example

If user selects "feat" at 2026-01-20 20:54:18:

```bash
git checkout -b feat-20260120-205418
```
