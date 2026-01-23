# Update CLAUDE.md for Bilingual .work/ Directory Policy

## Overview

Update the "Written Language" section in CLAUDE.md to allow both English and Japanese for content within the `.work/` directory, while maintaining English-only policy for all other artifacts (code, code comments, commit messages, pull requests, etc.).

## Key Files

- `CLAUDE.md` - Update the Written Language section with the new bilingual policy

## Implementation Steps

1. Update the "Written Language" section in `CLAUDE.md` to:
   - Declare that `.work/` directory content can be written in either English or Japanese
   - Explicitly state that all other content (code, code comments, commit messages, PRs) must remain in English
   - Keep the section concise and clear

2. Suggested new section content:

```markdown
## Written Language

- **`.work/` directory**: English or Japanese (bilingual)
- **All other content**: English only
  - Code and code comments
  - Commit messages
  - Pull requests
  - Documentation outside `.work/`
```

## Considerations

- The `.work/` directory contains working artifacts (specs, tickets, stories, changelogs, terminology) that may benefit from Japanese language support for Japanese-speaking contributors
- Keeping code, commits, and PRs in English ensures broader accessibility and maintains consistency in the codebase
- This change is specific to the Workaholic project and doesn't affect the general multi-language documentation policy in the plugin
