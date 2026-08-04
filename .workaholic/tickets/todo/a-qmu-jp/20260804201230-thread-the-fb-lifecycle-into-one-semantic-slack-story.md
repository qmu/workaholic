---
created_at: 2026-08-04T20:12:30+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: make-routine-notifications-one-semantic-story
merge_policy:
---

# Thread the FB lifecycle into one semantic Slack story

## Overview

FB `20260804101847` (instruction, qmu/workaholic#192): replace the per-step,
non-semantic "🟢 PR opened" / "🟣 PR merged" top-level posts with **one thread
per feedback item** that tells its whole life. The reporter's flow: the [FB]
routine posts the thread root "Proposed to @developer" (🟢) with a
`[Proposal]`/`[提案]`-prefixed PR; review conversation happens in that thread;
the merge lands "Proposal merged by @developer" (🟣) **in the same thread**;
[Drive] outcomes also land there — "Merge Requested for @developer" (🟢),
"Merged by @developer" (🟣), "Auto Merge by Claude" (🚀, only when the FB asked
for auto), or "Handoff @developer" (🟡). Every post carries the **session URL**
of the Claude Code Web routine session that did the work.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / UX policies — a notification stream is an interface; its unit is the reader's item of interest, not the emitter's step

## Key Files

- `plugins/workaholic/skills/workaholify/routines/fb.md` — becomes the thread-root author
- `plugins/workaholic/skills/workaholify/routines/merged-pr.md` — becomes an in-thread reply (find the item's thread; its one-merge-one-session rule stays)
- `plugins/workaholic/skills/workaholify/routines/drive.md` — drive outcomes post into the item's thread when the unit traces to an FB
- `plugins/workaholic/skills/workaholify/SKILL.md` + `commands/workaholify.md` — document the threading model once, referenced by the templates

## Implementation Steps

1. Design the thread-discovery convention first and write it in the workaholify
   SKILL: the root post embeds a stable key (the FB issue number / feedback
   record filename); a later routine session finds the thread by searching the
   channel for that key (the Slack MCP tools the routines already use can read
   channel history). State the fallback: no thread found → post a new root
   carrying the same key, never a keyless top-level line.
2. Rewrite `fb.md`'s notification block: root post format "🟢 Proposed to
   @<developer> — [#N title](pr_url)" + `[Proposal]` PR-title prefix rule +
   session URL line + the embedded key.
3. Rewrite `merged-pr.md`: identify the merged PR's FB key (from the PR
   body/title trail), reply in-thread "🟣 Proposal merged by @<developer>" +
   session URL; keep rules 1-3 (exactly one PR, silence on ambiguity, no
   re-announce).
4. Extend `drive.md`'s notification guidance: when the driven unit's tickets or
   mission trace to an FB key, the outcome post is an in-thread reply using the
   reporter's four-outcome vocabulary (🟢 merge requested / 🟣 merged by dev /
   🚀 auto merge / 🟡 handoff) + session URL.
5. Note the scope line from the FB verbatim: notification and threading only —
   no change to what drive/survey picks or implements.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No template emits a keyless top-level "PR opened"/"PR merged" post
- Each template states how it finds (or founds) the item's thread, and every post format includes the session URL
- The threading model is stated once and referenced, not restated per template

**Verification method** — the commands/tests/probes that prove them:

- `grep -n "thread" plugins/workaholic/skills/workaholify/routines/*.md` shows the convention referenced in all three templates
- A dry read-through of each template against the FB's illustrated flow

**Gate** — what must pass before approval:

- Docs consistent in the same change; `/workaholify`'s compare-routines drift report will flag the live routines as drifted (expected — refreshing them is the developer's confirmed act)

## Considerations

- Session URL availability inside a routine session needs verifying against the
  harness (the template should state the graceful form if the URL is not
  discoverable: post without it rather than not posting).
- Thread discovery via channel search is eventually consistent; the fallback
  root-with-key keeps the story reconstructable even when search misses.
- This ticket rewrites the same templates the notification-filter ticket
  touches — drive them in the mission's order.
