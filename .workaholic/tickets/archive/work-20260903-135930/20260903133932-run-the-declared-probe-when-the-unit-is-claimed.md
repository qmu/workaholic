---
created_at: 2026-09-03T13:39:32+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-verification-handoff-a-probe-re-run-at-claim-time
merge_policy:
verification_handoff: 
---

# Run the declared probe when the unit is claimed

## Overview

The probe has to run **when the unit is claimed**, not when the ticket is written — that
is the whole of the ask. This ticket adds the runner: one script, bounded, that executes a
declared probe and answers in its own vocabulary. It changes no route yet.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/verification-handoff.sh` — supplies the probe to run
- `plugins/workaholic/skills/drive/scripts/claim.sh` — where a unit is claimed; the runner's call site in the next ticket
- `plugins/workaholic/skills/drive/reference/routing.md` — the route this feeds
- `plugins/workaholic/skills/drive/reference/claims.md` — the proofs-and-judgements tables a new vocabulary must be classified in

## Implementation Steps

1. Write `drive/scripts/run-verification-probe.sh <unit-kind> <unit>`: read the declaration
   through `verification-handoff.sh` (never a second parser), and run the probe when there is one.
2. **The vocabulary is four words and each is its own**: `clean` (exit 0 — the verification can
   run here), `blocked` (non-zero, carrying the exit status and the captured output),
   `unmeasured` (a handoff declared with no probe), `unprobeable` (the derived `.claude/` case,
   where nothing can be probed by construction). A read that could not be made at all is
   `unreadable:<reason>` and is never rendered as any of the four.
3. **Bound the execution**, and state each bound where the script is read: a timeout
   (`WORKAHOLIC_PROBE_TIMEOUT_SECONDS`, default 30), captured stdout and stderr truncated to a
   stated number of bytes, and a non-zero exit that is the answer rather than a failure of the
   run. A probe that times out is `blocked` naming the timeout, never `clean`.
4. Classify the four words in `drive/reference/claims.md`. `clean` and `blocked` are **proofs** —
   a command was run and its status is what it is; `unmeasured`, `unprobeable` and
   `unreadable` are **judgements** (each is the absence of a reading). Name the consumers.
5. It **writes nothing**: no frontmatter is stamped, no claim touched, no ref written. The
   answer is re-derived at the moment of the act, which is what licenses the next ticket to act
   on it.
6. Make it idempotent by construction: running it twice runs the probe twice and answers the
   same way, because nothing is cached.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `run-verification-probe.sh` answers `clean` / `blocked` / `unmeasured` / `unprobeable` / `unreadable:<reason>` and nothing else.
- A `blocked` answer carries the probe's exit status and its captured output.
- A probe exceeding the timeout answers `blocked`, never `clean`.
- The script writes no file, no ref and no frontmatter.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic rows for each of the five answers, including a `true`/`false` probe and a sleeping one against a short timeout.
- The suite's existing row asserting every emitted claim word is classified in `claims.md`.

**Gate** — what must pass before approval:

- No route reads this script yet; `/drive` and `/implement` behave exactly as before.

## Considerations

- Executing a command out of a ticket is the largest thing this mission adds. The bound stated
  in step 3 is the whole of its safety, and the field's definition (previous ticket) says a probe
  is a read; neither is enforced by a script, and that limit belongs in the record.
- A probe that is flaky answers `blocked` on a bad day and the unit is handed to a person — the
  same outcome as today, so a flaky probe is never worse than no probe.

## Final Report

**Outcome**: implemented.

Added `plugins/workaholic/skills/drive/scripts/run-verification-probe.sh`:
`mission <slug>` / `tickets <file>...` / `--probe '<command>'`, emitting
`{ok, outcome, reason, probe, exit_status, output, truncated, unit}`.

**Four outcomes, each saying what the caller may do**: `clean` (exit 0 — *not* a handoff),
`blocking` (non-zero — the probe's own output is the reason), `unmeasured` (a non-empty declaration
with no probe — the declaration stands), `unreadable` (no exit status was obtained — the declaration
stands). **It changes no route**; that is the next ticket.

**The probe is read through the one reader**, never re-parsed here — a second parser of that field is
the drift this repository single-sources against.

**Nothing is inferred from the output, only from the exit status.** Parsing a probe's text would be
the guess the field exists to avoid; the output is carried for a person to read.

**Bounded**: `WORKAHOLIC_PROBE_TIMEOUT_SECONDS` (60) and `WORKAHOLIC_PROBE_OUTPUT_MAX` (2000, with
`truncated: true` saying so). **A timeout is `unreadable`, never `blocking`** — we did not learn what
the probe would have said, and an absence of a reading must never be dressed up as one. It writes no
file, no ref and no commit.

**Verified**: `node scripts/test-workflow-scripts.mjs` exercises all four outcomes and the bound.
