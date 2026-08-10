---
created_at: 2026-08-10T09:00:05+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [.workaholic/feedbacks/20260810085823-version-binding-gate-in-implement-s-survey-step-stops-the-whole-session-instead-of-warning-and-continuing.md, .workaholic/feedbacks/20260810070110-implement-routine-over-blocks-on-unbound-in-claude-session.md]
merge_policy:
claim: work-20260810-124512
---

# Warn and continue instead of hard-stopping /implement's survey on a version-binding gate

## Overview

**PROPOSED.** `check-deps/scripts/check.sh` reports three version-binding
conditions — `loaded_version_behind_registry`, `registry_unreadable`, and
`unbound_in_claude_session` — and `drive/SKILL.md` §1 currently terminates the
whole `/drive`/`/implement` run `pending` on any of them, before the survey
ever runs (`skills/drive/reference/survey.md`). FB
`20260810070110-implement-routine-over-blocks-on-unbound-in-claude-session.md`
already recorded a live developer correction for the narrowest case
(`unbound_in_claude_session`): the plugin's own scripts stay runnable via Bash
from the checkout, and the safety hooks stay active, independent of whether
the Skill/Command tool binding itself resolved — so refusing to survey at all
is disproportionate to what is actually broken. This ticket generalizes that
correction to all three conditions: replace the unconditional hard stop with a
warned continuation, while preserving whatever narrower stop is still needed
to prevent the double-pick failure `loaded_version_behind_registry` exists to
catch (a superseded binding can silently change the survey's own answer — see
Considerations). The two feedback records this ticket answers are linked in
`feedback:` above.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/check-deps/scripts/check.sh` — emits the three
  fields (`loaded_version_behind_registry`, `registry_unreadable`,
  `unbound_in_claude_session`); the fields themselves likely stay as-is, only
  their consumers' severity changes.
- `plugins/workaholic/skills/drive/SKILL.md` §1 — the run-report table
  currently reads `pending` for all three (`| The run bound a superseded
  plugin ... | pending |`, `| The run never bound the plugin at all ... |
  pending |`).
- `plugins/workaholic/skills/drive/reference/survey.md` — the survey
  reference's *The install check* section states the STOP rationale for each
  condition in detail; this is the authoritative rule text to rewrite.
- `plugins/workaholic/commands/drive.md` / `commands/implement.md` (or
  wherever the §1 termination is actually invoked) — wherever the JSON from
  `check.sh` is read and the run is currently aborted.
- `CLAUDE.md` — the `/drive` and `/workaholify` table rows describe this gate
  ("terminates `pending` on it before surveying") and need the same update in
  the same commit per this repo's own documentation-drift rule.
- `.workaholic/feedbacks/20260810070110-implement-routine-over-blocks-on-unbound-in-claude-session.md`
  and `.workaholic/feedbacks/20260810085823-...md` — the two records this
  ticket answers; read both for the exact developer framing before changing
  behavior.

## Implementation Steps

1. Re-read `check-deps/scripts/check.sh`'s own header comments for each of
   the three conditions — they carry the specific incident each stop
   condition was added to prevent (a double-pick on a superseded binding for
   `loaded_version_behind_registry`/`registry_unreadable`; a totally invisible
   plugin surface for `unbound_in_claude_session`) — before deciding how far
   to soften each one.
2. Decide, per condition, whether "warn and continue" is safe as-is or needs
   a narrower companion check first (see Considerations — this is the open
   design question the source feedback explicitly leaves to the implementer).
3. Change `drive/SKILL.md` §1 (and `reference/survey.md`) so the chosen
   conditions report a warning in the run report and let the survey proceed,
   rather than terminating before it runs. Keep whichever condition is judged
   to still need a hard stop, and say why in the doc.
4. Update `CLAUDE.md`'s `/drive`/`/implement`/`/workaholify` prose to match
   the new behavior (this repo's own rule: docs update in the same change).
5. If the generated cross-agent bundle depends on any changed script,
   rebuild it: `node scripts/build-plugins/build.mjs`.
6. Run the local verification suite (`node
   scripts/test-workflow-scripts.mjs`, `node scripts/build-plugins/verify.mjs`)
   and, if feasible, a scripted reproduction of each of the three conditions
   against `check.sh`'s JSON output to confirm the run now warns and
   continues (or still stops, where kept) as designed.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `/drive`/`/implement` no longer terminate `pending` before surveying solely
  because of `unbound_in_claude_session`, `registry_unreadable`, or
  `loaded_version_behind_registry`, unless the implementer records a specific
  reasoned exception for one of them.
- The run report visibly warns on whichever condition fired, naming the
  condition and its values, so a developer reading the report can still see
  the drift.
- `CLAUDE.md` and `skills/drive/reference/survey.md` describe the actual
  behavior after the change.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` and `node
  scripts/build-plugins/verify.mjs` pass.
