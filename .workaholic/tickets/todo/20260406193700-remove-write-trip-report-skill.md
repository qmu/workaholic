---
created_at: 2026-04-06T19:37:00+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
---

# Remove write-trip-report Skill

## Overview

Remove the `write-trip-report` skill and its companion `gather-artifacts.sh` script from the work plugin. The report workflow has been unified so that developers generate reports during the drive session (via the `story-writer` agent), not during trip sessions. The trip mode in the `/report` command should be updated to use the story-writer agent instead of the now-redundant write-trip-report skill.

## Key Files

- `plugins/work/skills/write-trip-report/SKILL.md` - The skill to be removed (89 lines)
- `plugins/work/skills/write-trip-report/scripts/gather-artifacts.sh` - Companion artifact-gathering script to be removed (127 lines)
- `plugins/core/commands/report.md` - Preloads `work:write-trip-report` in frontmatter (line 6) and references it in Trip Mode (lines 56-57) and Hybrid Mode flows
- `plugins/work/README.md` - Skills table entry for `write-trip-report` (line 56)
- `CLAUDE.md` - Project structure comment listing `write-trip-report` in the skills directory (line 32)

## Related History

The write-trip-report skill was created during the trippin plugin era and later unified into drive-format output. Most recently, the report workflow was migrated so that drive sessions handle all report generation.

Past tickets that touched similar areas:

- [20260403230427-unify-trip-report-to-drive-format.md](.workaholic/tickets/archive/drive-20260403-230430/20260403230427-unify-trip-report-to-drive-format.md) - Rewrote write-trip-report SKILL.md to produce drive-format output (same skill)
- [20260328153616-enforce-trip-report-format-from-skill.md](.workaholic/tickets/archive/drive-20260326-183949/20260328153616-enforce-trip-report-format-from-skill.md) - Strengthened format enforcement in write-trip-report (same skill)
- [20260404014400-create-work-plugin-merge-drivin-trippin.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014400-create-work-plugin-merge-drivin-trippin.md) - Moved write-trip-report from trippin to work plugin
- [20260311103508-add-report-trip-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311103508-add-report-trip-command.md) - Originally created the write-trip-report skill and gather-artifacts.sh

## Implementation Steps

1. **Update `plugins/core/commands/report.md`**: Remove `work:write-trip-report` from the frontmatter `skills` list (line 6). Update the Trip Mode flow (lines 54-69) to route through the story-writer agent instead of the manual gather-artifacts + write-trip-report skill pattern. The trip mode should invoke `story-writer` the same way drive mode does (line 49), since the report format is now unified.

2. **Update Hybrid Mode** in `plugins/core/commands/report.md`: The hybrid mode (lines 71-77) references both Drive Mode and Trip Mode workflows. After step 1, Trip Mode already routes through story-writer, so hybrid mode needs no additional changes beyond what step 1 provides.

3. **Delete `plugins/work/skills/write-trip-report/` directory**: Remove both `SKILL.md` and `scripts/gather-artifacts.sh`. This is the entire skill directory.

4. **Update `plugins/work/README.md`**: Remove the `write-trip-report` row from the Skills table (line 56).

5. **Update `CLAUDE.md`**: Remove `write-trip-report` from the skills directory listing in the project structure comment (line 32). Change `create-ticket, discover, drive, report, trip-protocol, write-trip-report, check-deps` to `create-ticket, discover, drive, report, trip-protocol, check-deps`.

## Considerations

- The `gather-artifacts.sh` script is only referenced by `write-trip-report/SKILL.md` and `report.md`; no other plugin file uses it. Removal is safe. (`plugins/work/skills/write-trip-report/scripts/gather-artifacts.sh`)
- The story-writer agent currently handles drive mode reports. It must be verified that it can also handle trip context (branches with trip artifacts but no tickets). If story-writer cannot detect trip artifacts, the trip mode step in `report.md` may need to pass context hints. (`plugins/work/agents/story-writer.md`)
- Archived tickets and trip artifacts in `.workaholic/` contain many historical references to `write-trip-report`. These are read-only historical records and do not need updating. (`.workaholic/tickets/archive/`, `.workaholic/trips/`)
- The `work:trip-protocol` skill preload in `report.md` (line 5) is independent of write-trip-report and may still be needed for trip context detection. Do not remove it in this ticket. (`plugins/core/commands/report.md` line 5)
- Story files in `.workaholic/stories/` that mention write-trip-report are historical narratives and should not be modified. (`.workaholic/stories/`)
