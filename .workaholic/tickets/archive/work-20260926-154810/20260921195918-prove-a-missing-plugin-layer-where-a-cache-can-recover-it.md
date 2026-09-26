---
created_at: 2026-09-21T19:59:18+09:00
status: done
author: a@qmu.jp
assignees: []
mission:
depends_on:
feedback: [20260921180339-exclude-explicitly-deferred-tickets-from-the-claimable-offer.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff:
claim: work-20260926-154810
---

# Prove a missing plugin layer where a cache can recover it

## Overview

Two assertions in `scripts/test-workflow-scripts.mjs` answer differently depending on **where
`TMPDIR` puts the fixture**, so a developer running the suite by hand sees two red rows that the
declared proof set does not.

**Measured 2026-09-21** on `testInstalledCodexClock` ("the installed Workaholic plugin launches
one Codex dry-run tick and diagnoses each layer"). The fixture copies `plugins/workaholic` into a
throwaway repository under `os.tmpdir()`, deletes `commands/infinite-development.md`, and asserts
the launcher exits **2** naming `plugin_command_missing`; the sibling row does the same for
`skills/work/SKILL.md` and `plugin_skill_missing`. The same deletion, the same launcher, two
different answers:

| Fixture under | Launcher says | Exit |
| ------------- | ------------- | ---- |
| `/tmp` (a bare `node scripts/test-workflow-scripts.mjs`) | `recovered retired plugin tree … -> ~/.claude/plugins/cache/workaholic/workaholic/1.0.384` | **0** — the assertion fails |
| `~/.cache/workaholic/proof-tmp.<n>` (what `local-proof.sh` exports) | `no complete replacement for …; update or reinstall the Workaholic plugin` | **2** — the assertion passes |

So `sh plugins/workaholic/skills/branching/scripts/local-proof.sh` reports `ok: true`,
`complete: true`, `failed: []` with all six checks green — the gate is **not** broken — while
`node scripts/test-workflow-scripts.mjs` on its own reports `7907 passed, 2 failed`. The bare-run
failure reproduces byte-identically on `origin/main` (proved over
`git archive origin/main plugins/workaholic`), so it is not this branch's.

**A test whose verdict depends on where its fixture lives is a test that misleads whoever runs it
by hand**, which is the whole of this ticket. The launcher's recovery through the newest plugin
tree on the machine is deliberate (`rules/general.md`: *the harness binding is an input, never a
precondition*) and is not the defect.

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

1. **Reproduce both readings first** — the fixture under `/tmp` and under a `TMPDIR` the runner
   owns — and record both, with the launcher's own two messages. Then **find why the resolution
   differs between those two locations**: that is the fact the repair rests on, and guessing at it
   is how the repair lands on the wrong layer.
2. **Bound the fixture to one answer, whatever `TMPDIR` says.** The launcher's recovery is
   deliberate, so the assertion must name a tree the recovery cannot reach rather than assert that
   recovery never happens — and it must not be weakened to *exit 2 or recovered*, which would pass
   on a launcher that had lost the diagnosis entirely.
3. **Keep the passing sibling passing**: the `clock_wrapper_missing` row distinguishes a missing
   compatibility target from a missing skill, and that distinction must survive.
4. **Prove it fails when the diagnosis is removed** — a fixture that cannot fail proves nothing —
   and prove it under **both** `TMPDIR` locations.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Both assertions answer the same under `TMPDIR=/tmp` and under a runner-owned scratch directory.
- Deleting the launcher's `plugin_command_missing` / `plugin_skill_missing` diagnosis makes them
  fail under both.
- `plugin-src.sh` and the launcher's recovery behaviour are byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` run bare on this machine — `0 failed`
- the same suite through `sh plugins/workaholic/skills/branching/scripts/local-proof.sh` — still
  `ok: true`, `complete: true`
- `git diff --stat` proving the launcher and `plugin-src.sh` are untouched

**Gate** — what must pass before approval:

- The local proof set reports `ok: true` with every `not_run` row named.
- Both readings from step 1 appear in the branch story.

## Considerations

- **The launcher is not the defect.** The recovery exists so an unattended run whose binding is
  missing still executes the workflow; a fix that removes it to satisfy a test would break the
  behaviour the test is incidental to.
- **The declared gate is green and this is not an outage.** `local-proof.sh` passes; what is wrong
  is that a hand-run of the same suite does not, which costs a developer a wrong diagnosis rather
  than a merge.
- **This is why the two failures were reported rather than fixed in place** by the run that found
  them: it was driving an unrelated mission, and an observation outside the current ticket's scope
  becomes a ticket (`drive/reference/failure-contract.md`).

## Final Report

Development completed as planned. `testInstalledCodexClock` now runs the launcher with a
fixture-owned empty `HOME` and with `CLAUDE_PROJECT_DIR`, `CLAUDE_PLUGIN_ROOT`,
`CLAUDE_PLUGIN_REGISTRY`, `CLAUDE_PLUGIN_CACHE`, `CODEX_PLUGIN_CACHE` and `WORKAHOLIC_SRC_HOME`
removed, so no plugin source outside the fixture is reachable by the recovery.

Step 1 readings, 2026-09-26, before the change: the bare suite under `TMPDIR=/tmp` **and** under
`TMPDIR=~/.cache/workaholic/repro` both answered `4 passed, 2 failed`, the launcher writing
`codex loop: recovered retired plugin tree <fixture>/installed/workaholic ->
~/.claude/plugins/cache/workaholic/workaholic/1.0.389`. The registry install had moved to the
fixture's own version (1.0.389), and `plugin-src.sh` gives an equal version to the immutable
candidate, so the recovery now wins under both locations. The TMPDIR split the ticket measured was
therefore never about `TMPDIR`: the verdict tracked which plugin trees `$HOME` held and at which
versions relative to the checkout.

After the change: `6 passed, 0 failed` under both locations; with the launcher's
`plugin_command_missing` / `plugin_skill_missing` words replaced, both rows fail under both
locations (mutation reverted). `codex-loop.sh` and `plugin-src.sh` are untouched.

### Discovered Insights

- **Insight**: Any fixture that deletes a plugin layer and expects a refusal must isolate `$HOME`, because the launcher's recovery composes `plugin-src.sh`, which reads `~/.claude/plugins/installed_plugins.json`, `~/.codex/plugins/cache` and `~/.workaholic-src`.
  **Context**: Otherwise the assertion's verdict follows the machine's install version, flipping every time the developer updates the plugin.
