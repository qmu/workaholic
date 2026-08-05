---
type: Feedback
title: Routine Slack posts name the developer as inert text so nobody is notified
kind: instruction
source: discussion
created_at: 2026-08-05T02:04:01+00:00
author: a@qmu.jp
supersedes: 
---

# Routine Slack posts name the developer as inert text so nobody is notified

The routine templates in `plugins/workaholic/skills/workaholify/routines/` write the acting developer's name into their Slack lines as literal text — `@tamura_yoshiya` — rather than as Slack's `<@U…>` mention token. Slack renders only the token as a clickable mention that notifies; plain `@name` is inert, so a post reading "Proposal merged by @tamura_yoshiya" appears to call the person out while notifying nobody at all.

Five message formats across the three templates carry the `@<developer>` placeholder: `[Consent]`'s "Proposal merged by @" (`merged-pr.md`), `[Propose]`'s "Proposed to @" (`fb.md`), and `[Drive]`'s "Merge Requested for @", "Merged by @" and "Handoff @" (`drive.md`; the "Auto Merge by Claude" variant names no person and is unaffected). Nothing in this repository resolves an identity a routine session has in hand — a GitHub login, a git author email — to a Slack user id, and no code anywhere constructs `<@U…>`: the placeholder is filled directly with the name as text.

The ask is that these lines genuinely notify the person they name — resolve the acting developer to a Slack user id (a Slack API lookup by email or name, or a maintained mapping of the project's developer identities) and emit a real mention token in each of the five formats.
