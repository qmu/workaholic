# Move Documentation Update from /drive to /pull-request

## Overview

Documentation updates should happen at PR time, not during each ticket implementation. The doc-writer subagent should analyze all archived tickets for the branch and reorganize `doc/specs/for-user/` and `doc/specs/for-developer/` based on the cumulative changes. This provides a holistic view of what changed rather than incremental per-ticket updates.

## Key Files

- `plugins/tdd/commands/drive.md` - Remove section 2.3 (Update Documentation)
- `plugins/core/commands/pull-request.md` - Add documentation update step using doc-writer subagent

## Implementation Steps

1. **Update `plugins/tdd/commands/drive.md`**:

   - Remove entire section 2.3 "Update Documentation"
   - Renumber remaining sections (2.4 becomes 2.3, 2.5 becomes 2.4)
   - Update any cross-references to section numbers

2. **Update `plugins/core/commands/pull-request.md`**:

   - Add new step after CHANGELOG consolidation (step 3) and before PR check (step 4)
   - New step: "Update documentation using doc-writer subagent"
   - Instructions for the subagent:
     1. Read all archived tickets for this branch from `doc/tickets/archive/<branch-name>/`
     2. Analyze what changes were made across all tickets
     3. Plan documentation reorganization for `doc/specs/for-user/` and `doc/specs/for-developer/`
     4. Update, create, or delete documentation files as needed
     5. Commit documentation changes: "Update documentation for PR"

3. **Update doc-writer instructions** to handle batch ticket analysis:
   - Accept a directory of tickets to analyze (not just current changes)
   - Plan documentation holistically based on all tickets in the branch

## Considerations

- PR-time docs give a complete picture rather than per-ticket fragments
- Archived tickets in `doc/tickets/archive/<branch>/` contain all the context needed
- Documentation commit happens before PR creation, included in the PR
- This simplifies /drive by removing a step from each ticket iteration
