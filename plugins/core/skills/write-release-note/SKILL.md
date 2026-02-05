---
name: write-release-note
description: Release note content structure and guidelines for GitHub Releases.
user-invocable: false
---

# Write Release Note

Generate concise release notes from a branch story for GitHub Releases.

## Content Structure

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

## Guidelines

1. **Summary**: Extract the essence of section 1 (Overview) from the story. Keep it under 50 words.

2. **Key Changes**: Use the highlights from section 1. If fewer than 3 highlights, summarize the most impactful changes from section 4 (Changes).

3. **Metrics**: Extract from story frontmatter:
   - `tickets_completed` field
   - `commits` field
   - `duration_hours` field (round to 1 decimal)

4. **Links**: Include absolute GitHub URLs when available.

## Output Location

Write release notes to `.workaholic/release-notes/<branch-name>.md`

## Writing Style

- Use active voice
- Focus on user-facing impact
- Keep total length under 200 words
- No emojis
- No technical jargon unless necessary
