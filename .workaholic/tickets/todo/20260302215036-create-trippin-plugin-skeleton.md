---
created_at: 2026-03-02T21:50:36+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Create "trippin" Plugin with Skeleton Minimum Structure

## Overview

Create a new `plugins/trippin` directory with the minimum skeleton files and directories required for a Claude Code plugin. This establishes the foundation for a second plugin in the marketplace alongside "drivin" (formerly "core"). The skeleton should follow the same structural patterns as the existing plugin but contain only the minimal required files.

## Key Files

- `plugins/trippin/.claude-plugin/plugin.json` - Plugin metadata (new)
- `plugins/trippin/README.md` - Plugin documentation (new)
- `.claude-plugin/marketplace.json` - Add trippin plugin entry
- `plugins/drivin/.claude-plugin/plugin.json` - Reference for structure (existing)

## Related History

The marketplace has contained a single plugin ("core") since inception. The project structure and CI validation workflows are already designed to support multiple plugins via glob patterns (`plugins/*/.claude-plugin/plugin.json`).

Past tickets that touched similar areas:

- [20260302215035-rename-core-to-drivin.md](.workaholic/tickets/todo/20260302215035-rename-core-to-drivin.md) - Renames core to drivin; this ticket creates the second plugin after that rename

## Implementation Steps

1. **Create the plugin directory structure**:
   ```
   plugins/trippin/
     .claude-plugin/
       plugin.json
     commands/
     agents/
     skills/
     rules/
     README.md
   ```

2. **Create `plugins/trippin/.claude-plugin/plugin.json`** with minimum required fields:
   ```json
   {
     "name": "trippin",
     "description": "AI-oriented exploration and creative development workflow",
     "version": "1.0.37",
     "author": {
       "name": "tamurayoshiya",
       "email": "a@qmu.jp"
     }
   }
   ```
   Use the same version as the marketplace to keep versions in sync.

3. **Create `plugins/trippin/README.md`** with basic plugin documentation:
   - Plugin name and description
   - Empty Commands, Skills, Rules sections (to be populated later)

4. **Add trippin plugin entry to `.claude-plugin/marketplace.json`**:
   - Add new entry in the `plugins` array
   - Set `"source": "./plugins/trippin"`
   - Set `"category": "development"`

## Patches

### `.claude-plugin/marketplace.json`

> **Note**: This patch assumes the rename from "core" to "drivin" has already been applied.

```diff
--- a/.claude-plugin/marketplace.json
+++ b/.claude-plugin/marketplace.json
@@ -18,6 +18,16 @@
       "source": "./plugins/drivin",
       "category": "development"
+    },
+    {
+      "name": "trippin",
+      "description": "AI-oriented exploration and creative development workflow",
+      "version": "1.0.37",
+      "author": {
+        "name": "tamurayoshiya",
+        "email": "a@qmu.jp"
+      },
+      "source": "./plugins/trippin",
+      "category": "development"
     }
   ]
 }
```

## Considerations

- This ticket depends on the rename of "core" to "drivin" being completed first. The marketplace.json patch assumes the rename is already done. (`.claude-plugin/marketplace.json`)
- The version should be set to `1.0.37` to match the current marketplace version, keeping all plugin versions in sync per the Version Management section in CLAUDE.md. (`plugins/trippin/.claude-plugin/plugin.json`)
- The GitHub Actions `validate-plugins.yml` workflow validates that each plugin name in marketplace.json has a matching directory under `plugins/`. The name "trippin" must match the directory `plugins/trippin/`. (`.github/workflows/validate-plugins.yml` lines 95-100)
- Empty directories (`commands/`, `agents/`, `skills/`, `rules/`) cannot be committed in git. Either add a `.gitkeep` file in each empty directory, or omit them and let future tickets create them with actual content. (`plugins/trippin/commands/`, `plugins/trippin/agents/`, `plugins/trippin/skills/`, `plugins/trippin/rules/`)
- The `CLAUDE.md` project structure section should be updated to include the new `trippin/` entry under `plugins/`. (`CLAUDE.md` line 27)
- The branching skill currently supports `drive` and `trip` prefixes. The `trip` prefix aligns with the `trippin` plugin name, suggesting a natural convention where `trip-*` branches are used for trippin plugin workflows. (`plugins/drivin/skills/branching/SKILL.md`)
