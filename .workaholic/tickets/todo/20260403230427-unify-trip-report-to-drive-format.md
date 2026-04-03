---
created_at: 2026-04-03T23:04:27+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Unify Trip Report Format to Match Drive Report Structure

## Overview

The trip report (produced by `write-trip-report` skill) and the drive report (produced by the `report` skill via `story-writer`) use completely different formats. The drive report has a numbered 9-section structure (Overview, Motivation, Changes, Outcome, Historical Analysis, Concerns, Ideas, Release Preparation, Notes) with YAML frontmatter, while the trip report uses an agent-centric structure (Planner, Architect, Constructor, Journey, Trip Activity Log). This ticket unifies both by rewriting the trip report skill to produce output matching the drive report format, making the drive report skill the single authoritative template.

## Key Files

- `plugins/drivin/skills/report/SKILL.md` - The authoritative drive report format (Write Story section). This is the source of truth that the trip report must adopt.
- `plugins/trippin/skills/write-trip-report/SKILL.md` - The trip report skill that must be rewritten to produce drive-format output. Currently defines the Planner/Architect/Constructor/Journey/Trip Activity Log template.
- `plugins/trippin/skills/write-trip-report/scripts/gather-artifacts.sh` - Trip artifact gathering script. Still needed to collect trip-specific source data, but the output mapping changes.
- `plugins/core/commands/report.md` - The unified report command. Trip Context steps reference the write-trip-report skill; instructions may need updating to reflect the new format.
- `plugins/drivin/agents/story-writer.md` - The drive report orchestrator. Reference for how drive reports are generated (3 parallel agents, story file with frontmatter).

## Related History

The report infrastructure has been progressively unified: first the commands were merged into a single `/report`, then the story template was restructured from 11 to 9 sections, and trip format enforcement was strengthened. This ticket completes the unification by making the output format itself consistent.

Past tickets that touched similar areas:

- [20260311212022-unify-report-command-across-plugins.md](.workaholic/tickets/archive/drive-20260311-125319/20260311212022-unify-report-command-across-plugins.md) - Unified /report-drive and /report-trip into a single context-aware /report command (same concern: drive/trip unification)
- [20260329173605-restructure-story-template.md](.workaholic/tickets/archive/drive-20260329-173608/20260329173605-restructure-story-template.md) - Restructured story template from 11 to 9 sections, removing Performance and merging Journey into Changes (same file: report/SKILL.md)
- [20260328153616-enforce-trip-report-format-from-skill.md](.workaholic/tickets/archive/drive-20260326-183949/20260328153616-enforce-trip-report-format-from-skill.md) - Strengthened trip report format enforcement in both command and skill files (same file: write-trip-report/SKILL.md)
- [20260328150719-display-story-after-report.md](.workaholic/tickets/archive/drive-20260326-183949/20260328150719-display-story-after-report.md) - Added inline story display to both drive and trip report flows (same file: report.md)

## Implementation Steps

1. **Rewrite `plugins/trippin/skills/write-trip-report/SKILL.md`** to produce drive-format output:
   - Replace the current Planner/Architect/Constructor/Journey/Trip Activity Log template with the 9-section structure from `plugins/drivin/skills/report/SKILL.md` (Overview, Motivation, Changes, Outcome, Historical Analysis, Concerns, Ideas, Release Preparation, Notes)
   - Add YAML frontmatter to trip reports matching drive format: `branch`, `tickets_completed` (set to 0 or omit for trips since trips do not use tickets)
   - Define a mapping from trip artifacts to drive report sections:
     - **Overview**: Synthesize from direction artifact (goals, scope) into a 2-3 sentence summary with highlights
     - **Motivation**: Derive from direction artifact (stakeholder needs, the "why")
     - **Changes**: Use a Mermaid flowchart showing trip phases (planning, review, coding iterations) as the preamble, then summarize major implementation changes from the design artifact and git log. Use subsections (3-1, 3-2, etc.) keyed to significant commits or phases rather than tickets
     - **Outcome**: Summarize from test results, review summaries, and what was accomplished
     - **Historical Analysis**: Note if this trip relates to prior work; write "No related historical context." if none
     - **Concerns**: Extract from review artifacts (reviewer concerns, trade-offs identified)
     - **Ideas**: Extract from review artifacts (enhancement suggestions, out-of-scope improvements)
     - **Release Preparation**: For trips, default to "Ready for release" with no concerns unless the artifacts indicate otherwise
     - **Notes**: Include Trip Activity Log here if `has_event_log` is true (as a collapsed `<details>` block), and any additional context
   - Keep the `gather-artifacts.sh` invocation and JSON parsing unchanged
   - Keep the Extracting Summaries guidelines but reframe them for the new section targets
   - Remove the MANDATORY enforcement preamble (no longer needed since the format now matches the drive format)

