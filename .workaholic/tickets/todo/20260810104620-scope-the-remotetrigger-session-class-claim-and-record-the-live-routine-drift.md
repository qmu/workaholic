---
created_at: 2026-08-10T10:46:20+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [.workaholic/feedbacks/20260810104520-no-remotetrigger-tool-exposed-claim-is-session-class-dependent-and-reveals-real-cron-prompt-drift-on-the-live-routines.md]
merge_policy:
---

# Scope the RemoteTrigger session-class claim and record the live routine drift

## Overview

A local *attended* session measured `RemoteTrigger` (`list`/`get`/`create`/`update`/`run`/`create_webhook_trigger`) present on its tool surface, and `list` returned both live routine records (`[Propose] workaholic`, `[Implement] workaholic`) in full — prompt, model, repository, connectors, `cron_expression`. Ticket `20260810085351`'s re-verification found no such tool from inside a **routine-fired, unattended** session and concluded "no `RemoteTrigger`-family tool is exposed to a session" without qualification. `skills/workaholify/reference/routines.md` already scopes its own finding correctly ("scoped to what was checked: an unattended, routine-fired session... nothing here rules out a `RemoteTrigger`-class tool being available to a developer's own interactive session"), but `skills/workaholify/SKILL.md` §*What a routine can be triggered by* and `commands/setup-routines.md` still state the absence as if it held for every session, unqualified. Tighten those two spots to point at the reference doc's existing session-class scoping instead of restating the unattended-only finding as universal, and record the second half of the same measurement — both live routine records were found carrying `cron_expression: ""` (not the designed `0,30 * * * *`) and prompts that differ from the committed templates (`{repo}` placeholders, older wording, `next_run_at` unset) — as a currently-manual, developer-facing caveat next to the setup sheet, since nothing in this repository's tool surface (attended or not, as verified so far) can write that state; only read it, and only from an attended session.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — §*What a routine can be triggered by* states the `RemoteTrigger` absence unconditionally; needs to point at `reference/routines.md`'s already-scoped finding instead of restating it as session-class-independent.
- `plugins/workaholic/skills/workaholify/reference/routines.md` — already carries the correctly-scoped finding ("scoped to what was checked: an unattended, routine-fired session"); add the live-drift measurement (empty `cron_expression`, stale prompts) as a dated addendum here, the pattern the file already uses for prior re-verifications.
- `plugins/workaholic/commands/setup-routines.md` — "It manages nothing: no `RemoteTrigger` call..." should carry the same session-class qualifier as the skill, or point to it rather than restate it.
- `CLAUDE.md` — the `/setup-routines` and `/workaholify` command-table rows restate the unqualified claim inline; needs the same correction (and any `outputs/workflows` build implications, if this skill closure is part of that bundle).

## Implementation Steps

1. In `workaholify/reference/routines.md`, add a dated addendum under the existing *The schedule field, re-verified for a session (2026-08-10)* section (or a new section immediately after it) recording: measured in a local attended session, `RemoteTrigger` (`list`/`get`/`create`/`update`/`run`/`create_webhook_trigger`) *was* present and `list` returned both live routine records in full; both carried `cron_expression: ""` against the designed `0,30 * * * *`, and both prompts differed from the current committed templates. State plainly that repairing this is a manual, developer-side act (in the routines UI, or from within an attended session where the tool is confirmed present) — this ticket does not add a script or command that writes routine state.
2. In `workaholify/SKILL.md` §*What a routine can be triggered by*, reword the sentence that currently states the `RemoteTrigger` absence as if unconditional so it explicitly names the session class the finding was measured in (unattended, routine-fired) and links to `reference/routines.md` for the full scoping and the live-drift addendum, rather than repeating the unqualified claim.
3. In `commands/setup-routines.md`, adjust "It manages nothing: no `RemoteTrigger` call... (none is exposed to a session, either trigger kind)" to carry the same session-class qualifier, or drop the parenthetical and defer to the skill.
4. Update the `/setup-routines` and `/workaholify` rows in `CLAUDE.md`'s command table to match (per this repo's "update the docs in the same change" rule) — scope the claim by session class rather than restating it flatly, and mention the live-drift finding as a known, currently-manual gap.
5. Grep the plugin source for any other unqualified restatement of "no `RemoteTrigger`-family tool is exposed to a session" (`grep -rn "RemoteTrigger" plugins/workaholic`) and apply the same scoping wherever the claim is repeated rather than referenced.
6. If any touched skill file is part of the `outputs/workflows` cross-agent bundle, rebuild it: `node scripts/build-plugins/build.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No file in `plugins/workaholic` (or `CLAUDE.md`) states the `RemoteTrigger`-exposure absence as if it held for every session class without qualifying or linking to the session-class scoping.
- The live measurement (empty `cron_expression` on both live routines; stale prompts vs. the committed templates) is recorded in `workaholify/reference/routines.md` as a dated, attributed addendum, stated as a currently-manual fix.
- `outputs/workflows` stays in lockstep with source if a bundled skill changed.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "RemoteTrigger" plugins/workaholic CLAUDE.md` and read each hit for an unqualified absence claim.
- `node scripts/build-plugins/verify.mjs` — asserts generated skills stay self-contained and in sync with source.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/verify.mjs` passes if any bundled skill was touched.
- A human reviewer confirms the reworded claim still reads as true for both session classes measured so far, and that nothing here overclaims a fix that wasn't made (the live drift stays a reported, not repaired, condition).

## Considerations

- This ticket is documentation-only: it does not add a script, command, or capability that writes to a live routine's `cron_expression` or prompt — no tool confirmed available to any session class in this repository can safely claim to do that yet, and fabricating one "with nothing behind it to call" is exactly the mistake `reference/routines.md` already warns against repeating.
- The two measurements (tool-surface presence, live drift) came from one attended session and are not independently reproduced here; word the addendum as a dated, attributed finding rather than a settled fact, consistent with how `reference/routines.md` already frames its own prior re-verification.
- Whether `/setup-routines` should eventually gain read/drift-check/create-update capability where `RemoteTrigger` is confirmed present (raised as an open question in the sourcing feedback) is a larger design decision explicitly left open here, not decided by this ticket.
