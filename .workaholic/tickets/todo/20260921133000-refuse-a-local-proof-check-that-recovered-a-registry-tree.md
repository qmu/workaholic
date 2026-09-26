---
created_at: 2026-09-21T13:30:00+09:00
author: a@qmu.jp
assignees: []
depends_on:
feedback:
merge_policy:
claim: work-20260926-154810
---

# Refuse a local proof check that recovered a registry tree

## Overview

`scripts/test-workflow-scripts.mjs` fails two assertions on this machine, which makes
`branching/scripts/local-proof.sh` answer `ok: false` and would refuse **every** push through
`drive/scripts/catch-up-claim.sh` and `branching/scripts/prepare-publication.sh`
(`validation_failed:test-workflow-scripts.mjs`). The failing rows are in
`testInstalledCodexClock`: *a missing command body names the plugin command layer* and *a missing
work skill names the plugin skill layer*.

**Measured 2026-09-21**, reproducing the fixture by hand from **both** the pristine `main`
checkout and a work branch, with `TMPDIR` under `~/.cache/workaholic/` as `local-proof.sh` sets
it: both answer **`status=0`** where the test expects `2`, and `codex-loop.sh` writes
`codex loop: recovered retired plugin tree <fixture>/installed/workaholic ->
/home/ec2-user/.claude/plugins/cache/workaholic/workaholic/1.0.384`. The fixture deletes
`commands/infinite-development.md` from its own copied plugin tree; the launcher then finds the
**machine's registry install** and recovers to it, so the refusal the test asserts never happens.
The result is environment-dependent: on a machine with no registry install of this plugin the two
rows pass, which is why CI is green and why the same suite run outside `local-proof.sh` on this
machine also passed.

So there are two candidate defects and the ticket does not prejudge which:

1. **The test is under-isolated** — it asserts a refusal that any machine carrying a registry
   install cannot produce, so it measures the machine rather than the launcher.
2. **The recovery is too wide** — a plugin tree the caller explicitly named, with a file removed,
   being silently replaced by another tree on the machine is the `retired plugin tree` path doing
   something a caller may not want; a run can then execute code from a tree it did not name.

Whichever it is, the observable cost today is that a required member of the declared local proof
set reads `ok: false` on the developer's own server, so every gated push there is refused for a
reason that has nothing to do with the branch.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/test.md` — a test asserts the unit, not the machine
- `workaholic:operation` / `policies/monitoring-and-observability.md` — a gate's refusal must name
  a cause a reader can act on

## Key Files

- `scripts/test-workflow-scripts.mjs` — `testInstalledCodexClock`, the two failing assertions.
- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — the `retired plugin tree` recovery.
- `plugins/workaholic/skills/branching/scripts/local-proof.sh` — the declared set that goes
  `ok: false` on the failure.

## Implementation Steps

1. Reproduce both rows with `TMPDIR` outside the repository on a machine carrying a registry
   install, and again with the registry install made unreachable, to establish which side the
   behaviour belongs to.
2. Decide between isolating the fixture from the machine's plugin registry and narrowing the
   recovery, and record the reasoning where the chosen side lives.
3. Apply the fix and keep the other side's behaviour byte-identical.
4. Re-run `sh plugins/workaholic/skills/branching/scripts/local-proof.sh --repo .` on this server
   and assert `ok: true` with `complete: true`.

## Quality Gate

**Acceptance criteria** — `local-proof.sh` answers `ok: true`, `complete: true`, `failed: []` on
this server, and `testInstalledCodexClock` still fails if the launcher genuinely stops naming the
missing plugin command and skill layers.

**Verification method** — run the two assertions in isolation both with and without a reachable
registry install, then the whole declared set once.

**Gate** — no row is deleted or weakened to make the set green; a test that can only pass on a
machine with no plugin installed is not the repair.

## Considerations

Minted mid-run by the unit driving ticket `20260917174439`
(`.workaholic/tickets/todo/20260917174439-prove-the-declared-slack-transport-before-retiring-delivery-incidents.md`).
It carries **no `feedback:` ref**: the observation is about the local proof set and the launcher's
recovery, not about the Slack transport item that unit answers, and a wrong thread is worse than
none. The consequence is stated rather than hidden — when this ticket is driven as its own unit
its finish line has no thread to post into.
