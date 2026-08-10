---
type: Feedback
title: Version-binding gate in /implement's survey step stops the whole session instead of warning and continuing
kind: instruction
source: discussion
created_at: 2026-08-10T08:58:23+00:00
author: a@qmu.jp
supersedes: 
---

# Version-binding gate in /implement's survey step stops the whole session instead of warning and continuing

`/implement`'s survey step (`check-deps/scripts/check.sh`) terminates the entire run on `loaded_version_behind_registry`, `registry_unreadable`, or `unbound_in_claude_session` — before ever surveying. This is disproportionate: a full stop strands unattended work worse than a warned continuation would. This generalizes a correction already recorded in FB `20260810070110-implement-routine-over-blocks-on-unbound-in-claude-session.md` (the unbound-session over-block) — that same warn-and-continue fix should be broadened to cover all three gate conditions above, not just the unbound-session case.
