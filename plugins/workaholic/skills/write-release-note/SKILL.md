---
name: write-release-note
description: Release note content structure and guidelines for GitHub Releases.
user-invocable: false
---

# Write Release Note

Generate concise release notes from a branch story for GitHub Releases.

## Content Structure

```markdown
# <Story Title>

## Summary

<2-3 sentence overview extracted from story section 1>

## Key Changes

- <Highlight 1 from story>
- <Highlight 2 from story>
- <Highlight 3 from story>

## Changes

### Added
- <Entry from story Section 4 where ticket category is "Added">

### Changed
- <Entry from story Section 4 where ticket category is "Changed">

### Removed
- <Entry from story Section 4 where ticket category is "Removed">

## Metrics

- **Tickets Completed**: <tickets_completed from frontmatter>
- **Commits**: <commits from frontmatter>
- **Duration**: <duration_days from frontmatter> days (<duration_hours from frontmatter> hours)
- **Velocity**: <velocity from frontmatter> commits/<velocity_unit from frontmatter>

## Links

- [Pull Request](PR-URL)
- [Branch Story](.workaholic/stories/<branch-name>.md)
```

## Guidelines

1. **Summary**: Extract the essence of section 1 (Overview) from the story. Keep it under 50 words.

2. **Story Title (H1)**: Extract the first highlight from section 1 (Overview). Use the same derivation logic as PR title: first highlight text, appending "etc" if multiple highlights exist.

3. **Key Changes**: Use the highlights from section 1. If fewer than 3 highlights, summarize the most impactful changes from section 4 (Changes).

4. **Changes**: Group entries from story Section 4 by category (Added, Changed, Removed). The ticket `category` frontmatter is the immediate source; each commit also carries a `Category:` git trailer (the resilient, log-native source that survives ticket pruning — read it via `git log --format='%(trailers:key=Category,valueonly)'` when the frontmatter is unavailable). Each entry should be a concise one-line summary; omit empty subsections.

5. **Metrics**: Extract from story frontmatter:
   - `tickets_completed` field
   - `commits` field
   - `duration_hours` field (round to 1 decimal place)
   - `duration_days` field (use when available)
   - Format duration as: "N days (N hours)" when both fields exist, "N hours" when only hours exist
   - `velocity` field (round to 1 decimal place)
   - `velocity_unit` field
   - Format velocity as: "N commits/<unit>"
   - Omit velocity line when fields are absent

6. **Links**: The PR URL is provided as input (by the `workaholic:ship` Ship Flow, from its `pre-check.sh` output). Always include it.

## Output Location

This skill runs at **ship time** (the `workaholic:ship` Ship Flow generates the note before merging), so one branch can produce several notes across multiple ships:

- **First release on a branch**: `.workaholic/release-notes/<branch-name>.md`
- **Additional releases on the same branch** (subsequent ships): `.workaholic/release-notes/<branch-name>-<N>.md` (`-2`, `-3`, …), so each ship's release record is preserved separately.

Pick the next free `-<N>` suffix when `<branch-name>.md` already exists.

## Writing Style

- Use active voice
- Focus on user-facing impact
- Keep total length under 200 words
- No emojis
- No technical jargon unless necessary
