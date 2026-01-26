---
created_at: 2026-01-27T01:04:12+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.25h
commit_hash: d142373
category: Removed
---

# Remove /sync-workaholic command

## Overview

The `/sync-workaholic` command is now redundant because `/pull-request` already runs both spec-writer and terminology-writer subagents as part of its documentation generation step (step 4). There's no need for a standalone command that does a subset of what `/pull-request` already does.

**Functionality comparison:**
- `/sync-workaholic`: runs spec-writer + terminology-writer
- `/pull-request` step 4: runs spec-writer + terminology-writer + changelog-writer + story-writer

Since `/pull-request` is the recommended workflow and includes sync functionality, the standalone command can be removed to reduce maintenance burden and user confusion.

## Key Files

- `plugins/core/commands/sync-workaholic.md` - Delete this file
- `plugins/core/README.md` - Remove `/sync-workaholic` from command table
- `.workaholic/specs/user-guide/commands.md` - Remove `/sync-workaholic` section
- `.workaholic/specs/user-guide/commands_ja.md` - Remove `/sync-workaholic` section
- `.workaholic/specs/user-guide/workflow.md` - Update reference to removed command
- `.workaholic/specs/user-guide/workflow_ja.md` - Update reference to removed command
- `.workaholic/specs/developer-guide/architecture.md` - Remove sync-workaholic.md from file tree
- `.workaholic/specs/developer-guide/architecture_ja.md` - Remove sync-workaholic.md from file tree
- `.workaholic/terminology/workflow-terms.md` - Update sync definition (remove command reference)
- `.workaholic/terminology/workflow-terms_ja.md` - Update sync definition (remove command reference)
- `.workaholic/terminology/core-concepts.md` - Remove agent orchestration example
- `.workaholic/terminology/core-concepts_ja.md` - Remove agent orchestration example

## Implementation Steps

1. Delete `plugins/core/commands/sync-workaholic.md`

2. Update `plugins/core/README.md`:
   - Remove row `| /sync-workaholic | ... |` from the commands table

3. Update `.workaholic/specs/user-guide/commands.md`:
   - Remove the entire `### /sync-workaholic` section
   - Update the "Typical workflow" list to remove step 4 about `/sync-workaholic`

4. Update `.workaholic/specs/user-guide/commands_ja.md`:
   - Remove the entire `### /sync-workaholic` section
   - Update the "一般的なワークフロー" list to remove step 4

5. Update `.workaholic/specs/user-guide/workflow.md`:
   - Change "automatically runs `/sync-workaholic`" to "automatically runs spec-writer and terminology-writer subagents"

6. Update `.workaholic/specs/user-guide/workflow_ja.md`:
   - Same change as above in Japanese

7. Update `.workaholic/specs/developer-guide/architecture.md`:
   - Remove `sync-workaholic.md # /sync-workaholic command` from the file tree
   - Remove the sentence about running `/sync-workaholic` directly

8. Update `.workaholic/specs/developer-guide/architecture_ja.md`:
   - Same changes as above in Japanese

9. Update `.workaholic/terminology/workflow-terms.md`:
   - In the "sync" term, remove reference to `/sync-workaholic` command
   - Update usage patterns to remove command reference

10. Update `.workaholic/terminology/workflow-terms_ja.md`:
    - Same changes as above in Japanese

11. Update `.workaholic/terminology/core-concepts.md`:
    - Remove the line about `/sync-workaholic` orchestrating subagents

12. Update `.workaholic/terminology/core-concepts_ja.md`:
    - Same change as above in Japanese

## Considerations

- Historical references in `.workaholic/tickets/archive/` and `.workaholic/stories/` should NOT be modified - they document what happened
- The CHANGELOG.md entries about sync-workaholic are historical records and should remain
- Users who have learned about `/sync-workaholic` will need to learn that `/pull-request` handles documentation sync automatically

## Final Report

Development completed as planned.
