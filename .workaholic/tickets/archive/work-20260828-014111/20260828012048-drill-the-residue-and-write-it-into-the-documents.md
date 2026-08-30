---
created_at: 2026-08-28T01:20:48+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-what-the-direction-could-not-see-before-calling-it-arrived
merge_policy:
verification_handoff: 
---

# Drill the residue and write it into the documents

## Overview

A `loop-drill.sh` verification over local fixtures with no network, covering the honest and
the degraded residue read, the arrival question naming its residue, the asked-once gate, and
the attribution append landing and refusing — with **one row that deliberately breaks the
seam**, so the drill can be shown to fail.

And the documents, in the same change: `CLAUDE.md`, `workaholic:strategy`,
`workaholic:propose` and `workaholic:moderate`. Outdated documentation is a defect by this
repository's own rule; the backstops are backstops.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the new verification subcommand
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason to file blame table
- `CLAUDE.md` — the `/propose`, `/moderate` and strategy-conventions rows
- `plugins/workaholic/skills/strategy/SKILL.md` — the residue reader and the attribution append
- `plugins/workaholic/skills/propose/SKILL.md` — the residue on the survey row and in the run report
- `plugins/workaholic/skills/moderate/SKILL.md` — the arrival question naming its residue
## Implementation Steps

1. Read an existing drill — `verify-arrival` is the closest, since it is git-backed for the
   same reason this one must be (`landed` is a `git log --since` read).
2. Add the verification. Rows: the honest residue read; the degraded read refusing the
   arrival; the arrival question naming its residue by slug; the asked-once gate over
   `direction-arrived:<slug>` across two ticks; the attribution append landing; the append
   refusing `not_active` and leaving the mission byte-identical.
3. Add the breaker row: a fixture that deliberately breaks the seam — the residue read wired
   to the **archived** missions instead of the active ones — so a drill that always passes
   is impossible.
4. Stub the transport. No network call anywhere in the drill.
5. Update the four documents and the runbook in this same commit, each stating what is now
   true rather than what changed.
6. Run the local verification list from `CLAUDE.md` before pushing.
## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-residue` passes with no network.
- The breaker row fails when the seam is broken, proving the drill can fail.
- `CLAUDE.md`, `workaholic:strategy`, `workaholic:propose` and `workaholic:moderate` describe
  the shipped behaviour, and the runbook carries the new subcommand.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-residue`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- All of the above pass.
- `outputs/` is regenerated in the same commit, since workflow skills and their script
  closure changed.

## Considerations

- This ticket lands last on purpose: it documents behaviour the seven before it shipped, and
  a document written ahead of the behaviour is the defect it exists to prevent.
- The drill is operator tooling outside the plugin and assumes the server's full `gh` and
  `qfs`; it ships to no other agent.
## Final Report

Development completed as planned.

`sh scripts/e2e/loop-drill.sh verify-residue` drills the whole chain over local, git-backed
fixtures with **no network**: the honest residue read; the degraded read named with its reason
and null counts; a non-empty readable residue leaving the arrival standing; a blind one
refusing it; the arrival question naming the residue by slug and count; the asked-once gate
over `direction-arrived:<slug>`; the survey's `selected` unchanged when the residue is
emptied; and the attribution carry landing, re-running as a byte-identical no-op and refusing
a closed direction without writing. Twelve load-bearing rows, all passing.

The **breaker row** is `residue_reads_the_active_area`. The fixture carries an archived,
unattributed mission (`retired`) that must never reach the residue; pointing
`mission-strategy.sh` at `missions/archive` was run and the drill failed 3 of 12 rows,
so the drill is demonstrably able to fail.

Documents updated in this same change: `CLAUDE.md` (the `/propose`, `/moderate`,
`/specificate` and strategy-conventions rows, plus the drill list), `workaholic:strategy`
(the residue reader and the attribution carry), `workaholic:propose` (`quiescent`'s new term
and the run report's obligation, with `reference/loop.md` step 5), `workaholic:moderate`
(the arrival question naming its residue, with `reference/workflow.md`), and
`docs/loop-drill-runbook.md` (§5j and the drill table row).

### Discovered Insights

- **Insight**: the degraded-read row cannot be produced by malforming a strategy —
  `all_strategies_unreadable` necessarily makes the strategy itself unreadable, so the row
  would pass on `unreadable` without exercising the term. The drill copies the plugin tree and
  removes `mission-strategy.sh` instead, which leaves the direction perfectly legible and only
  the residue blind.
  **Context**: the same shape the hermetic suite needed, and the same trap either would fall
  into silently.
- **Insight**: a breaker row needs bait the broken seam would actually surface. An archived
  **attributed** mission is invisible to the residue either way, so the fixture had to gain an
  archived **unattributed** one before the row could fail.
  **Context**: the first version of this row was green under a deliberately broken seam, which
  is exactly the failure a breaker row exists to prevent.
