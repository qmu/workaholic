---
created_at: 2026-09-03T08:20:12+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: decide-each-tick-s-allocation-from-what-the-tick-just-read
merge_policy:
verification_handoff: 
---

# Read the machine's cores and load average

## Overview

The tick decides how many runners to start and never reads the machine it is starting them on.
`commands/infinite-development.md` §2 reads `ListAgents` and three cadences; nothing anywhere
reads core count or load. This ticket adds the reading and nothing else — it changes no
decision, so it can land and be wrong about nothing.

Measured mid-fan-out on the machine the loop runs on: three concurrent `implement` runners on a
**four-core** machine at loadavg `7.99 / 6.42 / 5.60`. The fifteen-minute figure says it had
been over capacity for a while rather than spiking. Memory was half free (8090 MB available of
16218) and the SoC was not throttling (64.2 °C, `throttled=0x0`) — **CPU was the binding
resource, and the other two are named so the reading is not over-claimed.**

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/skills/loops/scripts/read-machine-load.sh` — new; the skill's first script,
  so the directory is created by this ticket
- `plugins/workaholic/skills/loops/SKILL.md` — where the reader and its answers are documented
- `plugins/workaholic/rules/shell.md` — the POSIX `sh` rule the script is written to

## Implementation Steps

1. Write `read-machine-load.sh` as POSIX `sh` (`#!/bin/sh -eu`), a **pure read** that runs no
   command outside `nproc`/`getconf` and `/proc/loadavg`, opens no network connection and writes
   nothing anywhere.
2. Emit one JSON object: `{"cores": <n>, "load1": <float>, "load_per_core": <float>,
   "readable": <bool>, "reason": "<word>"}`.
3. **A reading that could not be made answers `readable: false` with a named reason and `null`
   counts** — never `0`, which reads as *an idle machine* and is the one answer that would make
   the consumer fan out hardest exactly when it must not. Reasons: `no_loadavg`,
   `no_core_count`, `unparseable`.
4. `readable` is **absent on a successful read**, matching the `merge_policy` / `status:`
   convention this repository already holds: absent means it completed, so the test is
   `readable == false` and never `readable // true`.
5. Derive `cores` from `nproc` and fall back to `getconf _NPROCESSORS_ONLN`; read `load1` as the
   first field of `/proc/loadavg`. A machine offering neither is `no_core_count`, not a guess.
6. Document the reader and each of its answers in `workaholic:loops` in this change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A healthy machine answers `cores`, `load1` and `load_per_core` with no `readable` key.
- An unreadable reading answers `readable: false`, a named reason, and `null` — never `0`.
- The script writes nothing, reads no network, and exits 0 in every case.

**Verification method** — the commands/tests/probes that prove them:

- Run it on this machine: the numbers match `nproc` and `/proc/loadavg` read by hand.
- Point it at an absent `/proc/loadavg` (`WORKAHOLIC_LOADAVG_PATH` or an equivalent seam the
  implementation chooses): it answers `readable: false` / `no_loadavg` / `null`.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- No consumer reads it yet; this ticket changes no decision anywhere.
- No zero is ever emitted for a reading that failed.

## Considerations

**Memory and thermal are deliberately out of scope**, and that is the ask's own scoping: on the
measurement above neither bound anything, so naming CPU as the first input is what the evidence
supports. Adding them later is a separate ask against a working reader.

The reading is Linux-shaped. A machine with no `/proc/loadavg` is answered `readable: false`
rather than approximated — the consumer's rule is that a gate which cannot be read is not a
gate, so an honest absence costs nothing.
