---
created_at: 2026-09-21T19:59:18+09:00
author: a@qmu.jp
assignees: []
mission:
depends_on:
feedback: [20260921180339-exclude-explicitly-deferred-tickets-from-the-claimable-offer.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff:
---

# Prove a missing plugin layer where a cache can recover it

## Overview

Two assertions in `scripts/test-workflow-scripts.mjs` fail on any machine that has the plugin
installed, and pass on CI. They are the only two failures in the suite here, and they fail
**identically on `origin/main`** — this ticket was minted by the run that measured that, not by
the change it was driving.

**Measured 2026-09-21** in `testInstalledCodexClock` ("the installed Workaholic plugin launches
one Codex dry-run tick and diagnoses each layer"). The fixture copies `plugins/workaholic` into
a throwaway repository, deletes `commands/infinite-development.md`, and asserts the launcher
exits **2** naming `plugin_command_missing`; the sibling row deletes `skills/work/SKILL.md` and
asserts `plugin_skill_missing`. On this machine the launcher instead prints

```
clock_wrapper_missing: retired plugin tree <fixture>/installed/workaholic
codex loop: recovered retired plugin tree <fixture>/installed/workaholic -> /home/ec2-user/.claude/plugins/cache/workaholic/workaholic/1.0.384
```

and exits **0** — it recovers through the newest plugin tree **on the machine**, which is
`plugin-src.sh`'s designed behaviour (`rules/general.md`: *the harness binding is an input,
never a precondition*). The recovery cannot fire on a CI runner, which carries no
`~/.claude/plugins/cache`, so the fixture passes there and fails for every developer.

Proved against the base as well as the branch: the same two commands run over
`git archive origin/main plugins/workaholic` answer `status=0` with the same recovery line.

## Policies

- `workaholic:implementation` / `policies/test.md` — a test asserts the behaviour, not the machine
- `workaholic:implementation` / `policies/error-handling.md` — a refusal is named, never silent
- `workaholic:operation` / `policies/observability.md` — a reading states what it could see

## Key Files

- `scripts/test-workflow-scripts.mjs` — `testInstalledCodexClock`, the two assertions and the
  sibling `clock_wrapper_missing` row that still passes.
- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — the launcher, and the recovery that
  defeats the assertion.
- `plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` — the resolution the recovery
  composes. **Read before touching**: the recovery is correct behaviour and is not the defect.

## Implementation Steps

1. **Reproduce both ways first** — the fixture on a machine with a plugin cache, and the same
   fixture with the cache made unreachable — and record both readings.
2. **Decide which layer the fixture is testing** and bound it there. The launcher's recovery is
   deliberate, so the assertion has to name a tree the recovery cannot reach, not assert that
   recovery never happens. Pointing the resolution at the fixture's own tree for the duration of
   the run is the obvious shape; do not weaken the assertion to *exit 2 or recovered*, which
   would pass on a launcher that had lost the diagnosis entirely.
3. **Keep the passing sibling passing**: the `clock_wrapper_missing` row already distinguishes a
   missing compatibility target from a missing skill, and that distinction must survive.
4. **Prove it fails when the diagnosis is removed** — a fixture that cannot fail proves nothing.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Both assertions pass on a machine carrying an installed plugin cache and on one without.
- Deleting the launcher's `plugin_command_missing` / `plugin_skill_missing` diagnosis makes them
  fail.
- `plugin-src.sh` and the launcher's recovery behaviour are byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` on this machine (a cache is present) — `0 failed`
- the same run with the resolution pointed away from the machine's cache
- `git diff --stat` proving the launcher and `plugin-src.sh` are untouched

**Gate** — what must pass before approval:

- The local proof set reports `ok: true` with every `not_run` row named.
- Both readings from step 1 appear in the branch story.

## Considerations

- **The launcher is not the defect.** The recovery exists so an unattended run whose binding is
  missing still executes the workflow; a fix that removes it to satisfy a test would break the
  behaviour the test is incidental to.
- **This is why the two failures were reported rather than fixed in place** by the run that found
  them: it was driving an unrelated mission, and an observation outside the current ticket's
  scope becomes a ticket (`drive/reference/failure-contract.md`).
