---
created_at: 2026-09-03T10:13:20+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-maintenance-tick-s-channel-presence-help-the-work-along
merge_policy:
verification_handoff: 
---

# Take the tick's own counters out of a question addressed to a person

## Overview

`未到達 0 件、未所属 1 件を残します` is the tick's own bookkeeping in a sentence addressed to a
person: it says what the counters will hold afterwards. Nobody asked. Remove the counter sentence
from the question body; what the reader needs is what the direction achieved, which ticket 4
supplies.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/user-experience.md` — the reader of the post is the user here
