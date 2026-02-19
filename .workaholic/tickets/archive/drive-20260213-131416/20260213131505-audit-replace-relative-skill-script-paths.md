---
created_at: 2026-02-13T13:15:05+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.25h
commit_hash: b24b530
category:
---

# Audit and Replace All Relative Skill Script Paths

## Overview

After the CLAUDE.md rule is established (ticket `20260213131504-enforce-absolute-paths-for-skill-scripts.md`), all existing skill, agent, command, and policy/spec markdown files must be audited and updated to replace relative `.claude/skills/` paths with the absolute `~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/` path. There are 40 active (non-archived) files containing the broken pattern across the `plugins/` and `.workaholic/` directories.

## Key Files

**Plugin source files (33 files in `plugins/core/`):**

Skills (25 files):
- `plugins/core/skills/analyze-performance/SKILL.md` - References `analyze-performance/sh/calculate.sh`
- `plugins/core/skills/analyze-policy/SKILL.md` - References `analyze-policy/sh/gather.sh`
- `plugins/core/skills/analyze-viewpoint/SKILL.md` - References `analyze-viewpoint/sh/gather.sh` and `read-overrides.sh`
- `plugins/core/skills/branching/SKILL.md` - References `branching/sh/check.sh` and `create.sh`
- `plugins/core/skills/create-pr/SKILL.md` - References `create-pr/sh/create-or-update.sh`
- `plugins/core/skills/create-ticket/SKILL.md` - References `gather-ticket-metadata/sh/gather.sh`
- `plugins/core/skills/discover-history/SKILL.md` - References `discover-history/sh/search.sh`
- `plugins/core/skills/gather-git-context/SKILL.md` - References `gather-git-context/sh/gather.sh`
- `plugins/core/skills/gather-ticket-metadata/SKILL.md` - References `gather-ticket-metadata/sh/gather.sh`
- `plugins/core/skills/lead-a11y/SKILL.md` - References `analyze-policy/sh/gather.sh`
- `plugins/core/skills/lead-db/SKILL.md` - References `analyze-viewpoint/sh/gather.sh` and `read-overrides.sh`
- `plugins/core/skills/lead-delivery/SKILL.md` - References `analyze-policy/sh/gather.sh`
- `plugins/core/skills/lead-infra/SKILL.md` - References `analyze-viewpoint/sh/gather.sh` and `read-overrides.sh`
- `plugins/core/skills/lead-observability/SKILL.md` - References `analyze-policy/sh/gather.sh`
- `plugins/core/skills/lead-quality/SKILL.md` - References `analyze-policy/sh/gather.sh`
- `plugins/core/skills/lead-recovery/SKILL.md` - References `analyze-policy/sh/gather.sh`
- `plugins/core/skills/lead-security/SKILL.md` - References `analyze-policy/sh/gather.sh`
- `plugins/core/skills/lead-test/SKILL.md` - References `analyze-policy/sh/gather.sh`
- `plugins/core/skills/lead-ux/SKILL.md` - References `analyze-viewpoint/sh/gather.sh` and `read-overrides.sh`
- `plugins/core/skills/manage-architecture/SKILL.md` - References `analyze-viewpoint/sh/gather.sh` and `read-overrides.sh`
- `plugins/core/skills/select-scan-agents/SKILL.md` - References `select-scan-agents/sh/select.sh`
- `plugins/core/skills/update-ticket-frontmatter/SKILL.md` - References `update-ticket-frontmatter/sh/update.sh`
- `plugins/core/skills/validate-writer-output/SKILL.md` - References `validate-writer-output/sh/validate.sh`
- `plugins/core/skills/write-changelog/SKILL.md` - References `write-changelog/sh/generate.sh`
- `plugins/core/skills/write-overview/SKILL.md` - References `write-overview/sh/collect-commits.sh`
- `plugins/core/skills/write-spec/SKILL.md` - References `write-spec/sh/gather.sh`
- `plugins/core/skills/write-terms/SKILL.md` - References `write-terms/sh/gather.sh`

Commands (2 files):
- `plugins/core/commands/scan.md` - References `select-scan-agents/sh/select.sh` and `validate-writer-output/sh/validate.sh`
- `plugins/core/commands/report.md` - References `branching/sh/check-version-bump.sh`

Agents (4 files):
- `plugins/core/agents/model-analyst.md` - References `analyze-viewpoint/sh/gather.sh` and `read-overrides.sh`
- `plugins/core/agents/overview-writer.md` - References `write-overview/sh/collect-commits.sh`
- `plugins/core/agents/performance-analyst.md` - References `analyze-performance/sh/calculate.sh`
- `plugins/core/agents/terms-writer.md` - References `write-terms/sh/gather.sh`

