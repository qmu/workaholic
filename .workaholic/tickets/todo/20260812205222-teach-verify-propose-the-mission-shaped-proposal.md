---
created_at: 2026-08-12T20:52:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260812205142-teach-the-loop-drill-s-verify-propose-the-mission-shaped-proposal.md]
merge_policy:
---

# Teach verify-propose the mission-shaped proposal

## Overview

<!-- PROPOSED. Merging the pull request this was published on turns it into queued work. -->

The first live run of `scripts/e2e/loop-drill.sh verify-propose` (issue #406, measured
2026-08-12 20:47 UTC) reported `verdict: fail` on a stage that had actually passed. The
proposal PR #407 emitted the **mission form** — the feedback record, a mission whose
frontmatter names that record in `feedback:`, and two tickets carrying `mission: <slug>` —
but the verifier's `ticket_feedback_ref` and `ticket_assignee` rows look only for a ticket
that names the record stem directly (`loop-drill.sh:609`,
`main_grep ".workaholic/tickets" "$stem"`). That shape is the **loose ticket** only. A
mission-shaped proposal satisfies the same chain indirectly — record →
`mission.feedback` → `ticket.mission` — so the verifier called a healthy stage broken.

A drill that reports red on a green run trains the operator to ignore red, which is the
failure mode the script's own `pending`-vs-`fail` comment already argues against.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — the verdict is the operator's signal; a false red is a defect
- `workaholic:implementation` / `policies/test.md` — the hermetic row-shape fixtures that keep this honest
- `workaholic:implementation` / `policies/command-scripts.md` — the drill is a POSIX operator script

## Key Files

- `scripts/e2e/loop-drill.sh:600-625` — `cmd_verify_propose`'s ticket rows, where the
  loose-only assumption lives; `main_grep`/`main_show` (`:457`, `:466`) are the readers it
  must keep using (everything is read from `origin/<base>`, never the working tree).
- `scripts/test-workflow-scripts.mjs:13967+` — the hermetic
  `testLoopDrillVerifyPropose` fixture and its row-shape assertions.
- `docs/loop-drill-runbook.md` — the failure-reason → file blame table, which names the rows
  by id and must match whatever ids this change adds.
- `plugins/workaholic/skills/propose/SKILL.md` — *The form follows the work's shape*: the
  three emission forms the verifier is being taught to read.

## Implementation Steps

1. **Reproduce first.** Run `verify-propose 406` against `main` at `ccb043c` or later and
   capture the JSON: the two false rows alongside PR #407's merged `Closes #406`, its
   mission and its two tickets. Keep that output as the before-state in the Final Report.
2. **Localize.** Confirm the cause is the single `main_grep ".workaholic/tickets" "$stem"`
   lookup at `loop-drill.sh:609` and nothing else in the row set — in particular that
   `feedback_record`, `issue_closed` and `proposal_pr_merged` all passed on that run.
3. **Teach the fallback.** When no ticket names the stem, look for a mission under
   `.workaholic/missions/active/` whose `feedback:` names the record, then follow it to the
   tickets carrying `mission: <slug>`. `ticket_feedback_ref` passes on either shape and says
   which one it found; `ticket_assignee` then checks the tickets that path reached.
4. **Keep record-alone distinguishable.** A record-only judgment is a legitimate outcome of
   the judgment bar, so report it as its own row (`proposal_form: record_alone`) rather than
   as a failure of a missing ticket. Decide and state whether that row is load-bearing —
   the recommendation is that it is not, since the drill cannot know which form the ask
   warranted.
5. **Keep the hermetic tests in step**: extend `testLoopDrillVerifyPropose` with a
   mission-shaped fixture (record + mission naming it + ticket carrying `mission:`) and a
   record-alone fixture, asserting the row ids and the verdict for each. The suite must stay
   hermetic — no `gh`, no network.
6. Update `docs/loop-drill-runbook.md`'s blame table for any row id added or re-scoped, in
   the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `verify-propose 406` returns `verdict: pass` against the real base, with a row stating the
  proposal was mission-shaped.
- A loose-ticket proposal still passes exactly as it does today (no regression on the shape
  the rows were written for).
- A record-alone proposal produces a distinct, non-crashing row rather than a missing-ticket
  failure.
- `scripts/test-workflow-scripts.mjs` covers all three shapes and passes.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `bash scripts/e2e/loop-drill.sh verify-propose 406 --json` (before/after, both quoted in
  the Final Report)

**Gate** — what must pass before approval:

- Both of the above, and the runbook's blame table matches the emitted row ids.

## Considerations

- The verifier reads the base through `main_grep`/`main_show`; the mission lookup must go
  through the same readers, or the drill starts disagreeing with itself depending on the
  operator's working tree.
- The mission→ticket hop is a frontmatter relation the repository already has one reader for
  (`mission/scripts/read-relation.sh`). The drill is operator tooling outside the plugin and
  cannot assume a plugin binding, so prefer a local grep over the base blob — but keep the
  match anchored to frontmatter, not any occurrence of the slug in prose.
- This is follow-up work on a delivered mission (`make-the-propose-implement-loop-drillable-on-demand`,
  acceptance already 3/3), not a sharpening of an in-flight one — hence a loose backlog
  ticket rather than a replan.
