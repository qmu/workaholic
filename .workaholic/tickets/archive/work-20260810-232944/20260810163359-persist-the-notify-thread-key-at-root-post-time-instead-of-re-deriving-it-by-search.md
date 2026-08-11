---
created_at: 2026-08-10T16:33:59+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260810163347-workaholic-notify-s-stateless-thread-lookup-fails-posting-new-threads-instead-of-replying.md, 20260808030816-propose-notify-posts-top-level-instead-of-the-fb-thread-and-omits-the-issue-link.md]
merge_policy:
claim: work-20260810-232944
---

# Persist the notify thread key at root-post time instead of re-deriving it by search

## Overview

Issue qmu/workaholic#360 (feedback `20260810163347`) reports that `workaholic:notify`'s
stateless thread-lookup (`workaholic:notify`, *One thread per feedback item*) is
unreliable: on a search miss for both `` `fb:<stem>` `` and the issue/PR number, it posts
a brand-new top-level thread root instead of finding the item's real existing thread — a
routine's own reported run named exactly this ("searched fb:, then #355 — both exhausted,
no match, posted a new root"). A closely related earlier report (feedback `20260808030816`,
issue #306) observed the same symptom from a different angle: wrong thread placement plus
a missing markdown link on the posted reference.

This ticket implements the reporter's proposed fix: **persist** the Slack thread's `ts`
(and/or permalink) alongside the `` `fb:<stem>` `` key at the moment the root is posted,
rather than re-deriving the thread via best-effort search on every later event. The
search-based lookup (cases 2–4 of the current model) becomes the fallback for a thread
whose key predates this change, not the primary path going forward.

