---
created_at: 2026-08-19T05:22:41+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260819051828-housekeep-must-post-only-fb-issue-filings-never-pr-status-notifications.md]
merge_policy:
verification_handoff: 
claim: work-20260819-063001
---

# Stop the housekeep tick posting PR-status notices

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

Issue #525: the `[Housekeep]` routine's responsibility should be filing `[FB] ***`
issues, and it is also posting PR-status and merge-readiness notices into Slack —
the reporter quotes "Needs a decision - N pull request(s) conflicting with main".
The reporter asks that the tick never post PR-status, merge-conflict or
merge-readiness messages, and that such messaging be handled by the Propose
routine instead.

**This is a failure report, so it is driven diagnosis-first**
(`workaholic:discover`, *Diagnosis-First Rule*): the first steps reproduce and
localize the post, and the reporter's proposed mechanism — moving the messaging to
`/propose` — is recorded as a hypothesis under Considerations and as an Open
Decision, not as step 1's design. What the localization will almost certainly find
is already visible from the tree and is stated here so the driver can confirm or
refute it rather than rediscover it: the `🔧 Needs a decision` shape is authorized
in exactly three places — `skills/housekeep/reference/workflow.md` step 6,
`skills/notify/reference/notifications.md` (*`/housekeep` — the maintenance tick's
two shapes*) and the `## Prompt` of `skills/workaholify/routines/housekeep.md` —
and it is fed by `step-stuck-prs.sh`'s `headline`/`blocked_by`/`stuck:<digest>`
over `pulls-state.sh`, with step 4 (`step-merge-conflicts.sh`) deliberately
carrying no post of its own and riding step 6's reminder.

**The removal must not destroy the finding.** Step 6 resolves real state (which
pull requests are blocked and by what) into the tick's report and its log; only
the *Slack post* is what the ask objects to. A driver that deletes the step
rather than its post would take the finding out of the tick log too, and the
dedup that log feeds with it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a routine's authorized post formats are part of its operational contract

## Key Files

- `plugins/workaholic/skills/housekeep/scripts/step-stuck-prs.sh` — resolves the
  stuck set, `blocked_by`, `headline` and the `stuck:<digest>` key that the post
  carries; the probe whose *output* is at issue, not its reading.
- `plugins/workaholic/skills/housekeep/scripts/step-merge-conflicts.sh` — step 4,
  which already posts nothing of its own and rides step 6's reminder; its finding
  is the "conflicting with main" wording the reporter quotes.
- `plugins/workaholic/skills/housekeep/scripts/pulls-state.sh` — read once per
  tick, used by both steps; unchanged by this ticket.
- `plugins/workaholic/skills/housekeep/reference/workflow.md` — steps 4 and 6,
  where the post, its two gates and its key are specified.
