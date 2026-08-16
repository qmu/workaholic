---
created_at: 2026-08-14T19:38:33+09:00
status: done
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

## Final Report

Development completed as planned. Both wiring halves now apply:
`apply-claude-md-reference.sh` (composes `audit-claude-md.sh`, appends the gateway
reference block, creates `CLAUDE.md` only when absent, `already_conformant` on a
second run, `unwritable` as its named refusal) and `apply-bootstrap.sh` (one repair
per `check-bootstrap.sh` problem id, `settings_unparseable` /`hook_source_missing` /
`unwritable` refusing with nothing written at all). `commands/workaholify.md` and
`SKILL.md` §3/§4 carry the apply contract with its one confirmation each, and
`CLAUDE.md`/`README.md` were updated in the same change.

### Discovered Insights

- **Insight**: The refusal had to cover the *hook file* too, not just the settings
  write. `apply-bootstrap.sh` checks `settings.json` parseability **before** copying
  the canonical hook.
  **Context**: The two repairs look independent, but installing the hook while the
  registration fails produces a state the run itself created — a hook present and
  unregistered — which `check-bootstrap.sh` then reports as `not_registered` against a
  file that exists. Refusing atomically keeps the repository in the state the operator
  can still reason about, which is what "an apply that cannot proceed names its refusal
  instead of half-writing" means in practice.

- **Insight**: The settings repair corrects the existing `SessionStart` group rather
  than appending a new one.
  **Context**: `check-bootstrap.sh` finds the group by matching `session-start.sh` in
  any entry's command, so an appended second group would leave the check reading
  whichever it found last while both fired the bootstrap once per session. The `matcher`
  and `timeout` problems are properties of an entry that already exists; repairing them
  in place is the only reading that makes the check and the apply agree.

- **Insight**: Composing `audit-claude-md.sh` rather than re-deriving conformance is
  what keeps the apply honest.
  **Context**: The audit's rule is a single `grep -q 'workaholify'`. Had the apply
  carried its own idea of "refers to the gateway", a block that satisfied the writer but
  not the checker would report `changed: true` and leave the repository non-conformant —
  the exact class of drift the two-lockstep-sources pattern exists to prevent.
