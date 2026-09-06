---
created_at: 2026-09-06T10:58:53+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
mission: finish-the-backlog-without-handing-it-back-to-the-operator
merge_policy:
---

# Read the probe before holding a mission open for a person

## Overview

`archive.sh`'s close gate refuses to close a mission at full acceptance when
`acceptance-handoffs.sh` answers `handoff: true` for any acceptance item's ticket. That reader
delegates to `verification-handoff.sh`, which answers `true` on the **presence** of a
`verification_handoff:` line — including the `probe:` form, which exists precisely to be
re-tested and which `/drive` §6 runs.

**Measured, on this mission, by the run that archived its last ticket** (2026-09-06): the queue
drained at 3/3 acceptance and the gate printed *"a person must verify it and close the mission"*,
naming `20260906082031-drain-a-seeded-backlog-in-one-work-run-end-to-end.md` — whose declaration
is `probe: command -v codex`, which `run-verification-probe.sh` had answered `clean` in that
same run, against `/home/tamurayoshiya/.local/bin/codex`. The verification was performed; the
mission is held open for a person to repeat it.

This is the **same presence-vs-probe conflation** that mission fixed one layer down in
`claims_declared_handoff` (a probe declaration no longer parks a claim `awaiting_verification`).
The close gate was not part of that change and still reads presence.

## Policies

- `workaholic:operation` — a degraded or absent reading is named, never rendered as a healthy one
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/archive.sh` — the close gate (the `HOFF_ANY` branch)
- `plugins/workaholic/skills/mission/scripts/acceptance-handoffs.sh` — the gate's one reader
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_declared_handoff`, the
  precedent: a **measurable** declaration answers `false`, prose is unchanged
- `plugins/workaholic/skills/drive/scripts/run-verification-probe.sh` — the probe runner

## Implementation Steps

1. Reproduce: archive a mission's last ticket where an acceptance item's ticket declares
   `probe: <a command that succeeds here>`, and record the refusal verbatim.
2. Decide where the reading belongs. `acceptance-handoffs.sh` is a **consumer** of
   `verification-handoff.sh` and that reader must keep answering on presence — it is the one
   reader and `/drive` §6 depends on its current answer. The precedent says the **consumer**
   distinguishes measurable from prose, exactly as `claims_declared_handoff` does.
3. Make a **measurable** declaration not hold the close, leaving **prose** holding it exactly as
   today. State the cost where the code is: a probe that would read `blocking` no longer blocks
   this gate, and the mission closes on arithmetic the run already proved.
4. Decide, and state, whether the gate may run the probe itself. `archive.sh` runs inside a
   worktree at commit time, unlike the offline claim scan — so the hazard argument that kept the
   probe out of `claims_declared_handoff` may not transfer. Record whichever way it goes.
5. Add the case to `node scripts/test-workflow-scripts.mjs` beside the existing close-gate rows.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A mission at full acceptance and an empty queue whose only handoff declaration is a `probe:`
  form closes `achieved`; the same mission with a **prose** declaration still refuses, with the
  refusal text unchanged.
- The refusal names which form held it, so a reader can tell the two apart.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- step 1's reproduction, re-run, now closing

**Gate** — what must pass before approval:

- the suite and the classified drill set both pass, and step 1's reproduction is shown before and after

## Considerations

- `close.sh` stays the only writer of an end state, and `archive.sh` still closes only
  `achieved` on arithmetic. Nothing here lets a run assert `abandoned` or `carried`.
- An **unreadable** reading is not a proof and must leave the mission alone, exactly as the
  surrounding gate already treats a missing number.
- Do not widen `verification-handoff.sh`. Two readers of one field eventually disagree; the
  change belongs in the consumer.
