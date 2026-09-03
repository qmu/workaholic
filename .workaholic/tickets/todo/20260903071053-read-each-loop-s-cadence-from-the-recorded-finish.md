---
created_at: 2026-09-03T07:10:53+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-finished-subagent-and-take-the-loop-s-clock-off-it
merge_policy:
verification_handoff: 
---

# Read each loop's cadence from the recorded finish

## Overview

With the finish recorded, the cadence stops needing a live agent. `/infinite-development` §2
currently derives every cadence from an idle agent's `started N ago`, which is what makes the
idle agent load-bearing and forces reaping to wait for the next spawn. Move the derivation onto
the recorded finish; the listing then answers exactly one question — is this loop still running.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §2's cadence table and the
  `not_due` / reap-at-spawn paragraphs are what this rewrites
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the reader; `--step-prefix
  loop-finish-` answers the whole question
- `plugins/workaholic/skills/loops/SKILL.md` — carries the premise this changes
- `scripts/test-workflow-scripts.mjs` — pins the command bodies

## Implementation Steps

1. For each cadenced loop (`propose`, `moderate`), read the newest `loop-finish-<name>` line
   through `log-read.sh` and compare its age against that loop's cadence.
2. Keep `moderate`'s existing 30-minute gate reading the same log — it already does, so this
   makes the two loops read one rule instead of two.
3. Rewrite §2 so the listing carries **only** the concurrency rule (`running` → do not spawn).
   Delete the sentence making an idle agent the clock and the stated cost that went with it.
4. An **absent** finish line means due — a fresh session, a rolled-over day, an unreadable log.
   Over-spawning beats a loop that stopped; state it where the rule is.
5. `implement` still carries no cadence and reaches none of this.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No cadence anywhere is derived from an agent's `started` age.
- An absent or unreadable finish line reads as due, and the command says so.
- The concurrency rule is unchanged: a `running` loop is never spawned again.

**Verification method** — the commands/tests/probes that prove them:

- Read `commands/infinite-development.md`: no cadence sentence names `started`.
- `bash plugins/workaholic/skills/moderate/scripts/log-read.sh --step-prefix loop-finish-`
  returns the lines the derivation reads.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- The idle-agent-as-clock rule is gone from the command body and from `workaholic:loops`,
  not merely contradicted in one of them.

## Considerations

This ticket must land before the reaping ticket or the tick loses its clock: the two are
ordered for that reason and not by preference.
