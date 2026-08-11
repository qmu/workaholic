---
type: Feedback
title: Notify thread key must not be persisted into the public repository
kind: instruction
source: discussion
created_at: 2026-08-11T08:41:30+09:00
author: a@qmu.jp
supersedes: 
---

# Notify thread key must not be persisted into the public repository

The persisted notify thread key (ticket `20260810163359`) must NOT be stored anywhere that is committed to the repository — the repository is public, and the repository's own record already settles this: the P9 withdrawal (`workaholic:notify` reference, *Withdrawn, not deleted*) states that a Slack thread coordinate in a public body disclosed the workspace subdomain, the channel id, and the message timestamp, and that the exposure was **not retractable** because public repository content is permanently archived and scraped. A committed frontmatter field on the feedback record is exactly that exposure under a new name, so the ticket's leading candidate is ruled out by the developer. The persisted key must live in a store private to the workspace that fresh cloud containers can still reach — the natural candidate being Slack itself (a pinned index canvas or a dedicated index message the connector writes at root-post time and reads back by exact key), keeping Slack coordinates inside Slack; any store outside Slack must be non-public and reachable from a fresh container, or the idea reduces back to the search fallback. The search-based lookup stays as the fallback either way.
