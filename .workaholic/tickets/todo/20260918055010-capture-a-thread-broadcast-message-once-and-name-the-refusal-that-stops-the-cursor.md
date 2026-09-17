---
created_at: 2026-09-18T05:50:10+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260918054606-channel-observation-aborts-silently-on-a-thread-ts-mismatch.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
---

# Capture a thread_broadcast message once and name the refusal that stops the cursor

## Overview

`observe-channel.sh` has reported `observation_proved: false` with an unreadable source on every
run and the binding cursor has not advanced for two weeks, so a human `@`-mention posted as a
reply under a day-old root reached nobody. The reporter traced it to `capture-inbox.sh`: the same
message, read once through `read_thread` and once through `read_channel_delta`, is stored and then
re-read with a different `thread_ts` (the provider's channel listing carries `null` for a
`thread_broadcast` message), and the duplicate branch requires the stored `message` object to
equal the newly read one byte for byte — so the capture takes its `exit 10` branch, and under
`sh -eu` the failing pipeline aborts the script before the `capture_incomplete` line is printed.
The cursor-advancing seam therefore refuses, without saying why, on a message it had already
captured correctly.

This ticket is the first of the report's two causes. The second — thread discovery on the native
QFS route — is out of scope with its reasons named under Considerations.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a refusal that stops a cursor must
  name itself; an empty reason is an outage nobody can read
- `workaholic:implementation` / `policies/persistence.md` — the duplicate test narrows what
  already-stored inbox records must satisfy
- `workaholic:implementation` / `policies/test.md` — the fixture is the proof, including the
  legacy-row case

## Key Files

- `plugins/workaholic/skills/transport/scripts/capture-inbox.sh` — the duplicate test that
  compares the whole stored `message` object, and the `capture_incomplete` line that `sh -eu`
  makes unreachable.
- `plugins/workaholic/skills/transport/scripts/observe-channel.sh` — the consumer, at both
  capture call sites (the channel page and the thread read), which currently substitutes
  `capture_unreadable` / `thread_capture_failed` for a reason it never received.
- `plugins/workaholic/skills/transport/scripts/adapters/qfs-native.sh` — where
  `read_channel_delta` and `read_thread` compose the message object the capture stores
  (`select ts, user, text, thread_ts, subtype` plus `{id, sender_id}`).
- `scripts/test-workflow-scripts.mjs` — the hermetic suite that must carry the regression.

## Implementation Steps

1. **Reproduce and localize before designing anything.** Build a hermetic fixture in which one
   provider id is captured first from a `read_thread` result (with `thread_ts` set) and then seen
   again in a `read_channel_delta` page (with `thread_ts: null`). Record the observed stdout,
   exit status and the binding record's cursor across the call, and confirm both halves of the
   report separately: that the mismatch takes the duplicate branch's failure path, and that no
   `capture_incomplete` line reaches stdout under `sh -eu`.
2. From that measurement, decide **which fields identify a message and which are per-operation
   renderings**, and write the chosen key into the script's own header beside the existing
   contract note. The duplicate test then compares on that key rather than on the whole object.
3. Make the refusal **reachable and typed**: a capture that genuinely cannot complete prints its
   own `capture_incomplete` reason, naming the offending provider id, on stdout with exit 0 —
   not an abort whose output the consumer has to guess at.
4. Check the two consumer call sites in `observe-channel.sh` carry that reason **verbatim** into
   `unreadable[]` and the page/thread reason, so the existing non-empty defaults stop standing in
   for a word the capture can now supply.
5. Prove the effect the defect denied: after the repair, a delta whose messages are all already
   captured completes, advances the cursor, and clears `unproved_since` only when the window
   reached the mark — the behaviour `capture-inbox.sh`'s header already states.
6. Add the fixture to `scripts/test-workflow-scripts.mjs` and regenerate the bundle
   (`node scripts/build-plugins/build.mjs`, then `verify.mjs`).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A message whose provider id is already stored, and whose `thread_ts` differs between the
  thread read and the channel delta, is counted as a duplicate: the capture returns
  `status: ok`, reports it under `duplicate_input_ids`, and the cursor advances.
- A capture that genuinely cannot complete prints `status: deferred` with reason
  `capture_incomplete` and the offending provider id on stdout, and exits 0.
- `observe-channel.sh` reports that reason verbatim; neither `""` nor a substituted
  `capture_unreadable` appears where the capture named a cause.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with the new fixture, covering the duplicate case,
  the genuine-failure case and the cursor advance.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`.

**Gate** — what must pass before approval:

- No live Slack call and no provider credential: everything is proved against fixtures.
- The duplicate test narrows what **already-stored** inbox records must satisfy, so the upgrade
  path is exercised against a legacy fixture holding records written under the current
  whole-object shape, including ones the new key would otherwise reject
  (`plugins/workaholic/rules/general.md`, *A tightened constraint over persisted data is verified
  against legacy rows*).

## Considerations

- **The reporter's two remedies are hypotheses, not the design.** Comparing by provider id and
  content, and normalising `thread_ts` at the adapter, are not equivalent: normalising changes
  what every consumer of a message sees (the classifier, the watch-set derivation and the mention
  arm all read `thread_ts`), while comparing at the capture leaves the stored shape alone. Step 1's
  measurement decides between them.
- **Half of the reported symptom has already landed.** At head, `observe-channel.sh` defaults an
  empty capture reason to `capture_unreadable` and `thread_capture_failed`, so the reported
  `unreadable: [""]` no longer occurs on plugin versions after 1.0.343. What is still missing is
  the typed word and the provider id — a named cause, not merely a non-empty one — and the
  comparison that caused the abort is untouched.
- **The report's second cause is deliberately not in this ticket.** Its fallback remedy is already
  implemented: `observe-channel.sh` searches the channel for the declared sender's mention token,
  registers every discovered root in the durable `watch_threads` set, reads a mention's own thread
  immediately, and reads the watch set newest-first when `list_thread_changes` refuses — reported
  as `source: watch_set_fallback` with coverage still `partial`. Its other remedy is refused by the
  provider here rather than by this repository: `describe-native-qfs.sh` proves `<base>/threads`
  through the driver's own `verbs.select`, and the channel node advertises only `messages` and
  `files`, so `thread_discovery_unavailable` stands with the describe that proved it. Issue #1132
  is closed, and verifying the declared operations end to end is already queued as
  `20260917174439-prove-the-declared-slack-transport-before-retiring-delivery-incidents.md`, which
  waits on an operator-provided route.
- **No `verification_handoff` is declared.** The repair is provable with hermetic fixtures in this
  repository; no credential, device or third-party account is required, and the ask states none.
