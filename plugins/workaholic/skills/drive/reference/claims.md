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
  - **And a *reported* unit is two states as well** (2026-08-27, mission
    `close-the-units-the-loop-already-finished`). `queue_drained` means *waiting on a person* and
    was also covering the loop's **own undelivered work**: a unit whose merge the transport
    refused, whose claim every later survey excludes `claimed_reported`, which no path offers and
    nobody was told about. Measured 2026-08-27: four pull requests the loop opened the day before
    were green and unmerged, with `ok` reported over all of them. This is the 2026-08-19 split's
    shape one state later, and it rests on that split's own rule — **a reason must imply its own
    next action**, and folding two next actions into one word is what makes the invisible half
    invisible. The new verdict is **`report_undelivered`**, excluded `claimed_undelivered`, and
    it **forbids `ok`**.
    **It is read off the branch, not re-derived and not re-fetched.** The scan cannot be re-run
    here — `scan-branch-safety.sh` diffs `<base>..HEAD` of the *current* checkout and the oracle
    stands in the main tree — and a fresh lookup is worse than the run's own answer for the
    reason `claim-merged.sh` is three-valued: a wrong verdict here releases work still in flight.
    So the run that attempted the merge records its outcome into the branch story it already
    committed (`story/scripts/record-merge-outcome.sh`, idempotent, replacing rather than
    stacking), and `claims_merge_outcome` reads that one line out of a blob the oracle already
    fetches. **An absent section keeps `queue_drained`** — every story written before this
    section, and every run that died before recording, answers empty, and the new reason is
    claimed only on positive evidence.
    **`resumable: false`, and for a different reason than `queue_drained`'s.** The next action is
    a **merge retry**, which is not a takeover: resuming would push an empty `Resume` commit onto
    a branch whose pull request is open — the 2026-08-01 gate exactly. The 2026-08-19 split went
    `resumable: true` because its unit had never reported and the takeover had real work to do
    (write the story, open the pull request); this one has already done both. `claim.sh resume`
    refuses it under its own name rather than `queue_drained`'s wording, which would send the
    reader to wait for a human who is not coming.
  - **And a *reported* unit with work left is two states as well** (2026-08-27, mission
    `stop-re-resuming-a-declared-handoff-unit`). `parked_with_pr`'s own contract says *the
    follow-up tickets on its branch are why it still has work. Taking it over is legitimate* —
    and that sentence is **false by declaration** for a unit whose remaining queued work carries
    `verification_handoff:`. §6 routed it to the **handoff** route precisely because nothing
    unattended can finish it, leaving the pull request open and the claim standing on purpose;
    the oracle then offered the takeover anyway, on every tick. Measured on PR #647: routed at
    02:14 UTC, taken over again at 06:43 for nothing. The new verdict is
    **`awaiting_verification`**, excluded `claimed_awaiting_verification`, `resumable: false`,
    and it does **not** forbid `ok`.
    **A sibling word, not a narrowed `parked_with_pr`**, on the `report_undelivered` precedent:
    the two states call for different next actions — take it over versus satisfy the declared
    verification — and one word answering both is what made this invisible. `claim.sh resume`
    refuses it under its own name; refusing under `queue_drained` would send the reader to wait
    for a merge that is not what is owed.
    **Nothing new is derived, and no artifact gained a field.** `verification-handoff.sh` already
    reads the declaration and stays its only reader: `claims_declared_handoff` materialises the
    tip-side blobs of the unit's still-queued work — plus the mission's own `mission.md`, since
    any member declaring it carries the whole unit — and hands them to that script. The set comes
    from `claims_remaining_tickets`, the walk `claims_has_work` already made, lifted out so the
    two readings cannot answer from two different ticket sets.
    **It releases itself.** The declaration is read from the work still *queued*, never the
    archived work, so driving that ticket makes the same reader answer `false` and the unit reads
    `parked_with_pr` or `queue_drained` again — no stored state, no cursor to reset. `superseded`
    keeps its precedence over it: a claim proved empty is still superseded, whatever it declares.
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
or `claim_active` / `superseded` / `awaiting_verification` / `queue_drained` /
`report_undelivered` / `foreign_identity` / `identity_unresolved` / `shallow_history`. Each row
also carries `declared_handoff`, whether the work this claim still has **queued** was declared
unverifiable here — read through the one script that owns `verification_handoff:`, from the
branch tip, with no network call.

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

## Proofs and judgements

**A consumer may _act_ on a proof. A consumer may only _report_ or _ask about_ a judgement.**

