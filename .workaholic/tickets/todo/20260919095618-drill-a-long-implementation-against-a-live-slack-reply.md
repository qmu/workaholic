---
created_at: 2026-09-19T09:56:18+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: dispatch-bounded-workers-without-stopping-the-observation-clock
merge_policy:
verification_handoff:
---

# Drill a long implementation against a live Slack reply

## Overview

Operator's ask: **issue #1142**, final item — *add a regression scenario: lengthy active
implementation plus new Slack reply plus restricted context delegation. Verify that observation
and acknowledgment continue on cadence, with bounded child input.*

**Why a drill and not a unit test.** The property under test is a **timing** one — that the
observation clock keeps ticking while a worker is busy — and it spans the coordinator, the
dispatch path, the transport adapter and the receipt store. `scripts/e2e/loop-drill.sh` is this
repository's instrument for exactly that class: it drills the loop's own mechanisms, `verify-all`
runs the classified set (`docs/loop-drill-runbook.md` §9), and CI runs its hermetic part on every
push. The existing contract tests in `scripts/tests/agentic-loop/` prove allocation and
coordination in isolation and cannot see a clock that stopped.

**It must be hermetic and offline.** Every existing drill verb is; a scenario that needed a real
Slack workspace would run nowhere, and this repository's own Slack binding is currently
undeliverable. The transport is stubbed at the adapter seam the same way the existing fixtures
stub it.

