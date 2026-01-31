---
created_at: 2026-01-31T20:35:00+09:00
author: tamurayoshiya@gmail.com
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: 16887e9
category: Changed
---

# Shorten Verbose Story Sections by Half

## Overview

Add explicit word count constraints to story sections 2, 3, 5, 6, 7, 8, 9.1, and 11 in the write-story skill. Current sections are too verbose; each should be reduced to approximately half their typical length.

## Motivation

Generated stories are overly long, making PR descriptions difficult to scan. Key sections like Motivation, Journey, Outcome, and Historical Analysis often run 100-200+ words when 50-100 words would convey the essential information. Shorter sections improve readability and focus reviewer attention on the Changes section (which should remain detailed).

## Key Files

- `plugins/core/skills/write-story/SKILL.md` - Add word count constraints to section templates

## Related History

- [20260127205054-enhance-story-format.md](.workaholic/tickets/archive/feat-20260126-214833/20260127205054-enhance-story-format.md) - Previously shortened Journey to 50-100 words; this ticket extends the pattern
- [20260124005056-story-as-pr-description.md](.workaholic/tickets/archive/feat-20260123-191707/20260124005056-story-as-pr-description.md) - Established story as PR description source

## Implementation

### 1. Update Section Templates with Word Limits

Modify the section templates in `plugins/core/skills/write-story/SKILL.md`:

**Section 2. Motivation** (line ~62):
```markdown
## 2. Motivation

[Why this work started. 40-60 words max. Synthesize ticket Overviews into a single paragraph.]
```

**Section 3. Journey** (already has 50-100 words guideline, keep as-is)

**Section 5. Outcome** (line ~116):
```markdown
## 5. Outcome

[What was achieved. 40-60 words max. Focus on key accomplishments, not exhaustive listing.]
```

**Section 6. Historical Analysis** (line ~120):
```markdown
## 6. Historical Analysis

[Related past work context. 30-50 words max. Or "No related historical context." if none.]
```

**Section 7. Concerns** (line ~124):
```markdown
## 7. Concerns

[Risks or trade-offs. 30-50 words max per concern. Or "None" if nothing to report.]
```

**Section 8. Ideas** (line ~128):
```markdown
## 8. Ideas

[Future enhancement suggestions. 30-50 words max. Bullet list preferred. Or "None" if nothing.]
```

**Section 9.1. Pace Analysis** (line ~136):
```markdown
### 9.1. Pace Analysis

[Quantitative reflection on velocity. 30-50 words max. State pattern (steady/varied), commit size observation, notable timing.]
```

**Section 11. Notes** (line ~199):
```markdown
## 11. Notes

[Additional context. 30-50 words max. Or omit section if nothing relevant.]
```

### 2. Update Writing Guidelines

Modify the Writing Guidelines section (line ~222) to add summary:

```markdown
## Writing Guidelines

- Write in third person ("The developer discovered..." not "I discovered...")
- Connect tickets into a narrative arc, not a list
- Highlight decision points and trade-offs
- **Section length targets:**
  - Motivation/Outcome: 40-60 words
  - Journey prose: 50-100 words (let flowchart carry detail)
  - Historical Analysis/Concerns/Ideas/Pace Analysis/Notes: 30-50 words each
  - Changes section: detailed (no limit, one entry per ticket)
- Historical Analysis/Concerns/Ideas can be "None" if empty
```

## Verification

1. Generate a story with `/story` and verify sections are shorter
2. Compare with existing story (feat-20260131-125844.md):
   - Section 2 Motivation: ~150 words → should be ~50 words
   - Section 5 Outcome: ~100 words → should be ~50 words
   - Section 6 Historical Analysis: ~100 words → should be ~40 words
   - Section 9.1 Pace Analysis: ~80 words → should be ~40 words

## Notes

- Section 4 (Changes) intentionally has no word limit - it should remain detailed
- Section 9.2 (Decision Review) is a table and doesn't need word limits
- Section 10 (Release Preparation) is structured data from JSON, no changes needed
