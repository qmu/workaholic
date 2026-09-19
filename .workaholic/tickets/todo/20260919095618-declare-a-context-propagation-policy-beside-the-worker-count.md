---
created_at: 2026-09-19T09:56:18+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: dispatch-bounded-workers-without-stopping-the-observation-clock
merge_policy:
verification_handoff:
---

# Declare a context propagation policy beside the worker count

## Overview

Operator's ask: **issue #1142** — *support a low-context dispatch mode … supplying a bounded task,
relevant artifact paths, worktree/claim, receipt ID, current user constraints and result schema*,
and *expose worker count and context-propagation policy separately from cadence*.

**Established in this tree.** Three dials exist and none of them is the one the operator needed.
Cadence lives in the runtime config's `polling` (`runtime/scripts/read-config.sh`, whose accepted
top-level keys are exactly `polling`, `target` and `limits`). Worker count is
`WORKAHOLIC_MAX_WORKERS`, named in `commands/infinite-development.md`, `skills/work/SKILL.md` and
`skills/loops/SKILL.md`. **Context propagation appears nowhere**: a tree-wide walk for
`fork_turns`, `low-context`, `low_context` and *context propagation* returns nothing. So an
operator whose objection is the per-child context copy has exactly one lever — turning delegation
off — and pulling it produced the measured outage: the parent implemented inline and the
coordinator stopped receiving role ticks.

**The child's input contract is half-written.** `skills/work/SKILL.md`, *Children and reports*,
specifies what a worker **returns** (`executed`, `outcome`, `reason`, `report`, with a schema at
`work/worker-result.schema.json`) and what the parent records (`coordinator.sh` receipts,
`child_id`, `started`, `finish`, `reported`). What it does **not** specify is what a child
**receives** — so how much conversation a child inherits is a property of whichever harness
launched it rather than of a declared policy.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`
- `workaholic:implementation` / `policies/persistence.md` — the policy is declared configuration
  read back each tick; absent, invalid and unreadable are three answers
- `workaholic:implementation` / `policies/observability.md` — the tick reports the policy it ran
  under; a bounded dispatch and a full-context one must not read alike
- `workaholic:implementation` / `policies/test.md` — the reader, its defaults and its refusals are
  pinned hermetically

## Key Files

- `plugins/workaholic/skills/runtime/scripts/read-config.sh` (the `allowed` guard, lines ~40-44) —
  the one reader of `workaholic.config.json` and the legacy `.claude/settings.json`; a new
  top-level key must be added to that closed set or it is rejected.
- `plugins/workaholic/skills/work/SKILL.md` (*Children and reports*) — where the child contract
  lives; the input half lands here beside the existing return half.
- `plugins/workaholic/skills/work/worker-result.schema.json` — the return schema, the model for
  whatever shape the input contract takes.
- `plugins/workaholic/skills/runtime/scripts/coordinator.sh` — the receipt writer; a child's
  receipt is the natural home for *which policy this child was launched under*.
- `plugins/workaholic/skills/work/scripts/codex-loop.sh` (`--dispatch`) — the non-native dispatch
  path; it must carry the same policy as the native one or the two will disagree.
- `plugins/workaholic/commands/infinite-development.md` — the tick ceiling; the report obligation
  lands here and must be byte-identical to the one in `work/SKILL.md` (the suite pins such pairs).
- `plugins/workaholic/skills/loops/SKILL.md` and `scripts/allocate-implement.sh` — worker count and
  allocation, which this ticket must leave **untouched**: the ask is for a separate dial.
- `scripts/tests/agentic-loop/coordinator-allocation.test.mjs` — the existing allocation contract.

## Implementation Steps

1. **Reproduce the three-dial reading** before designing: confirm `polling`, `limits` and the
   absence of any context key, and record the accepted top-level set from `read-config.sh`.
2. **Declare the policy where the other settings live**, as its own top-level key — not folded
   into `limits`, which is a count, and not into `polling`, which is a clock. The ask's phrase is
   *separately from cadence*, and one key answering two questions is how two questions drift.
3. **Give it a small closed set of values**, named for what a child inherits rather than for a
   harness flag: the full conversation, or nothing beyond a bounded task. Map the low-context
   value onto `fork_turns="none"` **where the harness supports it** and say plainly what happens
   where it does not — an unsupported policy is reported as unsupported and the dispatch proceeds
   under the policy that is available, never silently under a different one.
4. **Absent means today's behaviour.** A repository declaring nothing dispatches exactly as it
   does now. That is the same safety property `WORKAHOLIC_WIP_LIMIT` states for itself, and it is
   what keeps this change from altering every consuming repository at once.
5. **Write the child input contract** in `work/SKILL.md` beside the return schema: a bounded task,
   the artifact paths it needs, its worktree and claim, its receipt id, the current user
   constraints, and the result schema — the ask's own list. State that a child receives no more
   than this under the bounded policy, and that a worker proves only its own unit.
6. **Carry the policy to both dispatch paths** — the native child launch and
   `codex-loop.sh --dispatch` — and record it on the child's receipt through `coordinator.sh`, so
   a resumed coordinator can tell what a live child was launched under.
7. **Report it on the tick**, in one wording carried into `commands/infinite-development.md` and
   `work/SKILL.md`: the policy in force, and whether the harness honoured it.
8. **Change no count and no cadence.** `WORKAHOLIC_MAX_WORKERS`, the implement fanout,
   `allocate-implement.sh` and every polling value are byte-identical.
9. **Hermetic rows**: an absent policy dispatches as today; a declared bounded policy is reported
   and rides the receipt; an invalid value is refused by name with nothing dispatched under a
   guessed policy; an unsupported harness reports unsupported rather than silently downgrading;
   and the allocation contract test is unchanged.
10. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
    `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`,
    `node --test scripts/tests/agentic-loop/*.test.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The policy is declared as its own setting, accepted by `read-config.sh`, and is neither a count
  nor a clock value.
- **Absent means current behaviour**: a repository declaring nothing produces byte-identical
  dispatch.
- An invalid value is refused by its own word with nothing dispatched; an unsupported harness
  reports unsupported and does not silently substitute another policy.
- A dispatched child's receipt records the policy it was launched under.
- Both dispatch paths carry the same policy.
- The tick reports the policy in one wording, byte-identical across the ceiling and the skill.
- `WORKAHOLIC_MAX_WORKERS`, the fanout and every cadence value are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` and `node --test scripts/tests/agentic-loop/*.test.mjs`
  are green; the new rows fail when reverted.
- `git diff origin/main -- plugins/workaholic/skills/loops/scripts/allocate-implement.sh` is empty.
- A fixture config with no policy key produces a dispatch record identical to the pre-change one.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- The suite is green and the bundle rebuild is diff-clean.
- The child input contract is written in exactly one place and cited elsewhere.
- POSIX `sh` throughout.

## Considerations

- **A bounded child knows less and can therefore claim less.** That is not a cost to hide: it is
  the premise of the ask's own last sentence — *a worker finish should be evidence for the parent,
  not automatic permission*. The contract in step 5 should say so.
- **`fork_turns` is a harness capability, not a workaholic one.** Name it as the mapping, never as
  the policy, so a harness that spells it differently needs no new policy value.
- **Do not let the policy become a second cadence lever.** Spawning fewer workers to save context
  is a count decision and belongs to the dial that already exists.
