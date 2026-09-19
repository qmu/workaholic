---
created_at: 2026-09-19T10:01:43+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: hold-the-completion-mention-until-the-whole-human-request-set-is-in
merge_policy:
verification_handoff:
---

# Separate a worker receipt from progress and from completion

## Overview

Operator's ask: **issue #1146**, last two items — *distinguish a worker's terminal receipt, a
scoped progress message, and a human-facing all-requests-complete notification* … *do not silently
redefine scope around the latest worker or pull request; only an explicit human defer or cancel
changes the accepted completion scope* … *a worker finish should be evidence for the parent, not
automatic permission to send a completion mention.*

**Established in this tree.** The loop has two of the three and conflates them with the third. A
worker's terminal result is a structured fact (`work/worker-result.schema.json`: `executed`,
`outcome`, `reason`, `report`) recorded by `runtime/scripts/coordinator.sh` as `finish` — the
skill already says *process exit, execution, work completion and notification delivery are
separate facts*. The channel side has `🟢 Implemented`, which `workaholic:notify` defines as a
**per-unit** post of `/implement`. There is **no** shape for *the whole request set is in*, so a
per-unit finish carrying a mention is the only completion signal that exists — which is exactly
what went out while four requests were still queued.

**Scope narrowing has no rule at all.** Nothing in the notify catalog or the tick ceiling states
who may remove a request from the accepted set. Absent a rule, the set is implicitly whatever the
latest worker touched, which is the silent redefinition the ask names.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh` for any script touched
- `workaholic:implementation` / `policies/observability.md` — the governing policy: a per-unit
  finish and an all-requests-complete notification must not be the same observable event
- `workaholic:implementation` / `policies/test.md` — the shapes and the scope rule are pinned by
  the suite, which already pins post shapes byte-identically

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` and `reference/notifications.md` — the post catalog
  and the one home of every shape. A third class is defined here or nowhere.
- `plugins/workaholic/commands/infinite-development.md` (*Announce landed asks*, *Dispatch*) — the
  consumer; the mention decision and the receipt recording both pass through here.
- `plugins/workaholic/commands/implement.md` — `/implement`'s per-unit posts; `🟢 Implemented`
  keeps its meaning and must not quietly become a completion signal.
- `plugins/workaholic/skills/work/SKILL.md` (*Children and reports*) — where *process exit,
  execution, work completion and notification delivery are separate facts* is already stated; the
  fourth separation belongs beside it.
- `plugins/workaholic/skills/work/worker-result.schema.json` and
  `plugins/workaholic/skills/runtime/scripts/coordinator.sh` — the worker receipt, which is
  evidence and stays internal.
- `scripts/test-workflow-scripts.mjs` — pins post shapes and byte-identical wordings across the
  ceilings.

## Implementation Steps

1. **Read the notify catalog whole** before adding anything, including the recorded reasons two
   status roots were retired. A third class must not become an hourly status line.
2. **Name the three acts, once, in the catalog**: a **worker terminal receipt** (internal
   evidence, not a channel post), a **scoped progress message** (channel, names what landed and
   what remains, carries **no** mention token), and a **completion mention** (channel, carries the
   mention, permitted only on the thread-grain `complete` verdict from this mission's first
   ticket). State the rule as a sentence a reader can check: *a worker finish is evidence for the
   parent, never its permission.*
3. **Give the completion notification its own shape** in `reference/notifications.md`, in the
   catalog's existing style and in Japanese readable on first sight, enumerating the linked items
   and pointing at the shared outcome — which is also issue #1110's item 7, so the two shapes
   must not contradict each other. Check that ask's emitted work before writing this shape.
4. **`🟢 Implemented` is untouched.** It remains the per-unit post with its existing meaning, and
   the change must say so explicitly so a reader does not repurpose it.
5. **State the scope rule**: the accepted set changes only on an **explicit human defer or
   cancel**, captured as an ordinary inbound ask. A worker's judgement, a merged pull request, a
   closed issue and a run's own reading never narrow it. Write it once, in the catalog, and cite
   it from the ceiling.
