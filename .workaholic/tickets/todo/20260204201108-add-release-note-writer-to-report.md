---
created_at: 2026-02-04T20:11:08+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Config]
effort:
commit_hash:
category:
---

# Add release-note-writer Subagent to /report Command

## Overview

Add a `release-note-writer` subagent to the `/report` command workflow that generates concise release notes from the branch story. The release notes will be written to a dedicated file that the GitHub Actions release workflow can use when creating GitHub Releases.

## Key Files

- `plugins/core/agents/release-note-writer.md` - New subagent to create
- `plugins/core/skills/write-release-note/SKILL.md` - New skill for release note structure
- `plugins/core/agents/story-writer.md` - Modify to invoke release-note-writer in Phase 1
- `plugins/core/skills/write-story/SKILL.md` - Update agent output mapping table
- `.github/workflows/release.yml` - Modify to use generated release notes file

## Related History

The codebase shows a consistent pattern of extracting documentation generation into dedicated subagents that run in parallel within story-writer. The release workflow currently extracts notes from git commit messages, which misses the structured narrative context.

Past tickets that touched similar areas:

- [20260127004417-story-writer-subagent.md](.workaholic/tickets/archive/feat-20260126-214833/20260127004417-story-writer-subagent.md) - Established story-writer subagent pattern (same file: story-writer.md)
- [20260127005414-changelog-writer-subagent-and-concurrent-pr-agents.md](.workaholic/tickets/archive/feat-20260126-214833/20260127005414-changelog-writer-subagent-and-concurrent-pr-agents.md) - Established parallel subagent invocation pattern (same pattern)
- [20260127205856-add-release-preparation-to-story.md](.workaholic/tickets/archive/feat-20260126-214833/20260127205856-add-release-preparation-to-story.md) - Added release-readiness subagent to /report workflow (same integration point)
- [20260129140000-add-release-github-action.md](.workaholic/tickets/archive/feat-20260129-023941/20260129140000-add-release-github-action.md) - Created GitHub Actions release workflow (same file: release.yml)

## Implementation Steps

1. **Create write-release-note skill** at `plugins/core/skills/write-release-note/SKILL.md`:
   - Define release note content structure
   - Include guidelines for summarizing branch story
   - Define key indicators format (metrics, counts, impact measures)
   - Template for GitHub Release-compatible markdown

2. **Create release-note-writer subagent** at `plugins/core/agents/release-note-writer.md`:
   - Tools: Read, Write, Glob, Grep
   - Skills: write-release-note
   - Input: Branch name, story file path
   - Tasks:
     - Read the branch story file
     - Extract overview, highlights, and key metrics
     - Generate concise release note (100-200 words)
     - Write to `.workaholic/release-notes/<branch-name>.md`
   - Output JSON:
     ```json
     {
       "release_note_file": ".workaholic/release-notes/<branch-name>.md",
       "summary": "Brief one-line summary",
       "metrics": {
         "tickets_completed": 6,
         "commits": 12,
         "duration_hours": 1.0
       }
     }
     ```

3. **Update story-writer.md** to invoke release-note-writer:
   - Add to Phase 1 parallel agent invocation (becomes 5 agents instead of 4)
   - Pass branch name and story file path
   - Include in output JSON `agents` object

4. **Update write-story skill** Agent Output Mapping table:
   - Add row for release-note-writer (writes separate file, no story section)

5. **Modify release.yml** to use generated release notes:
   - Check for `.workaholic/release-notes/<branch-name>.md` file
   - If exists, use its content for GitHub Release notes
   - Fall back to git log extraction if file not found

6. **Create release-notes directory**:
   - Add `.workaholic/release-notes/README.md` index file
   - Pattern follows `.workaholic/stories/` structure

## Release Note Content Structure

```markdown
## Summary

[2-3 sentence overview extracted from story section 1]

## Key Changes

- [Highlight 1 from story]
- [Highlight 2 from story]
- [Highlight 3 from story]

## Metrics

- **Tickets Completed**: N
- **Commits**: N
- **Duration**: N hours

## Links

- [Pull Request](PR-URL)
- [Branch Story](.workaholic/stories/<branch-name>.md)
```

## Considerations

- **Parallel execution**: release-note-writer should run alongside other Phase 1 subagents for performance
- **Idempotency**: Running /report multiple times should overwrite the release note file, not duplicate it
- **Fallback behavior**: GitHub Actions should gracefully fall back to git log if release note file is missing (for branches created before this feature)
- **File cleanup**: Release notes for merged branches are archived with the story (no separate cleanup needed)
- **Order of operations**: The release-note-writer needs the story file to exist, so it may need to run in Phase 2 after story file is written, or read from archived tickets directly like the overview-writer does

## Final Report

Development completed with adjusted phase ordering:
- Phase 3: Commit and Push Story (enables PR creation)
- Phase 4: Generate Release Note AND Create PR (parallel)
- Phase 5: Commit and Push Release Notes (added to existing PR)

Created write-release-note skill and release-note-writer subagent. Updated story-writer to orchestrate the new agent in parallel with pr-creator. Updated release.yml to use generated release notes with fallback to git log.
