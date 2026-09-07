---
created_at: 2026-09-06T02:28:55+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-each-tick-in-the-originating-codex-chat
merge_policy:
verification_handoff: 
---

# Delegate each due role as a bounded native child

## Overview

The worker half of the native-parent branch. Each due role — `implement`, `propose`,
`moderate` — is delegated as a **bounded native child agent** that does its work and returns a
result; it never becomes a second looping coordinator. The parent keeps a **role-to-child map**
so a role already running is not dispatched again, which is the guarantee `ListAgents` gives
the Claude tick and the per-role lock gives the CLI supervisor, made here with the map.

The concurrency bound is the **harness's actual capacity** — the reporting session had four
slots — read at dispatch time rather than assumed unlimited.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the running loop's own reporting and recovery

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — the substitution table's dispatch and
  concurrency rows, which gain the native-child branch beside the detached-process one.
- `plugins/workaholic/commands/infinite-development.md` — where the tick decides which roles
  are due and what each is handed.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh`,
  `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the `loop-finish-<role>` cadence
  readers, which are unchanged and which a native child records into exactly as a worker
  process does.

## Implementation Steps

1. Keep a **role-to-child map** in the coordinator: role → child identifier → dispatched-at.
   A role with a live entry is **not** dispatched again, and the refusal is reported by name in
   the tick report.
2. Dispatch each due role as a **bounded** child: it performs its role's work once and returns.
   It reads no channel, decides no cadence, starts no other worker, and never loops.
3. Read the harness's **actual concurrent capacity** before dispatching beyond the first role,
   and hold a dispatch that would exceed it, naming the hold and the capacity. Never assume an
   unlimited pool. Capacity that cannot be read holds nothing and is named as unread.
4. At each wake, collect **newly available** child outcomes without blocking, and report each
   completion or blocker **once** — a role reported once is not reported again.
5. Keep the cadence unchanged: each child records `loop-finish-<role>` into the same tick log
   the coordinator already reads, so no new store, cursor or field is introduced.
6. State in `work/SKILL.md` that the native-child branch and the detached-process branch answer
   the same two questions — *is this role running* and *when did it last finish* — by different
   mechanisms, and that neither is a second clock.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A role with a live child is never dispatched twice; the refusal is named.
- A child performs bounded work and returns; nothing in its contract loops or reads the channel.
- The concurrency bound is read rather than assumed, and an unreadable bound holds nothing.
- Each completion or blocker is reported once.
- Cadence reads still go through `log-read.sh --step-prefix loop-finish-<role> --latest-tick`;
  no new store is added.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- No second liveness authority is introduced beside the tick log and the role map.

## Considerations

- The claim protocol remains the only allocator of repository work; the role map bounds
  *dispatch*, never claims.

## Final Report

Development completed as planned.

`work/SKILL.md` gains *The workers: bounded children the coordinator never awaits* — the role map,
the bounded child's contract, the read (never assumed) concurrency bound, the non-blocking
collection with once-only reporting, and the unchanged `loop-finish-<role>` cadence. The
closing paragraph states that the native-child branch and the detached-process branch answer *is
this role running* and *when did it last finish* by different mechanisms and that neither is a
second clock. `commands/infinite-development.md` §2 says the same at the point where the tick
decides which roles are due, so a session reading only the ceiling reaches it.

**No second liveness authority was introduced**: the tick log remains the only answer to *when
did it last finish*, on every branch, and the role map answers only *is this role running* — the
question `ListAgents` and the per-role lock already answered by their own mechanisms.

### Discovered Insights

- **Insight**: the harness's concurrency bound and the machine's load bound are two different
  gates on one fan-out, and collapsing them would lose a case each way.
  **Context**: `WORKAHOLIC_MAX_LOAD_PER_CORE` measures CPU on the box; the harness's capacity is
  a slot count the agent runtime enforces. A four-slot harness on an idle machine and a
  two-core machine with unlimited slots are both real, and each needs its own refusal word.
- **Insight**: *never loops* is the whole difference between a worker and a coordinator here.
  **Context**: the retired three-loop premise was three children that each held a clock; the role
  map bounds dispatch and would not have prevented it, so the bound that matters is written into
  the child's own contract rather than into the parent's bookkeeping.
