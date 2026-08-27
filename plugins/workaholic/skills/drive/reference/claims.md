# The claim protocol — reference

Companion to [`../SKILL.md`](../SKILL.md)'s **Claims** section, which states the model. This file
carries the full protocol: the scan mechanics, each script's contract, the resumption rules, and
the release/landing tables. The scripts implement this model and never extend it silently.

## The model

**The repository is the coordination medium.** Before driving a unit, a runner claims it on a
pushed branch; every runner reads the claims in flight from the unmerged remote branches. There is
no run-lock, no lock file, and no server — nothing leaks when a runner dies mid-run, and a runner
on another machine coordinates through exactly the same artifact.

- **PR-unit.** The thing a runner takes: one approved **mission** (unit id = the slug) or one
  **batch** of related backlog tickets (unit id = `batch-<YYYYMMDDHHMMSS>`, minted at claim time).
  One unit ↔ one branch ↔ one worktree ↔ one PR.
- **Claim.** A commit whose subject is `Claim <unit-id>`, on a fresh `work-*` branch cut from
  `origin/main` by the standard creator, stamping `claim: <branch>` into the claimed artifacts'
  frontmatter — the mission's `mission.md`, or each batched ticket file — pushed immediately. The
  stamp rides the **worktree** checkout only, so the runner's main checkout stays clean between
  ticks (the `/specificate` batch depends on that). **A stamp that reaches the base is history, never
  a claim** (decision M1, 2026-08-04): a `handoff` or `blocked` unit merges its PR with tickets
  still in `todo/`, so a base-side stamp on a live queue item is an ordinary state — the
  unmerged-branch scan is the only claim oracle, and it already reports a merged branch's claim as
  released. A mission absent from the claiming checkout is refused `mission_missing`: after J1,
  absence means a wrong slug or a stale checkout.
