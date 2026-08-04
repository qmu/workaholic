---
created_at: 2026-08-01T02:03:14+00:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260804-035024
---

# Merging a handoff PR leaves a live `claim:` stamp on `main`, which the design says can never happen

## Overview

`CLAUDE.md` states the invariant plainly:

> The stamp is branch-only — **`main` never shows a claim**, and the runner's main checkout stays clean between ticks (which the `/propose` batch depends on).

That is false today. Observed on `main` at `b70bb0a9`, immediately after PR #153 merged:

```
$ sed -n '1,11p' .workaholic/tickets/todo/a-qmu-jp/20260724094304-containerize-long-running-servers-policy.md
---
created_at: 2026-07-24T09:43:04+09:00
...
claim: work-20260731-221002
---
```

The ticket is in `todo/`, it is **not** claimed (the branch merged, so it left the unmerged set and `list-claims.sh` no longer reports it), and yet `main` carries the stamp of a claim that no longer exists.

## Why the invariant broke

The invariant holds only under the assumption that **a claim branch merges after `archive.sh` has moved every one of its tickets out of `todo/`**. Under that assumption the stamp rides along into `archive/<branch>/<ticket>.md`, where it is honest history — that is the documented, intended behavior and it is not what this ticket is about.

The handoff protocol broke the assumption. `drive/SKILL.md` §7 defines `handoff` as a first-class terminal state whose unit **opens or updates its PR with the partial work pushed**, and the unattended drive routine goes further — *"for every unit still claimed and unmerged … open or update the unit's PR even when the work is incomplete"*. A `blocked` unit takes the same path. So a PR now routinely carries tickets that are **still in `todo/` and still stamped**, and merging it publishes the stamp to `main`.

Both halves are correct in isolation; the interaction is what nobody re-derived. The claim protocol says a stamp is branch-local; the handoff protocol says publish unfinished units. Together they mean the stamp reaches the base.

## Blast radius — small today, and that is the point

Nothing is currently broken by it, because the survey does not read the key:

- `plan-units.sh` subtracts claims from the **shared scan over unmerged branches**, never from frontmatter, so the stale stamp does not hide the ticket. It was correctly re-offered after #153 merged.
- `validate-ticket.sh` **tolerates and never validates** `claim:` — deliberately, because "its truth lives in git, which a hook reading one file cannot answer."
- The next real claim overwrites the key, so it self-heals per ticket.

