---
name: discover-ticket
description: Guidelines for analyzing existing tickets to detect duplicates, merge candidates, and split opportunities.
user-invocable: false
---

# Discover Ticket

Guidelines for analyzing existing tickets to determine if a proposed ticket should proceed, merge with existing, or trigger a split.

## Search Locations

Search these directories for existing tickets:

- `.workaholic/tickets/todo/*.md` - Pending tickets
- `.workaholic/tickets/icebox/*.md` - Deferred tickets

## Overlap Analysis Criteria

### Category Definitions

| Category | Overlap | Action |
|----------|---------|--------|
| **Duplicate** | 80%+ | Block creation - existing ticket covers request |
| **Merge candidate** | 40-80% | Suggest combining into single ticket |
| **Split candidate** | N/A | Existing ticket too broad - suggest decomposition |
| **Related** | <40% | Can coexist - note for cross-reference |

### Calculating Overlap Percentage

Evaluate overlap based on:

1. **Key files overlap**: Do tickets modify the same files?
   - Same primary file = +40%
   - Overlapping key files = +20% per file
2. **Scope overlap**: Do tickets solve the same problem?
   - Identical goal = +40%
   - Subset/superset relationship = +20%
3. **Implementation overlap**: Would work be duplicated?
   - Same code changes = +20%

### Duplicate Detection (80%+)

A ticket is a duplicate when:
- Same key files AND same implementation goal
- Existing ticket fully addresses the request
- Creating new ticket would duplicate completed work

Example: Request for "add validation to login form" when ticket exists for "implement form validation across auth pages"

### Merge Candidates (40-80%)

Tickets are merge candidates when:
- Significant key file overlap (2+ shared files)
- Related but distinct goals that benefit from unified approach
- Sequential dependencies that should be one atomic change

Example: "Add error handling to API client" and "Improve API timeout behavior" - both touch the same module

### Split Candidates

An existing ticket needs splitting when:
- Covers multiple distinct features/concerns
- Key files span unrelated areas
- Implementation steps lack cohesion
- Estimated effort exceeds 4h

Example: "Refactor user module and update dashboard" - these are unrelated concerns

### Related Tickets (<40%)

Tickets are related (not blocking) when:
- Minor file overlap (1 shared file)
- Same domain area but different goals
- Useful context but independent implementation

## Evaluation Process

1. **Extract keywords** from proposed ticket description
2. **Glob search** for tickets in todo/ and icebox/
3. **Read matching tickets** and compare:
   - Key Files sections
   - Implementation Steps
   - Overview goals
4. **Calculate overlap** per criteria above
5. **Categorize each match** and determine status

## Output Schema

Return structured JSON recommendation:

```json
{
  "status": "clear|duplicate|needs_decision",
  "matches": [
    {
      "path": ".workaholic/tickets/todo/filename.md",
      "title": "Ticket title from H1",
      "category": "duplicate|merge|split|related",
      "overlap_percentage": 85,
      "reason": "Specific explanation of overlap"
    }
  ],
  "recommendation": "Action to take"
}
```

### Status Values

| Status | Meaning | Next Action |
|--------|---------|-------------|
| `clear` | No blocking issues | Proceed with ticket creation |
| `duplicate` | Existing ticket covers request | Do not create new ticket |
| `needs_decision` | Merge/split opportunity found | User must decide strategy |

### Recommendation Examples

- `"Proceed"` - No conflicts found
- `"Block - duplicate of 20260101-feature.md"` - Exact duplicate exists
- `"Merge with 20260101-feature.md - both modify API client"` - Merge candidate
- `"Split 20260101-large-ticket.md before creating"` - Split candidate
- `"Proceed - related to 20260101-feature.md (cross-reference)"` - Related only
