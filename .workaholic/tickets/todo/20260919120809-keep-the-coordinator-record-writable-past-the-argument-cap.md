---
created_at: 2026-09-19T12:08:09+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy: review
verification_handoff:
---

# Keep the coordinator record writable past the argument cap

## Overview

`skills/runtime/scripts/state.sh` passes whole JSON values to `jq` as single `argv`
strings (`--arg` / `--argjson`). Linux caps one argument at `MAX_ARG_STRLEN`
(32 × PAGE_SIZE), so once the coordinator's durable record grows past that cap the
store stops accepting writes — and, one step further, stops being readable at all.
The loop then cannot record a `finish`, a `reported` or a `continued`, and a
long-running `/work` instance bricks its own bookkeeping while every caller is told
something that is not true.

Make the store's size independent of the argument cap by passing unbounded values
through **files**; bound what the coordinator **stores** per worker so the record
does not grow without limit; and replace the misleading refusal word so an
unwritable record answers by its own name instead of `state_invalid`.

**This ticket reports a failure of an existing mechanism.** Step 1 reproduces and
localises it; the measurements below are evidence gathered while writing the
ticket, not an adopted design (`workaholic:discover`, *Diagnosis-First Rule*).

### What was measured

On this machine (`aarch64`, page size 4096), while the live `/work` instance
`b7fa8a11-6c2b-480c-8c69-7f237c54a79e` was running at base `f4f261e08`:

- `getconf ARG_MAX` = **2,621,440**. The failure is **not** `ARG_MAX`.
- `getconf PAGESIZE` = **4096**, so `MAX_ARG_STRLEN` = 32 × 4096 = **131,072**
  bytes **including the terminating NUL** — a payload limit of 131,071 bytes.
  Probed directly: a single argument of 131,071 bytes executes; 131,072 bytes
  answers `E2BIG`.
- A `finish` event failed with, verbatim on stderr:
  `.../runtime/scripts/state.sh: 行 134: /usr/bin/jq: 引数リストが長すぎます`
  and the call answered `{"reason":"state_invalid"}`. The finish was **not**
  recorded, so the receipt stayed `running`.
- Cause of the growth: the coordinator stores each worker's full `result.report`
  prose under `.data.coordinator.workers[<id>].result.report`. Twenty-four workers
  at roughly 2.7–5.4 KB each reached the cap; `.data` measured **129,906 bytes**.

### Two distinct failure modes, both reproduced

Reproduced in a throwaway repository with a seeded record (not the live store).
The record is rewritten in full on every event, so `state.sh` composes the new
value from the old one — the **old** record rides `stdin` (safe), while the
**new** `.data` and the **final** value ride `argv` (unsafe).

**Mode A — `.data` over the cap.** `state.sh:134`'s `--argjson data "$data"`
fails `E2BIG`; `$value` is left empty; the shape assertion at `state.sh:176`
therefore fails and the script answers `state_invalid`, exit 0, with **nothing
written**. Measured at 131,140 bytes of new `.data`. This is the reported defect.

**Mode B — `.data` just under the cap, whole record just over.** `state.sh:134`
succeeds and the record **lands on disk at line 180**; then `state.sh:181`, which
passes the *whole record* as `--argjson v "$value"` to render the success result,
fails `E2BIG` and the script exits **2 with completely empty stdout**. Measured at
131,040 bytes of new `.data`: the write committed (`revision` advanced from 2 to 3)
and the caller received no JSON at all. The window between the modes is only about
the width of the record's wrapper (~100 bytes), and Mode B is the more dangerous of
the two: a caller that reads empty output as failure retries a write that already
succeeded, and the retry answers `revision_conflict` against the revision its own
successful write produced.

**And the read path has the same shape.** `state.sh:42` renders a successful read
by passing the whole record as `--argjson v`. Seeded with a 131,145-byte record on
disk, `state.sh read` exits **0 with empty stdout**. `coordinator.sh:21` then reads
that empty file, `jq -r .status` yields the empty string, the `= ok` test fails,
`cat "$WORK/read"` emits nothing and the coordinator `exit 0`s — so **every**
coordinator event, including a plain read, answers with total silence carrying no
reason word whatsoever. The write refusal in Mode A is what has so far kept the
on-disk record under the cap and the read path alive; nothing guarantees that.

### Why the reported word is wrong

`state_invalid` means *the composed value failed its shape assertion* — a malformed
input. Nothing in the result says the write was too large, and a caller cannot tell
"your event was bad" from "this record can no longer be written". That is the same
family this loop repaired three times this month: a failure reported as something it
is not.

### Recovery already applied, and its cost

