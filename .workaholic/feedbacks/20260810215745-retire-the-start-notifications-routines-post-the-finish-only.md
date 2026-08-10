---
type: Feedback
title: Retire the start notifications - routines post the finish only
kind: instruction
source: discussion
created_at: 2026-08-10T21:57:45+09:00
author: a@qmu.jp
supersedes: 
---

# Retire the start notifications - routines post the finish only

The start notifications are retired: a routines unit posts **only its finish** — `🔵 Proposed` for `/propose`, and the outcome shape for `/implement` (`🟢 Implemented`, `🚀` merge, `🟡` handoff, `🔴` blocked). The developer ordered the beginning posts (`📐 Proposing`, `🟠 Implementing`) removed, and on 2026-08-10 both live routine records were edited accordingly — their prompts now instruct the finish post alone. The repository must catch up in the same direction: the routine templates (`skills/workaholify/routines/implement.md` and `fb.md`) still embed the start format as one of their two post shapes, and `workaholic:notify` still specifies "exactly one start and one finish per thread" with the `🟠 Implementing` / `📐 Proposing` literals as sanctioned shapes (P10). Drop the start event from both templates and from the notify model (SKILL.md and `reference/notifications.md`), leaving the finish-only contract, so the documented shapes and the live prompts stop drifting. The purpose the start post served — telling an absent operator a fleet is alive before any PR exists — is knowingly given up for the quieter channel; the claim-time bot line and the finish posts remain the operators signals.
