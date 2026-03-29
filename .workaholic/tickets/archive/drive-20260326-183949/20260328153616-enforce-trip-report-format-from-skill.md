---
created_at: 2026-03-28T15:36:16+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.25h
commit_hash: a55a696
category: Changed
---

# Enforce Trip Report Format from write-trip-report Skill

## Overview

When `/report` is executed during a trip session on a worktree, Claude Code tends to ignore the report template defined in `write-trip-report/SKILL.md` and generates reports in a freeform format. The skill file clearly defines the required sections (Planner, Architect, Constructor, Journey, Trip Activity Log) with specific extraction guidelines, but these are not being reliably followed. The report command needs stronger enforcement so that the skill's template is the authoritative format.

## Key Files

- `plugins/core/commands/report.md` - The report command orchestration. The Trip Context and Trip Worktree Context flows invoke the write-trip-report skill but lack explicit instructions to strictly follow the skill's template structure.
- `plugins/trippin/skills/write-trip-report/SKILL.md` - Defines the canonical report template with sections, extraction rules, and formatting guidelines. This is the source of truth that is being ignored.

## Related History

- [20260311212022-unify-report-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212022-unify-report-command-across-plugins.md) - Unified report command across drive/trip contexts (same file: report.md)
- [20260328150719-display-story-after-report.md](.workaholic/tickets/archive/drive-20260326-183949/20260328150719-display-story-after-report.md) - Added inline story display after report generation (same file: report.md)

## Implementation Steps

1. In `plugins/core/commands/report.md`, strengthen the Trip Context step 3 ("Generate journey report") to explicitly instruct that the report **must** follow the exact template structure defined in the preloaded write-trip-report skill. Add a directive that no sections may be added, removed, or renamed, and that the extraction guidelines in the skill must be followed precisely.

2. Apply the same strengthening to the Trip Worktree Context flow (step 7: "Follow Trip Context steps 2-6 from within the worktree"), ensuring the worktree path does not weaken format adherence.

3. In `plugins/trippin/skills/write-trip-report/SKILL.md`, add a format enforcement preamble before the Template section that explicitly states the template is mandatory and must be followed exactly — no creative reinterpretation, no section additions or omissions, no reordering.

## Considerations

- The root cause is likely that Claude Code treats the skill template as a suggestion rather than a strict requirement. Adding explicit "MUST follow exactly" language in both the command and skill files should improve compliance. (`plugins/trippin/skills/write-trip-report/SKILL.md`)
- The worktree context is especially prone to format drift because the flow involves more steps (worktree selection, directory switching) before reaching the report generation, which may dilute the skill's instructions in context. (`plugins/core/commands/report.md` lines 63-71)
- The drive context does not have this problem because story-writer is a dedicated subagent with its own focused prompt, which naturally constrains the output format. The trip context generates the report inline within the command flow, making it more susceptible to prompt drift.
- Care should be taken not to make the enforcement so rigid that it breaks when trip artifacts are partially missing (e.g., no event log, no reviews). The skill already handles optional sections — enforcement should cover structure, not content completeness.

## Final Report

Development completed as planned.