The live record was recovered by pruning `result.report` to its first 120 characters
for workers already `completed` or `reported`, keeping `executed` / `outcome` /
`reason` — the fields `lib/coordinator.jq` and the finish-log summary actually read.
That took `.data` from 129,906 to 21,060 bytes and writes resumed. **It is lossy**:
the pruned prose survives only in what was already relayed and in
`.workaholic/moderations/`. The surviving rows carry a visible
`(pruned; relayed and logged)` prefix. This ticket's change must not depend on that
prune having happened — see *Upgrade path* below.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions (all code work)
- `workaholic:implementation` / `policies/command-scripts.md` — the scripts changed here are the plugin's own command scripts; their argument handling, refusal words and exit contract are the subject of the change
- `workaholic:implementation` / `policies/persistence.md` — this is a durable store whose already-written rows must keep being readable across the change
- `workaholic:implementation` / `policies/observability.md` — a refusal that names the wrong cause, and a failure that produces empty output, are both observability defects before they are anything else
- `workaholic:implementation` / `policies/test.md` — the gate below turns each measured mode into an assertion

## Key Files

- `plugins/workaholic/skills/runtime/scripts/state.sh` - the defect. Lines 42, 120, 134, 151, 172 and 181 pass a value through `argv`; 42 and 181 pass the **whole record** and are therefore the tightest. Lines 142, 145, 146, 155, 159 and 164 compose from `stdin` and are already safe.
- `plugins/workaholic/skills/runtime/scripts/lib/result.sh` - `runtime_json_result` itself passes its data block as `--argjson d`, so line 181's payload rides `argv` a second time; fixing 181 alone is not enough.
- `plugins/workaholic/skills/runtime/scripts/coordinator.sh` - the caller. Its three large values (`old`, `input`, `plan`) already ride `--slurpfile` files and are safe; only line 64's `--argjson log` rides `argv`, bounded by `log-append.sh`'s own output. Line 21 is where an empty `state.sh` result becomes silence.
- `plugins/workaholic/skills/runtime/scripts/lib/coordinator.jq` - `valid_result` (line 16) requires `.report | type == "string"`, so the field must survive any bounding; line 100 is where a worker's result is stored.
- `plugins/workaholic/skills/work/scripts/codex-loop.sh` - line 989 asserts the same three fields plus `report` on a worker result; a bound must not break it.
- `scripts/test-workflow-scripts.mjs` - the hermetic suite; `state.sh` is already exercised near lines 32060, 42097 and 42308.
- `scripts/tests/agentic-loop/native-coordinator.test.mjs` - the coordinator's own contracts, including the `result` fixture at line 55.

## Related History

Two recent tickets in the same family — a refusal reported as something it is not —
settled the same way this one should: rename the word, keep the existing consumers
working, and prove the new word is reachable.

- [20260918210738-never-report-an-unreadable-binding-as-an-undeclared-one.md](.workaholic/tickets/archive/work-20260918-211451/20260918210738-never-report-an-unreadable-binding-as-an-undeclared-one.md) - an unreadable binding answered as an undeclared one (word names the wrong cause)
- [20260829152415-let-a-changed-refusal-reach-the-claim-holder.md](.workaholic/tickets/archive/work-20260829-154131/20260829152415-let-a-changed-refusal-reach-the-claim-holder.md) - a refusal word that changed had to reach the holder rather than being swallowed

## Implementation Steps

1. **Reproduce and localise both modes before changing anything.** In a throwaway
   repository, seed `<git-common-dir>/workaholic/runtime/v1/instances/<id>/meta.json`
   and drive `state.sh` directly. Confirm: (a) `.data` above 131,071 bytes answers
   `state_invalid` with nothing written and the `jq` `E2BIG` line on stderr; (b) a
   `.data` sized so the whole record crosses the cap **lands on disk** and then exits
   2 with empty stdout; (c) `state.sh read` against an on-disk record above the cap
   exits 0 with empty stdout; (d) `coordinator.sh` against that record emits nothing
   at all. Derive the cap on the test machine rather than hard-coding 131072 —
   `32 × $(getconf PAGESIZE)` — since page size is not 4096 everywhere.

2. **Pass every unbounded value by file, not by `argv`.** This is the correctness
   fix and it is the one that removes the cliff rather than moving it. In `state.sh`,
   write the payload into a file under the already-locked scratch area and read it
   inside the program (`--slurpfile` for JSON, indexing `[0]`; `--rawfile` where the
   value is text), at each of lines 42, 120, 134, 151, 172 and 181. Do the same for
   `runtime_json_result`'s `--argjson d` in `lib/result.sh`, or give it a variant
   that takes a data **file**, so line 181's record does not ride `argv` on the way
   out. Temp files are created inside the existing lock-held region, cleaned by the
   existing `trap`, and named uniquely per process; per `rules/shell.md`, a redirect
   onto a possibly-existing path uses `>|` or a run-unique filename, never a bare `>`
   under `noclobber`.

