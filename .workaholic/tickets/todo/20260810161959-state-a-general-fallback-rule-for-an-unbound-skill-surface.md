---
created_at: 2026-08-10T16:19:59+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [.workaholic/feedbacks/20260810161811-routines-should-keep-going-when-the-plugin-is-unbound.md]
merge_policy:
---

# State a general fallback rule for an unbound skill surface

## Overview

**PROPOSED** (from qmu/workaholic#356 / feedback `20260810161811-routines-should-keep-going-when-the-plugin-is-unbound.md`). `/drive`'s survey step already falls back to invoking its own scripts by checkout-relative path instead of stopping when `check-deps/scripts/check.sh` reports `unbound_in_claude_session: true` (ticket `20260810090005`, commit `d291125`). That fix is scoped to `/drive`'s own `SKILL.md`/`reference/survey.md` text — it exists only because a developer, live in-session, told that one run to keep going. The issue reports the same failure shape stopping **other** unattended runs (an `[Implement]` tick, and — historically, before `[Consent]` was retired — a merge-announcement run) with no equivalent instruction to fall back on, because nothing states the pattern generally.

The fix belongs where every workflow already looks first: an always-loaded rule. State once, in `plugins/workaholic/rules/general.md`, that when the `Skill`/`Command` tool surface is unreachable (`Skill(...)` fails "Unknown skill", `ListSkills` returns empty) but the repository checkout is present and current, a routine should read the needed skill's `SKILL.md` and scripts directly via `Read`/`Bash` and carry out the documented workflow from the checkout path, rather than stopping — **except** when the flow genuinely cannot proceed without the skill surface (an `AskUserQuestion`-driven step, or logic too risky to hand-reconstruct from source), which still fails safe. Point `/drive`'s existing text at the shared rule instead of restating it, and note the same fallback applies to `/propose` and any other unattended entry point, so a future routine does not have to re-learn this from a live correction.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/rules/general.md` — always-loaded rule file (`paths: '**/*'`); the general fallback principle belongs here, alongside the existing "never modify another repository" rule this file already carries
- `plugins/workaholic/skills/drive/SKILL.md` and `reference/survey.md` — carry the existing `unbound_in_claude_session` fallback prose scoped to `/drive`'s survey step; reference the new general rule instead of restating the pattern
- `plugins/workaholic/skills/check-deps/SKILL.md` and `scripts/check.sh` — document `unbound_in_claude_session` / `loaded_version_behind_registry`; note which of the two the general fallback rule applies to (the former: scripts stay runnable; the latter: `/drive` still terminates `pending`, per the existing registry-drift stop, which this ticket does not change)
- `plugins/workaholic/skills/workaholify/SKILL.md` (or `reference/routines.md`) — the *Scheduled routines* section that documents the bootstrap/binding contract; add a pointer so a reader following the routine story lands on the general rule
- `CLAUDE.md` — the `/drive`/`/implement` command-table entries describing the current `unbound_in_claude_session` behaviour; update in the same change per this repo's "update the docs in the same change" rule

## Implementation Steps

1. Add a new, clearly-scoped subsection to `plugins/workaholic/rules/general.md` stating the fallback principle: unbound skill surface is not, by itself, a reason to stop; read the needed skill and its scripts directly from the checkout and continue; the two named exceptions (an `AskUserQuestion`-driven flow; logic too risky to hand-reconstruct) still fail safe and report why.
2. Edit `plugins/workaholic/skills/drive/SKILL.md` / `reference/survey.md` so the existing `unbound_in_claude_session` fallback text references the general rule rather than independently restating it (keep the concrete detail — checkout-relative script paths, the registry-drift stop staying unchanged — since that is `/drive`-specific).
3. Add a short cross-reference from `check-deps/SKILL.md`'s description of `unbound_in_claude_session` to the general rule, and from `workaholify`'s routines documentation, so a reader who lands on either finds the governing principle rather than only `/drive`'s instance of it.
4. Update `CLAUDE.md`'s `/drive`/`/implement` table rows and any other prose that currently describes the fallback as `/drive`-specific, to say it is the general rule's instance for that command.
5. Run the local verification commands (`build.mjs`, `verify.mjs`, `validate-metadata.mjs`, `test-workflow-scripts.mjs`, `layout-doctor.sh .`) since a `rules/general.md` change ships to every consuming repo and the generated bundles must stay in lockstep with any skill text that changed.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `plugins/workaholic/rules/general.md` states the fallback rule once, generally, independent of any single command
- `/drive`'s own fallback text points at the general rule instead of duplicating it
- `CLAUDE.md` and the relevant skill docs describe the fallback as general, not `/drive`-only

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — generated bundles and policy index stay in lockstep
- Manual read-through of `rules/general.md`, `drive/SKILL.md`, `check-deps/SKILL.md`, and `CLAUDE.md` confirming the rule is stated once and referenced elsewhere

**Gate** — what must pass before approval:

- The registry-drift stop (`loaded_version_behind_registry`, which `/drive` still terminates `pending` on) is explicitly left unchanged — this ticket narrows only the blanket "unbound → stop" default the issue names, not the version-drift gate

## Considerations

- The two failure instances named in the triggering issue are an `[Implement]` schedule tick and a merge-announcement run; `[Consent]` (the merge-announcement routine) is already retired, so that second instance is historical — the ticket's scope is the general rule plus `/drive`'s existing reference, not resurrecting a retired routine.
- `/propose` currently has no `check-deps` gate or documented unbound-fallback at all; this ticket does not add one mechanically (a script gate the way `/drive`'s survey has one) — it relies on the general rule being visible in the always-loaded `rules/general.md` so a routine reasons its way through even when `workaholic:propose` itself is unreachable. If that proves insufficient in practice, a follow-up ticket can add an explicit check-deps call to `/propose`.
- Keep the general rule's exceptions narrow and named, not open-ended — a rule that reads as "always work around a broken tool surface" would invite hand-reconstructing logic that should fail safe (destructive git operations, anything gated by a hook the model can no longer rely on being active).
