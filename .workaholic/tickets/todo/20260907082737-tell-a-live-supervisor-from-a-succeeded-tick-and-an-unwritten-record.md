---
created_at: 2026-09-07T08:27:37+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: recover-the-codex-loop-from-a-retired-plugin-path-and-refuse-a-false-healthy-status
merge_policy:
verification_handoff: 
---

# Tell a live supervisor from a succeeded tick and an unwritten record

## Overview

PROPOSED. `supervisor_reading` answers from its own record file alone: `[ -f "$SUPERVISOR_FILE" ]
|| { printf 'never_started'; ... }` (`codex-loop.sh:207`), and its header states the bound —
"derived from the file alone — no lock, no live probe of anything but the pid". `CLAUDE.md`
documents the same reading: for `.codex-loop/supervisor.json`, **absent means never started**.

Measured 2026-09-06 (#1052), that is false in the case that matters. An older supervisor was
holding the role lock and turning, while the newer status reader — finding no record it
recognised — answered `never_started`. In the same incident a start request was answered
`already_running` from the pid and the lock alone, so the operator could neither see the live
supervisor through `--status` nor start a working one.

Three states have to be told apart and today two readers collapse them: a supervisor that is
**alive**, a tick that **recently succeeded**, and a record that was **never written**.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — `supervisor_reading` (`:206-225`),
  `liveness_reading` (around `:200`, the pid/boot-id probe), `role_state` and `worker_reading`
  (`:228-260`), `dispatch_claim_role` (`:137`, the `already_running` answer), and the two status
  surfaces `show_status` (`:263-300`) and `show_status_json` (`:378-414`).
- `CLAUDE.md`, *Loops* — the sentence "`.codex-loop/worker-<role>.json` … **absent means never
  started**" and the surrounding measured record. Documentation is part of this change: the
  reading it states is the one being corrected.
- `plugins/workaholic/skills/work/reference/other-agents.md` — the durable record of the external
  clock's contract and the per-role lock as the only concurrency authority.
- `scripts/e2e/loop-drill.sh`, `docs/loop-drill-runbook.md` §9 — `verify-codex-clock` and register.

## Implementation Steps

1. **Reproduce both halves.** With a role lock held by a live process and no supervisor record
   present, record what `--status`, `--status --json` and a start request each answer today.
   Then, with a record present but its process dead, record the same three. Baseline first.
2. **Localize it.** Establish exactly which evidence each reader consults — record file, pid,
   boot id, lock — and which of the three states each can and cannot distinguish. The claim that
   the lock is unread is from the function's own header; confirm it against behaviour.
3. Decide what evidence a liveness answer may consult. The lock is already the **only**
   concurrency authority (`other-agents.md`); this ticket must not create a second one. Reading
   the lock as *evidence* for a status answer is the narrow move — it decides nothing about who
   may run.
4. Make `--status` distinguish the three states, each by its own word, with an unreadable part
   named by its own reason rather than omitted or rendered healthy — the surface's existing rule.
5. Make the start decision rest on more than a pid and a lock, so a held lock behind a supervisor
   that is not turning does not answer `already_running` forever. Preserve the 2026-09-06 repair
   at `dispatch_claim_role`: the **parent** claims the lock before it forks, and a lost race is
   `already_running` on exit 0. That property is load-bearing and must not regress.
6. Update `CLAUDE.md`'s *Loops* wording and `other-agents.md` in the same change — the current
   text states the reading being corrected.
7. Breaker-backed drills for both halves; register in §9. Then
   `sh scripts/e2e/loop-drill.sh verify-all` and `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A live process holding a role lock is never reported `never_started`.
- `--status` and `--status --json` distinguish a live supervisor, a recently succeeded tick and
  an unwritten record, each by its own word.
- A start request does not answer `already_running` on the strength of a pid and a lock alone.
- `--status` still starts nothing, writes nothing, takes no lock and needs no `codex` CLI.
- The concurrent-dispatch property holds: the parent claims before it forks; a lost race is
  `already_running` on exit 0.

**Verification method** — the commands/tests/probes that prove them:

- The step-1 reproductions re-run against their recorded baselines.
- `sh scripts/e2e/loop-drill.sh verify-all` (the concurrent pair, which is the shape that exposes
  the dispatch window)
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- Each new drill fails with its repair reverted.
- `CLAUDE.md` and `other-agents.md` updated in the same commit as the behaviour.

## Considerations

- The lock must stay the only concurrency authority. Reading it as evidence for a *status* answer
  is not the same as making it a second allocator, but the distinction has to be held explicitly
  or this ticket reintroduces the thing `other-agents.md` forbids.
- A pid can be reused after a reboot; `liveness_reading` already carries a boot id for exactly
  that reason. Any widened liveness reading inherits that problem and must not drop the boot-id
  term.
- "Recently succeeded" needs a stated bound. Prefer composing the tick log's own recorded finish
  (`log-read.sh --step-prefix loop-finish-<name> --latest-tick`), which the loop already reads for
  its cadences, over introducing a second clock or a new stored cursor.
- Widening what `--status` reads must not make it write, lock, or require the CLI — those four
  bounds are the surface's stated contract and were themselves a measured repair.
