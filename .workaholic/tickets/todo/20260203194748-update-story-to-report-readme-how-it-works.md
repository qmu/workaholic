---
created_at: 2026-02-03T19:47:48+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
---

# Update /story Reference to /report in README.md How It Works Section

## Overview

Update a missed `/story` reference in README.md's "How It Works" section. The `/story` command was renamed to `/report` in commit 6265bac, but one reference was missed in the descriptive text on line 38.

## Key Files

- `README.md` - Contains the outdated `/story` reference in the "How It Works" section

## Related History

This is a follow-up to the /story -> /report rename. Similar missed references were caught and fixed in architecture.md (commit 978d741).

Past tickets that touched similar areas:

- [20260203180235-rename-story-to-report.md](.workaholic/tickets/archive/drive-20260203-122444/20260203180235-rename-story-to-report.md) - Original rename ticket that missed this reference

## Implementation Steps

1. Open `README.md`
2. Locate line 38 in the "How It Works" section
3. Change `/story` to `/report`

## Patches

### `README.md`

```diff
--- a/README.md
+++ b/README.md
@@ -35,7 +35,7 @@ A ticket is a markdown file describing a change you want to make—the context,

 Once tickets are queued, `/drive` implements them one by one with confirmation at each step. While one agent drives, others can keep creating tickets—no git worktree overhead, just serial execution with clear commits. The bottleneck is human cognition, not implementation speed.

-When ready to deliver, `/story` generates changelogs and PR descriptions from the accumulated ticket history. No manual summarization—the intent behind each change is already documented, so the narrative writes itself.
+When ready to deliver, `/report` generates changelogs and PR descriptions from the accumulated ticket history. No manual summarization—the intent behind each change is already documented, so the narrative writes itself.

 > [!NOTE]
 > **A flavor of Spec-Driven Development**
```

## Considerations

- This is a simple one-line text change
- No behavior changes, only documentation consistency