`lib/claims.sh` emits a word per reading, and two of those words are **proofs** — a reading the
tree or a merged pull request established, which cannot become false by somebody looking again.
Every other word is a **judgement**: a reading that says *look at this*, whose next step belongs
to a person or to a takeover. Nothing wrote that distinction down until 2026-08-27, so each
consumer that wanted to act on a verdict re-derived which words were safe — and two copies of a
rule are how the rule drifts. The table is the one source; a consumer keys on the word
`lib/claims.sh` already emits, and **no artifact gained a field and no script gained a
classifier** — a function returning `proof`/`judgement` would be a second derivation of the
same fact, which is exactly what this exists to prevent.

### The resumability verdict (`resume_reason`, one per claim row)

| Word | Class | What established it, and what a consumer may do |
| ---- | ----- | ----------------------------------------------- |
| `superseded` | **proof** | Every one of the unit's tickets is archived on the base, or a **merged** pull request has this branch as its head. The claim's content reached the base by another route, so the branch can never land and holds no work. A consumer may **act**: resurvey the work behind it (`plan-units.sh`), claim over it (`claim.sh`), retire the claim itself. |
| `report_undelivered` | **proof** | The run that drove this unit recorded `merge_refused: <word>` into its own branch story (`record-merge-outcome.sh`). The unit is finished, pushed, at an open pull request, and the **transport** — not a person — is what stopped it. A consumer may **act**: re-attempt the merge through the seam that refused it. |
| `heartbeat_lapsed` | judgement | The tip has not moved inside the heartbeat window. It says a run *probably* died; it does not prove one did. Offered as a takeover, which the runner decides — never acted on by anything else. |
| `report_incomplete` | judgement | The queue is drained with no story at the tip: the run *probably* died between §4 and §5. Same standing as `heartbeat_lapsed` — a mandatory **takeover offer**, not a licence to close, delete or merge anything. |
| `parked_with_pr` | judgement | Reported and pushed, with work still on the branch **that nothing declared unverifiable here**. A human is the next step; a takeover is legitimate but never forced. |
| `awaiting_verification` | judgement | Reported and pushed, with work still on the branch that was **declared** unverifiable in an unattended environment at creation (`verification_handoff:`). Classifying it a *proof* is the tempting error — the declaration is read straight off the tree, which looks like the property `superseded` has. It is not: a proof is a reading that **cannot** become false by looking again, and this one is designed to, because driving the declared ticket releases it. So a consumer may only **report** it, and decline to offer the takeover; nothing closes, deletes, merges or retires on it. |
| `queue_drained` | judgement | Reported, pushed, at an open pull request, with **no** recorded merge refusal. It means *waiting on a person*, and an absent merge-outcome section keeps it — the reading is claimed only on positive evidence, so a consumer must not read it as "delivered" or as "refused". Report it; a person merges. |
| `claim_active` | judgement | The tip moved inside the heartbeat window: another run is *probably* still driving. Wait — never take over, never retire. |
| `stale` | judgement | Not a `resume_reason` but a boolean beside it (`WORKAHOLIC_CLAIM_STALE_HOURS`, default 24). It has been **reported, never acted on** since the protocol shipped and stays that way: a tip older than the threshold says *look at this*, not *take it*. `/moderate`'s `stalled-units` step asks a person about it, which is the only thing a judgement licenses. |
| `foreign_identity` | judgement | The claim commit's author is not this runner. Untouchable at any age — a refusal, and the safest kind, since it rests on somebody else's live work. |
| `identity_unresolved` | judgement | This runner has no identity to compare against. The **absence** of a reading; every consumer refuses. |
| `shallow_history` | judgement | The scan ran over truncated history, so the branch may already be merged and simply unprovable here. Also the absence of a reading: the verdict is suppressed at the one point where the *input*, not the unit, is the problem. |

### The merged-pull-request lookup (`claim-merged.sh`)

| Word | Class | What established it, and what a consumer may do |
| ---- | ----- | ----------------------------------------------- |
| `merged` | judgement | An **input** to `superseded`, never a verdict a consumer acts on directly. Reading it straight would be the second derivation the split exists to prevent: take `superseded` off the row. |
| `not_merged` | judgement | Same standing, the other way. It leaves the row whatever verdict the local reading gave it. |
| `unanswerable` | judgement | **The absence of a reading, and acting on an absence is the failure the three-valued lookup exists to avoid.** It leaves the row precisely the verdict it would have had without the lookup, and is named in `merged_lookup_unanswered` instead. The direction of failure is chosen: a wrong `merged` releases work still in flight, a wrong `in flight` only delays a claim. |

### Resolving a unit to one row (`claims_unit_resolution`)

A different axis: these words say **which row a writer may read**, never whether a unit's work is
finished. None is a proof, and a consumer that acts on one is acting on the *row's* verdict, not
on the resolution word.

