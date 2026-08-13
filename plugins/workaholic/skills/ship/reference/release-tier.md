# Release promotion — the `release/*` tier in detail

The rules — explicit invocation, the window carries the production evidence, a failed
confirmation deletes nothing — are `SKILL.md` §6. This file is the mechanics. (Decisions
L1-L3, `docs/loop-engineering-workflow.md`.)

The tier is **one branch form and nothing else**: no `develop`, no `hotfix/*`, and the
base stays the default and production branch. A unit still claims, drives, reports and
merges into the base exactly as today — one merge target per unit.

## The flow

1. **Cut the window.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cut-release-branch.sh [base]`
   mints `release/YYYYMMDD-HHMMSS` at the base tip and pushes it. It carries no commits
   of its own and never checks itself out. On a refusal (`no_origin`,
   `origin_unreachable`, `base_unresolved`, `branch_collision`, `push_failed`) **stop**:
   nothing has changed and there is no window.
2. **Hold it open for QA.** The batch is verified *together*, on a ref that will not
   move under it, before it is called a release. The base is not blocked meanwhile —
   later units keep merging there and simply belong to the next release.
3. **Confirm it.** Run the target's `## Confirmation` (or `CLAUDE.md` `## Verify`)
   against the release branch's tip, and record the attempt with `confirm-release.sh`.
   Since 2026-08-13 this is **the** production confirmation, not a second one: the Ship
   Flow drafts a deployment plan and deploys nothing, so what a unit branch used to
   prove before it landed is proved here, over the batch, or it is not proved at all.
   Skipping it does not defer the evidence — it removes it.
4. **Deploy/tag from the confirmed branch.**
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/publish-release.sh "<release-branch>" "<release tip sha>" "<tag>" "<notes-file>"`.
   It still defers to CI (`ci_publishes`) — in a deploy-on-merge project the release is
   published from the merge commit on the base, and the release branch's role is to be
   the recorded, confirmed identity of what that release carried, not a second
   publishing path.

## When confirmation fails

The release branch is **not deleted**: it is the rollback boundary (the base is
unaffected — its units are already merged there; a failed promotion never un-lands
anything) and the durable evidence of what was tried. Record the failure, leave the
branch pushed, and cut a **fresh** release branch for the next attempt. Never re-point,
force-push, or reuse a failed release branch: its identity is "the commits confirmed, or
not, at that moment".

## Recording it

Every promotion writes its durable ship record — which base commits the branch carries,
when it was cut, when it was confirmed or failed — as
`.workaholic/releases/<release-branch>.md`. This is **additive**:
`.workaholic/release-notes/<branch>.md` and the story's `## Deployment Evidence` block
keep their shape. Both scripts run **on the base with a clean tree** (a record on the
release branch would be invisible until that branch merged somewhere):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/record-release-cut.sh "<release-branch>" [since-ref] [base]
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/confirm-release.sh "<release-branch>" "<method>" "<non-secret result>" "pass"|"fail" [tag] [base]
```

**`record-release-cut.sh`** runs immediately after the cut and writes the record:
`type: Release`, the release branch, `cut_at`/`cut_sha`, the carried commit range with
`carried_count`, and a pending confirmation — everything **derived from git at cut
time**. The previous boundary is resolved most-specific-first and recorded as
`since_reason`: an explicit `since-ref` (`given`), else the newest prior
`.workaholic/releases/` record whose `cut_sha` still resolves (`prior_release`), else
the latest tag reachable from the cut (`latest_tag:<tag>`), else the whole history
(`full_history` — a first release genuinely carries everything). Commits
(`Record release cut`) and pushes. Refusals: `unknown_release_branch`, `not_on_base`,
`dirty_workspace`, `already_recorded` (one record per release branch, never rewritten),
`commit_failed`.

**`confirm-release.sh`** runs after step 3 and closes the other half: sets the record's
`status` to `confirmed`/`failed` with `confirmed_at`, `confirmation_method`,
`confirmation_status` and `tag`, and **appends** a dated block to the body — body
entries are append-only (several attempts each leave their own) while the frontmatter
carries the latest verdict. It applies the same secret guard as `record-evidence.sh`,
from the same shared rule source, and refuses (`possible_secret`) rather than writing a
credential into a version-controlled record. Refusals: `bad_status`, `no_record`,
`not_on_base`, `dirty_workspace`, `commit_failed`.

**Both halves are on the base, so `grep` and `git log` answer the question alone**:
`grep -l 'status: confirmed' .workaholic/releases/*.md` finds the releases that reached
production, and `git log <since_ref>..<cut_sha>` replays exactly what each carried. The
range is **literal** — every base commit between the boundaries, this pipeline's own
bookkeeping commits included — precisely so that replay works; a filter that hid
bookkeeping would have to recognise it by subject, and the first wrong guess would cost
the record the one property it has.

**The record and the branch find each other by name, in both directions.** The record's
`release_branch` names the branch; the branch's record is at
`.workaholic/releases/<branch with `/` → `-`>.md`, derived with no lookup. A pointer
*on* the branch is impossible by construction — a release branch carries no commits —
so a deterministic filename is the only both-ways link that costs nothing to keep true.
