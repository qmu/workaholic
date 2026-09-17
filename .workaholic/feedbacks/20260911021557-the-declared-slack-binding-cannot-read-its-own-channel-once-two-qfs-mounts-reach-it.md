---
type: Feedback
title: The declared Slack binding cannot read its own channel once two QFS mounts reach it
kind: concern
source: development
subject: observer_ai:[Moderate] tick 20260910-170313
created_at: 2026-09-11T02:15:57+09:00
author: a@qmu.jp
supersedes: 
---

# The declared Slack binding cannot read its own channel once two QFS mounts reach it

## What was measured

Moderation tick `20260910-170313` (2026-09-10 17:03Z), on `main` at `f7b409b4d`, tried to read
`#dev-workaholic` for its `unanswered-asks` step through the declared binding and nothing else.

- `read-declared-binding.sh --root .` reads `AGENTS.md` (digest `953c1ab7f2f9ab3c395828af767506b6`):
  workspace `qmu`, channel `dev-workaholic`, six operations, fallback `connector, slack_token`,
  and — deliberately, as the paragraph under the block says — no `mount`, no `account`, no `sender_id`.
- `describe-qfs.sh --workspace qmu --channel dev-workaholic` (undeclared mount, so it enumerates)
  answered `described: true` with **two** routes to the same channel `C0BLL9J7FMY`:
  `/slack-cc01-qmu` (account `cc01-qmu`) and `/slack-cdx01-qmu` (account `cdx01-qmu`), each
  offering `read_channel_delta, read_thread, search_exact, post_reply`, each `sender_id: null`,
  plus two mounts whose channel list could not be read (`/slack-clauyo`, `/slack-yodex`).
- `resolve-target.sh` for the six declared operations: `deferred / operations_unsatisfied`
  (offered `post_reply, read_channel_delta, read_thread, search_exact`) — already recorded.
- `resolve-target.sh` for **`read_channel_delta` alone**: `deferred / ambiguous_identity`,
  `identities: [{account: cc01-qmu, sender_id: null}, {account: cdx01-qmu, sender_id: null}]`.

So under the declaration as written, on a machine where two QFS connections reach the one channel,
the loop cannot select a route even for a pure read. The tick therefore reported the channel read as
`channel_unreadable: ambiguous_identity` — the read did not happen — rather than `window_empty`.

## Why it matters

- The 16:18Z tick of the same day reported `window_empty` for the same channel. It got there by
  describing `/slack-cc01-qmu` **by name** (`describe-qfs.sh --mount /slack-cc01-qmu`), a mount
  the binding does not declare. That is a hand-pick: it made the read work and it made the report
  say the declared route read the channel, which it cannot. The two ticks disagree about whether the
  channel is readable and the second one is the honest reading of the declaration.
- The resolver's rule is deliberate and right (`resolve-target.sh`: more than one described
  account/sender tuple is an ambiguity even when every route reaches a channel with the same name),
  and `AGENTS.md`'s omission is deliberate and right for **writes** (no verified sender exists to
  name). What neither surface states is that the omission also stops **reads** the moment a second
  connection to the workspace is mounted — which `20260909162831` shows has been the state of this
  machine since at least 2026-09-09.
- The escalation the step names, `inbound-channel-unreadable:dev-workaholic`, is refused
  `premise_resolved` by `ask-question.sh` because the registry retired the key on the earlier
  tick's `window_empty`. That is the stated cost of the asked-once design (a channel that breaks,
  is fixed and breaks again is not re-asked), so no question reaches anybody about this. This record
  is the only surface carrying it.

## What a fix could look like (for the operator to rule on; nothing here decides it)

1. Declare `mount:` (or `account:`) in `AGENTS.md` for the route reads should take, while still
   declaring no `sender_id` — the `unverifiable_sender` advisory keeps naming the write side
   truthfully, and a declared mount makes the read deterministic (one describe call instead of
   three, as `describe-qfs.sh`'s header already promises).
2. Or, in `resolve-target.sh`, let a target whose required operations are **all reads** resolve
   over identical-capability routes without choosing an identity, since no identity speaks.
   That widens the resolver and its ambiguity rule and is a judgement, not a repair this tick
   may make.
3. Either way, a tick must not pass `--mount` by hand to a describe when the binding declares
   none; the report then claims a route the declaration never authorized.

## What this tick did not do

Nothing was read over a hand-picked mount, no account was selected or substituted, no fallback
was taken (the resolution itself refused, which is none of the four typed `perform.sh` classes;
the connector, probed once for the inbound sweep, cannot see the channel — `No results found`
for `dev-workaholic` over public and private channels), nothing was posted, and no question was
recorded as asked.
