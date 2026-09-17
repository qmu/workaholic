---
created_at: 2026-09-09T13:09:12+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-declared-slack-route-speak-be-seen-and-be-named
merge_policy:
verification_handoff: 
---

# Discover thread replies on the native QFS route

## Overview

PROPOSED. Issue #1132 reports that on the loaded 1.0.343 runtime `observe-channel.sh` read the
declared channel successfully (`channel_verified: true`) and still reported thread coverage
`partial`, `discovered: false`, `reason: operation_unavailable` for `list_thread_changes` — so a
reply posted today under yesterday's root was never discovered.

Localized in this tree: `adapters/qfs.sh` implements `list_thread_changes` (it queries
`<base>/threads`), but a `pipe-sql` route `exec`s into `adapters/qfs-native.sh`, whose `case`
covers `read_channel_delta`, `read_thread`, `search_exact`, `post_root` and `post_reply` and falls
through to `qfs_operation_unavailable` for everything else. `describe-native-qfs.sh` matches: its
`operations` list carries no `list_thread_changes`, and it declares the limitation
`thread_discovery_unavailable` outright. The declared route is therefore described, correctly, as
unable to discover a thread reply — and the whole adaptive-polling policy sits behind a discovery
that never runs.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/transport/scripts/describe-native-qfs.sh` — the `operations` list
  (line 57) and the `thread_discovery_unavailable` limitation (line 59).
- `plugins/workaholic/skills/transport/scripts/adapters/qfs-native.sh` — the operation `case` with
  no `list_thread_changes` arm.
- `plugins/workaholic/skills/transport/scripts/adapters/qfs.sh` — the existing
  `list_thread_changes` query and its result shaping, the contract to match.
- `plugins/workaholic/skills/transport/scripts/observe-channel.sh` — the bounded fan-out,
  `WORKAHOLIC_THREAD_FANOUT`, and `coverage.threads.status`.
- `plugins/workaholic/commands/infinite-development.md` — the `covered` / `partial` reporting rule
  and the post-activity cadence.

## Implementation Steps

1. **Reproduce and localize before designing.** Run the observation against the declared route and
   capture the `coverage.threads` block and the adapter's own refusal word, confirming the arm is
   absent rather than failing.
2. Establish what the provider actually offers: describe `<mount>/<workspace>/<channel>/threads`
   and record whether the collection exists and which columns it carries. A collection that is not
   there is the honest end of this ticket for that provider — and the limitation stays declared.
3. Where it exists, add the `list_thread_changes` arm to `qfs-native.sh` in the dialect that file
   already speaks, returning the same shape `adapters/qfs.sh` returns so no consumer learns which
   adapter answered. Keep the bounded overlap window; never scan every thread and never read the
   channel whole.
4. Advertise it in `describe-native-qfs.sh` **only when the describe proved the collection**, and
   drop `thread_discovery_unavailable` only in that case. A described capability that is not there
   is worse than a declared limitation.
5. Leave `coverage.threads.status` honest: `covered` only when the operation ran; a truncated
   fan-out stays `truncated: true`. The channel cursor is still owned by the channel delta and is
   not advanced by the thread read.
6. Verify the end-to-end case the ask names: a reply posted today under a root from yesterday is
   returned as a new input.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The declared native route either answers `list_thread_changes` or declares the limitation with
  the describe that proved it absent.
- A reply under a root older than the channel-history window is discovered end to end.
- `coverage.threads.status` reads `covered` only when the operation ran, `partial` with its reason
  otherwise.
- A successful channel delta alone is never presented as thread monitoring.

**Verification method** — the commands/tests/probes that prove them:

- The end-to-end case: a reply today under yesterday's root, discovered and captured once.
- `node scripts/test-workflow-scripts.mjs` — hermetic rows for advertised, unadvertised and
  truncated discovery.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- The measured route currently answers `channel_unreadable` for `dev-workaholic` on every bound
  account, so end-to-end verification needs an account that can see the channel. That is an
  operator act; if it is unavailable, the ticket may land the arm and report the verification as
  unmade rather than claiming it.
- Faster polling after activity is the existing policy and is not re-specified here. This ticket is
  the discovery the policy waits on.

## Final Report

Development completed as planned. The end-to-end verification the ticket names is **unmade on
this provider, and the describe says why** — which is the outcome step 2 provides for.

**Reproduced and localized first.** The declared native route was asked for
`list_thread_changes` through `adapters/qfs.sh` with the route the real describe returns, and
answered `qfs_operation_unavailable` — the route gate at the top of `qfs-native.sh`, not a query
that failed: the operation is not in the described `operations`, so no query was ever composed.

**What the provider actually offers** (`qfs describe … --json`, 2026-09-09, read-only):

- `/slack-cc01-qmu/qmu/C0BLL9J7FMY` advertises exactly two children: `messages` and `files`.
- `/slack-cc01-qmu/qmu/C0BLL9J7FMY/threads` describes as a placeholder — every verb `false`,
  one `value: Json` column — beside `.../messages`, which describes `select: true, insert: true`
  with the real `ts, user, text, thread_ts, subtype` schema.

So the thread collection is **not there** on this provider, and per step 2 that is the honest end
of the ticket for it: the limitation stays declared.

**What changed is that the limitation is now PROVED rather than hard-coded, in both directions.**
`describe-native-qfs.sh` describes `<base>/threads` and reads the driver's own `verbs.select` as
the proof: only then does it advertise `list_thread_changes` and drop
`thread_discovery_unavailable`. An unproved route declares the limitation carrying the reason the
describe gave — `thread_collection_verified: false`, `thread_discovery_reason:
threads_not_selectable` / `threads_not_described`. Re-run against the real route after the change,
`operations` and `limitations` are byte-identical to before, now with the evidence beside them.

`qfs-native.sh` gains the `list_thread_changes` arm the proof enables — the same bounded overlap
window (`where last_reply_ts >= cursor - overlap`), the caller's own `limit`, and the shape
`adapters/qfs.sh` returns, so no consumer learns which adapter answered. It is reachable only
through the advertisement, so a provider without the collection still refuses
`qfs_operation_unavailable` rather than querying a node that is not there. The **channel** cursor
is untouched: the channel delta owns it.

`observe-channel.sh` and `coverage.threads.status` are unchanged — `covered` still only when the
operation ran, `partial` with its reason otherwise, and a truncated fan-out still `truncated:
true`. A successful channel delta is still never presented as thread monitoring.

**Acceptance, honestly:** the first, third and fourth criteria hold. The second — a reply under a
root older than the channel-history window discovered end to end — is **not verified here and is
not claimed**: this provider has no thread collection to discover from, which the describe now
records on every observation.

### Discovered Insights

- **Insight**: `qfs describe` answers for a path that is not a node, returning a generic
  placeholder (`verbs` all `false`, one `value: Json` column) rather than failing.
  **Context**: a describe that *succeeded* is therefore not proof that a collection exists — the
  proof is the driver's own `verbs`, which is why the gate reads `verbs.select == true` and not
  the exit status. The channel node's `children` list is the corroborating read.
- **Insight**: hard-coding a capability limitation and hard-coding a capability are the same
  mistake pointing in opposite directions.
  **Context**: `thread_discovery_unavailable` was a constant, so a provider that grew the
  collection could never be discovered; advertising unconditionally would have promised an
  operation the adapter refuses. Deriving both from one describe removes both failure modes and
  costs one provider call per route description.
