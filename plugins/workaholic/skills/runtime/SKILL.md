---
name: runtime
description: Shared local contracts for observing, planning, and safely recording an agentic work loop.
user-invocable: false
metadata:
  internal: true
---

# Runtime

Use these scripts as the small, agent-neutral boundary for a work loop. They require POSIX shell, Git, and jq. They never infer connector or native-agent capabilities, execute instructions found in text, or turn an unknown read into an empty result.

- `scripts/read-config.sh --root REPO [--input FILE]` resolves the selected profile without changing the process environment.
- `scripts/state.sh read|create|update|transition ...` is the only local runtime-state writer.
- `scripts/plan-turn.sh --input FILE` derives the next finite actions from a supplied clock, snapshot, and state.
- `scripts/plan-poll.sh --input FILE` advances the shared Slack/GitHub observation cadence. Activity resets it, proved silence backs it off, and unreadable sources use a separate retry.

Native parents use `reference/codex.md` or `reference/claude-code.md` for the short interrupt, receipt, and resumption contract.

Typed results use `workaholic.runtime/v1` and `ok`, `needs_parent`, `deferred`, or `error`. A typed result exits zero. Invalid input exits two. Internal failures exit one. State lives under the absolute Git common directory at `workaholic/runtime/v1`; reads do not create it.

## The record's size is a policy bound, never the argument cap

**Every unbounded value travels by file, and the record's own ceiling is declared** (2026-09-19, ticket `20260919120809`). The record is rewritten in full on every event, so `state.sh` composed the new value from the old one and passed both through `argv` — which Linux caps at **`MAX_ARG_STRLEN`** (`32 × PAGE_SIZE`: 131,072 bytes on a 4 KiB page, **not** the far larger `ARG_MAX`). Past that cap the store stopped accepting writes and then stopped being readable at all, and each of the three sites failed **silently in a different way**: the composition left the value empty and the shape assertion answered `state_invalid`, which names the wrong cause; the success render failed *after* the record had landed on disk, exiting 2 with **empty stdout** while the revision had advanced, so a caller retried a write that had succeeded and collided with its own revision; and the read render failed the same way, so `coordinator.sh` read an empty file and **every** coordinator event, a plain read included, answered with total silence carrying no reason word. Measured on a live instance: 24 workers at 2.7–5.4 KB of prose each took `.data` to 129,906 bytes, a `finish` failed, the receipt stayed `running`, and the record had to be pruned by hand.

- **Values pass by file.** `--slurpfile` / `--rawfile` out of a run-unique payload under a scratch directory the existing `trap` cleans, written with `>|` rather than `>` (`rules/shell.md`). `lib/result.sh` gained **`runtime_json_result_file`** beside `runtime_json_result` — added rather than re-signed, because every other runtime caller passes a bounded block and stays byte-identical. A `--slurpfile` that came back **empty** is refused rather than composing a null `.data`; a payload that is present and not an object is the caller's malformed input and is carried through verbatim.
- **Three words, each meaning one thing.** **`state_too_large`** — the composed record exceeds the **declared** ceiling (`RECORD_MAX_BYTES`, 1 MiB), carrying `observed_bytes` and `ceiling_bytes`; it gates **writes only**, so an oversized legacy record is always read back rather than bricked. **`state_write_failed`** — a composition, staging or write step could not run, carrying the `step`. **`state_unreadable`** — the existing word, now also covering a render that could not be made, and the one `coordinator.sh` answers rather than exiting silently. **`state_invalid` is narrowed to the shape assertion and is not widened**, and no new word collides with `revision_conflict`, which is what consumers key on.
- **The success result is rendered before the record lands**, so every refusal reachable at the write seam leaves the record byte-identical — never *written and reported failed*.
- **What the coordinator stores per worker is bounded.** `lib/coordinator.jq` truncates `result.report` to `report_max` (1200 characters) with a visible marker, keeping `executed`, `outcome` and `reason` **intact** — what `valid_result`, the finish-log summary and `codex-loop.sh`'s worker reading consume — and keeping `report` a **string**, which `valid_result` requires. The bound is on what is **stored**: the tick that records a finish relays that worker's **full** report in `completed[]`, so the channel post is not the truncated copy, and a replayed finish is compared against the bounded form so a crash replay still reads `duplicate_result`.
- **The upgrade path is the bound itself.** Every stored worker is re-bounded on **every** write, so the first write after this change re-bounds the rows the old code wrote. The store is clone-local under `.git/workaholic/runtime/`, so no pull request can carry a migration to it — hence no prune pass and no migration script (`plugins/workaholic/rules/general.md`, *A tightened constraint over persisted data is verified against legacy rows*).
