---
created_at: 2026-08-12T20:49:46+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260812204800-setup-routines-must-configure-the-routines-itself-not-only-when-a-remotetrigger-tool-happens-to-exist.md]
merge_policy:
claim: work-20260812-211712
---

# Make /setup-routines configure the routines itself, not only when a RemoteTrigger tool is exposed

## Overview

<!-- PROPOSED. Merging the pull request this was published on turns it into queued work. -->

A developer ran `/setup-routines` in another repository and the session announced its
direct registration as an accident of the session's tool surface — "たまたま API 経由で
ルーチンを直接作れるツール(RemoteTrigger)が生えていたので、手順書を印刷する代わりに
その場で登録まで済ませました" (issue #408). The reporter's point is that the command must
be *the thing that configures the routines*, not a renderer that occasionally gets to
configure: the earlier instruction (FB `20260810214929`) asked for the direct-apply
implementation, and what landed branches on tool detection first
(`workaholify/SKILL.md` §5 *Direct-apply when `RemoteTrigger` is exposed*, and the
`/setup-routines` command's own description), so a session without the tool still falls
through to sheet-rendering as its *normal* outcome.

This ticket is a **failure report first**: what actually blocks unconditional
configuration is a transport question nobody has measured, and the answer decides the
shape of the fix. Diagnose before designing.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/observability.md` — a refusal must be reported with its reason, never rendered as a normal result
- `workaholic:development` / `policies/policy-as-plugin.md` — the command and skill text are the distributed contract

## Key Files

- `plugins/workaholic/commands/setup-routines.md` — the entry-point contract that today
  leads with "Detects a `RemoteTrigger`-family tool first" and names the sheet path as an
  equal branch.
- `plugins/workaholic/skills/workaholify/SKILL.md` §5 — *Direct-apply when `RemoteTrigger`
  is exposed* (steps 1–4), *The scripts* ("manages nothing when no `RemoteTrigger`-family
  tool is exposed"), *What may be applied unattended*, *What the command does with all this*.
- `plugins/workaholic/skills/workaholify/reference/routines.md` — the session-class scoping
  and the 2026-08-10 live-drift addendum this rests on.
- `plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh`,
  `list-routine-templates.sh`, `render-routine.sh` — the target-state source shared by both paths.
- `CLAUDE.md` — the `/setup-routines` row, which states the two-branch behavior verbatim.
- `outputs/` — regenerate (`node scripts/build-plugins/build.mjs`) after any skill edit.

## Implementation Steps

1. **Reproduce.** Run `/setup-routines` in a session and capture what it reports, in both
   session classes if both are reachable: one where a `RemoteTrigger`-family tool is
   exposed and one where it is not. Record the exact wording each path produces — the
   report's framing ("happened to be available") is half of what was reported as broken.
2. **Localize the constraint.** Establish, with evidence, whether a session *without* the
   `RemoteTrigger` tool has any other transport that can create or update an account
   routine: another exposed tool family, an authenticated HTTP endpoint reachable from the
   session, or none at all. Record the finding in the ticket's Final Report — this is the
   fact the whole design turns on, and it has never been measured, only assumed.
3. **If a transport exists**, make the command use it so configuration succeeds regardless
   of which tool surface the session carries; the sheet then stops being a behavior branch
   entirely.
4. **If no transport exists**, restructure the contract so the command is still *always
   trying to configure*: attempt configuration unconditionally, and when the attempt cannot
   be made, report it as a **named refusal** (`no_transport: <what was looked for>`)
   followed by the setup sheet offered explicitly as the recovery path — never as the
   ordinary outcome, and never phrased as luck when the tool *is* present. Rewrite the
   command description and §5 so a reader sees one job with a failure mode, not two equal
   branches keyed on tool detection.
5. Align the docs in the same commit — `CLAUDE.md`'s `/setup-routines` row,
   `workaholify/SKILL.md` §5, and `reference/routines.md` — then regenerate `outputs/`.
6. Verify: `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`,
   `node scripts/test-workflow-scripts.mjs`, and re-run `/setup-routines` in the session
   class from step 1 to confirm the report reads as one job.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The `/setup-routines` contract states configuring the routines as the command's own job;
  neither the command file nor §5 presents tool detection as the first branch of two equal
  outcomes.
- A session that cannot configure reports a named refusal with its reason, and the setup
  sheet appears only as the stated recovery from that refusal.
- The step-2 transport finding is recorded in the repository (Final Report and, where it
  changes a stated fact, `reference/routines.md`).
- `CLAUDE.md`, `workaholify/SKILL.md`, `reference/routines.md` and `outputs/` agree.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/test-workflow-scripts.mjs`
- A live `/setup-routines` run in each reachable session class, with its report quoted.

**Gate** — what must pass before approval:

- The above pass, and the reproduce/localize evidence from steps 1–2 is in the Final Report.

## Open Decisions

<!-- Recorded verbatim rather than resolved: /propose cannot ask. The driving session
     resolves each explicitly and records the resolution in its Final Report. -->

- **Does "always configure" extend to the unattended, routine-fired session class?** The
  reporter asks for behavior that does not depend on the session's tool surface, while
  `workaholify/SKILL.md` §*What may be applied unattended* states that every mutation of a
  standing outward-facing process needs a human seeing exactly what it will be — never
  performed by an unattended run. Today those two do not collide only because the
  routine-fired class has no tool. Removing the tool-detection branch makes them collide
  directly. Either the unattended prohibition is narrowed (and stated as such), or the
  unconditional rule is scoped to attended sessions (and the report says so in that class).
  Do not pick silently.

## Considerations

- The earlier record this follows, FB `20260810214929`, itself asked to keep "the sheet only
  as the fallback for session classes without the tool". This ask is stronger than that one,
  not a restatement of it: it rejects the fallback as a *normal* outcome. Where they
  conflict, the newer instruction governs — say so in the change.
- The reporter's evidence is a session's own wording, so the fix is not complete while the
  report still describes a successful configuration as a lucky accident. Wording is part of
  the deliverable here.
- Step 2 may find that no transport exists in the routine-fired class. That is a legitimate
  result and must be written down rather than worked around — it is the fact that makes the
  step-4 shape honest.

## Final Report

Development completed as planned, diagnosis first.

**Step 1, reproduce.** Only one session class was reachable from here — the unattended,
routine-fired one this tick runs in. What it produces on the absent path is the sheet render plus
the preconditions, framed by the command's own description as one of two equal branches
("Detects a `RemoteTrigger`-family tool first … otherwise render copy-paste setup sheets"). The
interactive-session wording the reporter quoted ("たまたま … 生えていたので") is not stored text —
it is what a session composes when the contract tells it detection comes first and configuration
is the branch that detection happened to select. That framing is the half of the report this
change answers directly.

**Step 2, the constraint — measured, and this is the fact the design turns on.** In this session:

- `ToolSearch` by name and by keyword (`RemoteTrigger`, routine, schedule, trigger, cron, account)
  returns **no `RemoteTrigger`-family tool** — confirming the 2026-08-10 finding still holds for
  the routine-fired class.
- The only scheduling tools present are `CronCreate` / `CronList` / `CronDelete`, whose own
  documentation says jobs "live only in this Claude session — nothing is written to disk, and the
  job is gone when Claude exits." They schedule a prompt inside this REPL; they cannot create,
  read or update an **account** routine.
- The `claude` CLI on PATH exposes no routine/cron/schedule subcommand.
- The session's environment carries no routines-API credential. A harness-internal OAuth token
  handle (`CLAUDE_CODE_OAUTH_TOKEN_FILE_DESCRIPTOR`) exists, but reading a session credential to
  hand-roll calls at an undocumented endpoint is an outward mutation of a standing process — the
  safety floor and §*What may be applied unattended* both put that behind a human, so it is not a
  transport this command may reach for.

**Conclusion: no second transport exists**, so step 4 applies rather than step 3. Nothing in the
plugin can make a tool-less session configure a routine; what it can do is stop presenting that
inability as an ordinary outcome.

**Steps 4-5, the restructure.** §5's *Direct-apply when `RemoteTrigger` is exposed* is now
*Configuring the routines is the job; `no_transport` is its one refusal* — attempt, converge,
or report `no_transport: RemoteTrigger-family tool` and render the sheet **as that refusal's
recovery path**. The sheet's content is byte-identical; only its standing changed. The command
description, *The scripts*, *What the command does with all this*, `reference/routines.md`'s two
back-references and `CLAUDE.md`'s row were rewritten to match, and the measured absence above is
recorded in the skill so the refusal is honest rather than a shrug.

### Discovered Insights

- **Insight**: the defect was in the *shape* of the contract, not in any behavior. Both paths did
  the right thing; describing them as peers keyed on detection is what made a success read as
  luck and a failure read as normal. A contract that says "detect, then branch" produces exactly
  that narration, because the session reports the structure it was given.
  **Context**: worth checking wherever a capability probe precedes an action — the probe's result
  should name a refusal, not select an outcome of equal standing.
- **Insight**: `CronCreate` is a permanent near-miss. Its name, its cron syntax and its
  scheduling vocabulary all match what a routine needs, and only its documentation says it is
  session-only and in-memory. Every re-verification of this question has had to rule it out
  explicitly.
  **Context**: keep the exclusion written next to the transport rule; a future session searching
  "cron" will find it first and could reasonably assume it qualifies.
