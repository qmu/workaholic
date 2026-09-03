---
created_at: 2026-09-03T10:13:20+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-maintenance-tick-s-channel-presence-help-the-work-along
merge_policy:
verification_handoff: 
---

# Ask one question per kind naming every subject, not one per subject

## Overview

One morning sent five `🙋` questions in twenty-four seconds, three of them the same sentence
with a direction slug swapped. `lib/question-id.sh` derives a question id per **subject**, so a
step with N candidates asks N questions, and the per-tick cap only spaces them out. Make a step
able to ask **one** question of a kind that names every subject it holds, so three arrived
directions cost one reply.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/user-experience.md` — the reader of the post is the user here
