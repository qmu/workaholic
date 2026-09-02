---
created_at: 2026-08-18T20:30:11+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260818202939-the-claude-app-notifies-on-routine-results-though-routine-reporting-is-slack-only.md]
merge_policy:
verification_handoff: Confirming the app notifications stopped requires the developer's own Claude app account and device; an unattended run cannot observe push or email delivery.
claim: work-20260902-220412
---

# Turn off routine completion notifications

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

Issue #514: the Claude app sends its own push/email notifications when routine
results land, although every routine's reporting is deliberately designed to arrive
in Slack and nowhere else — the timing and content are woven into each routine's
own instruction. The developer asks for the cause to be found and prevented.

**Part of this is outside this repository and part of it is a real gap here, and
the two must not be conflated.** The ask's own investigation found the notifications
came from one-shot, `send_later`-style check-ins bound to a persistent session,
which the server will not even accept a `notifications` parameter for — so no
routine-level control existed to be misconfigured, and the likely origin is a
client/app-level setting or a notification path with no exposed opt-out. Nothing in
this repository can change that.

What **is** in scope was verified against the tree before this proposal was written:
**no routine template declares a `notifications` field, and no setup script converges
one.** `render-routine.sh`, `render-setup-sheet.sh` and `list-routine-templates.sh`
read `cron_expression`, `model`, `autofix_on_pr_create`, `allowed_tools` and `mcp` —
`notifications` appears nowhere in the routine tooling. The five workaholic routines
are scheduled, fresh-session-per-fire routines, which is exactly the class the field
*is* accepted for. So the loop currently creates recurring routines and leaves their
completion-notification setting to whatever the server defaults to, while every one
of those routines reports through Slack by design.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/delivery.md` — how routines are configured and converged
- `workaholic:design` / `policies/user-experience.md` — a notification the design does not want

## Key Files

- `plugins/workaholic/skills/workaholify/routines/*.md` — the five templates
  (`fb`, `implement`, `prepare-release`, `standup`, `housekeep`); none declares
  `notifications:`.
- `plugins/workaholic/skills/workaholify/scripts/render-routine.sh` — reads the
  frontmatter fields a routine is created with; the field must be added here to be
  carried.
- `plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh` — the
  one list both setup commands read.
- `plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh` — the
  copy-paste fallback sheets; a field the command converges must also appear here or
  a hand-configured routine silently differs.
- `plugins/workaholic/skills/setup-dev-routines/` and `setup-repo-routines/` — the
  convergence diff (name/prompt/model/cron/autofix/connectors) that must gain the
  field.
- `scripts/test-workflow-scripts.mjs` — where the template/reference pinning lives.

## Implementation Steps

1. **Diagnose before changing anything — the reporter's own hypothesis is a
   hypothesis, not the design.** Determine which routine class actually produced the
   notifications the developer received: the persistent-session check-ins the
   investigation found, the five scheduled workaholic routines, or both. Record the
   finding. If the workaholic routines are not implicated, say so plainly rather
   than letting the change below read as the fix for the reported symptom.
2. Confirm against the live routine-management surface which fields a
   fresh-session-per-fire routine accepts, and what the server's default for
   completion notifications is when the field is omitted. A default of "on" and a
   default of "off" lead to different work, and the current code omits the field
   either way.
3. Add `notifications:` to the five routine templates' frontmatter, set for
   Slack-only reporting, with a one-line comment in each template's prose saying why
   — the routines post their own results to Slack, so a second channel is duplication.
4. Carry the field through `render-routine.sh`, `list-routine-templates.sh` and
   `render-setup-sheet.sh`, and add it to both setup commands' convergence diff so an
   existing routine is corrected, not only a new one.
5. Handle the rejection case honestly: if a routine type refuses the parameter, the
   setup command reports that by name rather than failing or silently dropping it —
   the same degradation discipline the rest of the routine tooling already uses.
6. Record what remains outside this repository (Open Decision 1) in the docs, so a
   later reader is not left believing the in-repo change resolved the whole report.
7. Update `CLAUDE.md`, the `workaholify` skill docs and both setup command docs in
   the same change.

## Open Decisions

<!-- Forks this proposal cannot recommend one side of. The driving session
     resolves each explicitly and records the resolution in its Final Report. -->

1. **What to do about the half that is not this repository's.** The reported
   notifications came from persistent-session-bound check-ins with no exposed
   opt-out — an Anthropic product surface, not a workaholic one. Repository
   confinement means no change here can reach it, and the only sanctioned crossing
   (`/fb <ask> to <owner/name>`) requires a human's verbatim confirmation, which an
   unattended run cannot give. Decide whether the outcome is (a) the in-repo field
   plus a written note of what is out of scope, or (b) that plus raising the
   platform half with the developer so they can run the crossing themselves. Do not
   perform a crossing without the developer.

## Quality Gate

<!-- Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Every routine template declares `notifications:`, and the value is carried into a
  created routine by `render-routine.sh`.
- Both setup commands converge the field on an existing routine, not only a new one.
- The setup sheets show the field, so a hand-configured routine matches a converged one.
- A routine type that refuses the parameter is reported by name, never silently dropped.
- The diagnosis from step 1 is recorded, including whether the workaholic routines
  were implicated at all.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- Render each template and assert the field is present in the output JSON.
- Run both setup commands against the account and read the reported per-routine diff.

**Gate** — what must pass before approval:

- The tests pass, the field appears in every rendered routine and both setup sheets,
  and step 1's diagnosis is written down.

## Considerations

- **This ticket declares `verification_handoff` and that is deliberate.** The report's
  symptom is a notification arriving on the developer's own Claude app; no unattended
  run can observe push or email delivery, so the unit is handed to a person rather
  than merged with a claim that it was verified. Setting the field is provable here;
  *the notifications stopping* is not.
- Adjacent prior work, so it is not mistaken for a duplicate: feedback record
  `20260804085719-make-the-web-routine-notify-slack-only-and-filter-what-it-posts.md`
  made the routine's **own posts** Slack-only. This ask is about the **app's**
  notifications about the routine — a different layer, already-landed work on the
  other one.
- The honest risk: steps 3–5 may close a real gap and still leave the developer
  receiving the notifications they reported, because the cause is elsewhere. That is
  why step 1 is a diagnosis and why the Final Report must state which one it fixed.