3. **Make every composition step answer by name instead of falling through.** A `jq`
   invocation that does not run to completion must produce a named JSON result, never
   empty stdout and never a bare non-zero exit. Concretely: guard the composition and
   the render so a failed step answers **`state_write_failed`** (the value could not
   be composed or the record could not be written) rather than `state_invalid`, and
   so the **read** path answers the existing **`state_unreadable`** rather than
   nothing. `state_invalid` is retained for exactly what it says — a composed value
   that failed the shape assertion at line 176 — and this ticket does not widen it.

4. **Refuse an oversized record by name, with a declared bound.** Once step 2 lands
   there is no mechanical argument cap left, so introduce a **declared** record
   ceiling in `state.sh` and refuse it as **`state_too_large`**, carrying the observed
   byte size and the ceiling in the result's `data` block. Set the ceiling generously
   (the record is rewritten in full on every event, so the cost of a large record is
   real but is a policy question, not a `MAX_ARG_STRLEN` question) and well above the
   argument cap, so that the test in the gate below — a record larger than
   `MAX_ARG_STRLEN` — **succeeds** rather than trading one refusal for another.

5. **Bound what the coordinator stores per worker result.** File-passing alone lets
   the record grow without bound, and every event rewrites the whole record, so an
   unbounded store makes each write O(n) in the loop's own history. In
   `lib/coordinator.jq` at the point a worker result is stored (line 100), truncate
   `result.report` to a declared constant and mark the truncation visibly, keeping
   `executed`, `outcome` and `reason` **intact and untruncated** — those are what
   `valid_result` (line 16), `coordinator.sh:58`'s finish-log summary and
   `codex-loop.sh:989` read. `report` must remain a string, because `valid_result`
   requires it. The full prose is not lost: it is relayed to the channel and written
   to `.workaholic/moderations/` by the finish-log seam, which is where a reader
   already goes for it.

   A separate prune-on-write pass is **not** added. The bound applied where the value
   is composed *is* the prune, and the upgrade path in step 6 re-bounds a legacy row
   on its first write after the change, so no migration script is needed.

6. **Upgrade path — an existing oversized record must become readable and writable
   again.** This store is clone-local under `.git/workaholic/runtime/`, so a
   fresh-store test proves nothing about a record that already exists; a record that
   crossed the cap before this change is exactly the row the change must rescue
   (`plugins/workaholic/rules/general.md`, *A tightened constraint over persisted data
   is verified against legacy rows*). After step 2, reading such a record must return
   it; writing over it must succeed; and the first write must leave the record
   re-bounded by step 5's constant. Verify against a **seeded** oversized record in
   the legacy shape — full untruncated `result.report` prose on many workers — not
   against a store the test just created.

7. **Enumerate and check the consumers of `state.sh`'s `reason`.** A consumer keying
   on `state_invalid` must not swallow the new words. The enumeration as measured:
   `state_invalid` appears in the tree **only at its emission site**
   (`state.sh:176`) — no consumer keys on it, so the new words flow through as an
   ordinary non-`ok` status. What consumers *do* key on is `revision_conflict`
   (`coordinator.sh:39` and `:43`) and `status == ok`
   (`coordinator.sh:21`, `:40`; `drive/scripts/deliver-unit.sh:31`). The new words
   must therefore not collide with `revision_conflict`, and step 3's guarantee — a
   named result rather than empty stdout — is what makes the `status == ok` tests
   correct. Re-derive this list from the tree rather than trusting the paragraph.

8. **Guard `coordinator.sh` against an empty or unparseable state result.** Line 21
   currently turns an empty `$WORK/read` into a silent `exit 0`. Give it a named
   refusal so a coordinator event that cannot read its own state says so. This is a
   second, independent defect found while localising the first: step 3 removes its
   present trigger, but a caller that renders silence for an unreadable answer is
   wrong regardless of who stopped producing it.

9. **Regenerate and verify.** Run the local verification list in `CLAUDE.md`
   (`build.mjs`, `verify.mjs`, `validate-metadata.mjs`, `test-workflow-scripts.mjs`,
   the `agentic-loop` node tests, `layout-doctor.sh`). Update `CLAUDE.md` and any
   affected `rules/` page in the same change if the refusal vocabulary or the
   coordinator's storage contract is described there.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `state.sh create` and a `state.sh update` whose `.data` is **larger than
  `MAX_ARG_STRLEN`** (computed as `32 × $(getconf PAGESIZE)`, not hard-coded) both
  answer `status: ok` and the record round-trips: a subsequent `state.sh read`
  returns the same `.data`.
