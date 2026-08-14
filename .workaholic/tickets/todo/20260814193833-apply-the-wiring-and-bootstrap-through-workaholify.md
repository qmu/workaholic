---
created_at: 2026-08-14T19:38:33+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-workaholify-converge-the-repository-state
merge_policy:
verification_handoff: 
---

# Apply the wiring and bootstrap through workaholify

## Overview

`/workaholify`'s layout half now converges (`converge-layout.sh`), but its two wiring halves still stop at audit-and-offer: `audit-claude-md.sh` reports `conformant: false` and the command "offers" to add the gateway reference, and `check-bootstrap.sh` names each bootstrap problem (`hook_missing`, `hook_stale`, `not_registered`, …) while the repair — copying the canonical `bootstrap/session-start.sh` and registering its `SessionStart` entry — stays a manual follow-up. The developer's ruling (issue #445): `/workaholify` is the preparation command; running it should leave the repository prepared. Make both halves apply — each after one confirmation in an attended session — with report-only remaining the recovery path of a named refusal, never the ordinary outcome.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / recovery-first behavior — an apply that cannot proceed names its refusal instead of half-writing

## Key Files

- `plugins/workaholic/commands/workaholify.md` — the command flow that today says "offer a reference, never a copy" and "report what needs fixing"
- `plugins/workaholic/skills/workaholify/SKILL.md` — §3 (CLAUDE.md audit) and §4 (web bootstrap): gains the apply contract beside each check
- `plugins/workaholic/skills/workaholify/scripts/audit-claude-md.sh` — the check the apply is derived from
- `plugins/workaholic/skills/workaholify/scripts/check-bootstrap.sh` — per-problem findings the repair maps one-to-one
- `plugins/workaholic/skills/workaholify/bootstrap/session-start.sh` — the canonical copy the apply installs
- `scripts/test-workflow-scripts.mjs` — hermetic coverage for both apply scripts

## Implementation Steps

1. Add `apply-claude-md-reference.sh`: append the minimal gateway-reference block to `CLAUDE.md` (create it when absent) — a reference to `workaholic:workaholify`, never a copy of any rule; idempotent (`changed: false` when the reference already resolves); emits JSON naming what it wrote.
2. Add `apply-bootstrap.sh`: for each `check-bootstrap.sh` problem, the matching repair — install/refresh the canonical hook copy, register the `SessionStart` entry with `matcher: startup` and `timeout: 120`, correct a wrong matcher/timeout; idempotent; refuses by name (e.g. `settings_unparseable`) rather than guessing; never touches a hook that `matches_canonical`.
3. Wire both into the command: run the check, show what would change, apply on one confirmation each (attended command — the Recommended-label test permits the confirmation because destructive-adjacent file writes in a *consuming* repository are the operator's to veto); a decline or a named refusal falls back to today's report with the refusal stated.
4. Update `commands/workaholify.md`, `SKILL.md` §3/§4, `CLAUDE.md`'s `/workaholify` row, and `README.md` in the same change.
5. Hermetic tests: both scripts converge a throwaway repo from each named problem state and are no-ops on a conformant one.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Running `/workaholify` in a repository missing the gateway reference and the bootstrap hook ends with both present after two confirmations, and a second run reports `changed: false` for both.
- Every refusal path is named in the command's report; no apply half-writes.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` covering both apply scripts' converge and no-op paths.
- `bash apply-claude-md-reference.sh` / `apply-bootstrap.sh` twice in a scratch repo: first run converges, second reports `changed: false`.

**Gate** — what must pass before approval:

- Smoke tests green; `build.mjs`/`verify.mjs` clean (workflow-skill closure changed).

## Considerations

- The confirmation is an attended-session act; unattended callers (none today invoke `/workaholify`) must keep report-only.
- `apply-bootstrap.sh` edits `.claude/settings.json` in the consuming repository — parse-don't-regex, and an unparseable file is a named refusal, never overwritten.
