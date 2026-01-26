---
created_at: 2026-01-26T13:52:12+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add commit_hash to Stories README

## Overview

Add `commit_hash` frontmatter field to `.workaholic/stories/README.md` (and its Japanese translation) to match other `.workaholic/` READMEs. This enables Claude to quickly determine the git state of the stories documentation and identify what changes need to be reflected.

## Key Files

- `.workaholic/stories/README.md` - Add `commit_hash` field to frontmatter
- `.workaholic/stories/README_ja.md` - Add `commit_hash` field to frontmatter

## Implementation Steps

1. Add `commit_hash` field to `.workaholic/stories/README.md` frontmatter:
   ```yaml
   ---
   title: Stories
   description: Branch development narratives that serve as PR descriptions
   category: developer
   last_updated: 2026-01-24
   commit_hash: <current-short-hash>
   ---
   ```

2. Add the same `commit_hash` field to `.workaholic/stories/README_ja.md` frontmatter

3. Get the current short commit hash using: `git rev-parse --short HEAD`

## Considerations

- This is a simple frontmatter addition, consistent with other READMEs in `.workaholic/`
- The `commit_hash` allows Claude to run `git log <hash>..HEAD` to see what changed since the README was last updated
- Future edits to these READMEs should update the `commit_hash` along with `last_updated`