- A `state.sh read` of an on-disk record **larger than `MAX_ARG_STRLEN`** answers
  `status: ok` with the record, and never empty stdout.
- Genuinely malformed input still answers **`state_invalid`**, with nothing written.
- Every refusal path emits a parseable JSON result on stdout; no input, and no
  record size, produces empty stdout or an unnamed non-zero exit from `state.sh` or
  from `coordinator.sh`.
- The Mode B window is closed: a record sized so the old code would land the write
  and then fail the render either succeeds and reports success, or refuses and
  leaves the record byte-identical — never both.
- A record above the declared ceiling answers **`state_too_large`** carrying the
  observed size and the ceiling; a composition or write step that could not run
  answers **`state_write_failed`**. Neither answers `state_invalid`, and neither
  collides with `revision_conflict`.
- Bounding keeps `executed`, `outcome` and `reason` intact and untruncated on every
  stored worker result; `report` remains a string, so `valid_result`
  (`lib/coordinator.jq:16`) and `codex-loop.sh:989` still accept it.
- Repeated `finish` events over many workers leave `.data` bounded rather than
  growing with the number of workers.

**Verification method** — the commands/tests/probes that prove them:

- New rows in `node scripts/test-workflow-scripts.mjs` covering: the over-cap
  create/update/read round-trip; the malformed-input `state_invalid` case; the
  `state_too_large` and `state_write_failed` cases; and the empty-stdout prohibition
  across every refusal path.
- **The upgrade path exercised against a representative legacy fixture**: a
  **seeded** `meta.json` written on disk in the pre-change shape — several workers
  carrying full, untruncated `result.report` prose, `.data` above
  `MAX_ARG_STRLEN` — proving that the old code fails against it and the new code
  (a) reads it, (b) writes over it, and (c) leaves it re-bounded. A suite that
  builds its store fresh does **not** satisfy this criterion: the store is
  clone-local and production's record already exists.
- A row in `scripts/tests/agentic-loop/native-coordinator.test.mjs` driving repeated
  `finish` events with oversized `report` values and asserting both that the three
  read fields survive intact and that `.data` stays bounded.
- A row asserting `coordinator.sh` answers a named refusal, not silence, when
  `state.sh` returns an unreadable result.
- `node scripts/build-plugins/build.mjs`, `verify.mjs`, `validate-metadata.mjs`,
  `node --test scripts/tests/agentic-loop/*.test.mjs`, and
  `bash plugins/workaholic/hooks/layout-doctor.sh .` all green.

**Gate** — what must pass before approval:

- The whole local verification list in `CLAUDE.md` is green, including the
  regenerated `outputs/`.
- The scripts stay POSIX `sh` (`#!/bin/sh -eu`); no `bash`-only construct is
  introduced.
- The reproduction from step 1 is demonstrated failing on the pre-change code and
  passing on the post-change code, for **both** modes and for the read path.
- No behaviour change for a record below the ceiling: an ordinary create, update,
  transition and read answer byte-identically to before.

## Considerations

- The temp files introduced in step 2 carry the record's full contents. They live
  under the existing lock-held scratch area and are removed by the existing `trap`
  on `EXIT HUP INT TERM`; a new temp path must not escape that trap, or a crash
  leaves the record's contents lying around
  (`plugins/workaholic/skills/runtime/scripts/state.sh` lines 61-92).
- `--slurpfile` slurps a *stream* into an array, so a payload file must hold exactly
  one JSON value and the program must index `[0]`; a file that ends up empty yields
  an empty array and would silently read as `null`. Guard that case rather than
  letting it compose a record with a null `.data`
  (`plugins/workaholic/skills/runtime/scripts/state.sh` lines 120, 134).
- `runtime_json_result` is shared by every runtime script, not only `state.sh`
  (`plugins/workaholic/skills/runtime/scripts/lib/result.sh` lines 3-8). Changing its
  signature reaches `coordinator.sh` and the transport scripts; adding a file-taking
  variant beside it is the smaller blast radius.
- The declared ceiling in step 4 is a policy bound, not a platform one. Setting it
  too low would reintroduce the same cliff under a nicer name; it exists so an
  unbounded record refuses deliberately rather than by `E2BIG` accident.
- The `(pruned; relayed and logged)` rows already on the live record were produced by
  the manual recovery, not by this change. The new bound's marker should be
  distinguishable from that prefix so a later reader can tell a hand-pruned row from
  a bounded one (`plugins/workaholic/skills/runtime/scripts/lib/coordinator.jq`
  line 100).
- Two `[Implement]` runners were live on their own claims and worktrees when this
  ticket was written; the live runtime store under `.git/workaholic/runtime/` was read
  but never modified while measuring. A session driving this ticket should seed its own
  throwaway store rather than experiment against the running instance's record.
