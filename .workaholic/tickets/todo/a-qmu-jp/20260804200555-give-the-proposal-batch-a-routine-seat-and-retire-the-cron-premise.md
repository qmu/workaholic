---
created_at: 2026-08-04T20:05:55+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on: 20260804200555-move-the-proposal-cursor-to-a-shared-pushed-ref.md
mission: make-the-feedback-loop-actually-propose
merge_policy:
---

# Give the proposal batch a routine seat and retire the cron premise

## Overview

`/propose` has no runner. `docs/proposal-loop-runbook.md` prescribes a 15-minute
server cron that was never installed (and whose installation is deliberately a
human act), while the live deployment moved to Claude Code Web routines — whose
template set (`skills/workaholify/routines/`: `fb`, `merged-pr`, `drive`) has no
propose entry. The only place `/propose` currently executes is inside the [FB]
routine's own session, where the record it just wrote is still on an unmerged PR
branch and therefore invisible to the window by design. Give the batch its own
scheduled seat and stop the [FB] template from claiming a step it cannot perform.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / delivery-path policies — a standing outward-facing process is created only through the verbatim-confirmation seam (/setup-routines)

## Key Files

- `plugins/workaholic/skills/workaholify/routines/` — add `propose.md` (follow `drive.md`'s scheduled-trigger shape; `fb.md`/`merged-pr.md` are the event-trigger shape)
- `plugins/workaholic/skills/workaholify/routines/fb.md` — remove the in-session `/propose` step
- `docs/proposal-loop-runbook.md` — rewrite from cron to the Web-routine deployment
- `plugins/workaholic/skills/workaholify/SKILL.md`, `CLAUDE.md`, `plugins/workaholic/commands/workaholify.md`, `plugins/workaholic/commands/setup-routines.md` — every enumeration of the template set (`fb`, `merged-pr`, `drive`) gains `propose`
- `plugins/workaholic/skills/workaholify/scripts/compare-routines.sh` — confirm it discovers templates by scanning the directory; if the set is hard-coded, extend it

## Implementation Steps

1. Author `routines/propose.md`: scheduled trigger at the 15-minute cadence the
   loop doctrine already prescribes; prompt = run `/propose` once headlessly,
   never prompt, report the one-line outcome; require the workaholic plugin
   (same bootstrap precondition the drive template states); Slack notification
   only when a proposal PR was actually opened, in the fb/merged-pr message
   format.
2. Edit `fb.md`: "/fb and /propose via pull request" → the fb step only; add
   one line saying proposals ride the scheduled propose routine once the FB's
   PR merges (so the next editor knows the step moved, not vanished).
3. Rewrite the runbook: provisioning = `/workaholify` or `/setup-routines`
   surveying and creating the routine (verbatim confirmation, one at a time);
   keep the Slack-bot/notifier env section; keep the private-repo precondition
   (decision I9); mark the cron shape as the retired predecessor.
4. Update every template-set enumeration named in Key Files.
5. Run `compare-routines.sh` afterwards and confirm the new template reports as
   `missing` for this repo (that is the correct post-merge state — creating the
   live routine is the developer's verbatim-confirmed act, not this ticket's).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `routines/propose.md` exists, scheduled-shaped, and `compare-routines.sh` reports it (as `missing` until a human creates the live routine)
- `fb.md` no longer instructs an in-session `/propose`
- No document still presents the cron as the live deployment path

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/workaholify/scripts/compare-routines.sh` output lists the propose template
- `grep -r "propose" docs/proposal-loop-runbook.md plugins/workaholic/skills/workaholify/routines/` reads consistently

**Gate** — what must pass before approval:

- `verify.mjs` / `validate-metadata.mjs` clean; docs updated in the same change; no live routine created by the branch itself

## Considerations

- Creating the live routine remains a human act behind /setup-routines'
  digest-confirmed seam — this ticket ships the template and the truth, nothing
  standing.
- Cadence: 15 minutes matches the written doctrine; if account-level routine
  quotas make that heavy, the template documents the knob rather than a second
  opinion.
- The drive routine's known bootstrap caveats (stale baked-in plugin) apply
  identically; the template should reference the same session-start bootstrap
  requirement rather than restating it.