So this is a **correctness-of-record** defect, not an outage: `main` asserts something false about coordination state, and the one documented reason the key is un-validated ("its truth lives in git") is exactly what makes a stale copy on `main` indistinguishable from a live one to any human reading the file. It will recur on **every** merged handoff or blocked-unit PR, which the routine now produces by design.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — an invariant stated as absolute in `CLAUDE.md` (`main` never shows a claim) is either true or it is a lie the next reader will build on; whichever way this is resolved, the sentence must end up matching the code
- `workaholic:implementation` / `policies/observability.md` — a coordination marker that survives its own coordination is a stale signal that reads as a live one, which is the masked-state failure this policy names
- `workaholic:operation` / `policies/deployment-pipeline.md` — the merge is the seam where the two protocols meet, so whatever the fix is, it belongs at that seam rather than in a periodic cleanup

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim.sh` — writes the stamp; the "branch-only" claim originates here
- `plugins/workaholic/skills/drive/scripts/archive.sh` — the path that *legitimately* carries the stamp into `archive/<branch>/`
- `plugins/workaholic/skills/drive/SKILL.md` — the **Claims** section states the invariant, and §7 defines the `handoff` state that violates it; both are in one file and disagree
- `CLAUDE.md` — carries the same invariant sentence
- `plugins/workaholic/skills/workaholify/routines/drive` — the routine step that makes merged-while-claimed PRs routine
- `scripts/test-workflow-scripts.mjs` — no case covers "merge a branch whose ticket is still in todo/"

## Related History

The `claim:` key was deliberately left un-validated by `validate-ticket.sh` on the reasoning that its truth lives in git. That reasoning is sound and should **not** be reversed here — a hook reading one file still cannot answer it. The fix belongs at the merge seam or in the invariant's wording, not in a validator.

Decision I5 / the 2026-08-01 resumption work made a dropped claim recoverable; the handoff state was added in the same round. This ticket is the third-order consequence of that round meeting J4's PR-first publication.

## Implementation Steps

1. **Decide which of the two statements is wrong**, and record it — this is the whole ticket, and the code change is small either way:
   - **(a) The invariant is right; stop publishing the stamp.** Strip `claim:` from any ticket still in `todo/` as part of the handoff PR's final commit, so what merges is unstamped. Cost: the pushed branch is then the *only* record of which unit held the ticket, and a resumed run must re-derive it from the `Claim <unit-id>` commit subject (which it already reads).
   - **(b) The invariant is too strong; narrow it.** Accept that a stamp reaches `main` for an unfinished unit, and re-word `CLAUDE.md` + `drive/SKILL.md` to say so — "a stamp on `main` is historical, never authoritative; the unmerged-branch scan is the only claim oracle." Cost: a human reading a `todo/` ticket cannot tell live from dead without running the reader.
   - Recommend **(a)**: it keeps a strong, checkable invariant, and the information (b) preserves is already in the commit subject. Record the rejected option and why.
2. Implement the chosen option at the **merge seam**, not as a sweep — a periodic cleaner would be a second source of truth about claims, which the claim protocol exists to avoid.
3. **Reconcile the two passages in `drive/SKILL.md`** so the Claims section and §7 stop contradicting each other, plus the `CLAUDE.md` sentence.
4. **Add the missing test**: merge a branch whose ticket is still in `todo/`, then assert the base-side ticket's `claim:` state matches the chosen contract.
5. Fix the one live instance on `main` (`20260724094304-containerize-long-running-servers-policy.md`) in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Under the chosen contract, a merged handoff/blocked PR leaves the base-side `todo/` ticket in the documented state — no stamp under (a), or a stamp the docs explicitly call historical under (b).
- `drive/SKILL.md`'s Claims section, `drive/SKILL.md` §7, and `CLAUDE.md` all state the same thing about what `main` may show.
- The rejected option and its reason are written down where the next session will find them.
- The live stale stamp on `20260724094304-containerize-long-running-servers-policy.md` is gone from `main`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with a new hermetic case that claims a ticket, merges the branch **without archiving it**, and asserts the base-side frontmatter.
- `grep -rn 'claim:' .workaholic/tickets/todo/` on `main` returns nothing (under contract (a)).

**Gate** — what must pass before approval:

- The suite is green, the three prose locations agree, and no `todo/` ticket on `main` carries a stamp.

## Considerations

- **Do not fix this by validating `claim:` in `validate-ticket.sh`.** That was considered and rejected on its own merits already: a `PostToolUse` hook reading one file cannot know whether an unmerged remote branch of that name still exists. Reversing it here would trade a stale-record defect for a hook that blocks on a question it cannot answer.
- **Do not fix it with a sweep over `main`.** Two writers of claim state is the condition the single shared scan (`lib/claims.sh`) was built to prevent.
- The defect is *caused by* a protocol that is otherwise working exactly as intended — the handoff PR is what let this run's blocked finding survive a sandbox that gets reclaimed. Nothing here argues against handoff PRs.
- Under (a), note that `archive.sh`'s carry-the-stamp-into-`archive/` behavior must be left alone; the strip applies only to tickets still in `todo/` at merge time.

## Final Report

Implemented as **option (b)** — narrow the invariant — recorded as decision **M1** in `docs/loop-engineering-workflow.md` (eighth round).

**The ticket's own recommendation was wrong, and that is the main finding.** Step 1 recommended option (a): strip `claim:` from any ticket still in `todo/` in the handoff PR's final commit. Reading `drive/scripts/lib/claims.sh` before implementing showed why that cannot work — a claim's artifacts are sourced as *the files the claim commit touched that still carry `claim: <branch>` **at the tip***, so removing a stamp drops that artifact from the claim. Deliberately: the behaviour is documented and pinned by tests. Stripping at handoff time would therefore un-claim a ticket **while its pull request is still open and unmerged**, offering in-flight work as fresh backlog — the double-pick the claim protocol exists to prevent, observed live on 2026-07-30 and again on 2026-08-04. A fix that creates the failure it was written to prevent is not a fix.

Recorded as M1a rather than silently switching options, and the second half of the new test *asserts that failure mode directly*, so the strip cannot be re-proposed without seeing it fail.

**Also rejected (M1b):** re-sourcing the reader from the claim commit instead of the tip — it would make the strip safe, but reverses the deliberate, tested "a stamp removal releases that artifact" behaviour, which is a design change needing its own ticket and a human, not a side effect of a record fix. And a sweep over the base, on the ticket's own grounds (two writers of claim state is what the single shared scan prevents).

### Acceptance

- **Met** — the contract is documented: a base-side stamp is history, never a claim.
- **Met** — `drive/SKILL.md`'s Claims section, `CLAUDE.md`, and the §7 handoff route now agree; the Claims bullet names the handoff/blocked merge as the ordinary case that produces a base-side stamp.
- **Met** — the rejected options and their reasons are in M1a/M1b.
- **Superseded, not skipped** — "the live stale stamp on `20260724094304` is gone from `main`". That bullet was written assuming (a) would win; under (b) removing it would delete exactly the history the ruling legitimizes. The file has also been **iced** by the developer since this ticket was written (`.workaholic/tickets/icebox/`), which is developer-curated space `/drive` must not edit. Left in place deliberately.

### Discovered Insights

- **Insight**: A coordination marker can be simultaneously load-bearing on a branch and meaningless on the base, and the two readings cannot be separated by removing the marker — only by documenting which reader is authoritative.
  **Context**: `lib/claims.sh` gives the stamp its meaning *relative to the unmerged set*. Any future change that tries to make frontmatter self-describing about claims will hit this same wall: the file cannot know whether its branch is merged, which is precisely why the scan exists.
- **Insight**: The `handoff` terminal state changed a precondition of the claim protocol without either document noticing, because each was internally consistent.
  **Context**: `drive/SKILL.md` held both statements — the Claims section's "`main` never shows a claim" and §7's "open or update its PR even when the work is incomplete" — in one file. When adding a terminal state, check what the other protocols assumed about *when* a branch merges, not only about what the state does.