- `plugins/workaholic/skills/housekeep/SKILL.md` — *Standing rules* ("a question
  becomes a Slack post") and the nine-step description.
- `plugins/workaholic/skills/notify/reference/notifications.md` — *`/housekeep` —
  the maintenance tick's two shapes*; the canonical copy of the `🔧` format.
- `plugins/workaholic/skills/workaholify/routines/housekeep.md` — the routine
  prompt, which is the ceiling on what a session running it may emit; its `##
  Prompt` carries the `🔧` block verbatim.
- `scripts/test-workflow-scripts.mjs` — pins the routine prompts byte-identical
  against `notify/reference/notifications.md`, so both copies move together or CI
  fails.
- `CLAUDE.md` — the `/housekeep` row and the *Routines* section describe the
  `🔧 Needs a decision` post and its headline derivation.

## Implementation Steps

1. **Reproduce.** Run `bash plugins/workaholic/skills/housekeep/scripts/step-stuck-prs.sh`
   (and `step-merge-conflicts.sh`) against this repository and capture what they
   return — the stuck set, `blocked_by`, `headline`, `actionable` and the
   `stuck:<digest>` key. Confirm the reporter's quoted wording is this step's
   `headline`, not another surface's.
2. **Localize the authorization.** `grep -rn "🔧" plugins/ CLAUDE.md` and confirm
   the shape is authorized in exactly the three documents named under Key Files
   (script output feeds the post; no script calls Slack itself). Record any fourth
   site found — the localization, not the assumption, decides the edit set.
3. **Decide the disposition with the Open Decisions below resolved** (a driving
   session records its resolution in its Final Report; it may not resolve them
   silently). The default disposition, if the operator has not ruled otherwise, is
   the narrow one: **the tick keeps finding the stuck set and stops posting it.**
4. **Remove the post, keep the finding.** Drop the `🔧` block from the routine
   prompt's `## Prompt`, drop the corresponding shape from
   `notify/reference/notifications.md`, and rewrite step 6 in
   `housekeep/reference/workflow.md` so it reports into the tick's own report and
   log and posts nothing. `step-stuck-prs.sh` keeps resolving `blocked_by` and
   `headline`; what changes is that no session is authorized to emit them to
   Slack.
5. **Keep the gates honest.** With no post, the "already posted" gate that the
   `stuck:<digest>` search answered has nothing to dedup on the wire; state in
   step 6 that the tick log alone answers repetition, and leave the digest
   derivation untouched so a later relocation can reuse it verbatim.
6. **Update the documents in the same change** (`CLAUDE.md`'s `/housekeep` row and
   Routines section, `housekeep/SKILL.md`) — outdated documentation is a defect by
   this repository's own rule.
7. **Re-run the pins.** `node scripts/test-workflow-scripts.mjs` (the routine
   prompt is pinned byte-identical to the notify copy) and
   `node scripts/build-plugins/build.mjs` + `verify.mjs` to regenerate `outputs/`.

## Open Decisions

<!-- Recorded verbatim rather than resolved: /propose cannot ask the developer,
     and both forks change what ships. The driving session resolves each one
     explicitly and records the resolution in its Final Report. -->

1. **Does the PR-status messaging move to `/propose`, or simply stop?** The ask
   says it "should instead be handled by the Propose routine". Adding an hourly
   PR-status digest to `[Propose]` is a new post shape for a routine whose prompt
   today authorizes exactly two (its finish line and the description root), and
   `workaholic:notify`'s *the prompt is the ceiling* makes that an explicit
   authorization rather than an implementation detail. Fork: (a) remove the post
   and stop there — the finding stays in the tick log, nobody is told in Slack;
   (b) remove it here and re-authorize it on `[Propose]`, which is a second unit
   of work on a different routine's contract.
2. **Which routine will be called "Propose" when this lands?** Issue #526, filed
   seven minutes after #525 by the same reporter, renames `[Propose]` →
   `[Specificate]` and `[Housekeep]` → `[Propose]`. Under that rename the routine
   that posts these notices today *becomes* `[Propose]`, so "move it to Propose"
   is satisfied by doing nothing, while "the housekeeping tick must only file
   `[FB]` issues" still asks for the removal. The two asks are not obviously
   reconcilable and this session may not pick between them.
3. **Does "sole responsibility is filing `[FB]` issues" also retire the `❓`
   check-in post?** Step 9 asks humans questions in Slack; those are not
   PR-status, merge-conflict or merge-readiness notices, so the ask's explicit
   list does not reach them — but its first sentence would. Scope this
   deliberately; do not let it be decided by whichever `grep` the driver ran.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No `🔧 Needs a decision` shape is authorized for the maintenance tick in any of
  `skills/notify/reference/notifications.md`, `skills/workaholify/routines/housekeep.md`
  or `skills/housekeep/reference/workflow.md`, under the disposition step 3
  resolved.
- `step-stuck-prs.sh` still resolves and reports the stuck set, its `blocked_by`
  reasons and its `headline`; the finding survives in the tick report and the tick
  log.
- Every document that described the post (`CLAUDE.md`, `housekeep/SKILL.md`) says
  what is true after the change, in the same commit.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "🔧" plugins/ outputs/ CLAUDE.md` returns only what the resolved
  disposition permits.
- `bash plugins/workaholic/skills/housekeep/scripts/step-stuck-prs.sh` still emits
  its stuck set with `blocked_by` and `headline`.
- `node scripts/test-workflow-scripts.mjs`, `node scripts/build-plugins/build.mjs`,
  `node scripts/build-plugins/verify.mjs` all pass with `outputs/` clean.

**Gate** — what must pass before approval:

- The three Open Decisions are each resolved explicitly in the Final Report, with
  the reasoning, not silently by the edit that shipped.

## Considerations

- **The reporter's proposed mechanism is a hypothesis, not the design.** "Handled
  by the Propose routine" names a destination; whether that destination exists
  under that name when this lands is Open Decision 2.
- The `stuck:<digest>` derivation is deliberately distinct from
  `[Prepare Release]`'s `deploy:<digest>` so neither dedups the other away. If a
  later ticket relocates the post, reuse the derivation verbatim rather than
  cutting a new key — re-cutting a settled dedup key is the churn `CLAUDE.md`
  records twice.
- Removing a post is cheap to reverse and quiet to get wrong: nothing downstream
  reads it, and no artifact depends on it having been sent.
