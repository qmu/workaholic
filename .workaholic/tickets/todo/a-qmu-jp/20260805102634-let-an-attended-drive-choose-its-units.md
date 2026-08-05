---
created_at: 2026-08-05T10:26:34+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
feedback: [20260805102621-an-attended-drive-asks-which-unit-to-take-only-routines-run-promptless.md]
merge_policy:
---

# Let an attended drive choose its units

## Overview

Per FB `20260805102621` (amending decision G1): an **attended** `/drive` asks
which unit(s) to take when the survey offers more than one claimable or
resumable target — one `AskUserQuestion` listing the partition (multiSelect,
`[project label]` prefix). One target, or an instruction naming one, proceeds
without asking. The **unattended** shape keeps the zero-prompt path exactly,
selected by an **explicit invocation form** the [Drive] routine uses — never
inferred from the environment, because a wrong inference either blocks a cron
on a prompt or silently strips the operator's choice. The partition stays
reported in full either way. Background: the 2026-08-05 morning run where
resumable-first ordering overrode the developer's stated WIP twice.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / UX policies — when a person is present, the choice among peers is theirs; a heuristic decides only where nobody can

## Key Files

- `plugins/workaholic/commands/drive.md` — the "no AskUserQuestion anywhere, in any invocation" contract becomes the unattended form's contract; the attended default gains the selection step; define the unattended invocation form (`/drive auto` — and rule what `/drive night` now means, likely a synonym of the unattended form since that was always its intent)
- `plugins/workaholic/skills/drive/SKILL.md` — the Unified Run's partition step: reported always, chosen by the operator when attended and more than one target
- `plugins/workaholic/skills/workaholify/routines/drive.md` — the routine's prompt invokes the unattended form explicitly
- `CLAUDE.md` (drive row), `README.md`, `docs/drive-loop-runbook.md` — the G1 amendment recorded with its date and the FB ref
- `scripts/test-workflow-scripts.mjs` — any pinned prose assertions on the old contract move with it

## Implementation Steps

1. Decide the invocation vocabulary in `commands/drive.md`: bare `/drive` =
   attended (selection when >1 target); `/drive auto` (and `night` as its
   synonym) = unattended, zero prompts, current behavior verbatim. State that
   the routine template is the canonical unattended caller.
2. Insert the selection into the command's step 2-3 seam: after the partition
   is composed, when attended AND targets > 1, ask once (multiSelect over the
   partition rows, each labeled unit id + kind + one-line content); drive the
   chosen units in the chosen order; report the unchosen as `deferred_by_operator`
   in the reconciliation rather than dropping them silently.
3. Keep every downstream step identical (claim, drive, report, route) — the
   gate touches only which units enter the loop.
4. Update the routine template to invoke the unattended form; update the
   G1 prose in CLAUDE.md/README/runbook with the dated amendment.
5. Tests: the drive scripts are unchanged (the gate is command-level prose),
   so coverage is the doc-pin layer — update any assertion that pins the old
   "no AskUserQuestion anywhere" sentence, and add one pinning the new
   contract's two forms.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Bare /drive with >1 claimable target is specified to ask exactly one selection question; with 1 target or an explicit instruction it asks nothing
- The unattended form is explicit, keeps the zero-prompt contract verbatim, and the [Drive] routine template invokes it
- The reconciliation names operator-deferred units instead of hiding them

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green (doc pins updated)
- Read-through: commands/drive.md, drive SKILL, routine template, CLAUDE.md row tell one consistent story

**Gate** — what must pass before approval:

- `build.mjs`/`verify.mjs` clean (drive skill ships in the bundle); docs updated in the same change

## Considerations

- The guard `hooks/guard-askuserquestion-label.sh` applies to the new prompt;
  the selection body carries the label prefix.
- `/goal /drive ok` loops call bare /drive expecting no prompts — note in the
  command that a caller-side loop should use the unattended form, and say so
  in the runbook.
- Do not infer attendance from TTY or environment: the form is chosen by the
  caller, which is the only signal that cannot be wrong.
