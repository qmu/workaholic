---
created_at: 2026-01-31T23:45:35+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Enforce Changes Section Formatting Rules in write-story Skill

## Overview

The story-writer subagent ignores two critical formatting rules from the write-story skill: (1) commit hashes must be GitHub-linked, and (2) the change list should be comprehensive. Current output shows plain hashes like `(06f8791)` instead of linked `([06f8791](https://github.com/qmu/workaholic/commit/06f8791))`, and provides abbreviated 1-2 sentence summaries instead of detailed change lists.

## Current Behavior

Generated Changes section:
```markdown
### 4.1. Rename fail/ Directory to abandoned/ (06f8791)

The .workaholic/tickets/fail/ directory was renamed to .workaholic/tickets/abandoned/...
```

Issues:
1. **Hash not linked**: `(06f8791)` should be `([06f8791](https://github.com/qmu/workaholic/commit/06f8791))`
2. **Abbreviated content**: Brief paragraph instead of itemized list of actual changes

## Expected Behavior

```markdown
### 4.1. Rename fail/ Directory to abandoned/ ([06f8791](https://github.com/qmu/workaholic/commit/06f8791))

- Renamed physical directory from `.workaholic/tickets/fail/` to `.workaholic/tickets/abandoned/`
- Updated `plugins/core/skills/handle-abandon/SKILL.md` path references
- Updated `.workaholic/tickets/README.md` structure diagram and section heading
- Updated `.workaholic/terms/file-conventions.md` term definition (English)
- Updated `.workaholic/terms/file-conventions_ja.md` term definition (Japanese)
- Updated `.workaholic/terms/workflow-terms.md` directory path
- Updated `.workaholic/terms/workflow-terms_ja.md` directory path
- Updated `.workaholic/terms/artifacts.md` failure-analysis section
- Updated `.workaholic/terms/artifacts_ja.md` failure-analysis section
```

## Key Files

| File | Purpose |
|------|---------|
| `plugins/core/skills/write-story/SKILL.md` | Has correct format spec but needs stronger enforcement language |
| `plugins/core/agents/story-writer.md` | Invokes write-story skill; may need explicit reminders |

## Related History

- [20260128-commit-hash-links-in-story.md](.workaholic/tickets/archive/feat-20260128-012023/20260128-commit-hash-links-in-story.md) - Added GitHub link format to write-story skill (already implemented but not followed)
- [20260127182720-improve-story-changes-granularity.md](.workaholic/tickets/archive/feat-20260126-214833/20260127182720-improve-story-changes-granularity.md) - Defined one subsection per ticket format

## Implementation

### 1. Strengthen write-story Skill Guidelines

Update `plugins/core/skills/write-story/SKILL.md` Changes section (around lines 96-114):

**A. Add explicit "MUST" language for commit links:**

```markdown
### 4.1. <Ticket title> ([hash](https://github.com/qmu/workaholic/commit/hash))

**CRITICAL**: The commit hash MUST be a clickable GitHub link, not plain text.
- Wrong: `(06f8791)` or `(hash)`
- Correct: `([06f8791](https://github.com/qmu/workaholic/commit/06f8791))`
```

**B. Replace "Brief 1-2 sentence" with comprehensive itemized list:**

```markdown
- **List each file changed** with what was modified
- Format as bullet points, not paragraph prose
- Include all files touched, not just "primary" changes
- Reference ticket Implementation Steps for the complete list
```

**C. Add example of comprehensive change entry:**

```markdown
### 4.1. Add Feature X ([abc1234](https://github.com/qmu/workaholic/commit/abc1234))

- Added `src/feature.ts` with main logic
- Updated `src/index.ts` exports to include Feature X
- Added `tests/feature.test.ts` test coverage
- Updated `README.md` documentation
- Updated `CHANGELOG.md` with Added entry
```

### 2. Update story-writer Agent Instructions

Update `plugins/core/agents/story-writer.md` to add explicit reminder:

```markdown
## Critical Format Rules

When writing section 4 (Changes):
1. Commit hash MUST be GitHub-linked: `([hash](https://github.com/qmu/workaholic/commit/hash))`
2. List ALL files changed as bullet points, not prose paragraphs
3. Reference archived ticket's changes list or Implementation Steps for completeness
```

## Considerations

- The write-story skill already has the correct format specification, but Claude ignores it
- Adding "CRITICAL" and "MUST" language helps emphasize non-negotiable requirements
- Providing explicit wrong vs. correct examples prevents ambiguity
- The story-writer agent needs explicit reminders since it may not fully read preloaded skills
