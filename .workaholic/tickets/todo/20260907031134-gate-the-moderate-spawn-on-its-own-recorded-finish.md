---
created_at: 2026-09-07T03:11:34+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260907030805-read-moderate-s-cadence-from-its-own-recorded-finish.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
---

# Gate the moderate spawn on its own recorded finish

## Overview

`commands/infinite-development.md` §2 reads `moderate`'s 30-minute cadence with
`log-read.sh --latest-tick` and no step filter, while `implement` and `propose` are read with
`log-read.sh --step-prefix loop-finish-<name> --latest-tick`. All three read the same file,
`.workaholic/moderations/<UTC-day>.md`, into which the coordinator tick writes its own
`loop-finish-<name>` lines under the **coordinator's** tick id every time it observes a subagent
idle. The unfiltered read therefore answers whichever tick wrote last — normally the coordinator —
so `moderate`'s gate can be pushed forward by a write that has nothing to do with `moderate`.

Measured at coordinator tick `20260906-175547`: `--latest-tick` answered `20260906-174615` (this
session's own `loop-finish-propose` line) while `--step-prefix loop-finish-moderate --latest-tick`
answered `20260906-173626`. The real finish was 19 minutes older than the gate believed. Because a
`loop-finish-*` line is written on most ticks, each write moves the bare reading forward, so on a
busy loop the gate can read *moderate ran just now* indefinitely and never fire — silencing the one
tick that notices absence, with **no degradation word for it**, because the read succeeds and
returns a real tick id.

The two halves shipped the same day, into the same file, and neither knew about the other: #960
(`Pay only the operative cost on every tick`) pointed the gate at the then-new `--latest-tick`, and
#961 (`Stop a finished subagent and take the loop's clock off it`) then began writing
`loop-finish-*` lines into that log. `log-read.sh`'s own header already records that every filter
still applies to `--latest-tick`, so the filtered reading has been available since #960 and is what
the sibling cadences use.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §2's `moderate` gate; **the one surface
  carrying the bare read**, and the ceiling a routine-fired session actually executes
- `plugins/workaholic/skills/work/SKILL.md` — states the cadence generically and **already carries
  the filtered form**; read it before editing (see Considerations) — expected to need no change,
  and if it needs one it is a consistency line, not a second reader
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the one reader; **not touched**, it
  already composes `--step-prefix` with `--latest-tick`
- `scripts/test-workflow-scripts.mjs` — the suite asserts *a* filtered cadence read exists but pins
  no row on the `moderate` gate, which is why this regression was invisible

## Implementation Steps

1. **Reproduce the divergence before changing anything.** Build a hermetic tick-log fixture
   carrying, in this order, a `loop-finish-moderate` line under an older tick id and a
   `loop-finish-propose` line under a newer one. Run both readings against it:
   `log-read.sh --root <fixture> --latest-tick` and
   `log-read.sh --root <fixture> --step-prefix loop-finish-moderate --latest-tick`. Record both
   answers. If they do not differ, the fixture does not reproduce the report and the rest of this
   ticket is not yet justified — say so and stop.
2. **Localize it to the caller, not the reader.** Confirm `log-read.sh` answers the filtered
   question correctly (it does per step 1) and that the defect is which invocation §2 names. Do not
   change `log-read.sh`: a reader that answers both questions correctly is not the fault.
3. **Point §2's `moderate` gate at the filtered reading** — `log-read.sh --step-prefix
   loop-finish-moderate --latest-tick` — so all three cadences are keyed on that loop's own
   recorded finish. Keep the surrounding sentences' rules verbatim: an empty `latest_tick` means
   *no such tick* and is due, never *just now*; an unreadable log spawns it; a recorded finish older
   than 30 minutes is due.
4. **Check the two sibling surfaces and change only what states the bare form.**
   `skills/work/SKILL.md` and `skills/work/scripts/codex-loop.sh` were both read while writing this
   ticket and neither carried it (Considerations); re-read both at implementation time rather than
   trusting this note, and if either states the bare form for `moderate`, correct it in the same
   change.
5. **Add the suite row that would have caught it**: assert that §2's `moderate` gate names
   `loop-finish-moderate`, so a future edit that drops the filter fails the build. The existing row
   asserting `/--step-prefix loop-finish-.*--latest-tick/` passes on the `implement`/`propose` block
   alone and cannot see this.
6. **Regenerate and verify** the generated outputs and the policy index, since a plugin file moved.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- §2's `moderate` gate reads `log-read.sh --step-prefix loop-finish-moderate --latest-tick`.
- Every existing rule around that gate is unchanged: empty `latest_tick` is *no such tick* and is
  due; an unreadable log is due; a finish older than 30 minutes is due.
- No second log, no cursor and no field on any artifact is added, and the tick still writes its
  `loop-finish-*` lines into the same file.
- A suite row fails when the `moderate` gate carries no `loop-finish-moderate` filter.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` passes, including the new row; deleting the filter from
  §2 makes that row fail (prove the assertion bites, not only that it passes).
- The step-1 fixture: the two readings differ, and the reading the gate now names is the
  `loop-finish-moderate` one.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` leave no diff.

**Gate** — what must pass before approval:

- `plugins/workaholic/skills/moderate/scripts/log-read.sh` is byte-identical: no reader changed.
- No other caller's cadence reading changes.

## Considerations

**What was consulted while writing this, and what it said.** The ask states that
`commands/infinite-development.md` §2 and `skills/work/SKILL.md` "both state the bare form". Read
2026-09-07 on `f30860ce0`: §2 does, and `skills/work/SKILL.md` does **not** — its cadence block
already reads `log-read.sh --step-prefix loop-finish-<name> --latest-tick` generically for every
loop. `skills/work/scripts/codex-loop.sh` reads `--step-prefix loop-attempt-<role> --latest-tick`,
also filtered, so the external clock is unaffected. The operative change is therefore expected to be
one file, and step 4 re-checks rather than trusting this paragraph. This narrows the ask's scope; it
does not contradict its diagnosis.

**The reporter named the fix, and it is carried here as a hypothesis rather than as the design.**
The ask asks for `--step-prefix loop-finish-moderate --latest-tick`. The history pass corroborates
it — `log-read.sh`'s own header states that every filter still applies to `--latest-tick`, and the
sibling cadences already use exactly that shape — but step 1 still reproduces the divergence first,
because a fix adopted from a report without a reproduction is a change nobody has seen work.

**Why the failure is silent, which is what makes it worth a ticket for a one-line change.** The
gate's wrong answer is a well-formed tick id, so no `cadence_unreadable` and no degraded reading
fires. The repository's standing rule is that a degraded read is never rendered as a healthy
`not_due`; this is the same failure reached through a *write* rather than a read, and nothing
reports a maintenance tick that was never spawned.

**Prior record.** The loop filed this same defect about itself on 2026-09-06
(`20260906110057-the-tick-s-own-log-writes-suppress-the-moderate-spawn-forever.md`) and
`/specificate` refused it `self_authored`, leaving it for the operator to rule on. Issue #1055 is
that ruling; the new record supersedes the old one.
