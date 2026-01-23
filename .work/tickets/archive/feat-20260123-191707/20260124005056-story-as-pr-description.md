# Refactor Story to Be PR Description

## Overview

Refactor the story format to contain the complete PR description content, then simplify the pull-request command to generate the story and copy it directly to the PR body. This eliminates duplication between story generation and PR description generation, making stories the single source of truth for PR content.

## Key Files

- `plugins/core/commands/pull-request.md` - Simplify to generate story then copy to PR
- `.work/stories/README.md` - Update to reflect new comprehensive story format

## Current State

**Story format** (narrative only):
- Motivation, Journey, Outcome, Performance sections
- Generated during `/pull-request` step 6

**PR description format** (in pull-request.md):
- Summary (numbered list from CHANGELOG)
- Story (Motivation + Journey from story file)
- Changes (detailed explanations from CHANGELOG)
- Performance (from story file)
- Notes

**Problem**: PR description is assembled from multiple sources (CHANGELOG + story), requiring complex logic in pull-request command.

## Target State

**New story format** (complete PR content):
```markdown
---
branch: <branch-name>
started_at: YYYY-MM-DDTHH:MM:SS+TZ
ended_at: YYYY-MM-DDTHH:MM:SS+TZ
tickets_completed: <count>
commits: <count>
duration_hours: <number>
velocity: <number>
---

Refs #<issue-number>

## Summary

1. First meaningful change (from CHANGELOG)
2. Second meaningful change (from CHANGELOG)
3. ...

## Motivation

[Why this work was needed - synthesized from ticket Overviews]

## Journey

[How the work progressed - narrative from ticket Final Reports]

## Changes

### 1. First meaningful change

Detailed explanation from CHANGELOG description.

### 2. Second meaningful change

Detailed explanation from CHANGELOG description.

## Outcome

[What was accomplished - summary of results]

## Performance

**Metrics**: X commits over Y hours (Z commits/hour)

### Pace Analysis
[Quantitative reflection on development pace]

### Decision Review
[Output from performance-analyst subagent]

## Notes

Additional context for reviewers.
```

**Simplified pull-request command**:
1. Check remaining tickets → move to icebox
2. Consolidate CHANGELOG
3. Sync documentation
4. **Generate comprehensive story** (reads CHANGELOG + archived tickets + git log)
5. Format changed files
6. Check if PR exists
7. **Copy story content to PR** (strip frontmatter, use as body)

## Implementation Steps

1. **Update story format in pull-request.md step 6**:
   - Add Summary section (from CHANGELOG entry titles)
   - Rename "Motivation" as-is
   - Rename "Journey" as-is
   - Add Changes section (from CHANGELOG descriptions)
   - Keep Outcome section
   - Keep Performance section
   - Add Notes section (optional, for reviewer context)
   - Include `Refs #<issue>` at the top of content

2. **Simplify PR generation steps 9-11**:
   - Remove CHANGELOG parsing for PR (already done in story)
   - Remove separate PR description assembly
   - Just read story file and use content (minus YAML frontmatter) as PR body

3. **Update PR title derivation**:
   - Derive from story's Summary section (first item or "First item etc" if multiple)

4. **Update .work/stories/README.md**:
   - Document new comprehensive format
   - Explain that stories are the single source of truth for PR content

## Considerations

- **Single source of truth**: Stories become the authoritative PR content, reducing duplication
- **Story readability**: Stories are now longer but more useful as standalone documents
- **Frontmatter preservation**: YAML frontmatter stays in story file but is stripped when copying to PR
- **CHANGELOG still needed**: CHANGELOG is the source data; story synthesizes it into PR format
- **Backwards compatibility**: Existing stories won't match new format, but that's acceptable for working artifacts

## Final Report

Development completed as planned.
