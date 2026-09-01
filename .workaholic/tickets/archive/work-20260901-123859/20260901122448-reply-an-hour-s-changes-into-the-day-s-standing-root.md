---
created_at: 2026-09-01T12:24:48+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-add-to-a-standing-thread-instead-of-restating-itself
merge_policy:
verification_handoff: 
---

# Reply an hour's changes into the day's standing root

## Overview

PROPOSED. With a day-stable key in hand (the previous ticket), the lookup can finally find the
standing root — but nothing yet posts into it. This is the behaviour half: the day's **first**
speaking tick opens the `🔎 Moderation` root, and every later speaking tick that hour replies
its change lines into that same thread. A reader then follows one thread per day instead of
meeting a new top-level post every hour, and the questions that were already mentioned replies
stay exactly where they are — beneath the same root, now with the hour's delta above them.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/moderate.md` — the notification ceiling: which shape goes out on which transport, and the one place a posting rule may be added.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — supplies `root_text`, the change lines and the questions.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the `🔎 Moderation` shape's copy.

## Implementation Steps

1. **Reproduce first**: with the day key in place, show that a second tick in the same day
   still renders a full root rather than a delta, so the defect that remains is the posting
   rule and not the lookup.
2. Render the hour's post in two forms off the same data: the **root** (what a day's first
   speaking tick posts, unchanged from today) and the **delta reply** (this hour's change
   lines and impairment lines only, no head that restates the day).
3. Post the delta as a reply whose `thread_ts` is the root the day key resolved. The `🙋`
   questions keep going out as mentioned replies into that same thread, unchanged — including
   their transport rule for a directed post.
4. When the lookup finds no root for the day (the day's first speaking tick, or a channel
   whose history the search cannot reach), post the root — the existing case-4 branch, now
   reached once a day rather than every hour.
5. Report per tick which it did (`root` / `reply`) and the surface that carried it, so a run
   that silently fell back to a root is visible in the run report rather than inferred from
   the channel.
6. Every gate above it is untouched: the speaking window still holds the post, the question
   gate still decides whether there is anything to say, and a tick with nothing to add posts
   neither a root nor a reply.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A day's first speaking tick posts a root; a later speaking tick the same day posts a reply
  into it and no second root.
- The reply carries only the hour's delta — no restated head, no repeated day summary.
- A tick the gates hold posts nothing at all, root or reply.
- Questions still arrive as mentioned replies in the same thread.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a row pinning the two render forms off one input.
- The offline drill added by this mission's last ticket.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **The delta reply stays addressed to nobody, and that is deliberate.** The ask asks for the
  delta to mention the operator. The repository's standing rule is that a root line names a
  repository event and carries no identifier, because *how many* is news and *which* is a
  task; the mention belongs on the question that asks somebody to act. Under this change both
  now live in one thread, so an hour with something a person must do already mentions them
  there. Adding a mention to the delta as well would wake the channel for orientation — the
  failure `📦 Release Preparation` was retired for. Recorded as an argued choice, not an
  oversight.
- **A day with nothing to say opens no root**, so the "day's first speaking tick" is not the
  day's first tick. A day where the first thing worth saying arrives at 16:00 gets its root
  then, which is correct and worth stating because it makes the root's timestamp uninformative
  about when the day started.
- The two tickets of this pair are only useful together; drive them in order.