**Documentation files (6 files in `.workaholic/`):**
- `.workaholic/policies/delivery.md` - References `branching`, `select-scan-agents`, `analyze-policy` scripts
- `.workaholic/policies/delivery_ja.md` - Same references (Japanese translation)
- `.workaholic/specs/component.md` - References `gather-git-context` and `analyze-viewpoint` scripts
- `.workaholic/specs/component_ja.md` - Same references (Japanese translation)
- `.workaholic/specs/ux.md` - References `branching/sh/check-version-bump.sh`
- `.workaholic/specs/ux_ja.md` - Same reference (Japanese translation)

## Related History

The absolute path pattern was established in ticket 20260204215053 when 4 files were fixed, but the majority of files were never updated. This ticket completes the migration across all remaining files.

Past tickets that touched similar areas:

- [20260204215053-fix-skill-script-race-condition.md](.workaholic/tickets/archive/drive-20260204-160722/20260204215053-fix-skill-script-race-condition.md) - Fixed archive-ticket, drive-approval, commit, and drive command paths (same fix pattern)
- [20260212183330-add-effort-enum-to-write-final-report.md](.workaholic/tickets/archive/drive-20260212-122906/20260212183330-add-effort-enum-to-write-final-report.md) - Discovered the path issue persists in write-final-report; final report notes it as insight
- [20260127193706-bundle-shell-scripts-for-permission-free-skills.md](.workaholic/tickets/archive/feat-20260126-214833/20260127193706-bundle-shell-scripts-for-permission-free-skills.md) - Original ticket that introduced bundled shell scripts in skills, establishing the `.claude/skills/` path convention that turned out to be wrong

## Implementation Steps

1. **Replace all relative paths in plugin source files** (`plugins/core/`). For each of the 33 files listed in Key Files, perform a find-and-replace: change `bash .claude/skills/` to `bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/`. This is a mechanical substitution -- the path suffix (skill name, script name, arguments) remains unchanged.

2. **Replace all relative paths in documentation files** (`.workaholic/policies/` and `.workaholic/specs/`). Apply the same substitution to the 6 documentation files. Note: these files are normally regenerated by scan agents, but they should be fixed now to prevent runtime failures if agents read them before the next scan.

3. **Verify no remaining relative paths**. Run `grep -r "bash .claude/skills/" plugins/ .workaholic/policies/ .workaholic/specs/ CLAUDE.md` and confirm zero matches (excluding archived tickets which are historical records).

4. **Do NOT modify archived tickets** in `.workaholic/tickets/archive/`. These are historical records and must remain as-is.

## Considerations

- This is a companion ticket to `20260213131504-enforce-absolute-paths-for-skill-scripts.md` which establishes the CLAUDE.md rule. This ticket should be implemented after the rule is in place.
- The substitution is purely mechanical: replace the prefix `.claude/skills/` with `~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/` in bash invocations. No argument or script name changes needed.
- Files already using the correct absolute path (e.g., `plugins/core/skills/archive-ticket/SKILL.md`, `plugins/core/skills/commit/SKILL.md`, `plugins/core/skills/drive-approval/SKILL.md`, `plugins/core/skills/write-final-report/SKILL.md`) should not be modified -- they were fixed in ticket 20260204215053 and 20260212183330.
- The `.workaholic/specs/` and `.workaholic/policies/` files will be regenerated by the next `/scan` run, but fixing them now prevents immediate runtime failures (`plugins/core/skills/manage-architecture/SKILL.md`, `plugins/core/skills/lead-*/SKILL.md`)
- Some skill SKILL.md files reference their own script (self-referential, e.g., `branching/SKILL.md` references `branching/sh/check.sh`), while others reference a different skill's script (cross-referential, e.g., `create-ticket/SKILL.md` references `gather-ticket-metadata/sh/gather.sh`). Both patterns need the same fix.

## Final Report

Mechanical substitution completed across all 39 target files:

1. **Plugin source files (33 files)** — 25 skill SKILL.md files, 2 command files (scan.md, report.md), 4 agent files, and 2 already-fixed files (no change needed)
2. **Documentation files (6 files)** — 2 policy files (delivery.md, delivery_ja.md), 4 spec files (component.md, component_ja.md, ux.md, ux_ja.md)
3. **Verification passed** — `grep -r "bash .claude/skills/" plugins/ .workaholic/policies/ .workaholic/specs/ CLAUDE.md` returns zero matches
4. **Archived tickets untouched** — Historical records in `.workaholic/tickets/archive/` were not modified
