---
created_at: 2026-09-03T10:13:20+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-maintenance-tick-s-channel-presence-help-the-work-along
merge_policy:
verification_handoff: 
---

# Keep the tick's internals out of every rendered post

## Overview

The morning's root printed `tick-day:20260903` and a sentence explaining which internal step
would have handled a thing it decided not to say. `render-tick-post.sh` prints neither — its own
header records that the token is not rendered — so the internals entered at the **composing**
surface, where the agent renders the post from `commands/moderate.md`. State the rule where the
composition happens and pin it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/user-experience.md` — the reader of the post is the user here
