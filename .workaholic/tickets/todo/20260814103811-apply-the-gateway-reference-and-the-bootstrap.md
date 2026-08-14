---
created_at: 2026-08-14T10:38:11+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-workaholify-apply-the-standards-not-report-them
merge_policy:
verification_handoff: 
---

# Apply the gateway reference and the bootstrap

## Overview

PROPOSED. Two of `/workaholify`'s steps still stop at a report, and both have a
mechanical, single-answer fix the command already knows how to compute.

`audit-claude-md.sh` returns `{conformant, checks, missing}`; the command's §3
says "offer to add a reference to this gateway". `check-bootstrap.sh` names each
problem separately — `hook_missing`, `hook_stale`, `not_registered`, `matcher`,
`timeout`, `enabled_plugin`, `marketplace` — and §4 reports them. The canonical
hook already lives in the skill (`bootstrap/session-start.sh`) and
`matches_canonical` already compares byte-for-byte, so "stale" is a diff against
a file in hand, not a judgment. A cloud session without that hook has every
routine stopping at its plugin precondition, firing on time and doing nothing —
which is exactly the class of silent failure this command exists to prevent.

The ask rules the interaction question in advance: "A confirmation dialog before
applying is acceptable; stopping at a rendered report is not."

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/workaholify.md` — the flow's one description;
  §3 "offer a reference" and §4 "check the web bootstrap" are the wording.
- `plugins/workaholic/skills/workaholify/SKILL.md` §3, §4 — the contracts.
- `plugins/workaholic/skills/workaholify/scripts/audit-claude-md.sh` — the read
  half; its `missing` list is what an apply half would answer.
- `plugins/workaholic/skills/workaholify/scripts/check-bootstrap.sh` — the read
  half, with the seven named problems and the byte-for-byte staleness compare.
- `plugins/workaholic/skills/workaholify/bootstrap/session-start.sh` — the
  canonical hook to install or refresh.
- `plugins/workaholic/skills/workaholify/scripts/converge-layout.sh` — the
  precedent for an applying step's boundary (composes, stages, exits 0).
- `plugins/workaholic/rules/general.md` — repository confinement; every write
  here lands inside the repository being prepared.
- `scripts/test-workflow-scripts.mjs` — hermetic coverage.
- `CLAUDE.md` — the `/workaholify` row states the flow.

## Implementation Steps

1. **Reproduce and localize first.** In a throwaway repository with no
   `CLAUDE.md` gateway reference and no `.claude/hooks/session-start.sh`, run
   both scripts and record exactly what each reports and what it leaves behind.
   Confirm the current end state is "reported, nothing written".
2. Write the apply half for `CLAUDE.md` as its own script beside the audit —
   idempotent, adding **a reference to the gateway skill and never a copy of the
   rules** (the §1 rule this command exists to protect). An already-conformant
   file must produce no diff. Do not restructure a repository's `CLAUDE.md`
   beyond inserting the reference.
3. Write the apply half for the bootstrap: install `bootstrap/session-start.sh`
   at `.claude/hooks/session-start.sh` and register the `SessionStart` entry with
   matcher `startup` and timeout 120. Refresh a stale copy from the canonical
   file. Each of `check-bootstrap.sh`'s seven problems either has a mechanical
   fix applied or is reported by name — no silent partial.
4. Keep the stages-never-commits boundary `converge-layout.sh` established, and
   keep the always-exit-0 rule: a preparation step that errors out of the session
   is a step nobody runs.
5. Re-run the read halves after applying and report the delta, the same
   before/apply/after shape `converge-layout.sh` returns. A converged repository
   produces an empty delta and no diff.
6. Update `commands/workaholify.md` §3/§4 wording and the SKILL sections so the
   command's description matches what it does — the drift that produced this ask
   was a command describing itself as an audit.
7. Add hermetic cases to `scripts/test-workflow-scripts.mjs`: unprepared
   repository becomes prepared; prepared repository is a no-op; a repository with
   a real, non-canonical `session-start.sh` is refreshed and reported.
8. Update the `/workaholify` row in `CLAUDE.md` in the same commit.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- An unprepared repository ends the run with the gateway reference present in
  `CLAUDE.md` and a canonical, registered `SessionStart` hook on disk.
- A prepared repository produces an empty delta and no diff — safe to re-run.
- A problem with no mechanical fix is reported by its existing name, not glossed.
- No rule text is copied into `CLAUDE.md`; only a reference to the gateway.
- Nothing is written outside the repository being prepared.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (new hermetic cases).
- Replay of step 1's reproduction against the applying command.

**Gate** — what must pass before approval:

- Smoke suite green; `commands/workaholify.md`, the SKILL sections and the
  `CLAUDE.md` row updated in the same commit as the behavior.

## Open Decisions

- Whether an applying `/workaholify` should **commit** its changes — options:
  (A) stage only, extending `converge-layout.sh`'s stated rule ("committing here
  would make an attended audit an author of history") to the new writes, vs
  (B) commit, or publish behind a pull request, so the operator gets a reviewable
  change instead of a mixed staged diff. Neither is clearly recommendable:
  (A) keeps one boundary across every step but hands the operator a multi-file
  staged diff spanning `CLAUDE.md`, `.claude/hooks/`, and moved tickets, which is
  harder to review than the report it replaces; (B) reads better but makes a
  preparation command a branch author, and `/workaholify` creates no branch of
  its own today. The driving session must record which it took and why in its
  Final Report; the same ruling governs the sibling routines ticket.

## Considerations

- **Confinement.** Writing `.claude/hooks/session-start.sh` is a write into the
  repository being prepared, which is inside the boundary. Nothing here may reach
  `~/.claude` or any path outside that repository (`rules/general.md`).
- The bootstrap's git-identity behavior is deliberate and narrow: it sets
  `user.email`/`user.name` only when the current value is empty or an
  `@anthropic.com` default. Installing the hook must not change that logic.
- A hook-registered install is still not a **bound** one — no supported way
  exists to make a SessionStart-time install live without `/reload-plugins`.
  Applying the hook does not fix binding, and the report must not imply it does.
