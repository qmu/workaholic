---
created_at: 2026-09-06T08:20:31+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: count-recovery-and-delivery-work-as-claimable
mission: finish-the-backlog-without-handing-it-back-to-the-operator
merge_policy:
verification_handoff: 
---

# Give a dispatched Codex worker the whole role it is named for

## Overview

`codex-loop.sh` builds one generic worker prompt: `ROLE_BODY` is `commands/<role>.md` and
the prompt says *execute it exactly once*. For `propose` that is `/propose` alone — never the
propose-then-specificate sequence the routine's own contract names — so the worker opens or
refuses a proposal and nothing ingests it. The same prompt forbids every worker from reading
the inbound channel, which also disables `/moderate`'s `question-answers` and
`thread-reconcile` steps, both of which read a thread at a coordinate they already hold. The
coordinator must stay the single inbound owner while the needed context and responsibilities
are routed explicitly.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the loop is a running system; a degraded read is named, never rendered as a healthy one

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — `ROLE_BODY` resolution (~line
  150) and `run_worker`'s `_wprompt` (~line 345), the one generic string.
- `plugins/workaholic/commands/propose.md` — the propose half only; the routine's contract is
  propose **then** specificate.
- `plugins/workaholic/commands/specificate.md` — the half a dispatched worker never reaches.
- `plugins/workaholic/commands/moderate.md` — the steps the channel ban disables.
- `plugins/workaholic/skills/work/reference/other-agents.md` — where the substitutions are
  stated; this is where the boundary belongs.

## Implementation Steps

1. **Reproduce and localize.** Run `codex-loop.sh --dispatch propose --dry-run` and record
   the composed prompt verbatim. Confirm it names `commands/propose.md` and nothing else, and
   that the sentence *do not read or answer the inbound channel* is emitted for every role.
2. Confirm from `commands/moderate.md` which steps require a thread read at a recorded
   coordinate, and that they are not channel turns.
3. Make the worker prompt **per role** rather than one string: `propose` carries the
   propose-then-specificate sequence and whatever reading the tick hands in; `moderate`
   carries its own steps' permission to read a thread it holds a coordinate for.
4. State the boundary in **one** place (`reference/other-agents.md`): the coordinator owns the
   channel *turn* — reading the window, answering, filing an ask — and a step reading a known
   thread is not that. Do not restate it in each prompt.
5. Keep the single inbound owner: no worker reads the channel window, files an ask, or posts a
   receipt.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A dispatched `propose` worker runs both halves and a proposal it opens is ingested in the
  same run.
- A dispatched `moderate` worker performs `question-answers` and `thread-reconcile`.
- No worker reads the inbound channel window or files an inbound ask; the coordinator's turn
  is unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- the reproduction named in step 1, re-run, now answering differently

**Gate** — what must pass before approval:

- the suite and the classified drill set both pass, and step 1's reproduction is shown before and after

## Considerations

- **The ask's reading**, recorded as a hypothesis: it says the propose prompt does not carry
  the coordinator's channel reading and stops after proposal selection. Step 1 establishes it.
- The `only_the_loop_spoke` brake is **handed in** to the propose run rather than taken by it;
  routing context must not turn that back into a read the worker makes.
- A per-role prompt is more surface to drift. Deriving each from the command body it names
  keeps one source, as the routine templates already do.
