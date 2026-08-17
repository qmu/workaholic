---
created_at: 2026-08-17T11:45:36+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: correct-the-release-note-automation-to-its-intended-design
merge_policy:
verification_handoff: 
---

# Diagnose the release note automation drift

## Overview

The mission's first unit, and it writes no feature code. Issue #472 is a **failure report**
— "the trial implementation deviated substantially from the intended design, showing up as
fragmented notifications into each Slack channel" — so the work starts by reproducing and
localizing that, not by building the design the reporter proposed. The reporter's design is
this mission's other six tickets; whether each is the right repair is what this ticket
establishes.

There is a strong prior on where the divergence lies, and it is a decision rather than a
defect: `workaholic:ship` §7, *Why this is a reader*, records that the identical ask ("run
`/ship` once per hour to update the release notes", ticket
`20260814064854-add-the-hourly-release-note-repo-routine`) was resolved on 2026-08-14 by
refusing all three unit-less writer designs and shipping a reader. That must be confirmed
against the live behaviour before it is treated as the cause.

## Policies

- `workaholic:operation` / `policies/observability.md` — a report of wrong behaviour is measured before it is repaired
- `workaholic:development` / `policies/change-history.md` — the divergence between intent and implementation is in the history; read it
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` §7 — the *Release status* section and the
  three-row refusal table. The primary suspect and the primary constraint.
- `plugins/workaholic/skills/ship/scripts/report-deploy-status.sh`,
  `read-deploy-state.sh`, `draft-deploy-plan.sh` — what the tick actually reads and writes.
- `plugins/workaholic/skills/workaholify/routines/release-status.md` — the live routine
  template: `scope: repository`, `45 * * * *`, `allowed_tools` with no `Write`/`Edit`.
- `plugins/workaholic/skills/notify/SKILL.md`, *The repository tick's status line* — the
  `📦 Release status` shape and its two gates. The candidate referent of "fragmented
  notifications".
- `plugins/workaholic/skills/workaholify/SKILL.md` §5 — still names the repository-scoped
  routine `[Release Notes]`, a surviving trace of the original intent.
- `.workaholic/deployments/` (one record: `marketplace.md`), `.workaholic/release-notes/`,
  and the absent `.workaholic/releases/`.

## Implementation Steps

1. **Reproduce.** Run `/release-status` and `sh scripts/e2e/loop-drill.sh verify-status` and
   capture exactly what the tick reads, writes and posts today. Record the actual output,
   not a description of it.
2. **Localize the "fragmented notifications".** Establish precisely which posts the reporter
   means: the per-repository `📦 Release status` root, some other post, or the pattern of
   one line per channel across several repositories. The repair for each is different, and
   the report does not say which. Read the recent `dev-*` channel posts through exact-string
   search under the notify skill's two-query bound.
3. **Trace the intent.** Read ticket `20260814064854-add-the-hourly-release-note-repo-routine`,
   its Open Decision, and §7's resolution; state in the Final Report which of the three
   refusals still binds under the reporter's *daily, per-target, GitHub-Releases-first*
   design and which the design dissolves.
4. **Measure the self-reference.** For each declared target, determine whether a note
   committed to `main` increments its own `unreleased_count` — it does for any target
   declaring no `paths:`, which is what `marketplace.md` does. Quantify it rather than
   assert it; this is the one refusal the reporter's design does not obviously answer.
5. Write the localization into the mission's Final Report and, where it changes a later
   ticket's plan, say which ticket and how.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The current behaviour is captured verbatim, not paraphrased.
- "Fragmented notifications" resolves to a specific, named set of posts.
- Each of §7's three refusals is marked still-binding or dissolved, with the reason.
- The self-reference measurement exists as a number per target.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-status`
- `bash plugins/workaholic/skills/ship/scripts/report-deploy-status.sh`
- `bash plugins/workaholic/skills/ship/scripts/read-deploy-state.sh`

**Gate** — what must pass before approval:

- The Final Report names the localization and its consequence for tickets 2–7.

## Considerations

- The reporter's proposed design is a **hypothesis about the repair**, not the diagnosis.
  It is well-specified and probably largely right; recording it as a hypothesis is what
  keeps this ticket from being the design ticket in disguise.
- This repository is a poor sample: one deployment target, no server runtime, and
  "production" is `origin/main` plus a GitHub Release. A consuming repository with several
  real targets is where the design's value shows and where its edge cases live.
