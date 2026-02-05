---
created_at: 2026-02-05T20:34:49+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add Filesystem Validation to Spec-Writer

## Overview

The /scan command's spec-writer only checks "what changed this branch?" via archived tickets or git diff, but never validates "does documentation match reality?" This causes file listings in architecture.md to become stale when files are renamed, added, or removed. Adding filesystem validation ensures explicit file listings in specs are always accurate.

## Key Files

- `plugins/core/agents/spec-writer.md` - Subagent that updates .workaholic/specs/
- `plugins/core/skills/write-spec/SKILL.md` - Guidelines for spec updates
- `plugins/core/skills/write-spec/sh/gather.sh` - Context gathering script
- `.workaholic/specs/architecture.md` - Contains explicit file listings that became stale

## Related History

The spec-writer workflow was established through several iterations focusing on change-based documentation updates. The original sync-doc-specs approach was rewritten to use archived tickets as the primary change signal. Cross-cutting documentation patterns were added but the focus remained on "what changed" rather than "what exists."

Past tickets that touched similar areas:

- [20260123135431-rewrite-sync-doc-specs-command.md](.workaholic/tickets/archive/feat-20260123-032323/20260123135431-rewrite-sync-doc-specs-command.md) - Rewrote spec synchronization to use tickets (same file: write-spec)
- [20260123154228-sync-doc-specs-cross-cutting-docs.md](.workaholic/tickets/archive/feat-20260123-032323/20260123154228-sync-doc-specs-cross-cutting-docs.md) - Added cross-cutting concern analysis (same layer: Config)
- [20260127021013-extract-spec-skill.md](.workaholic/tickets/archive/feat-20260126-214833/20260127021013-extract-spec-skill.md) - Extracted spec skill from agent (same file: spec-writer.md)

## Implementation Steps

1. **Update `plugins/core/skills/write-spec/sh/gather.sh`** to add ACTUAL STRUCTURE section:
   - Add new section that lists actual files in `plugins/core/agents/`, `plugins/core/commands/`, `plugins/core/rules/`, `plugins/core/skills/`
   - Output format should match the structure in architecture.md for easy comparison

2. **Update `plugins/core/skills/write-spec/SKILL.md`** to document the new section:
   - Add ACTUAL STRUCTURE to "Output Sections" documentation
   - Add "Using the Output" guidance for comparing documented vs actual structure

3. **Update `plugins/core/agents/spec-writer.md`** to add validation step:
   - After auditing current specs, compare ACTUAL STRUCTURE against documented file listings
   - Flag any discrepancies (files listed but not present, files present but not listed)
   - Require updates to architecture.md when discrepancies are found

## Patches

### `plugins/core/skills/write-spec/sh/gather.sh`

```diff
--- a/plugins/core/skills/write-spec/sh/gather.sh
+++ b/plugins/core/skills/write-spec/sh/gather.sh
@@ -35,3 +35,24 @@ git diff "${BASE_BRANCH}...HEAD" --stat 2>/dev/null || echo "No diff available"
 # Get current commit hash
 echo "=== COMMIT ==="
 git rev-parse --short HEAD
+echo ""
+
+# List actual file structure for validation
+echo "=== ACTUAL STRUCTURE ==="
+echo "agents/"
+ls -1 plugins/core/agents/*.md 2>/dev/null | xargs -I{} basename {} | sed 's/^/  /' || echo "  (none)"
+echo ""
+echo "commands/"
+ls -1 plugins/core/commands/*.md 2>/dev/null | xargs -I{} basename {} | sed 's/^/  /' || echo "  (none)"
+echo ""
+echo "rules/"
+ls -1 plugins/core/rules/*.md 2>/dev/null | xargs -I{} basename {} | sed 's/^/  /' || echo "  (none)"
+echo ""
+echo "skills/"
+for skill_dir in plugins/core/skills/*/; do
+  skill_name=$(basename "$skill_dir")
+  echo "  ${skill_name}/"
+  if [ -d "${skill_dir}sh" ]; then
+    ls -1 "${skill_dir}sh/"*.sh 2>/dev/null | xargs -I{} basename {} | sed 's/^/    /' || true
+  fi
+done
```

### `plugins/core/skills/write-spec/SKILL.md`

```diff
--- a/plugins/core/skills/write-spec/SKILL.md
+++ b/plugins/core/skills/write-spec/SKILL.md
@@ -40,6 +40,9 @@ The script outputs structured information:

 === COMMIT ===
 <current short commit hash>
+
+=== ACTUAL STRUCTURE ===
+<actual files in plugins/core/ directories>
 ```

 ### Using the Output
@@ -49,6 +52,7 @@ The script outputs structured information:
 - **SPECS**: Survey these to find documents needing updates
 - **DIFF**: Use when no tickets exist to understand changes
 - **COMMIT**: Use in frontmatter `commit_hash` field
+- **ACTUAL STRUCTURE**: Compare against file listings in architecture.md to detect stale documentation
```

### `plugins/core/agents/spec-writer.md`

```diff
--- a/plugins/core/agents/spec-writer.md
+++ b/plugins/core/agents/spec-writer.md
@@ -25,6 +25,8 @@ You will receive:

 2. **Audit Current Specs**: Read documents from SPECS section to understand scope and identify outdated content.

+3. **Validate Structure**: Compare ACTUAL STRUCTURE output against file listings in architecture.md. Flag discrepancies (files documented but missing, files present but undocumented). If discrepancies exist, architecture.md must be updated.
+
-3. **Plan Updates**: Determine which docs need updates, creation, or deletion. Identify cross-cutting concerns.
+4. **Plan Updates**: Determine which docs need updates, creation, or deletion. Identify cross-cutting concerns.

-4. **Execute Updates**: Follow the preloaded write-spec skill for formatting rules and guidelines.
+5. **Execute Updates**: Follow the preloaded write-spec skill for formatting rules and guidelines.

-5. **Update Index Files**: Maintain README links following preloaded translate skill.
+6. **Update Index Files**: Maintain README links following preloaded translate skill.

-6. **Summarize**: List specs updated/created/deleted, confirm all docs are linked.
+7. **Summarize**: List specs updated/created/deleted, confirm all docs are linked. Report any structure discrepancies found and fixed.
```

> **Note**: These patches are speculative - verify current file content before applying.

## Considerations

- The shell script uses pipes and `xargs` which may need adjustment for edge cases with special characters in filenames (`plugins/core/skills/write-spec/sh/gather.sh`)
- The ACTUAL STRUCTURE output format should closely match architecture.md's "Directory Layout" section for easy visual comparison (`plugins/core/skills/write-spec/sh/gather.sh`)
- This validation only covers the core plugin structure; if future plugins are added, the script may need extension (`plugins/core/skills/write-spec/sh/gather.sh`)
- The spec-writer step renumbering changes existing behavior documentation - ensure no other files reference steps by number (`plugins/core/agents/spec-writer.md`)
