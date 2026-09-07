---
created_at: 2026-09-07T08:27:37+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: recover-the-codex-loop-from-a-retired-plugin-path-and-refuse-a-false-healthy-status
merge_policy:
verification_handoff:
---

# Stop the Codex supervisor running against a retired plugin path

## Overview

PROPOSED. A running Codex supervisor resolves its plugin tree **once**, at launch, from its own
script directory — `PLUGIN_ROOT=$(cd -- "${SCRIPT_DIR}/../../.." && pwd)` (`codex-loop.sh:52`) —
and derives `TICK_PROMPT` and `COMMAND_BODY` from it (`:53-54`). A plugin update that installs a
new version and removes the old cache therefore leaves a live supervisor handing every tick a
`SKILL.md` and a command body that no longer exist. Measured 2026-09-06 (#1052): a supervisor
launched from 1.0.316 kept driving that path after 1.0.323 was installed; restarting it by hand
was the only repair, and the operator had to ask why development had stopped.

This ticket makes the tick detect retirement and recover through the sanctioned resolver,
recording the transition and refusing further execution when recovery is impossible. See
`## Resolved Decision` for the source ruling.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — `PLUGIN_ROOT` at `:52`, `TICK_PROMPT`
  and `COMMAND_BODY` at `:53-54`, and every later interpolation of `$PLUGIN_ROOT` into a worker
  prompt (`:689`, `:835-850`). The one place the launch path is frozen.
- `plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` — the sanctioned resolver, already
  answering `src` and `call_src` on two axes (newest wins; an equal version goes to the immutable
  candidate). If re-resolution is chosen, this is the reader; nothing else may resolve a tree.
- `scripts/codex-loop.sh` — the compatibility entrypoint, which already refuses a missing wrapper
  with `clock_wrapper_missing` and exit 2. The vocabulary this ticket extends rather than invents.
- `scripts/e2e/loop-drill.sh` — `verify-codex-clock`'s home; the breaker row must be written
  against the behaviour, not a return shape.
- `docs/loop-drill-runbook.md` §9 — the drill register; a new drill without a `bearing: "breaker"`
  row is `unproved`.

## Implementation Steps

1. **Reproduce it.** Stand up a throwaway tree with two plugin versions, launch the supervisor
   from the older one, delete that older tree, and record what the next tick does today —
   the exit status, what it printed, and what it wrote to `.codex-loop/supervisor.json`. This is
   the baseline the fix is measured against; do not skip it because the cause looks obvious.
2. **Localize it.** Confirm by instrumentation, not by reading alone, that `PLUGIN_ROOT` is the
   frozen value and that `TICK_PROMPT`/`COMMAND_BODY` point at deleted files. Establish whether
   `codex` itself fails, exits zero, or reports something the supervisor discards — the answer
   decides how much of ticket 2 in this mission overlaps this one.
3. **Apply the `## Resolved Decision`** (re-resolve, record, refuse when impossible).
4. Implement the decided behaviour at the one seam. Whatever is chosen, the tick **states the
   retired path by name**; a tick that silently continues is the defect, not the fix.
5. Give it a breaker-backed drill under `verify-codex-clock` (or a sibling verb) that fails when
   the supervisor runs a tick against a path that no longer exists, and register it in
   `docs/loop-drill-runbook.md` §9.
6. Run `sh scripts/e2e/loop-drill.sh verify-all` and `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A supervisor whose launch tree is removed mid-run does not execute a further tick against it.
- The retired path is named in what the tick emits; the condition is never silent.
- A supervisor whose tree is intact behaves byte-identically to today.

**Verification method** — the commands/tests/probes that prove them:

- The step-1 reproduction, re-run after the change, showing the new behaviour against the
  recorded baseline.
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The new drill fails with the repair reverted (the breaker row proves it).
- No change to `plugin-src.sh`'s two resolution axes.

## Considerations

- The compatibility entrypoint already has the vocabulary for this (`clock_wrapper_missing`,
  exit 2); prefer extending it over minting a new word.
- Re-resolving mid-run means a supervisor can silently change which code it runs. That is the
  reason to record both paths and state that the supervisor shell code remains loaded.
- Whatever is chosen must not make an ordinary tick pay a resolution cost every five minutes;
  `plugin-src.sh` was measured at a non-trivial cost elsewhere in this repository.

## Resolved Decision

The original verification handoff declared: "the operator's ruling on the Open Decision —
whether a tick that finds its launch tree retired refuses, or re-resolves to the installed tree.
#1052 asks for both and they exclude each other." That was an interpretation of the ask, not
an additional operator requirement. It is retained here as decision history; the frontmatter
handoff is cleared because #1052 itself resolves the choice, as follows.

Re-resolve without an unattended confirmation, as the operator explicitly requested in #1052.
Recovery and honest health reporting are compatible: report both paths, retain the transition
in the supervisor record, and refuse further execution if the sanctioned resolver cannot supply
a complete tree. The missing-wrapper startup behavior remains unchanged.

## Implementation Evidence

- Baseline reproduced with two throwaway installations and a real supervisor: after deleting
  the launch version, the next zero-exit fixture worker received that deleted skill and launcher
  path; `supervisor.json` still read `running`. The fixture controls worker output, so this
  establishes the supervisor's behavior rather than claiming to observe a real model.
- The repair retains the sanctioned resolver bytes before retirement, executes them only on
  missing tick resources, and updates the skill, command, launcher, schema, and relay paths.
  The existing supervisor shell code stays loaded; replacement workflow files govern the next
  tick and detached worker launches. No resolver policy or system configuration changes.
- `scripts/e2e/fixtures/codex-retired-path.mjs` proves recovery, refusal with exit 2 when both
  installations disappear, and recurrence of stale-path execution when the check is disabled.
- Verification: `node scripts/test-workflow-scripts.mjs` completed with **6,883 passed,
  0 failed**. `verify-codex-clock` passed **19 load-bearing rows and 5 breakers**; the direct
  fixture also passed recovery, equal-version workspace `call_src`, missing replacement, and
  breaker cases after waiting through the second tick's completion. Package generation and
  `node scripts/build-plugins/verify.mjs` passed with no generated drift.
- `verify-all` ran all 50 registered drills: 41 proved, 6 unproved (no breaker), 2 server-only
  skipped, and one failed `standup_writes_nothing` row because the README was added to the
  working diff during that read (7 to 8 status entries). With the tree held stable, the scoped
  `verify-standup --json` rerun passed all 3 load-bearing rows. No failing drill remains; the
  original aggregate is not represented as an all-green run.

## Final Report

Completed in the operator-authorized Codex session on 2026-09-07. The original ask resolves
the recovery decision: recover through the sanctioned resolver and name both paths; stop if
no complete replacement exists. The reproduction, breaker and verification results above are
the evidence. The earlier declaration is preserved under Resolved Decision rather than
substituted for an unresolved gate.

### Discovered Insights

- The resolver itself disappears with its installation, so the running supervisor must retain
  its bytes and original script identity before retirement. Its existing selection logic,
  including the workspace call path, remains the only resolver.
- Recovery at a boundary does not prevent a plugin directory from disappearing during a tick;
  that remaining race is stated in the work skill and drill runbook.