| Word | Class | What established it, and what a consumer may do |
| ---- | ----- | ----------------------------------------------- |
| `none` | judgement | No claim in flight for this unit. Proceed on the unit's own state. |
| `single` | judgement | Exactly one claim, whatever its verdict — byte-identical to the first-match lookup this replaced. Act on **that row's** verdict, per the table above. |
| `live` | judgement | One live claim beside one or more superseded ones. The live row wins; act on **its** verdict. |
| `superseded_only` | judgement | Every claim for this unit is superseded, and the first is returned — so a caller keeps refusing under `superseded` exactly as it did before. |
| `ambiguous` | judgement | Two or more live claims (`ambiguous_claim` where a caller reports it). **Reported, never picked between**: the protocol settles a race by the push, so this cannot arise from the sanctioned path, and choosing silently is how a runner would resume — or discard — work another run is still driving. Refuse and name both branches. |

**Its two consumers read this table rather than restating it.** The delivery retry acts on
`report_undelivered` and no other word; the retirement writer acts on `superseded` and no other
word. `scripts/test-workflow-scripts.mjs` fails when the table and either consumer disagree
about a word, or when a consumer acts on one classified `judgement` — the split is a fact a
change can lose, not a claim in prose.

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

## Retire a claim proved empty

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/retire-claim.sh <unit-id>
```

The **one** writer of a claim's retirement, and the second consumer of the proof/judgement table
above. Given a claim the oracle proved **`superseded`**, it closes the pull request, deletes the
remote branch and reaps the worktree — three acts, each reporting its own word. Emits
`{retired, unit, branch, pull_request, pull_request_closed, remote_branch_deleted,
worktree_reaped, reason}` and **always exits 0**: a refusal is an answer, and its caller reports
it rather than dying on it.

`superseded` has been *reported, never acted on* since it shipped, and that left the claim table
only ever growing — measured on this repository on 2026-08-27: 7 claims, **4 of them
`superseded`**, two naming missions archived days ago, the oldest branch last touched 2026-08-21.
What changed is not the verdict's standing but that one act now follows from it; nothing else
about `superseded` moved.

**It acts on the proof and refuses every judgement by its own name.** `not_superseded:<verdict>`
carries the verdict word itself, so `stale`, `queue_drained` and `claim_active` are each visible
as what they are rather than folded into a generic denial — acting on any of them is how a runner
tears down work somebody is still driving. **`ambiguous_claim`** is its own refusal (two live
claims cannot arise from the sanctioned path, and picking one silently is the failure), and
**`unanswerable:<reason>`** is its own refusal too: a branch whose merged-pull-request lookup
came back unanswerable kept the verdict it would have had without the lookup, and naming the
local verdict there would send a reader to a claim that looks live instead of to the lookup that
failed.

**The unit resolves through the live-row rule, never first-match.** A unit held by a `superseded`
branch *and* a live one is exactly what a fresh claim over a superseded one creates, and
`claims_scan` walks refs in name order — so first-match is the oldest. Here that is the dangerous
direction: it would retire whichever branch sorted first regardless of which is alive.
`claims_unit_resolution` / `claims_unit_row` are the shared derivation, so the survey's offer,
`claim.sh`'s refusal and this retirement cannot disagree about which branch a unit is.

**Order: close, delete, reap** — the reverse of `release-claim.sh`'s, on purpose. That script
tears the worktree down first because it discards *unfinished* work and must not publish "this
unit is free" over unpushed commits. Here there is no such work by construction, and the local
reap is the one step refusable for a reason outside this runner's control (the sanctioned cleaner
refuses a dirty tree, and must). Putting it last leaves a refusal there with both **remote** facts
already correct, and a re-run finishes the job.

**Every step is idempotent, and each says which kind of success it had.** An already-closed pull
request (`already_closed`), an already-deleted branch (`already_gone`) and an absent worktree
(`absent`) are real successes, not degradations. A step that fails is named and the other two are
attempted on their own merits — the three acts are independent, so one failure is no evidence
about the others. A **refusal** reports `not_attempted` for all three rather than `failed` or
`absent`: those are findings about the world, and a gate that never ran made no finding.

**How reversible each act is**, stated rather than assumed: a closed pull request is reopenable
with its review history intact; a deleted remote branch is recoverable from the base's own history
(its content *is* on the base — that is what `superseded` means) and from any clone's reflog; the
worktree is local and `claim.sh resume` rebuilds one at a branch tip. None of the three destroys
work — a property of acting only on the proof, never a licence to widen the verdict set.

**It merges nothing, pushes into no branch, and touches no `.workaholic/` artifact.** Its only
writes are one REST `PATCH` closing a pull request and one branch delete: no commit anywhere, no
mission closed, no ticket moved, no story edited. Run it from the main checkout — git cannot
remove the worktree you are standing in.

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
