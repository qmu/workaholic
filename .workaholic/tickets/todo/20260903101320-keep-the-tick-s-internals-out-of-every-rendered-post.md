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

## Final Report

**Outcome**: implemented.

**Localized first, and the ticket's own diagnosis held.** `render-tick-post.sh` prints neither the
dedup token nor a step's reasoning — its header records that the token is derived and not rendered —
so the internals entered at the **composing** surface, where the agent turns a step payload into a
message from `commands/moderate.md`. The rule is now stated there, immediately above the question
shape it governs.

**It is a closed list of five, each with what it is and why a reader has no use for it**: a dedup key
or search token (`tick-day:<YYYYMMDD>`, `fb:<stem>`, a question or step id — strings a machine
searches for); a step id or step name (a channel reader has no model of *steps*); a counter about the
tick; a sentence about a step's own reasoning (say the thing or do not — explaining the omission is
the machinery talking about itself); and a promise no step must keep (*the loop will follow up* — no
step is bound by it). It closes with the positive rule: the step payloads are **already** composed to
this standard, so composition here is a rendering and never a re-invention — adding a fact of your own
at this surface is exactly how the internals got out.

**Pinned** by a suite row asserting the rule's presence and each of the four named items, beside the
existing ceiling assertions. **What the row cannot see is named in its own comment**: what a session
actually emits at run time. That bound is the same one every ceiling assertion in this suite carries,
and it is stated rather than implied.

**Verified**: `node scripts/test-workflow-scripts.mjs`.
