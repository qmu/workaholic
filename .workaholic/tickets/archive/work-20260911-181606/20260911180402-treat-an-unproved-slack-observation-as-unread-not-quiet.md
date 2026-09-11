---
created_at: 2026-09-11T18:04:02+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-the-native-loop-alive-preserve-slack-input-and-stop-direct-commits-to-main
merge_policy:
verification_handoff: 
---

# Treat an unproved Slack observation as unread, not quiet

## Overview

Issue #1151, second repair. After a manual resumption the Slack adapter answered
`observation_proved: false` with an unreadable source while a new human-authored channel root
already existed; the session described the channel as quiet and found the message only after
the human pasted its permalink. The operator's rule, verbatim: *When Slack observation is
unproved or unreadable, do not classify it as quiet, do not advance beyond the unread interval,
and keep retrying independently; a later direct read must overlap the unproved interval.*

Two halves. The **classification**: `runtime/scripts/plan-poll.sh` already answers
`observation_unreadable` with a failure streak when `proved` is false, but
`work/scripts/codex-loop.sh` reports `observed_quiet` whenever no activity was seen, whatever
`proved` said, and the agent-level tick reads the same shape. The **interval**:
`observe-channel.sh`'s `empty()` answer carries no cursor and no record of *when* the read
became unproved, and both adapters read back a fixed `overlap_seconds` of 300, so a later
proved read overlaps five minutes and not the interval that was never read.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/objective-documentation.md` — an unreadable source is unknown, never an empty channel

## Key Files

- `plugins/workaholic/skills/transport/scripts/observe-channel.sh` - the one observer; `empty()` is the unproved answer, the cursor read at line 73 and the fixed `overlap_seconds:300` at lines 74 and 96
- `plugins/workaholic/skills/transport/scripts/capture-inbox.sh` - persists messages before advancing the binding cursor
- `plugins/workaholic/skills/transport/scripts/adapters/qfs.sh` - `read_channel_delta` and `list_thread_changes` derive `since` from cursor minus overlap
- `plugins/workaholic/skills/transport/scripts/adapters/qfs-native.sh` - the same derivation on the native route
- `plugins/workaholic/skills/runtime/scripts/plan-poll.sh` - the cadence transition; `observation_unreadable` and the failure streak already live here
- `plugins/workaholic/skills/runtime/scripts/state.sh` - the binding record the cursor lives in
- `plugins/workaholic/skills/work/scripts/codex-loop.sh` - lines 832-853: an unproved read with no activity is answered `observed_quiet`
- `plugins/workaholic/commands/infinite-development.md` - the tick's observation rule (lines 25-28, 113-122)
- `plugins/workaholic/skills/work/SKILL.md` - *An observation is quiet only when every configured source was read successfully*
- `scripts/tests/agentic-loop/transport.test.mjs` - the observation fixtures
- `scripts/tests/agentic-loop/polling-cost.test.mjs` - the cadence fixtures

## Related History

The binding, the typed fallback and thread discovery were repaired over the previous three
days; none of them touched what happens to the interval when a read is unproved.

- [20260911021557-the-declared-slack-binding-cannot-read-its-own-channel-once-two-qfs-mounts-reach-it.md](.workaholic/feedbacks/20260911021557-the-declared-slack-binding-cannot-read-its-own-channel-once-two-qfs-mounts-reach-it.md) - the mount ambiguity that produced the unreadable source

## Implementation Steps

1. **Reproduce and localize** (diagnosis first). In a hermetic fixture with a stub adapter,
   store a cursor, make the next `read_channel_delta` answer unproved (an unreadable source)
   while a human root with a timestamp inside the interval exists, then make the following read
   proved. Measure: what `codex-loop.sh` reports for the unproved tick, what the binding
   record's cursor reads after it, and whether the proved read's `since` reaches the root. Record
   the three readings; the operator's session is the fourth.
2. **Record the unproved interval.** When the observation is unproved, `observe-channel.sh`
   writes `unproved_since` (the stored cursor, or the read's own `now` when no cursor exists)
   into the binding record beside the cursor, through `state.sh`, and **never** writes the
   cursor. A record already carrying `unproved_since` keeps the earlier value.
3. **Overlap the unproved interval.** Derive `overlap_seconds` per read: the greater of the
   standing 300 and `now - unproved_since`, on both the channel delta and the thread discovery.
   Clear `unproved_since` only inside `capture-inbox.sh`, in the same revision-checked write
   that advances the cursor, and only when the proved read's window reached it.
4. **Never call it quiet.** In `codex-loop.sh`, an unproved observation answers
   `observation_unreadable` with `plan-poll.sh`'s own retry deadline and never
   `observed_quiet`; the retry is the failure streak's, independent of the work cadence. A read
   that is proved but carries `unreadable[]` entries stays proved for the cursor and names the
   entries, unchanged.
5. **State it where the tick reads it.** One wording in `commands/infinite-development.md` and
   `work/SKILL.md`: unproved or unreadable is never quiet, never advances the cursor, keeps
   retrying independently, and the next direct read overlaps the unproved interval; a report
   that calls an unproved read quiet is non-conformant on its face. Add the `unproved_since`
   field to `transport/SKILL.md`'s record description.
6. **Regression coverage, the operator's own shape.** `transport.test.mjs`: a human root exists
   during an unproved observation; the unproved read leaves the cursor byte-identical and
   records `unproved_since`; the next proved read returns the root in `new_input_ids`,
   `capture-inbox.sh` captures it, and no permalink was supplied anywhere in the fixture.
   `polling-cost.test.mjs`: the unproved tick is `observation_unreadable`, not quiet, and the
   quiet streak is preserved.
7. Update `CLAUDE.md` (*A thread reply is discovered, never assumed* paragraph's neighbour) in
   the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- an unproved observation writes no cursor and records `unproved_since`; the next proved read's `since` is at or before `unproved_since`
- a human root posted inside the unproved interval appears in `new_input_ids` on the next proved read and is captured, with no permalink in the fixture
- `codex-loop.sh` never answers `observed_quiet` for an unproved observation

**Verification method** — the commands/tests/probes that prove them:

- `node --test scripts/tests/agentic-loop/transport.test.mjs scripts/tests/agentic-loop/polling-cost.test.mjs` with the new cases green
- `node scripts/test-workflow-scripts.mjs` green, including the wording pin on the two surfaces
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` with no diff in `outputs/`