- **Reader.** Fetch, enumerate the `origin/*` branches carrying commits not on `origin/main`, and
  for each read the unit from its newest `Claim …` subject and the artifacts from the branch tip's
  stamps — **at each file's current path, not the path the claim commit stamped**. `archive.sh`
  *renames* a driven ticket (`todo/X.md` → `archive/<branch>/X.md`), so the reader maps paths with
  one tree-to-tree rename diff per claim; and because `--find-renames` only pairs above 50%
  similarity (the appended Final Report can push a short ticket below it), a path the diff does
  not map is resolved a second way: an exact **filename** lookup scoped to `.workaholic/tickets/`
  and to a single unambiguous match (`mission.md` is shared by every mission, so ambiguity falls
  back to the mapped path rather than guessing). What the reader reports is the **base-side**
  path — the coordinate space both consumers compare in. A genuine stamp removal drops the
  artifact, and a deleted artifact is not claimed — both deliberate, both pinned by tests. (An
  empty artifact list is two failures at once, measured 2026-08-04: the survey re-offers a ticket
  already in flight with no `excluded[]` row, and `claims_has_work`'s conservative "no artifacts
  means unknown" branch calls a drained unit resumable.)
- **Release = merge or branch deletion.** A merged branch's commits are on the base, so its claim
  leaves the unmerged set by definition — the normal path needs no script. Deliberately
  discarding an unfinished unit is `release-claim.sh` (below), which deletes the branch and is
  therefore **not** the recovery path — resumption is.
- **Resumable ≠ stale, and only one of them acts.** Past `WORKAHOLIC_CLAIM_STALE_HOURS` (default
  24) a claim is marked `stale: true` and **nothing acts on it** — reclaiming a colleague's work
  on a local verdict can silently duplicate it. Resumption is the narrower case: **your own**
  claim whose **heartbeat** lapsed, both computed in the one shared scan and carried on every row
  (`resumable`, `resume_reason`) — a writer free to decide independently could take over a unit
  the reader still calls active.
  - **Liveness is the branch tip**, refreshed by `heartbeat.sh` and by every ordinary work
    commit. The window is `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES` (default 30) — minutes, not
    the 24-hour `stale`, because a routine that recovers its own dropped unit only after a day is
    not a recovery path.
  - **Something left to drive.** At least one of the unit's tickets must still be undriven on
    that branch (for a mission unit: at least one tip-side todo ticket naming it). Without this
    the verdict cannot tell a run that died from a unit that finished: a `review` unit's branch
    correctly stays unmerged and its heartbeat lapses exactly like an abandoned one (measured:
    the hourly runner re-took one such unit three times, adding empty `Resume` commits to a
    branch under human review). Such a unit reports `queue_drained` and is excluded as
    `claimed_reported`.
  - **A claim whose content already reached the base is neither.** "In flight" is
    `git rev-list --count base..ref`, so a branch whose *commits* never landed is claimed
    forever even when its *content* did — a unit recovered by hand onto a fresh claim
    branch, a change re-applied, a revert-and-redo. `claims_superseded` reports it:
    **`superseded`**, `resumable: false`, excluded `claimed_superseded`. **Reported, never
    acted on** — nothing here deletes the branch or closes its pull request, exactly as
    `stale` has worked since the protocol shipped; an operator closes it out, and the
    verdict exists so the survey stops offering it. It must **not** forbid `ok`: a claim
    holding no work is the opposite of outstanding work. **And a fresh claim may be taken
    over it** (2026-08-27): `claim.sh` skipped this verdict and answered `already_claimed`,
    so the work `resurveyed[]` re-offered was reachable by no path — a fresh claim refused
    here, and `resume` refused it as `superseded` by design. The refusal loop now skips a
    row whose verdict is `superseded`, reading the same `lib/claims.sh` derivation the
    survey reads, so the offer and the refusal cannot disagree again. It frees the **work,
    not the branch**: nothing here deletes the old branch, closes its pull request or
    releases its claim, and the new claim is an ordinary `work-*` branch beside it. Every
    other refusal is untouched — a live claim, a colleague's, a `queue_drained` one and a
    `report_incomplete` one all refuse exactly as before, because only a claim already
    **proved** to hold nothing may be claimed over. The signal is *the unit's tickets
    are archived on the base* (every one of them, under any branch directory — which
    branch delivered them is exactly what the test must not care about), chosen over "the
    branch's diff is contained in the base" because the measured recovery landed
    **refined** rather than verbatim and containment would have answered `false` on the
    very branch that provoked the rule. **It answers at both grains since 2026-08-26.**
    A batch claim is answered from the tree, first and network-free, exactly as before.
    A **mission** claim — which stamps only `mission.md`, a file driving never archives —
    is answered by the merged-pull-request lookup (`claim-merged.sh`, above): *is there a
    merged pull request whose head is this branch?* is grain-agnostic and reads no
    artifact, so the many-valued `mission:` relation still has exactly one parser. The
    earlier scope rule (`false` for any non-ticket artifact, "a shape nothing has
    measured") is **replaced along with its reason**: the shape was measured on this
    repository the same day — three of five claims headed pull requests #521, #537 and
    #546, all merged, all mission units, one offered `resumable: true` five days after its
    own pull request merged. An `unanswerable` lookup answers `false`, which is precisely
    the verdict that grain had before, so a degraded run loses nothing and gains nothing.
    Measured 2026-08-26, on the first run to hold the `report_incomplete` tier: it resumed
    `batch-20260819063000` exactly as designed, and the unit had been recovered onto
    `work-20260821-221006` five days earlier — ten merge conflicts, three of them
    `modify/delete` against a directory the base had deleted in a rename, and a full
    story-and-pull-request cycle spent on a pull request whose only correct outcome was to
    be closed.
  - **Which branch *is* the unit, once two of them hold it** (2026-08-27). The verdict above
    is what made a unit legitimately reachable by **two** claim branches — a `superseded`
    one the survey ignores, and the live one a later run took its work on — and every
    writer resolved a unit to *a* branch by taking the **first** row out of `claims_scan`.
    That scan walks refs in name order, so first-match is the **oldest** branch, which for
    this shape is precisely the dead one. Measured 2026-08-27 on
    `make-workaholify-converge-the-account-s-routines`, held by `work-20260819-113836`
    (`superseded`) and `work-20260827-003544` (`claim_active`): `claim.sh resume` refused on
    the dead branch's own verdict, so the **live** claim was resumable by nothing, and
    `release-claim.sh` tore the dead branch's worktree down and reported `half_released`
    while the live claim stood. The rule is **the live row wins**, derived once in
    `lib/claims.sh` (`claims_unit_resolution` / `claims_unit_row` / `claims_unit_live_branches`)
    and read by both writers — three copies of a lookup is exactly how these disagreed. Its
    answers are `none` / `single` / `live` / `superseded_only` / `ambiguous`; a unit with
    **one** claim resolves byte-identically to first-match, and `superseded_only` returns
    that superseded row, so a caller keeps refusing under `superseded` exactly as before.
    **Two live claims are reported, never picked between** (`ambiguous_claim`, naming both
    branches): the protocol settles a race by the push, so the state cannot arise from the
    sanctioned path at all, and choosing silently is how a runner would resume — or discard —
    work another run is still driving. `plan-units.sh` reads the same resolution: its
    `claimed_superseded` **resurvey** was keyed on the first row too, so the dead branch
    governed and the survey offered as fresh backlog a mission another run held — observed
    live, the same mission in `missions[]`, `resumable[]` and `resurveyed[]` at once. A
    superseded row beside a live one now governs nothing while staying reported in
    `claimed[]`. `release-claim.sh` also sets `CLAIMS_FETCH_OK` after its own fetch, as
    `claim.sh` does: without it the merged-pull-request lookup is skipped `offline`, so a
    mission-grain `superseded` claim read as live there and the release refused
    `ambiguous_claim` over a unit with exactly one live branch. Separately, `ensure-worktree.sh` **refuses** a branch
    name that already exists on origin rather than minting a local branch at `HEAD` that
    shadows it: its contract is to create a worktree on a *new* branch, attaching to a
    published one is `create-mission-worktree.sh --branch`'s job, and the silent third
    option turned the next push into a claim-clobbering force-of-fact.
  - **A drained queue is two states, split on the same story signal.** "Finished" covers a unit
    that **reported** — story committed at the tip, pull request open, waiting on a human — and a
    run that died **after** archiving its last ticket and **before** opening anything, whose work
    is pushed and which nobody has been told about. Both answered `queue_drained`, so both were
    untouchable *and* both had their tickets excluded `claimed_reported` at every later survey:
    the second was reachable by no path at all (measured 2026-08-19, `batch-20260819063000` — two
    tickets archived and pushed, no story, no PR, four `[Implement]` ticks that each surveyed a
    clean checkout and drove nothing). A story at the tip now keeps `queue_drained`, unchanged;
    its absence reports **`report_incomplete`**, `resumable: true`, offered as `claimed_resumable`
    and taken over at §5 with nothing left to drive. This **narrows** the drained gate rather than
    reversing it — the case it was built for is byte-identical.
  - **Complete history, or no verdict at all.** "Unmerged" is `git rev-list --count
    <base>..<ref>`, which cannot be reduced across a shallow graft — in a shallow clone a fully
    merged branch still counts as ahead (measured 2026-08-04: a merged branch counted 154 ahead
    while shallow, 0 after `--unshallow`, and passed both gates above). The reader **repairs
    first**: `claims_fetch` deepens a shallow clone before anything reads ancestry. When origin
    is unreachable and it cannot, it **degrades loudly**: `shallow: true` goes out to both
    consumers and the branch reports `resumable: false`, reason `shallow_history` — an
    unanswerable question must not render as `heartbeat_lapsed`. The claim is still *listed*
    (over-reporting makes a runner wait; under-reporting double-picks work): the verdict is
    suppressed, never the row.
  - **Same identity only.** The claim commit's author must be this runner's
    `git config user.email`. A colleague's claim is `foreign_identity`, untouchable at any age;
    an unresolvable identity resumes nothing. Consequence: a runner configured with a
    developer's email inherits that developer's claims — intended — so never configure a
    *shared* identity across people.
- **Worktree lifecycle.** A worktree is claim-born and ship-torn: `claim.sh` creates
  `.worktrees/<unit-id>/`; it is removed when the unit ships or its claim is released.
  `/mission-close` never tears worktrees down — a lingering worktree is an in-flight or stale
  claim, the reader's business.

**The reader degrades offline; the writer does not.** With origin unreachable, `list-claims.sh`
reports `fetched: false` and answers from the last-known remote-tracking refs, while `claim.sh`
refuses outright. A stale reader over-reports claims (a runner waits); a claim nobody else can see
is not a claim, and driving on one is the double-pick the protocol exists to prevent. **One scan
serves both**: `drive/scripts/lib/claims.sh` holds it, `list-claims.sh` renders it, `claim.sh`
verifies through it.

## Read the claims in flight

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/list-claims.sh
```

Pure read. Emits `{fetched, shallow, stale_hours, heartbeat_stale_minutes, base,
merged_lookup_unanswered, claims: [{unit,
branch, artifacts, last_commit_at, stale, author, resumable, resume_reason, reported}]}`, where
`resume_reason` is one of `heartbeat_lapsed` / `report_incomplete` / `parked_with_pr` (resumable)
or `claim_active` / `superseded` / `queue_drained` / `foreign_identity` /
`identity_unresolved` / `shallow_history`.

`merged_lookup_unanswered` is `[{branch, reason}]` — every claim the **merged-pull-request
lookup** could not answer for (2026-08-26). That lookup, `claim-merged.sh`, is the claim
protocol's one **network** read: it asks whether a merged pull request has the claim branch as
its head, which answers *has this unit's work reached the base?* at both grains without reading
any artifact. Its three values are `merged` / `not_merged` / `unanswerable`, and the third is
the point — **a read we could not make leaves the row precisely the verdict it would have had
without the lookup, and is named here instead.** The direction of failure is chosen: a wrong
`merged` releases work still in flight, a wrong `in flight` only delays a claim. Reasons:
`offline` (the fetch failed, so no call is spent), `disabled`
(`WORKAHOLIC_CLAIM_MERGED_LOOKUP=0`), `gh_unavailable`, `rate_limited`, `session_refused`,
`transport_error`, `unparseable_response`, `slug_unresolved`, `no_reader_script`. The survey
(`plan-units.sh`) reads the same scan through the shared library rather than re-parsing this
output. This script takes nothing over; it exists so the state is readable without a survey.

## Claim a unit

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/claim.sh mission <slug>
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/claim.sh batch <ticket-file>...
```

Never prompts. Verifies the unit is unclaimed through the reader's own scan, then creates the
worktree, stamps, commits, and pushes. Emits `{claimed, unit, branch, worktree_path, artifacts}`,
or refuses with a `reason`: `already_claimed` (naming the holding branch and unit), `no_origin`,
`origin_unreachable`, `branch_collision`, `push_failed`, `artifact_missing`, `no_frontmatter`,
`mission_missing`. A refused claim leaves nothing behind — the half-made worktree and branch are
removed, because an unpublished claim is not a claim.

`claim.sh` also posts one Slack line (unit, branch, member count) through the bot token after its
push succeeds, reporting `announced`/`announce_reason` in its JSON. This bot notice is a separate
surface from the session's threaded posts (see [`routing.md`](routing.md)), is **never
load-bearing** (a missing token or broken notifier leaves the claim intact), and only a
successful claim announces.

## Resume a dropped unit

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/claim.sh resume <unit-id>
```

Takes over a claim the survey reported in `resumable[]`. It **adopts** this machine's existing
`.worktrees/<unit-id>/` when that worktree is on the claim's branch at the very tip the
resumability decision observed (same-machine resume is the common case, and the creator's
`worktree already exists` refusal used to break it), and otherwise **creates** one **at the pushed
branch tip** — never from the base — so archived tickets are not re-driven. It then publishes an
empty `Resume a PR-unit` commit; that push **is** the race arbiter — two racing runners resolve
non-fast-forward, never by comparing clocks. An abort never tears down an adopted worktree.

**Where the unit re-enters is decided by its tier, not by the takeover.** A `heartbeat_lapsed` or
`parked_with_pr` unit re-enters at **step 4**: its remaining tickets are whatever is still in
`todo/` on that branch, and step 5 updates the existing PR rather than opening a second one. A
**`report_incomplete`** unit has an empty queue by definition, so step 4 has nothing to do and it
re-enters at **step 5** — write the story, run the scan, open the pull request the dead run never
opened — then routes normally at step 6.

Emits `{claimed, resumed, unit, branch, worktree_path, adopted_worktree, resume_reason,
announced, announce_reason, artifacts}`, or refuses with `not_claimed`, `claim_active` (naming
the tip time), `queue_drained` (it finished **and reported**; its PR waits on a human — a drained
unit that never reported is `report_incomplete` and is accepted), `foreign_identity`,
`identity_unresolved`, or `resume_race_lost` (having taken nothing).

## Release a claim deliberately

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/release-claim.sh <unit-id>
```

For a unit that will **not** be finished. Tears the worktree down first (the cleaner refuses a
dirty worktree and never discards uncommitted work), then deletes the remote claim branch — that
order matters: dropping the claim first would publish "this unit is free" over unpushed work. Run
it from the main checkout; git cannot remove the worktree you are standing in. Emits `{released,
state, unit, branch, worktree_removed, remote_branch_deleted, local_branch_deleted}`.

`state` exists because the two steps can disagree (a container may push but not delete a branch —
measured 2026-08-05), and a bare `released: false` cannot say how:

| `state` | Meaning |
| ------- | ------- |
| `released` | both steps done — the unit is back in the pickable pool |
| `half_released` | the worktree is gone and **the claim branch is still live**. A human must delete it; the unit stays claimed and is re-offered as `resumable` once its heartbeat lapses |
| `untouched` | nothing changed (unreachable origin, or a refused teardown) |

Two rejected alternatives (a tombstone release commit; inverting the teardown/delete order) are
recorded in the script's header — read it before re-proposing either.

## Heartbeat mechanics

`heartbeat.sh` pushes an empty commit through `commit.sh --allow-empty`, so coordination markers
get the subject gate and trailers. There, **`--allow-empty` means empty**: the commit is built
against a scratch index seeded from `HEAD`, so its tree equals `HEAD`'s by construction and the
caller's index is left byte-identical (git's own flag merely permits a changeless commit and
otherwise commits whatever is staged — a beat fired over a staged `git rm` once swept real
deletions into a `Refresh heartbeat` commit). Beating over a dirty index is deliberately allowed:
mid-ticket is exactly when the index is dirty and exactly when a missed beat makes a working unit
look abandoned. The beat changes no file, so it never reaches the PR diff, and the merge or
release that cleans up the claim cleans it up too.

## Publication branches are not claims

The claim is the only creator of a worktree and of a branch a runner may drive (J1, amended by
J4). Artifact writers publish through a publish tree onto `work-*` branches behind pull requests
(`workaholic:branching`), but a publication branch carries no `Claim <unit-id>` commit and the
scan keys on that subject, never the branch name — so it is never mistaken for a claim. The
`release/*` tier is invisible to the scan for the same reason: a release branch carries no commit
at all. The optional `claim:` key on a ticket is tolerated and never validated by
`validate-ticket.sh` — its truth lives in git, which a hook reading one file cannot answer.
