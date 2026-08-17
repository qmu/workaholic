---
created_at: 2026-08-17T13:32:24+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817133224-route-a-destination-less-fb-to-an-in-repo-issue.md
mission: register-every-fb-as-an-issue
merge_policy:
verification_handoff: 
---

# Keep the record as /fb's fallback when the issue fails

## Overview

Once `/fb`'s primary path is a GitHub issue, the command depends on a network call that
can fail in ways the previous file write never could: `gh` absent, the session's REST
surface refusing the call (measured on this loop — a Claude Code Web session served 403
mid-run 80 minutes after the same path worked), issues disabled, rate limiting. The ask is
about where feedback *lands*, not about being willing to drop it, so this ticket gives the
in-repo path one explicit degradation: when the issue cannot be opened, write the
immutable record through `create.sh` as before and report plainly that the fallback was
taken and why.

The fallback is the in-repo path only. A refusal from a **different** repository stays
reported verbatim and never worked around — that is the target's own decision about its
boundary, and writing a local record about it would be a different act.

## Policies

- `workaholic:operation` / `policies/observability.md` — a degraded path names itself
- `workaholic:operation` / `policies/failure-handling.md` — degrade, never lose the input
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/feedback/SKILL.md` — the capture workflow gains its one
  documented degradation.
- `plugins/workaholic/skills/feedback/scripts/open-issue.sh` — already emits
  `{ok: false, error}` with exit 0 for every failure; that envelope is what the fallback
  reads, so nothing new is needed from it.
- `plugins/workaholic/skills/feedback/scripts/create.sh` — the fallback writer, unchanged.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — `available` is the cheap
  pre-check that distinguishes "no transport" from "call refused".
- `plugins/workaholic/commands/fb.md` — one sentence naming the fallback and its report.
- `docs/proposal-loop-runbook.md` — where the loop's failure modes are already written
  down; a record written by the fallback is not discovered by `[Propose]`, and that
  consequence belongs there.

## Implementation Steps

1. Define the trigger narrowly: the fallback fires only on `open-issue.sh`'s
   `{ok: false}` (or `gh-rest.sh available` reporting no transport) for the **in-repo**
   destination. A successfully created issue never also writes a record — the
   `already_captured` suppression in the previous ticket's reasoning applies unchanged.
2. On that failure, write the record through `create.sh` with the `kind`/`source`/`subject`
   already decided, and include the failure reason in the body so a later reader knows the
   issue was attempted, not skipped.
3. Report both facts in the one-line report: the record path, and that it is a fallback
   with `<reason>` — never a report that reads like the ordinary path.
4. Write down the consequence rather than papering over it: a fallback record is **not**
   discovered by `[Propose]` (discovery reads issues, not files), so the ask is captured
   but not proposed until someone files or re-runs. State it in the skill and the runbook;
   do not add a sweep that re-reads local records for something to propose — that is the
   retired `[Propose Batch]` design.
5. Update `commands/fb.md`, then `node scripts/build-plugins/build.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With the issue call failing, a destination-less `/fb` writes exactly one record and
  reports the fallback with the failure reason.
- With the issue call succeeding, no record is written — the fallback cannot fire on the
  happy path.
- The cross-repository path never falls back; its refusals are still reported verbatim.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic case in `scripts/test-workflow-scripts.mjs` driving the fallback decision off
  a stubbed `{ok: false}` envelope — no `gh`, no network.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`.

**Gate** — what must pass before approval:

- The hermetic suite passes and the runbook states the not-discovered consequence.

## Considerations

- The fallback must not become a silent second mode: if it starts firing routinely, the
  report is the only signal, so it is worth keeping the wording blunt.
- Resist promoting a fallback record into an issue later — that is a sweep over local
  state, which the loop deliberately does not do.
