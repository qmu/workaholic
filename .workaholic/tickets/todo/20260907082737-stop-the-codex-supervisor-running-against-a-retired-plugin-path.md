---
created_at: 2026-09-07T08:27:37+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: recover-the-codex-loop-from-a-retired-plugin-path-and-refuse-a-false-healthy-status
merge_policy:
verification_handoff: the operator's ruling on the Open Decision — whether a tick that finds its launch tree retired refuses, or re-resolves to the installed tree. #1052 asks for both and they exclude each other.
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

This ticket makes the tick notice. It does not decide between refusing and re-resolving — see
`## Open Decisions`.

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
3. **Settle the `## Open Decisions` fork** (refuse vs. re-resolve) before writing the repair.
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
  substance of the Open Decision below, not a detail to settle in passing.
- Whatever is chosen must not make an ordinary tick pay a resolution cost every five minutes;
  `plugin-src.sh` was measured at a non-trivial cost elsewhere in this repository.

## Open Decisions

**Should a tick that finds its launch tree retired refuse, or re-resolve to the installed tree?**

Sources consulted. `CLAUDE.md`, *Plugin boundary*: `plugin-src.sh` "resolves the newest plugin
tree on the machine so an unattended run whose binding is missing or superseded still executes
the workflow — the harness binding is an input, never a precondition." That argues for
re-resolving. Against it, `CLAUDE.md`'s *Loops* section records the operator's instruction that
the supervisor must not appear healthy merely because a process exists, and #1052 asks that the
loop "recover from retired cache paths **without an unattended confirmation**" — which reads as
re-resolve, while also asking that nothing "appear healthy" — which reads as refuse loudly. The
two halves of the ask do not settle each other. `scripts/codex-loop.sh` shows the repository's
existing answer for the sibling case (a missing wrapper): refuse with exit 2 and tell the
operator to reinstall.

The fork. **Refuse** keeps one supervisor bound to one tree for its whole life, which is the
property that makes `--status` meaningful, and costs a manual restart on every plugin update.
**Re-resolve** keeps the loop turning across updates, which is what the ask literally requests,
and means the code a supervisor runs can change under it mid-life with no pull request and no
record of the switch.

Whose ruling would settle it: the operator's — it is their loop and their instruction, and the
two halves of #1052 pull opposite ways.