- A manual or scripted run of `check-deps/scripts/check.sh` under each of the
  three conditions, followed by tracing through the updated `/drive`/
  `/implement` logic to confirm it warns-and-continues (or the recorded
  exception's narrower stop) rather than aborting outright.

**Gate** — what must pass before approval:

- No regression on the double-pick failure `loaded_version_behind_registry`
  was created to prevent: if that condition is softened to a warning, the
  ticket must explain what still prevents (or accepts) the risk of a
  superseded binding silently changing the survey's answer.

## Considerations

The two related feedback records disagree in scope but agree in direction:
`unbound_in_claude_session` was already corrected live by the developer as
over-conservative, because the plugin's scripts and safety hooks stay usable
via Bash regardless of Skill/Command binding. `loaded_version_behind_registry`
and `registry_unreadable` are a different risk in kind, not just degree: per
`check-deps/scripts/check.sh`'s own header, a superseded binding can run a
*stale* `claims.sh` that gives the survey a wrong answer (the measured
2026-08-04 incident: five already-driven tickets read as fresh backlog, one
was claimed — a double-pick reaching a pushed ref). A blanket "warn and
continue" for all three, with no other change, would reopen exactly that
failure. This ticket's implementer should treat "which conditions may safely
warn-and-continue, and whether any needs a narrower substitute stop (e.g.
refusing only the claim/write step rather than the whole survey)" as the open
design question — named here rather than pre-decided by the proposal, per
this feedback's own PR (#337) leaving it explicitly to whoever picks this up.

## Final Report

Decided the open design question from Considerations: `unbound_in_claude_session`
is now a warning, not a stop, generalizing the developer's live correction in
FB `20260810070110` — the plugin's scripts stay directly runnable via `bash`
from the checkout and the safety hooks stay active independent of whether the
Skill/Command binding resolved, so `/drive`/`/implement` §1 now names the
condition in the run report and continues, invoking the rest of the run's
scripts on their checkout-relative path instead of `${CLAUDE_PLUGIN_ROOT}`.

`loaded_version_behind_registry` and `registry_unreadable` are kept as the one
remaining hard stop, per the ticket's own Gate requirement: unlike the unbound
case, every other script this run touches (`claims.sh` chief among them) is
reached through the stale bound `${CLAUDE_PLUGIN_ROOT}` when this fires, so the
double-pick risk the field exists to catch (the 2026-08-04 incident) is
unchanged by softening it — nothing short of a fresh session repairs a
superseded binding. This is the reasoned exception the ticket's acceptance
criteria explicitly allows.

Updated `plugins/workaholic/skills/drive/SKILL.md` §1 and its §7
terminal-token table, `plugins/workaholic/skills/drive/reference/survey.md`'s
install-check section, `plugins/workaholic/skills/check-deps/SKILL.md`'s
three-drift-axes section, `plugins/workaholic/skills/workaholify/SKILL.md`,
and `CLAUDE.md`'s `/workaholify` row to match. `check-deps/scripts/check.sh`
itself is unchanged — the three fields it reports stay as-is; only their
consumers' severity changed, per the ticket's own Key Files note. Rebuilt
`outputs/workflows/` (`build.mjs`) since `drive`'s bundled `SKILL.md`/
`reference/survey.md` changed.

### Discovered Insights

- **Insight**: This very session hit `unbound_in_claude_session: true` while
  attempting to run this ticket (`workaholic:drive` was `Unknown skill`), and
  proceeded by invoking the plugin's scripts directly from the checkout path
  — a live re-confirmation, in the act of implementing this ticket, that the
  softened behavior this ticket adds is exactly what the situation calls for.
  **Context**: no test run was needed to validate the warn-and-continue path;
  the implementing session was itself an instance of it.
