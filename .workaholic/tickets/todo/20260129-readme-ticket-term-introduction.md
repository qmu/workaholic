# Add Ticket Term Introduction to README.md

## Overview

Add a brief explanation of what "ticket" means in the TiDD context, placed after the opening paragraph. Users should immediately understand the mental model without reading lengthy documentation.

## Background

The current README opens with the TiDD concept but jumps straight to installation. Users unfamiliar with the term "ticket" in this context may not picture what they're working with. A short, evocative definition bridges understanding.

## Related History

Previous documentation tickets established README.md as the primary entry point with a pattern of concise introductions followed by practical examples. Multi-language documentation policies allow English-only in root files.

## Key Files

- `README.md` - Target file for the addition

## Implementation

1. Insert a short paragraph after line 3 (after "...ticket-driven development (TiDD).")
2. Define "ticket" in 1-2 sentences:
   - What it is: a markdown file describing intended change
   - Where it lives: in the repo, tracked by git
   - Why it matters: becomes permanent record of intent

Example addition:
```markdown
A **ticket** is a markdown file that describes a change you want to make—the context, the plan, the rationale. It lives in your repo, committed alongside the code it produced, so future sessions can trace why things are the way they are.
```

## Verification

- [ ] README still renders correctly
- [ ] Flow from TiDD intro → ticket definition → benefits feels natural
- [ ] No redundancy with existing paragraphs