**This ticket is last in the mission deliberately.** It asserts the behaviour the first two
tickets create — a declared context policy with a bounded child input, and an observation clock
that survives a restriction — so it is the one that proves the mission rather than the one that
introduces it.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`, matching the existing
  drill verbs
- `workaholic:implementation` / `policies/test.md` — the governing policy: the scenario is
  hermetic, offline, deterministic and fails when the behaviour regresses
- `workaholic:implementation` / `policies/observability.md` — the drill's output names what it
  observed and what it could not, never a bare pass

## Key Files

- `scripts/e2e/loop-drill.sh` — the instrument, its verb registry and its classification of
  hermetic versus non-hermetic verbs. Read the whole file before adding a verb.
- `docs/loop-drill-runbook.md` (§9, the classified set) — where a new verb is registered and
  documented; a verb absent here is not in `verify-all`.
- `.github/workflows/loop-drills.yml` — what CI runs on push; the new verb must land in the
  hermetic set to be covered.
- `plugins/workaholic/skills/runtime/scripts/coordinator.sh` — receipts, `started`/`finish`; the
  drill drives a long-running child through this rather than simulating it separately.
- `plugins/workaholic/skills/transport/scripts/perform.sh` and the adapters — the seam the
  existing fixtures stub; the new Slack reply is injected here.
- `plugins/workaholic/skills/transport/scripts/observe-channel.sh` — the observation read whose
  cadence is the subject; its `overlap_seconds` and `unproved_since` behaviour must be honoured by
  the stub rather than bypassed.
- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — the non-native dispatch path.
- `scripts/tests/agentic-loop/*.test.mjs` — the isolated contracts this drill complements.

## Implementation Steps

1. **Read the instrument first.** `loop-drill.sh` in full, plus §9 of the runbook, and record how
   an existing hermetic verb seeds, verifies and resets, and how the classification is declared.
2. **Seed the three conditions.** A worker child launched under the bounded context policy and
   deliberately long-running; a Slack reply arriving **after** it started, injected at the
   transport stub; and a delegation policy that is restricted rather than absent.
3. **Assert the cadence, not the outcome.** The check is that between the child's `started` and
   its `finish`, at least one observation read occurred and the reply was acknowledged — the
   `📥 受理` or `💬` shape rendered against the stub. Assert on the **sequence of recorded
   events**, never on wall-clock sleeps: a drill that sleeps is a drill that goes flaky.
4. **Assert the child input is bounded.** The dispatch record carries only the contracted fields —
   the bounded task, artifact paths, worktree/claim, receipt id, user constraints and result
   schema — and no inherited conversation. This is the half that fails silently today, so assert
   the **absence** explicitly rather than only the presence of the fields.
5. **Assert the coordinator is unchanged.** Same instance id and same startup anchor across the
   whole scenario, one `start` only, and the child's receipt reconciled exactly once.
6. **Reset must be complete.** Following the existing verbs' contract, the drill leaves no
   worktree, branch, ref, receipt or log line behind, and touches no remote. Prove it by running
   the verb twice in a row.
7. **Register and classify** the verb in `loop-drill.sh` and in §9 of the runbook as **hermetic**,
   so `verify-all` and the CI push job both run it.
8. **Prove it fails.** Temporarily break the behaviour — suppress the observation read during a
   child's life — and confirm the verb fails with a message naming which assertion broke. Record
   that in the story; a drill nobody has seen fail is a drill nobody can trust.
9. **Regenerate and verify**: `sh scripts/e2e/loop-drill.sh verify-all`,
   `node scripts/test-workflow-scripts.mjs`, `node --test scripts/tests/agentic-loop/*.test.mjs`,
   `node scripts/build-plugins/verify.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A new drill verb exists, is registered in `loop-drill.sh` and in §9 of the runbook, and is
  classified hermetic.
- It reaches no network and requires no credential; it passes with no Slack binding configured.
- It asserts at least one observation read and one acknowledgement **between** a child's `started`
  and `finish`, from recorded events rather than elapsed time.
- It asserts the dispatched child's input carries only the contracted fields and **no** inherited
  conversation.
- It asserts one `start`, an unchanged instance id and anchor, and exactly one reconciliation.
- Two consecutive runs both pass and leave the tree, refs and receipts byte-identical.
- The verb **fails** when the observation read is suppressed during a child's life.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-all` is green, with the new verb in the run.
- The deliberate break in step 8 makes it red, and the message names the assertion.
- `git status --short` is empty after two consecutive runs.
- The CI drill job runs the verb on push.

**Gate** — what must pass before approval:

- No `sleep`-based timing assertion anywhere in the verb.
- The story records the observed failure from step 8.
- The suite is green and the bundle rebuild is diff-clean.
- POSIX `sh` throughout.

## Considerations

- **Order matters: drive this ticket last.** It asserts behaviour the mission's other two tickets
  introduce, and written first it would encode today's defect as the expectation.
- **A stub can prove the loop and not the provider.** The drill proves the coordinator keeps
  observing; it proves nothing about whether Slack would have delivered. Say so in the verb's own
  header so a green drill is never read as a working transport.
- **Keep the scenario to the ask's three conditions.** A drill that also exercises merges, claims
  or release paths becomes the one nobody can debug when it goes red.

## Final Report

Development completed as planned. Driven last, as the ticket asks: it asserts the behaviour the
mission's other two tickets introduce.

`scripts/e2e/drills/verify-observation-during-work.sh` adds one verb, registered in the
dispatcher, in the usage string and in `docs/loop-drill-runbook.md` §9 as **hermetic**, so
`verify-all` and the CI push matrix (`verify-all --list --kind hermetic`) both run it —
confirmed: the register resolves the row with `mission_resolved: true` and the listing names the
verb. It stages the ask's three conditions and nothing else: a deliberately long-running child
launched under a declared `bounded_task` policy, a Slack reply arriving **after** it started
(injected at the `qfs` adapter seam the existing fixtures already stub), and a delegation
restriction that is declared rather than absent.

Every assertion is made on the **recorded sequence of real calls** — a journal the drill appends
to as each script returns — and there is no `sleep` anywhere in the verb. Rows: an observation
read and an acknowledgement both recorded between the child's `started` and `finish`; the
receipt reading `running` on both sides of that window, from the coordinator's own `live[]`; the
dispatched child's input carrying the contracted fields **and no inherited conversation**,
asserted as an explicit absence against a planted marker; the restriction named with its one
cost; one `start`, an unmoved anchor and exactly one reconciliation; two consecutive runs
holding; and the checkout byte-identical afterwards.

**The failure was observed, not assumed** (step 8): the drill's own breaker row suppresses the
observation read during the child's life and the cadence assertion fails, which is why rows 1–2
prove anything. Three consecutive runs pass and `git status --short` afterwards shows only this
unit's own edits — no worktree, branch, ref, receipt or log line left behind, and no remote
touched.

The verb's header states its own bound: a stub proves the loop and not the provider. A green
verdict says the coordinator kept observing while a child was live and says nothing about
whether Slack would have delivered.

### Discovered Insights

- **Insight**: `verify-all`'s matrix is derived twice over — the dispatcher's own `case` arms
  (`sed -n 's/^    \(verify-[a-z-]*\)) cmd_.*/\1/p'`) intersected with the register table — so a
  verb added to only one of the two is reported `skipped: unclassified` rather than failing.
  **Context**: registering a drill means three edits (source, dispatcher arm, runbook row), and
  a missing runbook row is silent.
- **Insight**: asserting *observation happened while the child was live* needs no clock at all;
  the coordinator's `live[]` on either side of the read is the whole proof.
  **Context**: this is what lets the drill be timing-about-ordering rather than
  timing-about-duration, which is the difference between a stable drill and a flaky one.
