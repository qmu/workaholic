---
created_at: 2026-08-12T21:55:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback:
merge_policy:
claim: work-20260812-225831
---

# Teach the freshen step a checkout parked off main

## Overview

**Observed, not theorised** — an `[Implement]` tick on 2026-08-12T21:38Z hit this before it
could claim anything, and only got past it by a workaround the contract does not sanction.

`workaholic:drive` §1 freshens the checkout with `branching/scripts/sync-main.sh` before the
survey, and `commands/implement.md` step 0 routes `not_on_main` to **terminate `pending`,
never silently survey a branch**. The measured session started with its checkout on the
harness-assigned branch `claude/stoic-euler-thqys9`, so the freshen step returned
`{"ok": false, "reason": "not_on_main"}` and the run was contractually finished before it
began — with a claimable ticket sitting in the queue.

What made the refusal wrong *in this instance*, and what the fix has to reason about:

- `HEAD` was **exactly** `origin/main`'s tip (`c338f19`, verified after an explicit
  `git fetch origin main`), and the tree was clean. The survey would have read precisely
  the content the freshen step exists to guarantee.
- `plan-units.sh` is explicitly documented as side-effect-free and safe to run **inside a
  claim worktree**, which is never on `main`. So the survey itself does not require `main`;
  only the freshen step's own precondition does.
- Local `main` was a **stale image-baked branch** at `77c462d`, diverged from `origin/main`
  by 202/232 commits with a single `branch: Created from refs/remotes/origin/main` reflog
  entry — the exact artifact `sync-main.sh` §5 was written for, which realigned it cleanly
  once the checkout was moved onto `main`. §5 worked; it was simply unreachable, because §1
  refuses before §5 can run.

So the run recovered only by checking out `main` by hand — an unsanctioned repair that the
contract neither describes nor permits, and that the next session has to reinvent.

**This is the same failure class the repository has now ruled on twice**: a harness/image
artifact wearing a developer's clothes, reproducing on a tick and never self-healing —
`check-deps/scripts/plugin-src.sh` (a superseded plugin binding) and `sync-main.sh` §5 (an
image-baked base branch) are both the ruling that the run should proceed rather than stop.
What is **not** yet established is how often the container parks the checkout off `main`:
three ticks earlier the same day (`work-20260812-211128`, `-211712`, `-212339`) ran to
completion, so this is not known to reproduce hourly. Step 1 settles that before any code
is written — a one-off is a different fix from a standing condition.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a run that stops must be
  legible from outside; a stop whose recovery is an unwritten manual step is not
- `workaholic:implementation` / `policies/domain-layer-separation.md` — "is this checkout
  surveyable?" has one implementation; a second answer must not grow in command markdown
- `workaholic:operation` / `policies/failure-recovery.md` — which conditions a run repairs
  itself and which it reports is the decision this ticket makes
- `workaholic:development` / `policies/change-history-management.md` — `not_on_main`'s
  current handling is a written rule; narrowing it is recorded where the rule stands

## Key Files

- `plugins/workaholic/skills/branching/scripts/sync-main.sh` — §1 emits `not_on_main`; §5 is
  the precedent for the narrow, provable self-repair and holds the reasoning to follow
- `plugins/workaholic/skills/drive/SKILL.md` — §1's freshen step and its `ok: false` routing
- `plugins/workaholic/skills/drive/reference/survey.md` — the `reason` → action table that
  states the `pending` termination
- `plugins/workaholic/commands/implement.md` and `commands/drive.md` — step 0's copy of the
  same table
- `plugins/workaholic/skills/propose/SKILL.md` — `/propose` step 1 calls the same script and
  inherits whatever this decides
- `scripts/test-workflow-scripts.mjs` — the hermetic suite; `sync-main.sh`'s existing cases
  are the pattern to extend

## Implementation Steps

1. **Measure before designing.** Establish how the routine container actually starts: across
   recent `[Implement]`/`[Propose]` sessions, how often is the checkout on `main` versus a
   `claude/*` branch? The three same-day ticks that completed say it is not universal.
   Record the counts — they decide whether this is a standing condition worth a code path or
   a one-off worth only a documented recovery.
2. **Decide the rule and record it.** The candidate that matches the existing precedent: the
   freshen step proceeds when the checkout, whatever branch it is on, is **provably at the
   base's tip with a clean tree** — the survey then reads exactly the content the step
   guarantees, and nothing is silently surveyed because the condition is reported. Weigh it
   against simply teaching the run to move the checkout onto the base itself. Do not widen
   the exception past what is provable: a checkout merely *near* the base is the silent
   stale survey the refusal exists to prevent.
3. Implement in `sync-main.sh`, alongside §5 and in its idiom — a narrow, evidence-gated
   branch reported in the JSON (`{"ok": true, …, "off_base": true, "branch": "<name>"}` or
   equivalent), never a silent pass. One implementation; the callers keep reading one
   uniform contract.
4. If the run is to move the checkout, that belongs in the script too, not in command
   markdown — `rules/shell.md` forbids the inline shell it would otherwise take.
5. Update every document stating the current rule in the same commit: `drive/SKILL.md`,
   `drive/reference/survey.md`, `commands/implement.md`, `commands/drive.md`, and
   `CLAUDE.md` if it names the behaviour. State the narrowing where the old rule stands.
6. Add hermetic cases: a checkout on a non-base branch at the base's tip with a clean tree;
   the same but behind the tip (still refused); the same but dirty (still refused); and a
   genuine feature branch with commits of its own (still refused).
7. Run the local verification set in `CLAUDE.md` and regenerate `outputs/`.

## Considerations

- **The refusal is right in the general case and must survive.** A developer's feature branch
  carries different content, and surveying it reports a queue that does not exist. Whatever
  ships must keep refusing that, which is why the exception has to rest on a *proof* (same
  SHA as the base, clean tree) rather than on a branch-name pattern — a `claude/*` allowlist
  would be a guess about the harness, and the harness is free to change it.
- **`/propose` calls the same script** and would inherit the change. That is likely correct —
  it has the same reason to freshen and the same reason not to survey a divergent tree — but
  it must be checked rather than assumed.
- **Do not fold this into §5.** §5 realigns a *base branch* that is provably not a
  developer's; this is about the checkout being on a different branch entirely. Two
  conditions, two proofs, and blurring them would widen both.
- The workaround this run used — `git checkout main`, letting §5 realign — is recorded here
  as evidence, not as the recommended fix. It moved the developer's checkout, which a
  freshen step has no license to do without a stated rule.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Step 1's measurement is stated with actual counts.
- A checkout parked off the base but provably at its tip with a clean tree no longer ends the
  run before the survey, and the condition is reported in the JSON rather than passing
  silently.
- A checkout on a branch that is behind, ahead, divergent, or dirty is still refused, with
  its existing reason unchanged.
- No document still states the un-narrowed rule, and the narrowing is recorded where the old
  rule stood.
- "Is this checkout surveyable?" still has exactly one implementation.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including the four new cases in step 6.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs`
- `git diff` against the Key Files list, confirming the document rows moved in the same commit.

**Gate** — what must pass before approval:

- The whole local verification set in `CLAUDE.md` passes.
- The release-safety scan reports no `secret` finding.
