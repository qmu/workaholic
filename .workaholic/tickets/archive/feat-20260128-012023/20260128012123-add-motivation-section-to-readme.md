---
created_at: 2026-01-28T01:21:23+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: 999b21c
category: Added
---

# Add Motivation Section to Root README

## Overview

Add a "Motivation" section to the root README.md that explains why Workaholic exists and the problems it solves. This section should make the project's approach relatable to users who are evaluating or onboarding.

## Related History

- [20260123162007-document-cognitive-investment-principle.md](.workaholic/tickets/archive/feat-20260123-032323/20260123162007-document-cognitive-investment-principle.md) - Established "Cognitive Investment" as a core design principle
- `.workaholic/README.md` already contains Design Policy with Cognitive Investment explanation

## Key Files

- `README.md` - Add new section after "Why Workaholic?" or replace/expand it

## Implementation Steps

1. Add a "Motivation" section to `README.md` after the tagline (before or instead of "Why Workaholic?")

2. The section should explain three core ideas in user-friendly prose:

   **Backlog as Historical Assets**
   - Tickets live in the repository, not external project management tools
   - AI and developers both access the same searchable history
   - Decisions and context are preserved as git-tracked artifacts

   **Parallel Generation, Serial Execution**
   - Single repository, single worktree (no git worktree complexity)
   - Multiple Claude Code sessions can generate tickets in parallel
   - One session drives implementation, asking developer for confirmation

   **AI-Powered Explanations**
   - AI generates commit messages, documentation, and PR descriptions
   - Developer focuses on decisions, AI handles the writing
   - Consistent, comprehensive documentation without manual effort

3. Keep it concise - one well-organized paragraph or 3-4 bullet points is ideal

4. Add a fourth bullet point "Cognitive Investment" within Motivation that combines semantic aspects (intuitivity, consistency, describability, density) in the same style as the other bullets

## Content Guidelines

- Write for developers evaluating the tool (not for contributors)
- Avoid jargon; explain the "why" not just the "what"
- Connect motivation to concrete commands (`/ticket`, `/drive`, `/report`)
- Keep the existing installation and quick start sections prominent

## Final Report

Implementation deviated from original plan:

- **Change**: Added fourth bullet "Cognitive Investment" combining semantic aspects into one item
  **Reason**: User requested semantic aspects (intuitivity, consistency, describability, density) be added as a single bullet point in the same style as the other three, not as separate bullets or a separate section