**Gate** — what must pass before approval:

- the suite is green, `hooks/posix-lint.sh` conforming, and the story quotes the measured pre-change readings from step 1

## Considerations

- The overlap must stay bounded: a read after a long outage re-reads the whole unproved interval once, and `has_more` paging must carry the same `since` until the interval is covered (`plugins/workaholic/skills/transport/scripts/adapters/qfs.sh` lines 30-40)
- `capture-inbox.sh`'s revision-checked write is the only place the cursor and `unproved_since` may change together; two writers of one record would race (`plugins/workaholic/skills/transport/scripts/capture-inbox.sh` lines 50-53)
- Reporter-proposed mechanism recorded as a hypothesis: *a later direct read must overlap the unproved interval* — step 1 decides whether the gap is the missing overlap, the `observed_quiet` word, or the agent's reading of a proved-but-degraded result

## Final Report

Development completed as planned.

Measured before the change (step 1, hermetic fixture with a stub adapter): a proved read stored
cursor `801.0`; the next read, with the provider unreachable, answered `observation_proved:
false` / `unreadable: ["qfs_connector_failure"]` with no record of when the channel became
unread, and the binding record's cursor stayed `801.0` byte-identical; the following proved
read asked `after 501.000000` (cursor − 300) and returned the human root posted at `850.0`. So
the channel-delta interval was already preserved by the cursor's own construction (the
missing-overlap hypothesis is falsified for that path), `plan-poll.sh` already answered
`observation_unreadable` with the quiet streak preserved, and the live defects were the word —
`codex-loop.sh` reported `observed_quiet` for the observation-only wait whatever `proved` said,
and the agent-level tick read the same shape — and the absence of any stated *since when*. The
operator's session is the fourth reading.

### Discovered Insights

- **Insight**: `unproved_since` cannot be recorded for a refusal raised before the binding resolves (a contradictory declaration, a describe or resolve refusal), because the binding record is keyed on the resolved binding's hash; such a refusal carries `unproved_since: null`, and every binding's cursor is untouched by it anyway.
  **Context**: the measured `operations_unsatisfied` case is one of these — the report layer treats any unproved read as unread regardless, which is what the pinned wording says.
- **Insight**: the wait word in the Codex clock is now a mapping from `plan-poll.sh`'s own reason, so the two readers cannot disagree; the reason is recorded in the tick status file, which is what lets `--status` tell an unread channel from a quiet one.
  **Context**: a source-level pin (`quiet) _pt_wait=observed_quiet`) plus a supervisor fixture that drives two ticks with a failing provider is what proves it.