6. **Keep the observation tick running through the reconciliation** (the ask's own words). This is
   already the coordinator's contract — *never run those roles inline and never wait for them* —
   so cite it rather than adding a second rule, and confirm the mention-time reread in this
   mission's second ticket does not block the clock.
7. **Report the class of every post** in the tick report, so a reader can tell a progress message
   from a completion mention without opening the channel.
8. **Suite rows**: the three classes are defined once; the completion shape is byte-identical
   between the catalog and the ceiling; `🟢 Implemented` carries no mention token; a fixture with
   an incomplete set produces a progress message and no mention; and the scope rule appears in the
   catalog exactly once.
9. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Three classes are defined in the catalog, once, with the completion mention permitted only on a
  thread-grain `complete` verdict.
- A worker terminal receipt produces no channel post of its own and is stated as evidence, never
  permission.
- A scoped progress message carries no mention token and names what remains.
- `🟢 Implemented` keeps its per-unit meaning and is byte-identical.
- The accepted scope narrows only on an explicit human defer or cancel; no other path narrows it.
- The tick report names the class of each post.
- The completion shape is byte-identical between the catalog and the ceiling.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green and each new row fails when reverted.
- `git diff origin/main` shows `🟢 Implemented`'s shape unchanged.
- A fixture set with one queued member produces a progress message and no mention; the same set
  fully verified produces exactly one mention.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- The new shape is written in the catalog and cited by the ceiling, never authored twice.
- The Japanese in the shape reads on first sight, by the standing rule — a channel reader
  understands what is being said without opening the English record behind the link.
- The suite is green and the bundle rebuild is diff-clean.

## Considerations

- **A third shape is a cost this repository has paid badly before**: two keyed roots were retired
  for restating an unchanging status hourly. The bound here is that a completion mention fires
  **once** per accepted set, on a transition, and a progress message is sent only when there is
  something new to say.
- **This ticket and issue #1110's item 7 both touch the finish line's shape.** Read that ask's
  emitted work before writing, and if the two collide, say so in the story rather than shipping
  two wordings for one post.
- **Low-context workers are the reason the ledger sits with the parent** (issue #1142). A bounded
  worker can prove its own unit and nothing else; keep the completion decision at the parent and
  do not push it into a child to save a round trip.

## Final Report

Development completed as planned. The three acts are defined **once**, in
`skills/notify/reference/notifications.md` (*Three acts: a worker receipt, scoped progress, and a
completion mention*), and the block carrying the two shapes, the scope rule and the
`🟢 Implemented` non-repurposing clause is carried byte-identically into
`commands/infinite-development.md` between explicit markers, pinned by the suite. A worker
terminal receipt reaches the channel not at all; `📊 進捗` carries no mention token; `🏁` carries
the addressee's and is permitted only on the thread-grain `complete` verdict. The tick report now
names the class of every post and, for a withheld mention, what held it.

Verification: `node scripts/test-workflow-scripts.mjs` 7671 passed / 0 failed;
`node --test scripts/tests/agentic-loop/repair-contracts.test.mjs` 30/30 with the new row;
`build.mjs` + `verify.mjs` + `validate-metadata.mjs` clean (workflows@1.0.372);
`layout-doctor.sh .` `conforming: true` (pre-existing advisories only);
`git diff origin/main` leaves the `🟢 Implemented` shape unchanged.

### Discovered Insights

- **Insight**: `✅` is already taken by `/moderate`'s `✅ 解消を確認` and `🧾` by its
  `🧾 対応結果`, so the completion mention took `🏁` and progress took `📊`.
  **Context**: The catalog's labels are the dedup and search key, so a reused emoji would make
  two different events indistinguishable to a reader scanning the channel.
- **Insight**: Issue #1110's item 7 does **not** collide with this. Its own ticket
  (`20260919095108-make-a-shared-feedback-thread-grounds-for-one-pr-unit`) says the per-unit
  finish "needs no new shape" and only asks that it enumerate the linked items.
  **Context**: That is one pull request's post; this is a whole accepted set's, at the thread
  grain. Both were checked before writing, and the catalog states the distinction so a later
  reader does not merge them.