**Note for the reviewer:** the current stateless design was a deliberate decision (Q1,
2026-08-07 — "nothing carries a target between routines; the search is defined so it
cannot guess"), adopted specifically because a *carried* target had its own measured
failure mode (P4's propagation, retired). This ticket proposes reversing that in favor of
a *persisted* target instead of a *carried* one — a different mechanism with a different
failure mode (a stale or unwritable persisted key) that the interrogation/implementation
should weigh explicitly against Q1's original reasoning, not merely reintroduce what Q1
retired.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the notify path runs inside the unattended `/implement`/`[Propose]`
  loop, so a regression here degrades an unattended surface silently

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — the stateless lookup contract (*One thread
  per feedback item*) this ticket changes the primary path of
- `plugins/workaholic/skills/notify/reference/notifications.md` — lookup history, the
  withdrawn carried-target disclosure (Q1) this ticket's persisted-key approach must be
  distinguished from
- The `[Propose]` routine template (`skills/workaholify/routines/`) — posts the thread root
  and would need to write the persisted key at that moment
- The feedback record schema/writer (`skills/feedback/scripts/create.sh`,
  `skills/feedback/SKILL.md`) — candidate location for the persisted key, if it is stored on
  the feedback record itself

## Implementation Steps

**Root cause measured 2026-08-11 (FB `20260811084546`) — read it before implementing.**
The search does not miss because search is unreliable; it misses because it runs in the
wrong scope: `dev-<repo>` is a **private** channel and the default, consent-free
`slack_search_public` covers public channels only, so it returns zero for any `fb:` key
by construction (verified live: 0 results public-only, instant exact hit private-
inclusive). The persisted key attacks the wrong layer.

1. **Fix the lookup's search surface first**: specify in `workaholic:notify` that the
   thread lookup runs through the private-inclusive search (`slack_search_public_and_private`)
   with `include_bots: true` — the developer's consent to reading the repository's own
   `dev-<repo>` channel is a one-time recorded ruling carried by the skill and the
   routine templates, not a per-run prompt (an unattended routine can never answer one).
2. **Defer the persisted key** until a scope-corrected lookup is measured to still miss.
   Only if that day comes does the storage question reopen — and then **never anywhere
   committed to the repository** (developer's ruling, FB `20260811084130`; the P9
   withdrawal's irretractable-exposure reasoning): the store would have to be private to
   the workspace and reachable from a fresh container, the natural candidate being Slack
   itself (a pinned index canvas or index message keyed by `fb:<stem>`).
2. Update the `[Propose]` routine (and any other root-posting path) to write the persisted
   key immediately after a successful root post.
3. Update `workaholic:notify`'s lookup order so a persisted key is checked first, with the
   existing exact-string searches (cases 2–3) retained as the fallback for threads that
   predate this change or whose persisted write failed.
4. Update `reference/notifications.md`'s lookup history section to record this change and
   how it differs from the retired carried-target approach (Q1).
5. Update `SKILL.md`'s *One thread per feedback item* section to state the new primary path.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A thread root's key (ts/permalink) is persisted at post time, in a location the next
  event for that item can read deterministically.
- A later event for the same item finds the thread via the persisted key without relying on
  a search match.
- The existing search-based fallback still applies to threads that predate this change.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic scan/test asserting the persisted field is written by the root-posting path
  and read by the lookup path before any search query runs.
- A manual/live check: trigger `[Propose]` on a fresh feedback item, then trigger a later
  event for the same item, and confirm it replies in-thread using the persisted key (not a
  search).

**Gate** — what must pass before approval:

- `node scripts/build-plugins/verify.mjs` and `node scripts/test-workflow-scripts.mjs` pass.
- The reviewer has weighed this against the Q1 statelessness decision and accepted the
  tradeoff (see Overview note).

## Considerations

- This reverses part of a deliberate design decision (Q1, 2026-08-07) rather than a plain
  bug fix; the interrogation/implementation should explicitly re-examine Q1's stated reason
  for statelessness (a carried target's prior failure mode) and confirm a persisted key
  avoids the same failure rather than reintroducing it under a new name.
- Where to persist the key is constrained, not open: any repository-committed store is
  ruled out (public repo; FB `20260811084130` and the P9 withdrawal's irretractable-
  exposure reasoning), which also disposes of the immutability question the frontmatter
  candidate raised — the store lives outside the repository entirely.
- A failed or partial persisted-write must not silently break the fallback search path —
  the existing statelessness should remain a safety net, not be deleted outright.

## Final Report

Development completed as planned. `thread_ref` (`<channel-id>:<ts>`) is now an optional,
additive, write-once frontmatter field on a feedback record — the one sanctioned exception
to `feedback/SKILL.md`'s Immutability, filled exactly once by the new
`feedback/scripts/set-thread-ref.sh` immediately after a routine posts that item's Slack
thread root, and refused (`already_set`) on any second write attempt, even to the identical
value. `workaholic:notify`'s *One thread per feedback item* lookup checks it first (a plain
file read, not a search) before falling back to the pre-existing `` `fb:<stem>` ``/Issue-URL
searches, so a record predating the field or a failed persist degrades exactly to the prior
behavior. Both root-posting paths — `[Propose]`'s finish post and `/implement`'s own
fallback new-root case — now persist the key immediately after posting.

**Re-examined against Q1 (2026-08-07) rather than reintroducing what it retired**, per this
ticket's own note: Q1's statelessness was a rule about *not carrying a target between
routines* — P4's retired mechanism embedded a Slack thread URL in a public pull-request
body, readable by anyone, and readable forever once merged. `thread_ref` carries nothing in
a public body; it lives on the item's own (already-private-repository-scoped) feedback
record, the same record every routine already reads to get `fb:<stem>`. The failure mode
this reopens is bounded exactly the way Q1's own withdrawal note already accepts: a stale or
unwritten key degrades to the identical exact-string search that was the *entire* mechanism
before this ticket — never to a guess, and never to a second propagation channel. Documented
in `notify/reference/notifications.md`'s *Finding the thread — history* section for a future
reader who might otherwise read this as reopening Q1.

### Discovered Insights

- **Insight**: `notify` carries no `scripts/` directory of its own and is not one of
  `build.mjs`'s `DEFAULT_TARGETS`/`EXTRA_SKILLS`, so it never enters the generated
  `outputs/workflows` bundle on its own — it is pure prose other skills (`drive`, `propose`)
  point at by name. A script call this ticket needed to add for the persist-after-root-post
  step therefore had to live in `drive/reference/routing.md` and
  `propose/reference/workflow.md` (both already in a built target's closure) rather than in
  `notify/SKILL.md` itself, or the built `drive`/`create-ticket` bundles would carry the new
  instruction with no way to resolve `feedback/scripts/set-thread-ref.sh`.
  **Context**: relevant to anyone adding a new cross-skill script reference from a
  closure-adjacent prose skill (`notify`, `workaholify`) — `computeClosure` only walks a
  *build target's* own `SKILL.md`/`reference/`/`scripts/`, so a reference living solely in a
  non-target skill's prose is invisible to the build regardless of whether Claude Code can
  resolve it at runtime.
- **Insight**: the sibling mutators this script's write-once contract was modeled on
  (`mission/scripts/record-run-hours.sh`, `mission/scripts/link-acceptance.sh`) route
  argument/file-not-found refusals to **stderr** and business-logic refusals (duplicate,
  already-linked) to **stdout** — a convention `feedback/scripts/create.sh` does not follow
  (everything to stdout). `set-thread-ref.sh` follows the mission-mutator convention rather
  than `create.sh`'s, since it is a mutator of an existing file, not a first write; a test
  that assumed the `create.sh` convention initially misread `r.stdout` for the `not_found`/
  `missing_args` cases and had to be corrected to read `r.stderr`.
