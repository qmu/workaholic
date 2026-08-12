---
created_at: 2026-08-12T21:05:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-routine-finish-line-from-vanishing-on-the-script-path
merge_policy:
---

# Reconcile the runbook's version-binding stop rows

## Overview

Minted mid-run on 2026-08-12 by the `[Implement]` tick driving mission
`stop-a-routine-finish-line-from-vanishing-on-the-script-path` — an observed
documentation contradiction, outside that mission's scope.

`workaholic:drive` §1 and `drive/reference/survey.md` were changed on 2026-08-12 to make
`loaded_version_behind_registry: true` a **warning**, not a stop: `plugin-src.sh` resolves the
newest plugin tree on the machine and the run drives from it, so a superseded harness binding is
a reported source-selection fact. Two documents still state the old rule as current:

- `docs/drive-loop-runbook.md` rows 232-233 — "**a stop, and the only one in §1** — the run
  terminates `pending` *before* surveying", and the companion row instructing a run whose
  `check.sh` reports neither field to "treat it as the condition itself and terminate `pending`".
- `plugins/workaholic/skills/drive/reference/survey.md:57` — a back-reference to "the
  `loaded_version_behind_registry` stop above", where the text above it now says WARNING.

This is not cosmetic: the tick that minted this ticket read a bound-but-superseded plugin
(1.0.133 against a 1.0.166 registry) whose own command markdown carried the retired hard stop,
and had to consult the checkout's newer skill to know whether to survey at all. An operator
reading the runbook today gets the retired answer, and the measured cost of that answer is on the
record — twelve consecutive `[Implement]` ticks that stopped before surveying with a claimable
queue.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `docs/drive-loop-runbook.md` — the two rows of the `check.sh` troubleshooting table
- `plugins/workaholic/skills/drive/reference/survey.md` — line 10 (the current rule) and line 57
  (the stale back-reference to it)
- `plugins/workaholic/skills/drive/SKILL.md` §1 and §7 — the current rule and the token row that
  already treats a superseded binding as not-by-itself-`pending`; the reconciliation target
- `plugins/workaholic/skills/notify/SKILL.md` — the precondition-stop class, already reduced to
  `no_plugin_source`; a useful cross-check that no fourth document still lists the retired members

## Implementation Steps

1. Grep `loaded_version_behind_registry` and `registry_unreadable` across `plugins/` and `docs/`
   and list, per hit, whether it states the rule as a stop or a warning. Two are known; confirm
   there is no third.
2. Rewrite the runbook's two rows to the current rule: the field is a warning, `plugin-src.sh`
   selects the newest tree, the run reports `source`/`degraded`/`bound_version` and drives on.
   Keep the measured history (the 2026-08-04 double-pick, the cloud container's baked binding) —
   it is why the field exists and why the resolution replaced the stop; only the instruction changes.
3. Fix `survey.md`'s back-reference so it names the condition, not a stop that no longer exists.
4. Re-read `notify:SKILL.md`'s precondition-stop list against the result: it must stay
   `no_plugin_source` alone, since posting a `⚪ Paused` for a condition that no longer terminates
   a run would put a notification where there is no event.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No document under `plugins/` or `docs/` instructs a run to terminate on
  `loaded_version_behind_registry`, `registry_unreadable`, or their absence.
- The runbook still carries the measured history that produced the field.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "loaded_version_behind_registry\|registry_unreadable" plugins/ docs/` — every hit
  reads as a warning or as history.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The two rules (skill and runbook) agree on one instruction, stated once and referenced
  elsewhere rather than restated.

## Considerations

- A drift assertion over this pair is tempting but was not specified here: the rule is prose in
  two registers (a skill's contract and an operator's troubleshooting table), and a word-level
  tripwire over "stop" would fire on the legitimate history. Decide during implementation whether
  anything mechanical is worth pinning.
