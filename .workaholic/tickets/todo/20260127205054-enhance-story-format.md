---
created_at: 2026-01-27T20:50:54+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Enhance story format with analysis sections and fixes

## Overview

The story-writer agent needs three improvements:

1. **Shorter Journey descriptions**: The Journey section is too verbose; keep it more concise
2. **Fix commit hash links in Changes**: The `([hash](commit-url))` format produces dead links when viewing the story file directly in GitHub because the URL is constructed with the commit hash, but the hash may not be pushed yet or may change after rebase
3. **Add new sections**: Insert three new sections before Performance:
   - 6. Historical Analysis - Context from related past work
   - 7. Concerns - Risks, trade-offs, or issues discovered
   - 8. Ideas - Enhancement or improvement suggestions for future work

After changes, the section order will be:
1. Summary → 2. Motivation → 3. Journey → 4. Changes → 5. Outcome → 6. Historical Analysis → 7. Concerns → 8. Ideas → 9. Performance → 10. Notes

## Key Files

- `plugins/core/agents/story-writer.md` - Main agent defining story structure and sections

## Related History

Past tickets that touched similar areas:

- `20260127182720-improve-story-changes-granularity.md` - Modified Journey/Changes format (same file)
- `20260127163720-simplify-topic-tree-as-journey-reference.md` - Modified story-writer format (same file)
- `20260127100459-add-topic-tree-to-story.md` - Added topic tree section (same file)
- `20260127004417-story-writer-subagent.md` - Created the story-writer agent (same file)

## Implementation Steps

1. Update Journey section guidance in `plugins/core/agents/story-writer.md`:
   - Reduce recommended word count (e.g., 50-100 words instead of 100-200)
   - Emphasize brevity: "high-level summary only, let flowchart carry detail"

2. Fix Changes section commit links:
   - Change format from `([hash](https://github.com/.../commit/hash))` to just `(hash)` or `[hash]`
   - OR: Use relative path that works in PR context: `([hash](../../commit/hash))`
   - The link should work when viewed in GitHub PR description, not just in the raw file

3. Add section "## 6. Historical Analysis" after Outcome:
   - Summarize related past work from archived tickets
   - Reference the "Related History" data already gathered by ticket command
   - Show patterns: what similar problems were solved before

4. Add section "## 7. Concerns" after Historical Analysis:
   - Risks or trade-offs discovered during implementation
   - Known limitations or edge cases
   - Things reviewers should pay attention to

5. Add section "## 8. Ideas" after Concerns:
   - Enhancement suggestions for future work
   - Improvements that were out of scope
   - "Nice to have" features identified during implementation

6. Renumber existing sections:
   - Performance becomes section 9
   - Notes becomes section 10

7. Update the template example to show all 10 sections

## Considerations

- The commit link fix needs to work in multiple contexts:
  - Viewing story file directly on GitHub
  - Viewing PR description (which uses story content)
  - Local markdown preview
- Historical Analysis draws from ticket Related History - may be empty if no related tickets
- Concerns/Ideas sections should be optional (can be "None" if nothing to report)