2. **Update `plugins/core/commands/report.md`** Trip Context section:
   - Step 3: Remove the explicit "must use the exact template structure defined in the preloaded write-trip-report skill" enforcement language, since the trip skill now produces the same format as drive. Replace with a simpler reference: "Generate report following the preloaded write-trip-report skill."
   - Step 5: The PR creation should use `create-or-update.sh` from the report skill (same as drive) instead of raw `gh pr create`, since trip reports now have frontmatter that needs stripping. Update the script path to: `bash ${CLAUDE_PLUGIN_ROOT}/../drivin/skills/report/scripts/create-or-update.sh <branch-name> "<title>"`
   - Step 6: No change needed (display story content inline)
   - Apply the same `create-or-update.sh` update to the Trip Worktree Context flow (step 7)

3. **Update `plugins/core/commands/report.md`** to add frontmatter stripping for trip reports:
   - The drive flow uses `create-or-update.sh` which calls `strip-frontmatter.sh` internally. By routing trip reports through the same script, frontmatter stripping is handled automatically.

4. **Verify PR title derivation for trips**:
   - The current trip flow derives the PR title from the direction summary. The drive flow derives it from the first highlight in the Overview section. After unification, trip reports should follow the same derivation: extract from the Overview highlights, matching how `create-or-update.sh` expects to find the title.

## Considerations

- The trip report currently has no YAML frontmatter; adding it means `strip-frontmatter.sh` will be needed when creating PRs. This is already handled by `create-or-update.sh`, but the current trip flow bypasses that script and calls `gh pr create` directly. Routing through `create-or-update.sh` fixes this. (`plugins/core/commands/report.md` lines 57-62)
- The `gather-artifacts.sh` script output JSON structure does not change -- it still returns direction, model, design, reviews, event log, and history paths. Only the mapping of these artifacts to report sections changes. (`plugins/trippin/skills/write-trip-report/scripts/gather-artifacts.sh`)
- The drive report's Changes section uses per-ticket subsections (3-1, 3-2, etc.) keyed to `commit_hash` from ticket frontmatter. Trips do not have tickets, so the Changes subsections should be keyed to significant commits or implementation phases from the git log instead. The subsection format (3-N numbering, commit hash links) should remain consistent. (`plugins/drivin/skills/report/SKILL.md` lines 68-87)
- The existing trip report in `.workaholic/stories/trip-trip-20260319-squashed.md` uses the old format. This is a point-in-time document and does not need retroactive updating. (`.workaholic/stories/trip-trip-20260319-squashed.md`)
- The Trip Activity Log is a trip-specific artifact with no drive equivalent. Placing it in the Notes section (section 9) as a collapsed details block preserves the information without adding a non-standard section. If the event log is large, the collapsed block prevents the PR description from becoming unwieldy. (`plugins/trippin/skills/write-trip-report/SKILL.md` lines 79-81)
- This ticket is part 2 of 2 in a pair. The companion ticket handles adding development patterns to the story format. This ticket focuses solely on format unification and does not add new sections or content types beyond what already exists in the drive format.
- The drive report invokes 3 parallel subagents (release-readiness, overview-writer, section-reviewer) to populate sections. The trip report generates content inline from artifacts. This ticket does not change the generation mechanism -- only the output format. Trip reports will still be generated inline from artifacts, just structured to match the drive template. (`plugins/drivin/agents/story-writer.md`, `plugins/trippin/skills/write-trip-report/SKILL.md`)
