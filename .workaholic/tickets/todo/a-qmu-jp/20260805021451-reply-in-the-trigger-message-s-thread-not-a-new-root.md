---
created_at: 2026-08-05T02:14:51+00:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
feedback: [20260805021414-propose-roots-a-new-slack-thread-even-when-the-trigger-message-already-is-the-item-s-thread.md]
merge_policy:
claim: work-20260805-180653
---

# Reply in the trigger message's thread, not a new root

## Overview

The `workaholify` skill's *One thread per feedback item* convention finds an item's existing Slack thread only by searching the channel for the feedback record's `fb:<stem>` key. That key is minted by the very session that posts, so a message a developer wrote before the record existed carries no key and can never be matched by that search — and the routine falls through to its new-root fallback even when the triggering thread is sitting in the channel. On 2026-08-05 that produced two roots for one item: the developer's own thread about routine notifications not rendering a Slack mention, and a separate top-level announcement of the resulting PR #238.

This ticket adds the trigger-message case *alongside* the key search rather than replacing it. When a session can identify the Slack message or thread that triggered its run, it replies there; otherwise the key search and its new-root fallback stand exactly as they are. The key search remains the only answer for routine-originated items, which have no human trigger message to find.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/interaction-design-standard.md` — the unit of a notification is the reader's item of interest, which is the model this convention exists to serve

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — the *One thread per feedback item* section, whose "Finding the thread, and what to do when you cannot" paragraph is the single statement of the model. The new case is written here and only referenced elsewhere.
- `plugins/workaholic/skills/workaholify/routines/fb.md` — the `[Propose]` template, the routine that roots the thread and the one the report was filed against. Its prompt currently instructs a top-level post unconditionally.
- `plugins/workaholic/skills/workaholify/routines/merged-pr.md` — the `[Consent]` template; its rule 5 carries the key search and the new-root fallback.
- `plugins/workaholic/skills/workaholify/routines/drive.md` — the `[Drive]` template; §4 and §5 route their outcome lines through the same key search.

## Implementation Steps

1. In the `workaholify` SKILL's *One thread per feedback item* section, state the three cases in order: reply in the triggering Slack message's thread when the session can identify one; otherwise search the channel for `fb:<stem>` and reply in the thread whose root carries it; otherwise post a new root carrying the key. Include the reason the key search alone cannot cover the first case — the key is minted by the posting session, so a human-authored trigger message predates it and can never carry it — so that a later reader does not simplify the case back out.
2. In `routines/fb.md`, replace the unconditional "post as a top-level message" instruction with a reference to those ordered cases. The `fb:<stem>` line stays mandatory in whichever message the routine posts.
3. In `routines/merged-pr.md`, add the trigger-message case ahead of rule 5's key search, leaving rule 5's fallback and its "never post keyless" requirement intact.
4. In `routines/drive.md`, do the same at §4 and §5, where the outcome lines are routed.
5. Do not rebuild `outputs/`: the `workaholify` skill is not part of the generated `outputs/workflows` bundle, so this change has no generated artifact.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The SKILL's *One thread per feedback item* section states the trigger-message case, the `fb:` key search and the new-root fallback as ordered cases, and gives the reason the key search cannot match a human-authored trigger message.
- All three routine templates route their post through those cases, and none of them loses its `fb:<stem>` key requirement or its new-root fallback.
- No template instructs an unconditional top-level post.

**Verification method** — the commands/tests/probes that prove them:

- Read the SKILL section and the three templates and confirm the ordered cases and the retained fallbacks.
- `node scripts/build-plugins/verify.mjs` passes.
- `git status` shows no diff under `outputs/`, confirming step 5.

**Gate** — what must pass before approval:

- The SKILL and the three templates agree on the same ordered cases, stated once in the SKILL and referenced by the templates rather than restated.
- Rolling the change out to the live routines is explicitly **not** part of this ticket.

## Considerations

- Editing a template makes every live routine drift by construction. The rollout is a separate human act through `/setup-routines`, one routine at a time and confirmed verbatim, and an unattended run cannot do it at all. This ticket ends at the template edit.
- `[Consent]` and `[Drive]` fire on repository events — a merge, a schedule — rather than on a Slack message, so the new case will usually not apply to them. It is still written into all three templates, as the reporter asked, so the model reads identically everywhere and any future event that does carry a trigger message behaves correctly.
- How a session identifies its triggering message is left to the implementer; the routine's own trigger payload is the natural source. Where no reliable identification exists, the correct outcome is the unchanged key search — matching by recency or message content would thread unrelated items together, which is a worse failure than a second root.
- PR #238 is open and edits the same SKILL section and the same three templates for a different concern (rendering `@name` as a real Slack mention). Whichever merges second will need a rebase; the two changes do not conflict semantically.
