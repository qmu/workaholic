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
    branches), and choosing silently is how a runner would resume — or discard — work another
    run is still driving. **This paragraph used to add *the protocol settles a race by the
    push, so the state cannot arise from the sanctioned path at all*, and that half was
    false** (2026-08-30, mission `stop-two-runs-from-claiming-and-driving-one-unit`) — see
    *What the claim contends for* below. The refusal does not move; only its justification
    does, and it moves in the direction that makes it MORE necessary rather than less. `plan-units.sh` reads the same resolution: its
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
  - **A handoff blocked on an operator RULING has the same cost and no signal to read, and that
    is a finding rather than a repair** (2026-08-31, ticket
    `20260831024448-stop-re-resuming-a-handoff-blocked-on-a-ruling`). A unit that took the
    **half-driven** handoff route because its remaining work waits on a ruling reads
    `parked_with_pr`, `resumable: true`, and is offered as a takeover by every later survey. The
    takeover can drive nothing — the ruling is the blocker and `/implement` may neither ask for
    it nor make it — so each run pushes one empty `Resume a PR-unit` commit onto a branch whose
    pull request is already open and reports the unit blocked again. **Measured** on
    `work-20260830-124234` (PR #755, mission `stop-two-runs-from-claiming-and-driving-one-unit`):
    **eight** consecutive takeovers between 2026-08-30 13:42 and 2026-08-31 15:5x UTC, zero lines
    of implementation across all of them. It is `claimed_awaiting_verification`'s shape one state
    over, with no declaration for the oracle to read.
    **No existing signal carries both halves of what a sibling word would need**, and the halves
    are the pre-drive property (`awaiting_verification` is safe because the declaration is on the
    artifact *before* the drive, so a run can never write it for its own unit) and the meaning:
    - The branch story's **`## Handoff`** section is present by construction on exactly this
      route, and is written by the run *about its own unit* — the self-certifying evidence the
      2026-08-23 Open Decisions rule refuses by name. It is also present on **every** half-driven
      handoff, including one another session could legitimately continue, so a verdict keyed on
      it would withhold takeovers from drivable units.
    - A **`blocked` stamp** on the remaining queued tickets does not exist, and minting one is
      the field on an artifact this repository refuses by name.
    - An **`## Open Decisions`** item does carry the pre-drive property — `/specificate` writes
      it at creation, `/ticket` never writes one, and no driving run writes one — but it does not
      *mean* the work is blocked: the driving floor (`reference/ticket-workflow.md` §1) requires
      a run to **resolve** each item, so a ticket carrying one is ordinarily drivable. Keying on
      it would withhold the takeover from exactly the units a run is supposed to drive, and the
      measured unit carries none, so the reading would not reach the case it was written for.
    So the ticket's own step 3 fires — *record that finding and stop* — and **the verdict is left
    alone**: no word added, no verdict widened, no field on any artifact, `claim.sh resume` and
    `plan-units.sh` byte-identical. The cost of the status quo is bounded and visible (one empty
    commit an hour, no work lost, no gate overridden), and a repair that stranded a genuinely
    drivable `parked_with_pr` unit would be worse than the defect.
    **What would carry both halves already exists, at the writing seam rather than the oracle**:
    `verification_handoff:`, which `/specificate` declares for an **unresolved operator-only fork
    that survived the operator-record check** (2026-08-23, issue #83). A ticket whose completion
    waits on an operator's ruling *is* that case, and declared at creation it reads
    `awaiting_verification` through the reader that already exists — no new word, no new signal,
    nothing stored. The repair for this class is therefore a writer's, and a run may never make
    it for its own unit, which is the whole reason the property is worth keeping.
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
| `superseded` | **proof** | Every one of the unit's tickets is archived on the base (or a **merged** pull request has this branch as its head) **and the branch is empty against the base** — `claims_branch_empty_against_base`, one `merge-base` and one `diff --quiet`, no network (2026-09-01, issue #788). The claim's content reached the base by another route, so the branch can never land and holds no work. A consumer may **act**: resurvey the work behind it (`plan-units.sh`), claim over it (`claim.sh`), retire the claim itself. |
| `stranded` | judgement | The unit's tickets are archived on the base while the branch **still holds content found on no other ref**, or the emptiness could not be read. **Measured 2026-09-01**: two branches whose tickets landed through *different* branches still carried ~300 lines of code and a documentation section, and the tick was asking for both to be deleted; the stated recovery — *its content is on the base, that is what `superseded` means* — was false for exactly the branches it was protecting, and only a 403 on `push --delete` had prevented the loss for five days. It is **never** a retirement candidate, never enters `resurveyed[]`, and never licenses a delete: `retire-claim.sh` refuses anything but the word `superseded`. `/moderate`'s `retire-claims` step asks its holder what should happen to the work — landed, or discarded deliberately — and never suggests deleting the branch. An unanswerable emptiness answers `stranded` for the reason this protocol answers every absence of a reading that way: it does not license the act. |
| `report_undelivered` | **proof** | The run that drove this unit recorded `merge_refused: <word>` into its own branch story (`record-merge-outcome.sh`). The unit is finished, pushed, at an open pull request, and the **transport** — not a person — is what stopped it. A consumer may **act**: re-attempt the merge through the seam that refused it. |
| `heartbeat_lapsed` | judgement | The tip has not moved inside the heartbeat window. It says a run *probably* died; it does not prove one did. Offered as a takeover, which the runner decides — never acted on by anything else. |
| `report_incomplete` | judgement | The queue is drained with no story at the tip: the run *probably* died between §4 and §5. Same standing as `heartbeat_lapsed` — a mandatory **takeover offer**, not a licence to close, delete or merge anything. |
| `parked_with_pr` | judgement | Reported and pushed, with work still on the branch **that nothing declared unverifiable here**. A human is the next step; a takeover is legitimate but never forced. |
| `awaiting_verification` | judgement | Reported and pushed, with work still on the branch that was **declared** unverifiable in an unattended environment at creation (`verification_handoff:`). Classifying it a *proof* is the tempting error — the declaration is read straight off the tree, which looks like the property `superseded` has. It is not: a proof is a reading that **cannot** become false by looking again, and this one is designed to, because driving the declared ticket releases it. So a consumer may only **report** it, and decline to offer the takeover; nothing closes, deletes, merges or retires on it. Its one enumerated **reporting** consumer is `/moderate`'s `step-handoff-units.sh`, which asks the claim holder to run the declared verification and does nothing else. |
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
| `ambiguous` | judgement | Two or more live claims (`ambiguous_claim` where a caller reports it). **Reported, never picked between**: choosing silently is how a runner would resume — or discard — work another run is still driving. Refuse and name both branches. This row read *the protocol settles a race by the push, so this cannot arise from the sanctioned path* until 2026-08-30; it can, and does (*What the claim contends for*, below). |

### The base's own checks (`read-base-checks.sh`, `attribute-base-red.sh`)

A **second vocabulary in the same home** (2026-08-27, mission
`read-whether-the-base-survived-what-the-loop-merged`). The tables above are keyed on the claim
protocol's `resume_reason`; this one is keyed on what the base's checks said about a commit. One
section, two keyed tables — opening a second document would be the second home the whole split
exists to prevent, and folding the two into one table would key two different questions on one
column.

**There is no proof in this vocabulary, and that is the point.** A check run is *designed* to be
re-runnable, so every reading here can become false by somebody looking again — which is exactly
the property a proof must not have. The tempting error is to call `red` a proof because it is read
straight off GitHub; `awaiting_verification`'s row above records the same trap for the claim
vocabulary, and the answer is the same: read-straight-off is not the test.

| Word | Class | What established it, and what a consumer may do |
| ---- | ----- | ----------------------------------------------- |
| `green` | judgement | Every completed check on the commit succeeded (or was neutral/skipped) and none is pending. A re-run, a re-triggered workflow or a newly required check can turn it `red`, so it proves nothing durable. **Report it.** It licenses no merge, no release and no skipped gate — the `release/*` QA window still owns quality. |
| `red` | judgement | A completed check on the commit concluded in failure. It says *look at this*, not *this commit is bad*: a re-run can turn it green, and the failure may be in infrastructure rather than in the change. A consumer may **report** it and **ask about** it — `/moderate`'s `base-health` step asks the attributed author. Nothing may revert, re-run, block, gate, hold or merge on it. |
| `unattributable` | judgement | The base is red and the walk could not name the merge that broke it — its bound was exhausted, it reached the start of history, or a commit inside the walk was unreadable. **Never the tip by default**: blaming the head because the walk ran out of room is the failure this word exists to prevent. Report it, ask about it, name the reason. |
| `unanswerable` | judgement | The **absence** of a reading — no `gh`, a refused transport, a rate limit, an unparseable response, a commit with no checks at all, checks still running. Acting on an absence is the failure the three-valued shape exists to avoid, and the direction of failure is chosen: it must never be reported as `green`, because a base nobody looked at would then be indistinguishable from a base that passed. |

**Its consumers report and ask, and nothing else.** `/moderate`'s `base-health` step hands a red
base to the check-in as one question and writes nothing but its own tick-log line; the driving
run names the reading at the top of its report and **gates nothing** — no stop, no skip, no hold,
and the terminal token is byte-identical on a red base and a green one (`workaholic:drive` §1 and
§7). `scripts/test-workflow-scripts.mjs` pins this table the way it pins the one above: it fails
when a word either script emits is unclassified, when the table classifies a word neither emits,
when any row is called a `proof`, or when a consumer reaches an acting call site.

**Its two consumers read this table rather than restating it.** The delivery retry acts on
`report_undelivered` and no other word; the retirement writer acts on `superseded` and no other
word. `scripts/test-workflow-scripts.mjs` fails when the table and either consumer disagree
about a word, or when a consumer acts on one classified `judgement` — the split is a fact a
change can lose, not a claim in prose.

### Whether a claim branch holds work of its own (`claims_branch_emptiness`)

**A reading, not a verdict word.** It adds no row to the resumability table and is emitted by
nothing: `claims_superseded` composes it, and what a consumer sees is `superseded` or
`stranded`. It is recorded here because it is the term that makes those two words mean what
they say (2026-09-01, issue #788), and because a later change that removed it would leave the
verdict asserting a fact nobody reads.

`claims_branch_emptiness <base> <ref> [files]` prints one tab-separated line —
`<verdict>\t<reason>\t<count>\t<bounded comma-joined file list>` — and
`claims_branch_empty_against_base` is the thin wrapper every existing caller reads, returning
the first field alone.

| Value | Meaning |
| ----- | ------- |
| `true` | the branch's diff against its merge base with the base is empty **outside `.workaholic/`**. The exclusion is the whole precision of the test: the ordinary `superseded` shape is a twin branch that archived the same tickets under its own `archive/<branch>/` directory, so a bare diff would call every genuinely superseded claim stranded |
| `false` | the branch carries content the base does not have, with the **true count** and the first `WORKAHOLIC_CLAIM_STRANDED_FILES_MAX` (default 5) names. A branch differing in a thousand files reports a count and a few names, never a thousand names into a question |
| `unknown` | the reading could not be made: `no_args`, `no_ref`, `no_base_ref`, `no_merge_base` (a shallow clone or an unrelated history), `diff_failed` (git itself failed — `git diff --quiet` exits 1 for *differs* and >1 for *failed*, and collapsing the two would report a git error to a person as "this branch holds work") |

**Cost, measured 2026-09-02** on a throwaway repository, 50 readings of a non-empty branch:
373 ms for the raw derivation, 553 ms through the wrapper, **1484 ms with the file listing**.
So the listing is **opt-in** — the verdict path runs once per claim per scan and never needs
it, and only the one consumer that must NAME the files asks.

**Consumers.** `claims_superseded` (the word, at both grains — the whole of the safety
property); `list-claims.sh` (the word plus the files, for a `stranded` row alone, on
`claim-mergeability.sh`'s own precedent that the one consumer which must name something reads
it from the row rather than calling the reader a second time);
`delete-retired-claim-branch.sh` (the word, re-derived at the moment of the act, as
`branch_holds_work` / `emptiness_unanswerable`). Nothing else may read it, and nothing may act
on `unknown`: an absence of a reading licenses no delete.

#### What the narrowing did to every consumer of `superseded`

Narrowing a proof does not delete the rows it stops covering — they become **something else**,
and the risk of the change lives there rather than in the diff term. Every consumer was walked
when the term landed (2026-09-01, issue #788) and the walk is recorded here rather than
re-derived, because a later consumer must be added to this table rather than discovered by a
reader wondering what happens to it. Hermetic rows pin the ones with observable behaviour
(`scripts/test-workflow-scripts.mjs`, *drive: superseded narrowed to a branch that is actually
empty*).

| Consumer | Under `superseded` | Under `stranded` |
| -------- | ------------------ | ---------------- |
| `claim.sh` | the row is **stepped over**, so a fresh claim over proved-empty work goes through | refuses `already_claimed`, unchanged. The branch still holds work nobody has ruled on, so claiming over it would strand that work behind a second branch |
| `plan-units.sh` | the unit's work is named in `resurveyed[]` and driven again | excluded **`claimed_stranded`**, and it enters `resurveyed[]` **never** — re-driving the tickets would put a second copy of the work in flight beside the copy already orphaned |
| `list-retirable-claims.sh` | a `superseded_only` candidate | **no candidate**, so neither `retire-claim.sh` nor `delete-retired-claim-branch.sh` is ever handed it |
| `retire-claim.sh` / `delete-retired-claim-branch.sh` | act, re-deriving the proof at the moment of the act | refuse by their own word — `not_superseded:stranded` on the act, `branch_holds_work` / `emptiness_unanswerable` where the emptiness is a gate rather than the row's own evidence |
| `retry-undelivered.sh` | refuses `not_undelivered:superseded` | refuses `not_undelivered:stranded` — one rule, one word each, nothing special-cased |
| `catch-up-claim.sh` | not offered (`list-catchable-claims.sh` takes only `report_undelivered` and `queue_drained`) | not offered either, and it carries **no `stranded` bound of its own** — stated rather than implied. That is safe because its act merges the base *into* the branch and pushes; it deletes nothing, so a stranded branch reached by a hand invocation would be brought forward, never lost |
| `/moderate` `retire-claims` | hands the row to `retire-claim.sh` | **asks its holder** (`stranded-unit:<unit>`) what should happen to the work, and never suggests deleting the branch |
| `/moderate` `stalled-units` | filters and counts it | filters and counts it, on the same pairing rule — one step asks and the other filters, and either half alone is a defect |
| `/implement` §7's token | `superseded` does not forbid `ok` | `stranded` does not forbid `ok` either: the branch holds work, but nothing this run drove, and the person who must rule on it is reached by the question above rather than by a token nobody reads |

### Whether the base still accepts a claim branch (`claim-mergeability.sh`)

A **third vocabulary in the same home** (2026-08-29, mission
`land-the-loop-s-own-work-when-the-base-moves-under-it`), keyed on what the *base* says about a
branch rather than on whose business the claim is. It is rendered on every claim row as
`mergeability` / `mergeability_reason`, beside `resume_reason` and never instead of it: *is this
claim somebody's to take* and *does the base still accept it* are different questions, and one
column answering both is how two readings drift.

**There is no proof in this vocabulary either.** A base that moves is precisely a reading that
becomes false by looking again — the one property a proof must not have — so no consumer may
merge, revert, gate or release on it. `catch-up-claim.sh` re-derives its own answer at the
moment of its act rather than trusting a list it was handed, which is the discipline
`delete-retired-claim-branch.sh` already carries across an executor boundary.

| Word | Class | What established it, and what a consumer may do |
| ---- | ----- | ----------------------------------------------- |
| `clean` | judgement | `git merge-tree` produced no conflict at all — computed with the repository's own `.gitattributes` **out of reach**, because git reads merge attributes from the working tree and GitHub applies none of them when it answers `mergeable` (2026-09-01, ticket `20260901041500`: five publications read `clean` here and `dirty` there, and the loop was refused `merge_not_allowed` every hour). It says the merge *would* apply as of this read; the base moves every half hour, so it proves nothing durable. **Report it**; the catch-up re-derives it before acting. |
| `mechanical` | judgement | Every conflicted path is one the shared rule (`ship/scripts/lib/conflict-class.sh`) can settle without a judgement: an append-only `.workaholic/` tail, a version/lockstep manifest, or generated output — including an OKF index, wholly generated or generated-inside-its-markers. A consumer may **act** on it only under *When a bounded act may read a judgement* below, which is where that exception and its enumerated consumers live; nothing acts on the word itself. |
| `content` | judgement | Some other path conflicts. This is a **prediction that the merge will need a judgement**, not a finding that it does — since 2026-09-02 the catch-up and the publication act **attempt** it and let the writer decide (below). What refuses is the writer's own residue, still `content_conflict`, still writing nothing, and it is **reported by the act** rather than asked about (`catchup-blocked` retired 2026-09-02). **A hunk the merge cannot settle is never resolved by a machine.** |
| `unanswerable` | judgement | The **absence** of a reading — no merge base, truncated history, an unreadable ref, a git without `merge-tree --write-tree`. It must never be reported as `clean` and never collapse into `content`: a wrong `clean` pushes a merge nobody proved, a wrong `content` only delays a unit. Named with its own reason and left alone. |

#### The resolution strategy, per class

**Written down before it was written** (2026-09-02, mission
`resolve-a-conflicted-pull-request-in-the-tick-not-report-it`, ticket
`20260902042630-let-the-tick-resolve-a-content-conflict-not-defer-it`, step 2). The operator's
correction was that the tick "only spews reports and shows no sign of resolving anything" and
that deferring a conflict to a claim holder is *completely wrong* — a claim holder never comes.
What follows is the whole of what the loop decides and the whole of what it hands over, so a
reader can argue with the rule rather than reverse-engineer it from four scripts.

| What conflicts | Who resolves it, and how | Can behaviour be lost? |
| -------------- | ------------------------ | ---------------------- |
| **Generated output** (`outputs/*`, the three wholesale OKF indexes) | The merge takes **either side** and the caller then **re-derives the file from the merged source** (`refresh-index.sh`, `build.mjs`). Which side won is immaterial by construction — that is what *generated* means. | **No.** The output is a function of the merged input, and the input merged without conflict. |
| **A flat area's `index.md`** whose generated region is the only difference | Same: take a side, re-derive the region. The proof that nothing outside the `okf:generated` markers moved is `conflict_class_generated_region`'s, and a hand-authored index with no markers is not this row. | **No**, and the proof is what makes it so — a person's prose outside the region is byte-identical on both sides or this row does not apply. |
| **A version/lockstep manifest** | The **higher semver** wins and the rest of the file merges normally, because this repository's own rule is that every one of those files carries the same version. | **No.** The collision is on the version and on nothing else. |
| **An append-only `.workaholic/` tail** (two branches each appending, e.g. a `## Changelog` line) | **Keep both.** The proof is that the merge base is an exact line-prefix of both sides, so nothing existing was modified or removed. Bounded to `.workaholic/` on purpose: appending is evidence of independence in a *log*, and two branches appending a function to a source file have the same shape and a real decision behind it. | **No.** Nothing that existed changed; the shape proof is self-verifying and every failure mode answers *no*. |
| **A path the repository declared `merge=union`** | **git's own driver**, in the writer's real checkout. The loop does not choose this — the repository committed the attribute (`/workaholify` §1, `index_merge_union`). The union's known cost is a duplicated or mis-sorted line, and it is **repaired**, not shipped: the regeneration step above rewrites the file from the tree. | **No**, given the regeneration. Without it this row would not be admissible. |
| **A genuinely divergent hand-written hunk** | **Nobody here.** The act refuses `content_conflict`, pushes nothing, leaves the branch byte-identical, and the claim holder is asked by `/moderate`. | — the residue exists precisely so the answer above is always *no*. |

**The tick decides by attempting, not by predicting.** `claim-mergeability.sh` is a *reader*: it
computes `git merge-tree` from an empty directory with `GIT_DIR` set so the repository's
`.gitattributes` is out of reach, because its job is to predict **GitHub**, which applies no
merge driver. The writer merges in a real checkout where those drivers are in force. The reader
is therefore **pessimistic by construction** against the writer, and refusing on its `content`
declined branches the writer would have finished. So `catch-up-claim.sh` and
`settle-stranded-publication.sh` now accept a `content` prediction as a **candidate**, and the
refusal moved to the one place that actually knows: the writer's residue.

**What did not move.** `conflict_class.sh` is untouched — no new path is called mechanical, and
no judgement was reclassified. `unanswerable` keeps its refusal on both paths, because it is the
**absence** of a reading and acting on an absence is what a three-valued word exists to prevent.
The fast checks still gate every push and still refuse `validation_failed:<check>` with nothing
pushed. A colleague's claim is still untouchable, a live claim is still left alone, and a
scan-held pull request is still refused `scan_held:<tier>`. **No second merge engine exists**:
both acts compose `catchup-main.sh`.

**A branch nothing has attempted is not the same finding as one the loop looked at.** That is
the whole reason `content` is a reading rather than a bare *conflicted* boolean:
`/moderate`'s `merge-conflicts` step reports a pull request GitHub calls conflicted — *nobody
has looked yet* — while the catch-up **attempts** a branch this rule classified — *the loop
looked and only you can decide*. One unit never draws both: `merge-conflicts` counts what
the catch-up attempts, in the same shape `stalled-units` counts what `handoff-units`
asks about.

### Whether an act the loop took had its effect (`ci-retirement-turn.sh`)

A **fourth vocabulary in the same home** (2026-08-29, mission
`read-back-whether-the-loop-s-own-act-took-effect`). The three tables above are keyed on what is
true of a *claim* — whose business it is, what the base's checks said, whether the base still
accepts its branch. This one is keyed on a different question again: **did an act this loop
performed actually happen?** One column cannot classify four questions, and a second document
would be the second home the split exists to prevent.

**Why the question needed a vocabulary at all.** Every reading in this repository answered *what
did I find*; none answered *did what I did happen*. Measured 2026-08-29: `claim-retirement.yml`
was green on every run while three proved-`superseded` claims stood on origin, and the tick log
recorded, hour after hour, *"ci_turn: taken so CI could not take the delete either"* — an
assertion about a second executor that **nothing established**. `ci-retirement-turn.sh` answered
`taken` from a completed run's *existence*, which is a proxy for the act and not the act. The
turn now records what it attempted (`record-ci-retirement-turn.sh`) and this reading answers from
that record.

**There is no proof in this vocabulary either, and the reason is stronger here than anywhere
else.** A workflow run is re-runnable, a branch can be deleted or restored between two reads, and
the record is a projection of a run somebody can re-trigger — so every reading here can become
false by looking again, which is the one property a proof must not have. **No consumer may
revert, re-run, block, gate, hold or merge on it.** The one licence it carries is narrower than
*report and ask*: it may **hold a question**, and only on `taken` or `pending`.

| Word | Class | What established it, and what a consumer may do |
| ---- | ----- | ----------------------------------------------- |
| `taken` | judgement | Per unit: the act's own **success** word (`deleted`, or `already_gone` — the branch was not there when CI looked, the same outcome). At the run level it means only *CI had its turn and we can see what it did*, never that any act succeeded. A consumer may **hold** this unit's question, because nothing is owed. |
| `refused` | judgement | Rendered `refused:<word>`, carrying `delete-retired-claim-branch.sh`'s own refusal verbatim — or, where the turn's candidate reading was itself degraded, that reading's reason. Never a third vocabulary: a reader must be sent to a word some script actually printed. It **holds nothing**: this is precisely the case a person must hear about. |
| `pending` | judgement | No completed run at this tip yet — the push is in flight, or the run is still going. CI may still take the act, so the question is **delayed for this tick only**. The asked-once ledger keys on the unit, so a branch that outlives CI's turn is asked about later. |
| `unavailable` | judgement | The workflow is not present in this repository at all, so CI will never take the act. The unit is blocked exactly as it was before this reading existed, and the question **stands**. |
| `unreadable` | judgement | A run completed and we cannot say what it did — the record is absent, unparseable, past its truncation bound, or names this unit nothing while the candidate reading itself was fine. The **absence** of a reading, and it **holds nothing**: an over-eager question is better than a silently dropped one, and this repository has measured the cost of a blocked act nobody was told about. |

**Its one enumerated consumer is `/moderate`'s `step-retire-claims.sh`**, which removes a unit
from its own question set on `taken` or `pending` and does nothing else with any word. It never
re-runs a workflow, never re-attempts a delete on the strength of a reading, never releases a
claim and never reopens a pull request. `scripts/test-workflow-scripts.mjs` pins this table the
way it pins the three above: it fails when a word the reader emits is unclassified, when the
table classifies a word the reader never emits, when any row is called a `proof`, or when the
consumer reaches an acting call site.

### Whether an operator-facing pull request was acted on (`publication-effect.sh`)

A **fifth vocabulary in the same home** (2026-08-29, mission
`follow-the-pull-requests-the-loop-opens-for-a-person`). The four tables above are keyed on what
is true of a *claim*, of the *base*, or of an act *this loop* took. This one is keyed on the act
the loop takes **on the operator's behalf**: `publish-tree-pr.sh` refuses to auto-merge a ruling
or a strategy publication — because *merging is the ruling and closing is the refusal* — and
then somebody has to rule. One column cannot classify five questions, and a second document
would be the second home the split exists to prevent.

**Why the question needed a vocabulary at all.** Having opened the diff, the loop stopped
following it. No claim-side verdict could see it: a publication carries **no claim** at all
(`publish-tree-pr.sh` pushes `publish-main` to a `work-*` name with no `Claim` commit), and
`stuck-prs` and `merge-conflicts` find the pull request perfectly healthy — it is not stuck, it
is **waiting**, which is what it was opened to do. Measured 2026-08-29: #694 sat 18 hours
unanswered.

**There is no proof in this vocabulary either, and the reason is the plainest of the five.** A
pull request is *designed* to change state — anybody can merge it, close it, or reopen it
between two reads — so every reading here can become false by looking again, which is the one
property a proof must not have. **No consumer may merge, close, revert, re-run, block, gate,
hold work or lift a gate on it.** The licence is to **report and to ask**, and nothing else.

| Word | Class | What established it, and what a consumer may do |
| ---- | ----- | ----------------------------------------------- |
| `merged` | judgement | `merged_at` is set: the operator ruled, and the ruling landed. **Settled** — it draws no question. A consumer may only report it. |
| `closed` | judgement | The pull request is closed and was never merged: the operator **refused**, which is a real answer and not an omission. Settled, and never rendered as *merged* — the two ask a reader for opposite things. |
| `open:<age>` | judgement | Rendered with the age in hours from `created_at`, or `open:unknown` when only the clock arithmetic failed (the state is still honestly open). **This is the one word that draws a question**, addressed to the operator, keyed `operator-pull:<number>` so one pull request costs exactly one question however many ticks see it. |
| `unreadable` | judgement | The transport, the slug or the pull request could not be read (`gh_unavailable` / `read_failed` / `not_found` / `jq_unavailable` / `no_pull_number`), carrying a named reason and a **null** age — never a zero, which reads as *just opened* and would make a read we could not make the loudest answer in the set. The **absence** of a reading: it draws **no question** and is counted in the summary, `strategy-pace`'s rule that a person's attention is not spent on our own degradation. |

**Its enumerated consumers are two.** `/moderate`'s `step-operator-pulls.sh` **asks** — one
question per `open:<age>` reading and nothing else: it merges nothing, closes nothing, comments
on nothing, holds no work and lifts no gate. `/implement`'s and `/propose`'s run reports
**report** — once per run, as evidence, in the voice `pace`, `overdue` and `expiring` already
use; the reading **moves no token** and gates nothing. `scripts/test-workflow-scripts.mjs` pins
this table the way it pins the four above: it fails when a word the reader emits is
unclassified, when the table classifies a word the reader never emits, when any row is called a
`proof`, or when an enumerated consumer reaches an acting call site.

**Membership is not in this vocabulary.** *Which* pull requests are the operator's is a separate
question with a separate script (`branching/scripts/list-operator-facing-pulls.sh`) and a separate rule
(`branching/scripts/lib/publication-refusal.sh`, shared with the seam that refuses the merge).
This one answers only *what happened to this pull request* — one script, one question, because
one script answering both is how two readings of one fact start to disagree.

### Whether a unit is being driven twice (`list-raced-units.sh`)

A **sixth vocabulary in the same home** (2026-08-30, mission
`stop-two-runs-from-claiming-and-driving-one-unit`). The tables above are keyed on what is true
of one *claim*, of the *base*, of an act *this loop* took, or of a publication. This one is
keyed on a relation **between two claims of one unit**, which no per-row verdict can carry: each
of the two rows is individually healthy, and what is wrong is that both exist.

**Why it needed a vocabulary at all.** `ambiguous_claim` is refused by every writer that meets
it and was **asked about by nobody**. Measured 2026-08-30: `work-20260830-055314` and
`work-20260830-055318` were both claimed for one unit four seconds apart and each drove the same
four tickets for over an hour; the run that lost reported an ordinary undelivered unit and the
duplicated hour reached no person at all. No other step could see the shape — `stalled-units`
finds one claim that has not moved, `undelivered-units` finds one refused merge, the catch-up
finds one conflicted branch, and each of those is a *consequence* whose question hides the cause.

**There is no proof in this vocabulary either.** A race resolves the moment one of the two
branches merges, so every reading here can become false by looking again — the one property a
proof must not have. **No consumer may release a claim, pick between the two branches, delete a
branch, close a pull request, revert, re-run, merge, gate or hold work on it.** The licence is
to **report and to ask**, and nothing else.

| Word | Class | What established it, and what a consumer may do |
| ---- | ----- | ----------------------------------------------- |
| `ambiguous` (a unit in `raced[]`) | judgement | `claims_unit_resolution` answered `ambiguous`: two or more **live** claims hold this unit right now. **This is the one reading that draws a question**, addressed to the claim holders, keyed `raced-unit:<unit>` so one unit costs exactly one question however many ticks see it. Both branches are named and **neither is picked** — choosing silently is how a runner would discard work another run is still driving. |
| not raced (every other resolution) | judgement | `none`, `single`, `live` or `superseded_only`. **`live` is the deliberate exclusion**: one live claim beside a `superseded` one is byte-identical to the *sanctioned* recovery in which a superseded claim's work is resurveyed and taken on a fresh claim (`plan-units.sh`'s `resurveyed[]`). Separating a race from that recovery would need a clock threshold between the two claims' creation times or a field stored on an artifact, and this repository refuses both by name — so the aftermath is left where it is already handled: the loser reads `superseded`, `retire-claims` retires it, and `stalled-units` counts it. |
| `readable: false` | judgement | The claim scan could not be read (`no_claim_reader` / `claims_unreadable` / `claims_unparseable` / `origin_unreachable` / `shallow_history`), carrying a named reason and a **null** count — never a zero, which would render *we could not look* as *no unit is being driven twice*. The **absence** of a reading: it draws **no question**, and a filtering consumer filters **nothing** on it, because an over-eager question beats a silently dropped one. |

**This reading owns the raced unit's question, and three siblings filter it and count it** — the
`handoff-units`/`stalled-units` division, where one step asks and the others filter, and either
half alone is a defect. The four candidate steps are settled explicitly rather than left to
whichever runs first:

| Step | What it does with a raced unit | Why |
| ---- | ------------------------------ | --- |
| `raced-units` | **asks** | The race is the cause; the others see consequences. |
| `stalled-units` | filters, counts | *A claimed unit has not moved for a day or more* sends a person to look at one claim when the honest question names both. |
| `undelivered-units` | filters, counts | A raced loser's refused merge is the race's consequence; *retry your merge* hides the cause. |
| the catch-up | attempts neither | Catching one of two racing branches up presumes the answer to *which branch keeps going*. |
| `retire-claims` | **needs no change** | Its candidates are `superseded` rows, and a unit resolving `ambiguous` has none **by definition** — every one of its claims is live — so the two sets are disjoint by construction. `retire-claim.sh` refuses `ambiguous_claim` on its own besides. |

The filter is `moderate/scripts/lib/raced-units.sh`, one helper over the scan each step has
already made — no second walk of the refs, and no second definition of a race, which is how two
filtering steps would start disagreeing with the step that asks.

**Its enumerated consumers are two.** `/moderate`'s `step-raced-units.sh` **asks**; `/implement`'s
and `/drive`'s run reports **report** a race the run itself met — `archive.sh`'s re-check
refusing `ambiguous_claim` or `claim_taken_over` at the first write the base would see. The
reading **moves no token** and gates nothing: the run wrote nothing and the protocol worked.
`scripts/test-workflow-scripts.mjs` pins this table as it pins the five above.

**What this vocabulary does not contain, and why.** A word for *this run lost the race at its
claim push* is deliberately absent: it would rest on an arbitration this container cannot
perform (*What the claim contends for*, below — `refs/claims/*` is refused 403 on create and on
delete, and `refs/heads/*`, the only writable namespace, cannot be released either). Until that
arbitration exists, a run loses a race at `archive.sh`'s re-check rather than at its push, and
that refusal is what the run report names.

### How long a condition has been standing (`condition-age.sh`)

A **sixth vocabulary in the same home** (2026-08-30, mission
`say-how-long-the-loop-has-been-stuck`). The five tables above are each keyed on *what is true*
— of a claim, of the base, of an act, of a publication. This one is keyed on *how long it has
been true*, which is a different question about the same subjects, and one column cannot
classify six questions. It is folded into none of them, and least of all into the act-effect
table beside it: both concern the loop's own records, and that resemblance is exactly the
mistake the previous five splits each record.

**There is no proof in this vocabulary, and the tempting error is to think `first_seen` is
one.** It is read straight off an append-only log that never rewrites a line, which looks like
`superseded`'s property. It is not: the log **grows**, so `ticks` increases every hour, and a
bounded walk's `first_seen` can move as day files pass out of the bound. A proof is a reading
that *cannot become false by looking again*, and this one is designed to. `readable: false` is
besides that the **absence** of a reading.

**So no gate, hold, re-ask, escalation, merge, claim or sort may read the age.** The questions
name it and the run reports report it, and that is the whole licence.

| Word | Class | What established it, and what a consumer may do |
| ---- | ----- | ----------------------------------------------- |
| `first_seen` | judgement | The earliest tick in the question ledger (`human-checkin-ask-<slug>` / `human-checkin-reasked-<slug>`) carrying this subject's key, or **null** when the ledger has never carried it. Null is an **ordinary absence** — the first time anybody is being asked — never a degradation. A consumer may name it in a question or a report. |
| `ticks` | judgement | The distinct ticks the log holds at or after `first_seen`, compared lexically; **0** with a null `first_seen`, **null** on a degraded read. Never a wall-clock difference. |
| `truncated` | judgement | The walk was **cut** by `WORKAHOLIC_CONDITION_AGE_MAX_DAYS` — a day file older than the bound exists. Emitted only when true. It is **not** a degradation: the counts stay real and `readable` stays absent. |
| `first_seen_is_floor` | judgement | Emitted with `truncated` and a non-null `first_seen`: the date is a **floor**, so a consumer renders *at least*. Never a prose prefix on `first_seen` itself — a consumer parsing English is how two readings drift. |
| `reason` | judgement | The named cause riding a `readable: false` reading, carried verbatim by every consumer — a normalised word would send a reader to a string no script printed. |
| `readable` | judgement | Emitted only as `false`, and only when the log **exists** and could not be read (`log_unreadable`, `no_key`, `reader_missing`, or `log-read.sh`'s own reason). Counts are **null**, never zeroed. The **absence** of a reading, and it must be named as unreadable — rendering it as *this just started* is the collapse this whole vocabulary exists to close. |

**Its enumerated consumers are six**, and each may only name the age: the four question steps
(`step-undrivable-units.sh`, `step-retire-claims.sh`, `step-undelivered-units.sh`,
`step-stalled-units.sh`) and the two run reports (`/implement`, `/propose`). None of them
reaches an acting or gating call site on it — no `refusal`, no `selected`, no sort key, no
`--method PUT`/`PATCH`/`DELETE`, no `/merge`, no `retire-claim.sh`, no `release-claim.sh`, no
`catch-up-claim.sh`, no `plan-units.sh`, no `git push` — and `ask-question.sh` is
**byte-identical**: the age changes no key, no cap and no hold, so the gate gains nothing at
all. `scripts/test-workflow-scripts.mjs` pins this table the way it pins the five above.

### Which question reads which age

Four of the tick's questions now name **how long** their condition has been standing, and two of
them already had an age of their own from a different source (2026-08-30, mission
`say-how-long-the-loop-has-been-stuck`). The rule this table exists for is one sentence:
**nothing derives an age twice**, and where a question carries two ages they are named as **two
facts with their sources**, never blended into one number.

| Question key | Age source(s) | Notes |
| ------------ | ------------- | ----- |
| `undrivable-unit:<path>` | tick log | Only one. The artifact carries no timestamp a reader could use, so *how long we have been asking* is the whole answer available. |
| `retire-blocked:<unit>:<word>` | tick log | Only one. The key carries the refusal word, so a **changed** word starts a new question and its age legitimately resets — a reset is never the block clearing. |
| `undelivered-unit:<unit>` | tick log **and** the pull request | Two facts. `open_hours` is how long the pull request has been open (its own `created_at`); `age` is how long the unit has been asked about. A pull request opened an hour ago that nobody has been told about, and one open a week that a person was asked about on day one, call for different acts. |
| `stalled-unit:<unit>` | tick log **and** the claim tip | Two facts. `stalled_hours` is how long the branch tip has not moved (`WORKAHOLIC_CLAIM_STALE_HOURS`, the protocol's own threshold); `age` is how long we have been asking. |
| `operator-pull:<number>` | the pull request's `created_at` | **The tick log not at all.** `publication-effect.sh` stays the one reader of that age, and its **null**-on-`unreadable` rule stays. A second number on the one question whose own source is exact and external buys nothing. |

**The table is prose, so it can lie**, and the pin is what makes it a fact a change can lose:
`scripts/test-workflow-scripts.mjs` reads these rows and checks each named step **in both
directions** — a step that composes an age this table does not attribute, and a row naming a
step that composes none — exactly as the proofs-and-judgements pin does for the verdict words.

**What the tick-log age means, stated once so no consumer over-reads it.** It is the age of the
**question**, which is a *lower bound* on the age of the condition: a blocker that existed
before anybody asked reads younger than it is. That is the honest direction — understating an
age asks a person to look sooner than the truth would — so a consumer says *asked about since*
and never asserts how long the artifact itself has been stuck.

### Whether a recorded answer has been acted on (`answer-outcome.sh`)

An **eighth vocabulary in the same home** (2026-08-31, mission
`make-the-tick-s-questions-readable-and-close-them-in-the-thread`). The tables above are keyed
on what is true of a *claim*, of the *base*, of an act *this loop* took, of a publication, of a
relation between two claims, or of *how long* something has been true. This one is keyed on what
became of a **person's own answer** — the words they wrote in a question's thread, which
`record-answer.sh` recorded and which, when the answer asked for something, became one `[FB]`
issue. One column cannot classify eight questions, and a second document would be the second
home the split exists to prevent.

**Why the question needed a vocabulary at all.** Nothing could answer *what came of this
answer*. The person who replied in the thread got a `:ballot_box_with_check:` saying *received*
and nothing afterwards, so from where they sat an answer that became a merged mission and one
that was read and dropped looked identical.

**There is no proof in this vocabulary either.** An issue is *designed* to change state —
anybody can close it, and anybody can reopen it after the pull request that closed it merged —
so every reading here can become false by looking again, which is the one property a proof must
not have; `unreadable:<reason>` is besides that the **absence** of a reading. **No consumer may
merge, close, gate, hold work or re-ask on it.** The licence is to **report**, and to post the
one outcome reply the catalog names.

| Word | Class | What established it, and what a consumer may do |
| ---- | ----- | ----------------------------------------------- |
| `settled:nothing_filed` | judgement | The filing line says `not_filed: <reason>`: the answer asked for nothing, so nothing is owed and the outcome is known **with no network call at all**. It is a settled reading and the reply may say so. |
| `settled:issue_closed` | judgement | The filed issue is closed, carrying its `state_reason` **verbatim** (`completed` is what GitHub records when a merging pull request closes it; `not_planned` is equally an outcome the person is owed). Settled, and the one reading that says the work actually landed. Proving the *merge* closed it would need the issue's timeline — a second bounded call per candidate for a distinction no consumer acts on — so it is not asked for and not guessed at. |
| `pending` | judgement | The filed issue is still open, or the agent has not written a filing line yet (`reason: no_filing_line`). **Nothing to say**: it posts nothing, and it is a candidate again on the next tick. |
| `unreadable:<reason>` | judgement | The log, the filing line or the issue could not be read (`jq_unavailable` / `no_question_reader` / `no_log_reader` / `question_state_unreadable` / `log_unreadable` / `filing_line_unparseable` / `gh_unavailable` / `read_failed` / `not_found`), carrying a named reason and a **null** `issue` where none was resolved. The **absence** of a reading: it posts nothing and is reported by name, **never** rendered as `settled` — which would tell somebody their answer was acted on when nobody knows. |

**A question with no recorded answer is refused, not classified.** `ok: false` with
`reason: not_answered:<state>` and an **empty** `outcome`: there is no answer for anything to
have become of, and rendering that as `unreadable` is the collapse this vocabulary's
`unreadable` exists to close. The candidate set is the caller's — `step-question-answers.sh`
already derives the answered set in the one pass it makes over the ledger.

**Its enumerated consumer is one.** `/moderate`'s `step-question-answers.sh` hands each
`settled:` candidate back in `needs_agent` and the agent posts **one reply** into that
question's own thread, on the coordinate `ask-question.sh --record-ask` already recorded. It
merges nothing, closes nothing, gates nothing, holds no work and re-asks nothing; a failed post
is `outcome_post_failed: <reason>` and is never load-bearing on the recording, the filing or the
question's state. `scripts/test-workflow-scripts.mjs` pins this table the way it pins the seven
above: it fails when a word the reader emits is unclassified, when the table classifies a word
the reader never emits, when any row is called a `proof`, or when the enumerated consumer
reaches an acting call site.

### When a bounded act may read a judgement

The rule at the top of this section — **a consumer may act on a proof, and may only report or
ask about a judgement** — has one exception, and it was half-written until 2026-08-30 (mission
`catch-a-reported-claim-up-before-its-conflict-hardens`). The `mechanical` row above carried it
inline, as a fact about *one word*: a consumer may act on that reading only through
`catch-up-claim.sh`. That is correct and it cannot govern a **fourth** act somebody adds next
month against a different judgement, which is exactly how the classification would start
drifting again — the thing the tables themselves exist to prevent.

**The rule, stated once.** An act may read a judgement only when **all four** hold:

1. **It re-derives that judgement at the moment of the act**, from the reader itself, rather
   than trusting a list it was handed. This is the load-bearing clause: a judgement is by
   definition a reading that can become false by looking again, so the gap between the survey
   that named a candidate and the write that acts on it is precisely where the reading goes
   stale. It is the discipline `delete-retired-claim-branch.sh` already carries across an
   executor boundary, where that gap is a queue and a checkout.
2. **It is idempotent.** Running it twice over the same unit does the work once and reports the
   no-op by its own word (`already_current`), so a reading that flipped between two ticks costs
   a report line rather than a second write.
3. **It is reversible.** Every write it makes can be undone by an ordinary act of the
   repository — a merge commit that can be reverted, never a rebase, an amend, a force-push or
   a deletion of something the base does not carry.
4. **It refuses every bound by its own word**, writing nothing and exiting 0, so a refusal is
   legible as the specific thing that stopped it rather than as a generic denial.

**What it is not a licence for.** A judgement that is the **absence** of a reading —
`unanswerable`, `identity_unresolved`, `shallow_history` — is never actable under this rule
however bounded the act: acting on an absence is the failure the three-valued lookups exist to
avoid, and clause 1 cannot be satisfied by a re-derivation that answers nothing either. Nor
does the rule reach a judgement whose next step is a **person's judgement** rather than a
mechanical settlement: `content` stays refused, `awaiting_verification` stays reported, and
`stale` stays reported and never acted on, exactly as their own rows say.

**Two shapes, one rule** (2026-08-30, mission `stop-two-runs-from-claiming-and-driving-one-unit`).
An act may **read** a judgement to license itself (`catch-up-claim.sh` merges *because* the
conflict is `mechanical`) or to **gate** itself (`archive.sh` writes *unless* the claim has
changed hands). The four clauses are the same either way, and the direction decides which way an
**absence** falls: a licensing act must refuse on one, because acting on an absence is the
failure the three-valued lookups exist to avoid, and a gating act must **proceed** on one, for
exactly the same reason — refusing on a reading it could not make is acting on an absence too,
and there the cost is finished work stranded outside the archive. Neither may treat an absence
as the reading it wanted.

**The consumers, enumerated by name.** A glob would quietly pass an act added with no rule at
all, which is the same reason the proof-gated consumers are enumerated rather than discovered:

| Acting consumer | The judgement it reads | How each clause is met |
| --------------- | ---------------------- | ---------------------- |
| `catch-up-claim.sh` | `mergeability ∈ {mechanical, content}` (`claim-mergeability.sh`) | Re-derives by calling `claim-mergeability.sh` itself after resolving the unit; `already_current` on a branch that already contains the base, touching no ref; its write is a **merge commit** on the claim branch, revertible and never a rewrite; refuses `content_conflict`, `not_my_claim`, `foreign_identity`, `claim_active`, `dirty_worktree`, `scan_held:<tier>`, `pull_request_reviewed`, … each by its own word. **`content` joined the licence on 2026-09-02** and the clauses are met identically, because the licence is *the writer settles it without a judgement* rather than *the reader predicted mechanical*: the reader computes without the repository's `.gitattributes` and the writer merges with them, so its `content` is a pessimistic guess that the act now tests instead of trusting. The absence-word `unanswerable` is still refused, exactly as a licensing act must refuse an absence |
| `archive.sh` | `holder == mine` (`claim-holder.sh`) | Re-derives by calling `claim-holder.sh` itself immediately before the ticket moves — ahead of the todo-layout migration, so nothing has been staged yet; the archive it gates is idempotent in the shape this seam already guarantees (a re-run of a refused call finds the tree byte-identical, and the mission mutators below it no-op on a repeat); its write is a **commit on the claim branch**, revertible and never a rewrite; refuses `claim_taken_over` and `ambiguous_claim` by their own words, moving nothing, staging nothing and committing nothing |

**The table is prose, so it can lie**, and `scripts/test-workflow-scripts.mjs` pins it **in both
directions**: a script that both reads a judgement-emitting reader and carries an acting call
site must appear in this table, and a consumer named here that stops re-deriving its judgement
fails. One direction alone is half a rule — an unenumerated act has no bound at all, and an
enumerated one that trusts a handed-in reading has lost the clause that makes the exception
safe.

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

### What the claim contends for

**The premise was true for one path and false for the other, and the false half was
load-bearing** (2026-08-30, mission `stop-two-runs-from-claiming-and-driving-one-unit`). Two
places in this document said *the protocol settles a race by the push, so the state cannot
arise from the sanctioned path*, and `ambiguous_claim`'s standing as **reported, never picked
between** rested on it. Read against the mechanism:

- **`claim.sh resume` does contend, exactly as written.** A takeover pushes an empty
  `Resume a PR-unit` commit onto a branch that **already exists**, so two takeovers of one
  unit contend on **one ref** and the second is rejected non-fast-forward — `resume_race_lost`,
  and the pinned-tip check above closes the same window a second time.
- **A fresh claim contended for nothing.** `branching/scripts/create.sh` mints
  `work-$(date +%Y%m%d-%H%M%S)` and `claim.sh` pushes it `-u`, so two runners that survey
  before either pushes name **two different refs**: both pushes succeed, and
  `branch_collision` fires only in the narrower same-second case. **Measured 2026-08-30**:
  `work-20260830-055314` and `work-20260830-055318` were both claimed for
  `draft-a-dateless-direction-with-the-operator-s-one-week-default`, four seconds apart, and
  each drove the same four tickets for over an hour.

**What the claim must contend for is one ref per unit** — a ref derived from the unit id
rather than from the clock, pushed create-only, so that the first push wins at the **remote**,
the only arbiter both runners share, and the second is refused before the loser has written
anything.

**That repair is not available in the container the loop runs in, and this is the measurement
rather than a forecast.** Probed 2026-08-30 from a routine-fired container, on this
repository's own origin:

- `git push --force-with-lease='refs/claims/<x>:' origin <sha>:refs/claims/<x>` →
  `error: RPC failed; HTTP 403`, and `ls-remote` confirms **no ref was created**.
- Deleting the same ref (`git push origin :refs/claims/<x>`) → the identical 403, the shape
  `retire-claim.sh`'s Act 2 already records for a branch delete.
- The **same `--force-with-lease` flag against `refs/heads/<a work-\* branch>` succeeds**, so
  the refusal is the **namespace**, not the lease: the proxy permits writes to `refs/heads/*`
  and to nothing else.

**Re-probed 2026-08-30 from a second routine-fired container, and the two clauses that were
inferred are now measured.** *And to nothing else* rested on two namespaces; *a ref there
could never be released either* rested on `retire-claim.sh`'s branch-delete precedent. Both
were re-run directly, create-only rather than under a lease, against this repository's own
origin:

- `refs/claims/*` — `git push origin <sha>:refs/claims/<x>` → `error: RPC failed; HTTP 403`,
  and `git ls-remote origin 'refs/claims/*'` returns **empty**. The REST second transport
  agrees: `POST /repos/{o}/{r}/git/refs` → `403 "Write access to this GitHub API path is not
  permitted through this proxy."`
- `refs/tags/*` — the **last candidate namespace**, and it is refused in **both** directions:
  create → 403 with `ls-remote` empty, delete → the identical 403. Probing it is what turns
  *and to nothing else* from an inference over two namespaces into a reading.
- `refs/heads/*` — **create succeeds** (`* [new branch]`, confirmed by `ls-remote`), and its
  **delete is refused by both transports**: `git push origin :refs/heads/<x>` → 403, `DELETE
  /repos/{o}/{r}/git/refs/heads/{branch}` → the same proxy refusal, with `ls-remote`
  confirming the ref **survives** both. So the release is refused in the one namespace whose
  create is permitted, measured here rather than carried over from the branch-delete row.

**AND THAT MEASUREMENT IS THE CLOUD ROUTINE'S, NOT THE REPOSITORY'S** (2026-09-02, mission
`stop-two-runs-from-claiming-and-driving-one-unit`). Every probe above was taken **from a
routine-fired container**, whose proxy is what answers 403 — a fact the readings state and which
stopped mattering the day the loop moved onto the developer's own server (`workaholic:loops`,
2026-09-02). Re-measured there, over SSH, against this same origin:

- `refs/claims/*` create → `* [new reference]`, confirmed by `ls-remote`;
- the **create-only lease** (`--force-with-lease=<ref>:`, empty expected value = *must not
  exist*) → a second push on the same ref is `! [rejected] … (stale info)` and the ref keeps the
  winner's value;
- compare-and-swap on the known value → accepted;
- **delete** → `- [deleted]`, `ls-remote` empty.

No residue was left by any of it. **Both readings are true of their own environment**, so the
mechanism does not choose between them: it tries, and a refusal is reported as `unavailable`
rather than treated as a stop.

### The arbitration, as built

`drive/scripts/claim-arbitrate.sh` — `take` / `release` / `reap` / `refname`, exit 0 in every
case. `claim.sh` §3b runs it **after** the oracle's refusal and **before** the worktree exists,
which is what makes the mission's Experience true: a loser "stops within its survey, having
written nothing".

**The ref is derived from the ARTIFACTS, not from the unit id.** The ticket proposed the unit
id; that reaches one grain only, because `claim.sh` mints `batch-<timestamp>` **inside** the
claim act, so two runners racing over the same tickets would push two different unit-keyed refs
and both would still win — the defect, one layer down. The artifacts are what two racing runners
actually share and what §3's existing overlap refusal already keys on, so **one ref per
artifact** settles both grains: `refs/claims/artifact/<sanitised repo-relative path>`.

**The value must be unique per claimant**, and that cost a real bug: git treats a push of the
value a ref already holds as `Everything up-to-date` and exits 0, so with a shared base sha two
successive takes both answered `won` (measured 2026-09-02). Each `take` now mints one commit of
its own and pushes that, so the lease genuinely arbitrates.

**All or nothing.** A take wins every ref or releases what it won and answers `lost`; a partial
hold is the race with extra steps.

**THE LOCK'S LIFETIME IS THE CLAIM ACT, NOT THE CLAIM**, and that is the correction that made
the whole mechanism safe. §3b exists to close **one** window: between a runner deciding to claim
and its branch reaching the remote, the oracle — which reads pushed `work-*` branches — cannot
see it. The moment the push lands the oracle sees the claim, so `claim.sh` **releases the locks
right there**, and no lock outlives the act that took it.

**Measured 2026-09-02**, because the first design held the lock for the life of the claim and it
broke an existing row (*a merged stamp is history, not a claim*): a **merge** releases a claim by
definition and runs **nothing** in the container, so the survey re-offered the ticket immediately
while a lock nobody could release still refused it — the ticket's own warning, *a ref nothing
deletes makes an artifact claimable exactly once, forever*, arriving as a red row rather than as
a forecast. Ending the lock with the act removes the entire class: a merged, released, retired or
`superseded` claim needs no lock handling at all, **because by then there is no lock**.

So there are exactly two releases, and neither is a per-verdict rule:

| When | How |
| ---- | --- |
| the claim act ends | `claim.sh` — `arb_release` immediately after the successful push, and folded into `abort_claim` for every failure after a lock was won |
| the act was **killed** inside its own window | the arbiter's **reap**: a lock **no live claim stands behind** (the oracle decides) **and** older than `WORKAHOLIC_CLAIM_ARBITER_STALE_MINUTES` (default 10). Both terms are required — inside the window the first is true of a perfectly healthy act, and the age is what keeps the sweep from eating it. Run **lazily** by `claim.sh`, only when a take is lost, then the take retried once, so the ordinary claim pays nothing |

**The residual cost, stated**: a process killed between winning a lock and pushing leaves a lock
the next lost take sweeps — seconds of exposure against an hour of duplicated driving.

**`claims_scan` reads `work-*` refs and nothing else.** The contended ref is the **arbiter**,
not a second oracle; no reader consults it, no verdict word was added, and the
proofs-and-judgements tables do not move. The losing claim's own refusal — `claim_race_lost`,
the claim act's vocabulary rather than the oracle's — is below, beside `resume_race_lost`.

So the only writable namespace is the one the branch-name gate holds to two literal patterns,
and a ref there could never be released either (the delete is the same 403, now measured on
both transports), which is the condition the repair must not create: *a ref nothing deletes
makes every unit claimable exactly once, forever*. **An asynchronous CI-side release does not
rescue it**, which is why the executor precedent is named and refused twice over: between the
merge that releases a claim and CI's delete there is a window in which the unit's own
follow-up re-claim — the routine path a `parked_with_pr` mission takes every time — would be
refused by a ref that no longer stands for anything. That is the same regression the
condition names, narrowed to a window rather than removed. Recorded here as a finding for the
mission rather than worked around;
`.github/workflows/claim-retirement.yml` is the precedent for moving a refused write to
another **executor**, and it does not apply, because an arbitration must be decided
synchronously, in the container, before the run drives anything.

**And the named mechanism reaches one grain, not two — a second reason to re-scope rather
than force it** (2026-08-31, the same mission). *A ref derived from the unit id* arbitrates
only where two racers **name the same unit**, and they do so at exactly one grain:

- **Mission grain — one ref.** The unit id is the mission slug, which both runners read off
  the same artifact, so two claimants for one mission name one ref. This is the grain the
  2026-08-30 race was measured at, and the mechanism would close it.
- **Batch grain — two refs, and the ref arbitrates nothing.** `claim.sh` step 2 mints
  `unit="batch-$(date +%Y%m%d%H%M%S)"` **inside the claim act itself**, so two runners
  surveying the same unclaimed tickets mint two different unit ids and therefore push two
  different unit-keyed refs. Both creates succeed, and the loser is refused by nothing —
  the same both-win outcome, one grain over.

The batch grain is raceable for the same reason and in the same window. Step 3 already
carries an **artifact-overlap** check beside the unit-id check, precisely so *a batch that
scoops up a ticket another branch already took under a different batch id* is refused — but
it reads `claims_scan`, so it closes the **sequential** case and not the race: two runners
that both survey before either pushes see no claim, both pass, and both publish.

So arbitrating the batch grain needs a ref keyed on **each artifact** rather than on the
unit — N create-only pushes with **no atomicity across them**, where a partial acquire must
be released before the runner surveys again, in a container whose ref deletes are refused.
That is a materially larger mechanism than *one ref per unit*, and it is recorded here as a
finding rather than designed, on ticket 3's own instruction: *if the reproduction shows the
contention must sit earlier than the push, say so and re-scope rather than forcing the named
mechanism*. It is **independent of the transport** — it would hold in an environment where
every namespace were writable — so an operator ruling that unblocks the transport does not
by itself deliver the mission's first acceptance item at the batch grain.

**Two things follow, and both are shipped.** `ambiguous_claim` keeps its behaviour exactly —
reported, never picked between — and its justification becomes *this can arise from the
sanctioned path, which is why nothing may choose between two live claims*, rather than the
assertion that it already cannot. And the damage is bounded one layer later instead: the
claim is re-derived at the first write the base will see (`archive.sh`, *When a bounded act
may read a judgement*), and a unit whose content reached the base through a racing twin is
readable as `superseded` at the mission grain from the tree, so the existing retirement path
reaches the loser rather than leaving it as a person's conflict.

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

**What makes the delete safe is two proofs, not one, and the documents say so since 2026-09-02**
(ticket `20260831203454-make-the-retirement-s-stated-recovery-true`). The act's own header used
to offer as recovery that a deleted branch is recoverable from the base's history *because its
content is on the base — that is what `superseded` means*. It did not mean that. Two separate
facts are involved and neither implies the other:

- **the unit's tickets are archived on the base** — `claims_archived_on_base` at the batch
  grain, `claims_mission_landed` or the merged-pull-request lookup at the mission grain;
- **the branch holds no work** — `claims_branch_empty_against_base`.

The step from the first to the second holds only when a branch carries nothing but its own
unit's tickets, and the measured branches did not. Since the emptiness term joined the verdict
the recovery sentence is true **by construction**, and the term must not be removed as redundant
with the archive test: they answer different questions. **The 403 belongs in the record too** —
the delete never actually ran against those branches, so this is a near miss rather than a
history, and repairing the transport without the verdict would have turned a reported nuisance
into a silent loss on the first tick after the fix. `delete-retired-claim-branch.sh`'s
`not_on_base` therefore refuses on **both** facts while naming only the first; the word is kept
rather than renamed because it is a wire string reaching CI annotations, the record reader and
`/moderate`'s asked-once question key, and renaming it would re-ask every standing question about
a branch nothing had changed about.

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

### When an act of the retirement is refused

**Each blocked act reports its own word** (2026-08-27, mission
`finish-the-retirement-the-loop-cannot-complete`). The closing branch answered
`partial_retirement` for all three until then, so a refused pull-request close, a refused branch
delete and a dirty worktree read alike and only the first kept a note — measured on this
repository, three units reported `partial_retirement` for a **branch delete** and nothing in the
tick log said so. The words are `gh_unavailable` / `slug_unresolved` /
`pull_request_close_failed` for the close, **`branch_delete_failed`** for the delete, and
`worktree_reap_refused` for the reap; they are derived from the three act states already on the
row, in act order, so the reason names the first blocked act while the row's states show every
one. `partial_retirement` is retired.

**The new word belongs to the retirement's vocabulary, not the oracle's.** It is not a
`resume_reason` and must never be added to the tables above: `lib/claims.sh` does not emit it,
nothing keys a takeover or a survey on it, and `superseded`'s classification as a **proof** is
untouched by it. What the word describes is the outcome of an act taken *because* of the proof —
a different axis from what the claim reads.

**Act 2 is refused in the container the loop runs in, and no transport can take it.** Measured
2026-08-27 in a routine-fired container, against a claim already proved `superseded` here:

| Transport | Answer |
| --------- | ------ |
| `git push origin --delete <branch>` | `error: RPC failed; HTTP 403 curl 22 The requested URL returned error: 403` |
| `DELETE /repos/{owner}/{repo}/git/refs/heads/{branch}` via `gh-rest.sh` | `403 {"message":"Write access to this GitHub API path is not permitted through this proxy."}` |

The two transports **agree**, and the refusal is a **session-type** one — not a protection rule
(which answers `422` naming the rule) and not a missing scope (which answers a permissions
message). An ordinary `git push` of the same branch succeeds in the same container, so it is the
delete specifically that is refused. The 2026-08-05 note in `retire-claim.sh` predicted this and
called it "not fatal"; it is fatal to the mechanism's purpose, since unmerged remote branches are
the only claim oracle.

**No second transport exists *in the container*, and that is the recorded finding rather than an
open gap.** REST is refused above, and the GitHub connector exposes `create_branch` and
`list_branches` but **no branch- or ref-delete surface at all** — so there is nothing for a
`rules/shell.md`-style bounded retry to attempt, in the script or in its caller. A second REST
attempt is deliberately **not** made: it is measured to answer 403, and a call that cannot
succeed is noise with a cost. That finding is about the container and remains accurate there.

### Which act runs where

**A different executor takes Act 2** (2026-08-28, mission
`finish-a-proved-retirement-where-the-write-is-permitted`). The paragraph above closed the
question *inside the box*; this moves the act outside it, on the precedent
`release-note-draft.yml` set when the release-note write met the same refusal. A workflow is
**not a second transport** — it is the same REST seam (`gather/scripts/gh-rest.sh`) run by a
process that holds `contents: write`, which is exactly the capability the container lacks.

| Act | Executor | Why |
| --- | -------- | --- |
| 1 — close the pull request | the container, `retire-claim.sh` | already succeeds there |
| 2 — delete the remote branch | **CI**, `.github/workflows/claim-retirement.yml` | refused in the container by both transports; permitted to `GITHUB_TOKEN` |
| 3 — reap the worktree | the container, `retire-claim.sh` | local to the runner; CI has no worktree to reap |

`retire-claim.sh` is **unchanged**: it still attempts its own delete and still reports
`branch_delete_failed` when refused. A repository that has not adopted the workflow keeps
exactly the behaviour it had, and the container is still where a retirement starts.

Two scripts carry the CI side, and each re-derives everything it acts on:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/list-retirable-claims.sh
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/delete-retired-claim-branch.sh <unit-id>
```

The reader composes `list-claims.sh` — one walk of the refs, never a second oracle — resolves
each unit through the live-row rule, and answers `superseded_only` units **and branches whose
own pull request merged** (below). A degraded scan
yields **no candidates and its reason**, never a bare empty set: a proof that could not be read
is not a proof. The act re-runs the scan and re-derives the verdict **at the moment of the
delete** rather than trusting the list it was handed — the writer's existing discipline applied
across an executor boundary, where the gap between the two reads is a queue and a checkout — and
refuses every other verdict by its own word, with `ambiguous_claim` and `unanswerable:<reason>`
their own refusals as above. On top of the proof it is bounded, each refused by name:
`not_a_work_branch`, `release_branch`, `not_on_base` (re-derived from the tree, and at the
mission grain from the merged-pull-request lookup — the one reading here that can answer
differently the second time it is asked), and `pull_request_open`. Every path exits 0.

**`superseded` stays a proof, and no verdict word was added.** `lib/claims.sh` emits nothing new,
the *Proofs and judgements* tables above are unchanged, and nothing keys a takeover or a survey
on any of this. Which executor takes an act is a different axis from what a claim reads — exactly
as `branch_delete_failed` already is.

#### What made a branch a retirement candidate (`candidate_reason`)

**Another keyed vocabulary in this home** (2026-09-01, mission
`leave-only-live-work-in-the-unmerged-branch-list`), emitted by `list-retirable-claims.sh` on
every candidate row. It is not a claim verdict and enters no precedence: it says **which proof
put this branch on the list**, so a reader of the list, and the act that consumes it, can tell
the classes apart without inferring them.

| Word | Class | What established it, and what a consumer may do |
| ---- | ----- | ----------------------------------------------- |
| `superseded_only` | **proof** | Every claim for this unit reads `superseded` — the content reached the base and the branch is empty against it. The original class, unchanged; the act's `not_on_base` gate re-derives it. |
| `pull_request_merged` | **proof** | This branch's own pull request has a non-null `merged_at`, read through `branch-pull-request-state.sh`. The tree established it and looking again cannot make it false, which is the same standing `superseded` has and the reason a destructive act may rest on it. |
| `pull_request_closed_unmerged` | **proof** | A **person** closed this branch's pull request without merging it. The argument is different from the two above and is written out rather than borrowed: what makes it safe is **authorship**, not emptiness — closing a pull request unmerged is a recorded decision about that branch by somebody entitled to make it, and it does not become false by looking again. |
| `mission_not_active` | **proof** | The unit's **mission** has ended: `close.sh` — the only writer of an end state — moved it into `missions/archive/`, and re-opening is offered nowhere. Authorship again, one grain out: the decision is about the **work**, not about this branch, so the emptiness term below is a **gate** here exactly as it is for the class above. `mission_status` (`achieved` / `abandoned` / `carried` / empty) rides the row, because three different reasons the work stopped are three different things for a person to read. |

**What each class licenses, and what refuses it.** `delete-retired-claim-branch.sh` re-derives
its own class at the moment of the act — the `--reason` flag says *which* proof to re-derive and
is never trusted as the proof — and every bound refuses by its own word with nothing deleted and
exit 0. The bounds that hold for **all three** are the shape and transport ones:
`not_a_repository`, `no_origin`, `origin_unreachable`, `no_branch`, `release_branch`,
`not_a_work_branch`, `gh_unavailable`, `slug_unresolved`, `pull_request_open`, and the act's own
`branch_delete_failed`. Beyond those:

| Class | What else must hold | Its own refusals |
| ----- | ------------------- | ---------------- |
| `superseded_only` | the unit resolves to a claim, and the branch is on the base | `no_claims`, `no_such_claim`, `ambiguous_claim`, `not_on_base` |
| `pull_request_merged` | no live row for the unit, and the pull request still reads `merged` | `not_superseded:<verdict>`, `pull_request_unreadable:<reason>` (including `:no_reader_script`), `not_merged:<state>` |
| `pull_request_closed_unmerged` | the same, plus the pull request still reads `closed_unmerged` **and the branch is empty against the base** | `not_superseded:<verdict>`, `pull_request_unreadable:<reason>`, `not_closed_unmerged:<state>`, **`branch_holds_work`**, **`emptiness_unanswerable`** |
| `mission_not_active` | the same, plus a unit to name, the mission still reading `not_active` **and the branch empty against the base** | `not_superseded:<verdict>`, `pull_request_unreadable:<reason>`, **`no_unit_for_mission_class`**, **`mission_unreadable:<reason>`** (including `:no_reader_script`), **`mission_still_active:<state>`**, `branch_holds_work`, `emptiness_unanswerable` |

**The `pull_request_open` bound is NOT widened for the fourth class, and the argument is written
here rather than left to be re-derived** (2026-09-02). An ended mission whose pull request is
still open is exactly the case somebody proposed widening it for; deleting that head branch
leaves the pull request unmergeable by anybody forever — the headless shape measured on #813,
#799, #688, #635 and #625, every one of which a person had to close by hand. So the act keeps
refusing `pull_request_open`, and `list-retirable-claims.sh` declines to offer such a branch at
all rather than handing the act a refusal it would repeat hourly. Closing that pull request is
the operator's own act, and once they take it the branch reaches the class by its own terms.

**The emptiness term is evidence on the row and a gate in the act, and only on the third class.**
On the candidate row `branch_empty` is three-valued evidence so CI's record can answer *how often
does a hand-closed branch still hold work* from real data; in the act it **fails closed**, because
a person's decision to close a pull request asserts nothing about the base — an `unanswerable`
emptiness refuses, which is the direction issue #788 turned `superseded`.

**The third class is never folded into the second.** They answer different questions — *the loop
delivered this* and *a person discarded this* — and one word answering two questions is how two
questions drift. Measured 2026-09-01: five branches whose pull requests the operator closed
unmerged as superseded (#801, #802 and #790 by #800; #520 by #519; #466 by #465), one closing
comment reading *"this branch and `main` repaired the same defect twice"*. A hand-closed branch
is **not empty by construction**, so `superseded` can never reach it and `retire-claim.sh` never
would.

**The residual risk is stated rather than hidden**: such a branch may still hold work found on no
other ref. That is why `branch_empty` (`true` / `false` / **`unanswerable`**, the third named
rather than assumed) rides both pull-request classes as **evidence and not as a gate** — CI's own
record answers *how often does that actually happen* from real data before anything is gated on
it. A `superseded_only` row carries no such field: that verdict already asserts the emptiness,
and a second copy of one fact is how two copies come to disagree.

**Measured, and why the second class was needed** (2026-09-01): 30 unmerged branches, 17 with a
merged pull request. A squash merge never makes the branch an ancestor of the base, so
`--no-merged` lists it forever; `delete_branch_on_merge` is **forward-only**, so every branch
merged before it was applied stands permanently; and `superseded` reaches almost none of them,
because it is keyed on a **unit** and needs a claim commit, which a publish-tree publication
never has. The printed deletion command was 17 lines long and nobody had run it.

**A live row beats a merged pull request, always.** A unit the oracle holds any live row for is
never a candidate whatever its pull request says: a run may be driving a **fresh** claim over a
merged predecessor, and the merged pull request is a fact about the old work. The rule stays
`claims_unit_resolution`'s, read rather than restated.

**An unreadable pull request is not a merged one.** `branch-pull-request-state.sh` emits no
`state` key at all on a degraded read, and such a branch contributes no candidate and is named
in `pull_request_unreadable[]` with its reason — never a bare omission, which reads exactly
like a branch whose pull request is open.

**`superseded` was NOT widened to cover this**, deliberately: the emptiness proof that verdict
now carries (2026-09-01, issue #788) is what makes `stranded` meaningful, and a merged branch
that still holds unlanded work is a real shape that must not be swept into the same word.

**And which executor took a delete is derived, never stored.** `deleted` means the tick that
reported it performed the delete; `already_gone` means the ref was not on origin when it looked,
and asserts nothing about who removed it. `/moderate` renders those as different sentences. A
`deleted_by:` field is refused: the answer is already on the row, and a stored one eventually
disagrees with the derived one.

**So the blocked retirement is reported and asked about only once CI has also been refused.** The
caller renders the acts that stand beside the act that is blocked, and `/moderate`'s
`retire-claims` step asks the **claim holder** once — keyed
`retire-blocked:<unit>:<refusal word>`, naming the exact branch left on origin — which is the
whole licence a blocked act carries. The candidate set is narrowed by `ci-retirement-turn.sh`.

**That reading rested on a premise which was the design and not the behaviour, and the sentence
is corrected here rather than deleted** (2026-08-29, mission
`read-back-whether-the-loop-s-own-act-took-effect`). It read:

> CI *deletes* the branch when it succeeds and unmerged remote branches are the only claim
> oracle, so a successful turn removes the claim row and the candidate with it; a completed run
> at the base tip the tick is reading therefore means CI saw exactly this tree and the branch
> survived it.

The inference holds only if every completed turn actually **reached its act**. Measured
2026-08-29: `claim-retirement.yml` was green on every run while three proved-`superseded` claims
stood on origin, and the tick log recorded, hour after hour, *"ci_turn: taken so CI could not
take the delete either"* — an assertion about a second executor that nothing established. (The
live cause, localized the same day: the CI-side act refuses `gh_unavailable` before its proof
gate, because `gh-rest.sh available` probes `gh api user`, which a `GITHUB_TOKEN` installation
token cannot call. The two executors' candidate readers were found to **agree**, so the
candidate-divergence hypothesis was not the live one.)

**What replaced it**: the turn now **records** what it attempted and what each act answered
(`record-ci-retirement-turn.sh`, read back by `read-ci-retirement-record.sh` off the check run's
annotations), and the reading answers **per unit** from that record — `taken` only on the act's
own success word, never on a run's existence and never on its exit status, which is green by
design because a refusal must not fail the job. The vocabulary and its classification are
*Whether an act the loop took had its effect* above. **The store-free property is narrowed, not
abandoned**: nothing is stored anywhere — no cursor, no queue, no ledger, no field on any
artifact — and only *which part* of the run is consulted changed.

A unit whose reading is `pending` has its question suppressed for that tick only — the asked-once
ledger keys on the unit and its refusal word, so a branch that outlives CI's turn is still asked
about later — while `refused:<word>`, `unavailable` and `unreadable` all suppress nothing,
because an over-eager question is better than a silently dropped one. Nothing releases the claim,
reopens the pull request, re-runs the delete on the strength of an answer, or touches the
`superseded` verdict. Drilled with no network by `sh scripts/e2e/loop-drill.sh verify-retire`
(the container's half), `verify-ci-retirement` (the split, both executors, every bound and the
narrowing) and `verify-act-effect` (the effect reading, both causes, and the changed-word
re-ask).

#### Whether the work behind a claim is still wanted (`claim-mission-state.sh`)

**Another keyed vocabulary in this home** (2026-09-02, mission
`retire-a-claim-whose-work-is-finished-or-abandoned`), emitted by
`drive/scripts/claim-mission-state.sh`. It sits here rather than in the `## Proofs and
judgements` chain for `candidate_reason`'s reason: it is a reading *about a retirement*, keyed
on a unit rather than on a claim verdict, and one column cannot classify two questions.

Retirement is keyed on the branch's own pull request, so nothing in the protocol could answer
*is the work behind this claim still wanted*. Measured: the operator closed a pull request and
abandoned its mission, and the tick reported that branch as stuck work hourly until a person
deleted it — a mission's end state is read by no claim-side script at all.

| Word | Class | What established it, and what a consumer may do |
| ---- | ----- | ----------------------------------------------- |
| `not_active` | **proof** | The mission is in `missions/archive/`, where `close.sh` — its only writer — put it. What makes this safe is **authorship**: a person's recorded decision that the work is finished or is not wanted, and re-opening is offered nowhere, so it cannot become false by looking again. Same standing, and the same argument, as `pull_request_closed_unmerged` above. |
| `active` | judgement | The mission is in `missions/active/`. It is a positive reading of the tree and not the absence of one — but it is designed to become false the moment somebody closes the mission, which is the one property a proof must not have. A consumer may **report** it or refuse on it; nothing may treat it as durable. |
| `batch` | **proof** | The unit id is a `batch-<ts>`, which names no mission at all. The id is immutable, so the reading cannot change; it **licenses nothing**, because *is this mission still wanted* has no subject here. It emits no `state` key, so a consumer keying on `state` cannot read the absence as a value. |
| `ok: false` (`mission_not_found`, `mission_list_unreadable`, `mission_area_unresolved`, `no_unit`) | judgement | The **absence of a reading**, which this protocol never acts on. No `state` key is emitted at all. A wrong `not_active` deletes a live branch; a wrong `ok: false` only makes a caller wait — the asymmetry that decides every reading here. |

**The area decides and `status` rides along.** `achieved`, `abandoned` and `carried` are three
different reasons the work stopped, so a consumer that must tell them apart has the word, while
one that only needs *is it still wanted* reads `state`. An archived mission whose `status:` is
empty still answers `not_active` with an empty `status` — the place is the record, and inventing
a status here would be a second writer of one.

**It is a reader and never a verdict.** It names no candidate, fires no act, moves no claim
verdict and writes nothing anywhere. Whether `not_active` is strong enough to license a branch
delete is the **candidate's** question, settled where the candidate is derived — the split
`branch-pull-request-state.sh` states for itself and the one `retire-claim.sh` refuses to
collapse.

**Consumers**: `drive/scripts/list-retirable-claims.sh` (the candidate reading), and
`moderate/scripts/step-stalled-units.sh` (which filters a retired-by-definition claim out of its
own candidates and counts it instead). A third must be registered here rather than slipping in
unclassified.

## Catch a claim up with a base that moved

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/catch-up-claim.sh <unit-id> [base-branch]
```

Added 2026-08-29 (mission `land-the-loop-s-own-work-when-the-base-moves-under-it`). A unit the
loop finished and could not deliver is stranded the moment the base moves under it:
`retry-undelivered.sh` re-attempts the **merge**, which GitHub refuses again every hour, and
`/moderate`'s `merge-conflicts` step reports the pull request and says in its own header that it
never rebases. Measured 2026-08-29 on this repository: 4 of 7 open pull requests conflicting
with `main`, three of them recorded `report_undelivered` two days earlier, with 4 active
missions and 10 queued tickets behind them.

**It is a composition, not a merge engine.** `ship/scripts/catchup-main.sh` already performs the
merge, resolves what it can prove needs no judgement and classifies the rest; `land-unit.sh`
already composes it in this order. What was missing was a caller an unattended run can reach —
`land-unit.sh` refuses `headless_context` first and unoverridably, by design, because it *lands*
a `review` unit on a present developer's ruling. This lands nothing: it merges the base **into**
the claim branch and pushes that branch, which needs no authorization the unit does not already
have.

**THE STANDING RULE IS NARROWED, NOT REVERSED.** `step-merge-conflicts.sh`'s header carries the
fullest statement: a third party rebasing a claim branch races the holder's own pushes and can
strand or duplicate a unit. Both halves are **answered**, and neither may be quietly widened:

- **Not a third party.** The claim is this identity's own — `foreign_identity` /
  `not_my_claim` refuse anything else, and a colleague's claim is untouchable at any age.
- **Not a rebase.** It is a **merge**. Never a rebase, an amend or a force-push, on any path: a
  merge commit keeps the claim holder's own checkout valid, which is precisely what a history
  rewrite destroys.
- **And not a race.** `claim_active` refuses a branch a run is still committing to, so the
  thing the standing rule is really about cannot arise.

What stays a person's is the **contested** case: a hunk the merge itself could not settle is
refused `content_conflict` — **and it is reported by the act, not asked about**. `/implement`
names `catch_up_refused: content_conflict` with the colliding files where the attempt happened;
`/moderate`'s `catchup-blocked` step was **retired** in the same 2026-09-02 change, on the
operator's own words about it — a conflict handed to a claim holder is handed to somebody who
never comes, and parked work then reads as progress to the loop and as stagnation to its
operator. **Since 2026-09-02 the refusal is the writer's residue, not the reader's prediction** —
the act attempts a `content`-classed branch rather than refusing before it is checked out, on
the reasoning in *The resolution strategy, per class* above.

**The order of its acts, and why.** Resolve the unit through the **live-row rule** (never
first-match — a unit held by a superseded branch and a live one is what a fresh claim over a
superseded one creates, and catching up whichever sorted first is the dangerous direction);
**re-derive the verdict at the moment of the act** rather than trusting a list handed in, the
discipline `delete-retired-claim-branch.sh` carries across an executor boundary; check the
bounds; read the mergeability; report `already_current` if there is nothing to do; **then**
check liveness and act. `already_current` sits before the liveness check on purpose — reporting
a no-op protects nothing, and refusing it would make an hourly re-run of a finished catch-up
look like a failure.

**Every refusal writes nothing and exits 0**, each by its own word: `content_conflict`,
`not_my_claim`, `foreign_identity`, `identity_unresolved`, `claim_active`, `dirty_worktree`,
`scan_held:<tier>`, **`pull_request_reviewed`**, **`reviews_unreadable:<reason>`**,
`not_a_work_branch`, `ambiguous_claim`, `mergeability_unanswerable:<reason>`, plus the
composition's own (`no_such_claim`, `no_origin`, `origin_unreachable`, `catchup_<class>`,
`validation_failed:<check>`, `push_failed`).

**`pull_request_reviewed` is the one bound the 2026-08-30 widening added, and it belongs to the
widening rather than to the act.** While the only candidates were `report_undelivered` units the
question could not arise: such a pull request was refused by a **transport**, so nobody is
looking at it. A `queue_drained` unit's pull request may be one a person is **mid-review** on,
and a push resets an approval. What counts as a person's attention is decided rather than
inherited from the seam: the reviews endpoint returns only **submitted** reviews, so presence is
submission; `APPROVED`, `CHANGES_REQUESTED`, `COMMENTED` and `DISMISSED` all count, because the
safer reading of an ambiguous seam is that somebody looked; and a **bot's** review is not a
person's, since a review bot comments on every pull request the loop opens and counting that
would refuse the whole widening. The lookup is **three-valued** for the reason the
merged-pull-request lookup is: every way of failing to ask answers `reviews_unreadable:<reason>`
and never falls through, because a wrong *nobody has reviewed* pushes over somebody's approval
while a wrong refusal only delays a unit by an hour. The one
state that is not byte-identical after a refusal is `validation_failed`: by then the merge is
committed **in the unit's own worktree**. The **branch** — the claim, the thing every other
runner reads — is untouched, because nothing was pushed; the local merge is reported as
`merged: true, pushed: false` rather than hidden, and it is not undone, because `git reset
--hard` is what the failure contract's safety floor forbids outright. A re-run merges nothing
new and re-runs the checks.

**It overrides no gate.** A `hard` (`secret`) or `confirm` (`leak`) finding holding a pull
request open is the gate *working*, so a scan-held unit is refused `scan_held:<tier>` — read off
the branch story, offline, exactly as `retry-undelivered.sh` reads it. The catch-up is not a
route around a gate.

**Idempotent**: a branch that already contains the base reports `already_current` and touches no
ref at all — no worktree, no merge, no push.

**What it composes, and what it may never re-derive.** The merge and the conflict
classification are `catchup-main.sh`'s; the classification *rule* is
`ship/scripts/lib/conflict-class.sh`'s, shared with the reader so the two cannot disagree; the
worktree is `create-mission-worktree.sh --branch`'s resume mode (`ensure-worktree.sh` refuses a
name already on origin, which is correct and is not worked around); the regeneration is the
repository's own tooling (`okf/scripts/refresh-index.sh`, `scripts/build-plugins/build.mjs`),
never a hand edit; the delivery that follows is `retry-undelivered.sh`'s.

**`--resolve-mechanical` is the one flag it passes, and the flag binds the caller.**
`catchup-main.sh` classifies a mechanical remainder and aborts by default, because "routine
reconciliation the agent performs itself" was written for a caller with an agent in it. Under
the flag it resolves a **generated** path by taking a side (which side is immaterial — the
content is derived) and a **version manifest** by raising both sides to the higher semver and
merging normally, so a side that also added a plugin keeps that addition. Taking one side
wholesale is the tempting shortcut and it silently drops the other side's edits. The obligation
the flag creates is the caller's: regenerate before pushing. Without the flag `catchup-main.sh`
is byte-for-byte what it was, which is what `land-unit.sh` still gets.

**`--own-tip` on the delivery that follows.** The catch-up's own push makes the tip fresh, so
the very next verdict reads `claim_active` and the delivery the catch-up exists to unblock would
be refused by the act that unblocked it. `retry-undelivered.sh --own-tip` relaxes that **one**
term, by re-asking `claims_scan` with `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0`: identity,
ancestry, supersession, the drained fork and the recorded refusal all stay the oracle's own
answers, computed in one place. Nothing is re-derived, no verdict is widened, and the scan-held
refusal is untouched. It is passed **only** immediately after this run's own `caught_up`.

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
