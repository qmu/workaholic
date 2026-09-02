# Loop Drill Runbook

How to exercise the propose–implement loop **on demand** instead of waiting for its
hourly ticks: seed an ask, fire each routine by hand, and read a machine verdict per
stage. One command owns the mechanics — `scripts/e2e/loop-drill.sh` — and this document
is the only one an operator needs from seed to a clean pass.

**This runbook documents the drill, not the loop.** Every rule about how the loop itself
behaves lives in the skill that owns it (`workaholic:specificate`, `workaholic:drive`,
`workaholic:notify`); the blame tables below point at those files rather than restating
them, so a rule change cannot leave a stale copy here.

**Why it exists.** Measured 2026-08-12: a discovery regression cost a full day of ticks
before a human read the logs. The loop was testable only by its own failures.

**Two Slack surfaces, both advisory.** The seed root and the routines' finish lines are
reported and never load-bearing — a stage is decided by its artifacts, never by whether
anyone was told about it.

## 1. The stages

Run every command from the repository root, on a clean `main`.

| # | Stage | Command | Reads |
| - | ----- | ------- | ----- |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-all --json` | **the whole classified set at once** (§9), one verdict per drill — `pass` / `fail` / `skipped:<reason>` — plus totals, exiting non-zero only when something actually failed. `--only <drill>` narrows it, `--kind hermetic` is what CI runs, `--list` answers the set without invoking any of it |
| 1 | Seed | `sh scripts/e2e/loop-drill.sh seed` | preflight (inbox + claims), then mints the issue and the `dev-workaholic` Slack root |
| 2 | Fire `[Specificate]` | run the `[Specificate]` routine by its trigger id | — |
| 3 | Verify propose | `sh scripts/e2e/loop-drill.sh verify-specificate <issue> --json` | `origin/main`, REST issue + pull requests |
| 4 | Fire `[Implement]` | run the `[Implement]` routine by its trigger id | — |
| 5 | Verify implement | `sh scripts/e2e/loop-drill.sh verify-implement <issue> --json` | `origin/main`, REST pull requests, unmerged `work-*` branches |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-plan --json` | this checkout's deployment targets and commit range — proves the plan refresh `[Implement]` carries |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-status --json` | the same targets read the `[Prepare Release]` way — proves the repository tick reads soundly and stays silent when nothing changed |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-cadence --json` | the same targets' **draft notes** — proves the daily generation renders, is idempotent and clock-free, and derives its stage |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-standup --json` | this checkout's strategies and their attributable work — proves the daily digest reads soundly, names its silence and writes nothing |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-moderate --json` | one `[Moderate]` tick against a throwaway root — proves every step reports, the log carries one section per tick, and the checkout is untouched |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-propose --json` | a throwaway strategy tree and a synthetic open-proposal list — proves every gate of `/propose`'s brake refuses by name, and that it writes nothing |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-direction-health --json` | a throwaway strategy tree, one overdue direction, one dormant one and one carrying no date at all — proves the four lifecycle readings, the question keys, the asked-once gate, and that nothing was written, with one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-arrival --json` | a throwaway **git** strategy tree carrying landed work — proves `arrived`, that it outranks `overdue`, that `dormant`, `overdue` and `live` are unchanged, the `direction-arrived:<slug>` key and its asked-once gate, and that no reading closes a direction, with no network and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-residue --json` | a throwaway **git** strategy tree whose attributed work has all landed beside an **unattributed** active mission — proves the honest and the degraded residue read, that only an unreadable residue refuses the arrival, that the question names the residue by slug, the asked-once gate, that no gate moved, and the attribution carry landing and refusing, with no network and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-corpus-boundary --json` | a throwaway **git** strategy tree whose corpus is grown past the `xargs` batching boundary — the boundary derived by probing `xargs` rather than hard-coded — proves both hops attribute across it, that the survey brakes on a real reading, that the residue excludes the citing mission and no arrival question is asked over work the tree attributes, and, beside it, the degraded direction: a named reason, a refused row, a residue that lists nothing and no question at all, with no network and **two** rows that deliberately break the seam, one per hop |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-expiry --json` | a throwaway **git** strategy tree of five directions differing only in their dates and their work — proves `expiring` inside the window, `live` outside it, `overdue` past the date and `arrived` above both, that the window is the survey's own rather than a constant, the `direction-expiring:<slug>` question naming the date, the days left and the leaving, its asked-once gate, and that no reading re-dates, closes or amends a direction, with no network and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-rulings --json` | a throwaway **git** repository holding exactly one unattributed active mission and exactly one unmapped address, with a bare local origin and `gh` stubbed — proves the set is read with its evidence and repair and **nothing judged**, that a judged set lands as one pull request the seam refuses to merge, that a second tick is a no-op while it is open, that a subject the ruling does not name still asks and says why, that every refusal writes nothing, with no network and a breaker in two halves |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-succession --json` | a throwaway **git** tree carrying one dated direction, its landed work and an unattributed mission — walks close → read the leaving → announce a successor by explicit slug → the carried refs land → `attributed-work.sh` attributes the predecessor's work to it → `/propose` proposes against it, and proves nothing closed, authored or auto-merged a direction, with no network and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-revision --json` | a throwaway strategy tree and a local bare origin — proves the three revisions land, that every refusal leaves the artifact byte-identical, and that a strategy-touching publish never auto-merges, with the transport stubbed and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-merged-claim --json` | a throwaway repository carrying a **squash-merged** mission claim and batch claim — proves all four merged-claim readings (merged batch, merged mission, live, unanswerable) **and that the work a `superseded` claim frees can actually be claimed**, with the transport stubbed, so no `gh` call is made, and **one row that deliberately breaks the seam** |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-identity-handoff --json` | a throwaway repository with a two-address mapping — walks issue assignee → the address the writer stamps → the survey that offers the unit, for a canonical address, a mapped alias and an unmapped login, with no network and no credential |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-close --json` | a throwaway repository carrying three finished units — proves all four closing outcomes (merged, session-type-refused-then-retryable, refused-and-unretryable, scan-held) with the transport stubbed, plus one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-catch-up --json` | a throwaway repository holding four finished-and-undelivered units — proves a mechanical conflict is caught up, validated and pushed with the higher version winning the manifest collision, a `content` one **attempted and then** refused with the branch byte-identical, a scan-held pull request never caught up, a second run a no-op, the refused conflict reaching its claim holder exactly once, and — since 2026-08-30 — the widened trigger: a `queue_drained` claim still `mechanical` offered and caught up, a reviewed pull request refused, and a degraded scan answering null counts; and — since 2026-09-02 — that a `content` **prediction** is offered to the act while a colleague's claim still is not; with the transport stubbed and three rows that deliberately break the identity bound and the two widenings |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-retire --json` | a throwaway repository holding a `superseded` claim, a live one and a unit held by two — proves the retirement's three acts, that a judgement is refused by its own verdict word, and that the step asks nobody anything, with the transport stubbed and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-stranded-claim-branch --json` | a throwaway repository whose bare origin permits a real branch delete — proves the ordinary superseded twin is still deleted, that a branch holding a file on no other ref is refused at both grains with the file still on origin afterwards, that an unreadable emptiness licenses nothing, and that the row names the files a person must rule on, with the pull-request half stubbed and one breaker asserting surviving content rather than a return word |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-ci-retirement --json` | a throwaway repository whose bare origin refuses the container's branch delete and permits CI's — proves the act the container is refused is taken where the write is permitted, re-proved at the moment of it, bounded four ways, and asked about only once CI has also refused, with the transport stubbed and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-delivery-retry --json` | a throwaway repository holding three units finished in the identical shape — proves the survey offers an undelivered unit in a field of its own, that only the proof reaches the merge seam, and that a scan-held or unrecorded one never does, with the transport stubbed and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-handoff-question --json` | a throwaway repository holding a reported claim whose still-queued work declares `verification_handoff:` — proves the declared reason reaches its holder verbatim exactly once, that `stalled-units` asks nothing about the same unit, and that nothing is cleared, with the transport stubbed and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-base-health --json` | a throwaway repository whose base is red at a mid-walk merge — proves the reader's three states, that a bookkeeping tip is walked past to the newest checked ancestor while every other unanswerable stays terminal, the attribution walk's two outcomes, that one broken commit costs exactly one question, and that the reading gates nothing, with the transport stubbed and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-return-path --json` | a throwaway repository holding two asked questions with their coordinates recorded — walks ask → reply → record → file → stamp → **outcome reply**, proves the read is bounded to the question's own thread, that a second tick files, stamps and replies nothing, that only a settled outcome earns a reply, and that neither the stamp nor the reply is load-bearing, with the transport stubbed and **two** rows that deliberately break the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-checkin-delivery --json` | a throwaway tick log spanning several days, with the day's asks all on **earlier** days — walks the whole path from a machine finding to a person (gate → ordering → step → event → root), proving a held question lands, that it is not re-asked, that the drain honours `max_per_tick` oldest-held first, that a genuinely spent day still holds, and that a tick which reached nobody supplies its event while a quiet hour stays silent, that the arrears name their depth, their age and the gate's own refusal word per held question, and that an `all_held` tick past the working-day boundary earns a root line while one inside it stays silent, with no network and two rows that deliberately break the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-findings-to-work --json` | a throwaway git repository and a stubbed `gh` — walks the whole path from a tick finding to the work queue (classification → brake → filing → dedup → suppression), proving a `needs_ruling` finding never reaches the filer, that one open finding issue holds the rest, that a second tick files nothing, and that the filed step's question is held while every other step's still asks, with no network and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-operator-pulls --json` | a bare local origin and a stubbed `gh` — the pull requests the loop opens FOR A PERSON: membership derived from the publish seam's own refusal word (so a retitled ruling is still named and an auto-merged `[Proposal]` never is), the reader's four values with the null age on `unreadable`, the question reaching its person exactly once over two ticks, the settled case asking nobody, and that nothing merges, closes or gates — with no network and one row that deliberately breaks the seam by keying membership on the title |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-stage --json` | a throwaway git repository holding four directions — one per declared stage plus one carrying **no** `stage:` line — walks the staged lifecycle end to end (declare → move → read → gate → order → render → ask), proving the closed set is floored with nothing written on a refusal, that an absent field reads 進行中 and says it was not declared, that a move appends one dated line naming both ends and re-runs as a no-op, that the derived lifecycle state is identical across all three stages, that 観察中 originates nothing while staying visible, that 改良中 sorts first, that the digest and the question name the stage, that the transition question is asked exactly once, and that no reading moved a stage or reached a writer — with no network and one row that deliberately breaks the seam by wiring the gate at a derived reading |
| — | Any time | `sh scripts/e2e/loop-drill.sh status` | the drill's residue: issues, claim branches, tickets |
| — | After an abort | `sh scripts/e2e/loop-drill.sh reset` | closes/deletes **drill-minted** residue only |

`seed` prints `{"ok": true, "run_id", "issue_number", "issue_url", "assignee",
"slack_posted", …}`. The `issue_number` is the argument every later stage takes; nothing
else is carried between stages, because each relation is read back out of the artifacts.

**Firing a routine by hand.** The routines are account-scoped configuration, so their
**trigger ids** come from the trigger API's list (a `RemoteTrigger`-family tool, exposed
to interactive sessions only — `workaholic:workaholify`, *Direct-apply when
`RemoteTrigger` is exposed*), never from a value written down here. List the account's
routines, take the id of `[Specificate]` / `[Implement]`, run it, then read its session: the
run list first, then that run's log. A **scheduled** tick that happens to take the ask
first verifies identically — the drill asserts artifacts, and the artifacts do not record
which fire produced them.

## 2. Timing

Both routines fire hourly on explicit non-zero minutes (the API's minimum interval is one
hour, and a bare `:00` is rewritten to server jitter):

| Routine | Cron | Avoid firing by hand around |
| ------- | ---- | --------------------------- |
| `[Specificate]` | `15 * * * *` | **:10–:20** |
| `[Implement]` | `30 * * * *` | **:25–:40** |

Inside those windows a scheduled tick and your manual fire can both take the same ask.
Nothing corrupts — `[Specificate]` dedups on the feedback stream and on unmerged branches, and
`[Implement]`'s claim protocol lets exactly one runner hold a unit — but the loser's
session log reads like a failure (`already_captured`, `already_claimed`), which is a
diagnosis you did not need. Fire in the quiet half of the hour and both logs stay
readable.

Between stages 2 and 3, wait for the `[Specificate]` session to finish. A verify run against a
still-running fire reports `pending`, not `fail` (§3) — it is safe to run early, just
uninformative.

## 3. Reading a verdict

Each verify subcommand emits one JSON line:

```json
{"ok": true, "stage": "propose", "issue": 412, "verdict": "pass",
 "load_bearing": {"passed": 5, "failed": 0}, "advisory": 1, "rows": [...]}
```

Every row is `{check, pass, detail, bearing}`. `detail` names the file or ref the check
read — or, on a failure, the one it **expected**, which is the file to open.

| `verdict` | Exit | Means |
| --------- | ---- | ----- |
| `pass` | 0 | every load-bearing row is true |
| `fail` | 1 | the stage ran and at least one load-bearing row is false |
| `pending` | 5 | the stage **has not run yet** — no artifacts, the ask still open |

`pending` is deliberately not `fail`: a routine nobody fired has not failed, and reporting
it red is how an operator learns to ignore red.

| `bearing` | `pass` values | Effect on the exit code |
| --------- | ------------- | ----------------------- |
| `load` | `true` / `false` | decides the verdict |
| `advisory` | `true` / `false` / `null` (unread) | **none, ever** |

`--json` emits the full row set; without it only the rows that are not passing — the ones
to act on.

**The load-bearing rows.**

| Stage | Row | What it asserts |
| ----- | --- | --------------- |
| propose | `feedback_record` | a record under `.workaholic/feedbacks/` on `origin/main` names `/issues/<N>` |
| propose | `issue_closed` | the merged proposal's `Closes #<N>` closed the ask |
| propose | `proposal_pr_merged` | a pull request carrying `Closes #<N>` exists **and merged** |
| propose | `ticket_feedback_ref` | a ticket reaches that record — **directly** (a loose ticket naming the stem) or **through the mission** (`mission.feedback` names the record, a ticket carries `mission: <slug>`); the detail says which. `null`/advisory when the proposal was record-alone; **false** when a mission names the record but no ticket carries its relation |
| propose | `ticket_assignee` | the ticket carries the issue's assignee, not the runner's identity — **either spelling**: the GitHub login, or the git email `.claude/git-identities` maps it to, which is what the propose seam actually writes |
| implement | `ticket_archived` | the ticket moved to `tickets/archive/<branch>/` |
| implement | `story_exists` | a story under `.workaholic/stories/` names the unit |
| implement | `unit_pr_merged` | the unit's pull request merged |
| implement | `claim_released` | **this unit's** branch is no longer an unmerged `work-*` branch |

`claim_released` is narrow on purpose: a colleague's live claim is named in the row's
detail and never fails it, because a red an operator cannot act on is worse than no check.

**The unverifiable-unit fixture** (2026-08-14, issue #452). Seed the drill ticket with a
non-empty `verification_handoff:` — the declaration that the work's real-world verification
needs something an unattended run does not have — and the implement stage swaps its last two
rows for the inverse assertions, because that unit must **not** merge:

| Stage | Row | What it asserts |
| ----- | --- | --------------- |
| implement | `unit_pr_handed_off` | the unit's pull request is **open**, carries `## Handoff`, and names the declared verification |
| implement | `claim_held` | the branch is **still** an unmerged `work-*` branch — the unit stays owned while it waits for a person |

`ticket_archived` and `story_exists` are unchanged: a declared handoff has finished its work,
so its tickets archive normally and only the verification waits. The fixture is selected by
reading the archived ticket, never by a flag, so the drill routes on exactly the file the run
routed on. The Slack row is `slack_handoff_line` rather than `slack_finish_line`, and stays
advisory like every notification row.

**One advisory row on the propose stage**: `proposal_form` names which of the three
sanctioned shapes the proposal emitted — `loose ticket`, `mission <slug>`, or `record
alone`. It is deliberately **not** load-bearing: the drill can see which form was emitted,
never which form the ask warranted, and a row that graded that choice would fail every
correctly-record-alone proposal. Read it to understand a stage, never to judge one.

## 4. Blame table — the `[Specificate]` stage

Every abort reason the propose workflow can report, and the **one file to read** for it.
The reasons themselves are defined in `plugins/workaholic/skills/specificate/SKILL.md` and
[`reference/workflow.md`](../plugins/workaholic/skills/specificate/reference/workflow.md).

| Reason | Read |
| ------ | ---- |
| `nothing_in_hand` | `skills/specificate/scripts/list-inbound-issues.sh` — the inbox was genuinely empty (did `seed` really assign the issue to the running identity?) |
| `not_mine` | `skills/specificate/SKILL.md` (*Clock-fired discovery*) — the ask is assigned to somebody else; a `/specificate` run never takes it |
| `gh_unavailable` | `skills/gather/scripts/gh-rest.sh` — no `gh` on the runner's PATH |
| `identity_unresolved` | `skills/gather/scripts/gh-rest.sh` — `gh api user` returned nothing; the session's credential is the problem |
| `list_failed` | `skills/gather/scripts/gh-rest.sh` — REST itself failed; the `detail` carries the API's own message |
| `already_captured` | `skills/specificate/scripts/list-inbound-issues.sh` — a feedback record on the base already names `/issues/<N>`; the ask is settled, not new |
| `captured_on_branch` | `skills/specificate/scripts/list-inbound-issues.sh` — a record on an unmerged remote branch names `/issues/<N>`; the ask is in flight behind an open proposal's pull request |
| `no_publish_tree` / `nothing_to_commit` | `skills/branching/scripts/open-publish-tree.sh` — the publish tree was never opened, or the run wrote nothing into it |
| `commit_failed` | `skills/commit/scripts/check-subject.sh` — the commit subject failed the gate (present tense, ≤50 chars, no prefix) |
| `branch_collision` | `skills/branching/scripts/publish-tree-pr.sh` — two publishers minted the same second's branch name; nothing was published and a re-run succeeds |
| `push_failed` | `skills/branching/scripts/publish-tree-pr.sh` — the remote refused the push; nothing is published |
| `no_gh` / `pr_failed` | `skills/branching/scripts/publish-tree-pr.sh` — **the branch IS pushed**; see §6 |
| `merge_failed` | `skills/branching/scripts/publish-tree-pr.sh` — the auto-merge did not go through; the pull request is open and a human merges it. A release-scan finding is the legitimate case |
| `no_plugin_source` | `skills/check-deps/scripts/plugin-src.sh` — no plugin tree could be resolved at all; this is the one precondition stop |

## 5. Blame table — the `[Implement]` stage

The terminal token and its causes are the drive skill's §7 table
(`plugins/workaholic/skills/drive/SKILL.md`); the operational fixes are
[`drive-loop-runbook.md`](drive-loop-runbook.md) §6. What a drill needs is the mapping
from what the tick printed to the one file to read.

| The tick reported | Read |
| ----------------- | ---- |
| `pending` with a unit **blocked** | `skills/drive/SKILL.md` §6 — which gate hard-stopped (a `secret` finding is never overridable) |
| `pending` with a unit **demoted to PR** | `skills/drive/SKILL.md` §6 — an `auto` unit hit an overridable gate; the pull request is waiting for a human |
| `pending` with a unit in **handoff** | the unit's pull request `## Handoff` section — the authoritative record; the run report is only the log |
| `pending`, `current: false` | `skills/branching/scripts/sync-main.sh` — the checkout never saw the base's tip |
| `pending`, `backlog_error` | `skills/drive/scripts/plan-units.sh` — the queue was not read at all (`identity_unresolved` = no `git config user.email`) |
| `pending`, `shallow: true` | `skills/drive/scripts/lib/claims.sh` — truncated history, so merged branches cannot be told from live ones |
| `pending`, `loaded_version_behind_registry` / `registry_unreadable` | `skills/check-deps/scripts/plugin-src.sh` — the session bound a superseded plugin; the run drives from the newest tree instead of stopping |
| `not_on_main` / `dirty_workspace` / `diverged` | `skills/branching/scripts/sync-main.sh` — the runner checkout is not in a surveyable state |
| the drill ticket never offered: `mission_member` | `skills/drive/scripts/plan-units.sh` — it names an active mission and is driven only inside that mission's unit |
| `no_plan` / `no_tickets` / `queue_drained` | `skills/mission/scripts/queue-size.sh` — write the acceptance criteria, emit the ticket set, or decide the close |
| `owned_by_other` / `owner_unresolved` | `skills/gather/scripts/owners.sh` — the one ownership oracle; `seed` assigns the ask, so a mismatch starts there |
| `mission_closed` | `skills/drive/scripts/plan-units.sh` — the ticket's missions have all closed; it is ordinary backlog now |
| `already_claimed` / `claimed_active` / `claimed_reported` / `claimed_by_other` | `skills/drive/scripts/list-claims.sh` — another runner holds the unit; expected, no action |
| `deferred_by_operator` | `skills/drive/SKILL.md` §2 — cannot occur in a drill: the fire is `/implement`, which asks nothing. Seeing it means an attended `/drive` took the unit instead |
| `claimed_resumable` / `heartbeat_lapsed` | `skills/drive/reference/claims.md` — your own dropped claim; `claim.sh resume <unit-id>` continues it |
| `claimed_superseded` / `superseded` | `skills/drive/scripts/lib/claims.sh` — the claim's tickets are already archived on the base by another route; it holds no work, nothing acts on it, and it does not forbid `ok` |
| `report_incomplete` | `skills/drive/scripts/lib/claims.sh` — your own claim whose queue is drained and whose branch carries no story: the run died before opening the pull request. `claim.sh resume <unit-id>` takes it over and enters at §5, re-driving nothing |
| `branch_collision` on claim | `skills/drive/scripts/claim.sh` — nothing was claimed; the next tick succeeds |
| `origin_unreachable` / `no_origin` | `skills/drive/scripts/claim.sh` — an unpushed claim is not a claim; the run correctly claims nothing |
| `mission_missing` | `skills/drive/scripts/claim.sh` — wrong slug, or the checkout is behind the base |
| `pr_error: gh_unavailable` | `skills/story/scripts/create-or-update.sh` — the work **is** pushed; only the pull request is missing |

## 5b. The deployment-plan refresh

`verify-plan` needs no seed, no fire and no issue number: it drafts a plan into a
**scratch note in the temp directory** using this repository's real deployment targets
and real commit range, so it writes nothing under `.workaholic/` and can be run at any
moment, including mid-drill.

It exists because the refresh has no routine of its own. The carrier is `[Implement]`'s
existing hourly tick, through `/ship`'s drafting phase (`CLAUDE.md`, *Routines*), which
means the only other way to observe it is to wait an hour and read a note. Three
load-bearing rows, all three of which the carrier depends on:

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `plan_drafted` | the consolidation could not read this checkout | `skills/ship/scripts/read-deploy-state.sh` — an unresolvable base, or no `.workaholic/deployments/` target |
| `plan_idempotent` | a second run against an unchanged base changed the note | `skills/ship/scripts/draft-deploy-plan.sh` — something time-varying leaked into the section; an hourly carrier would now commit every tick |
| `plan_degraded` | an unreadable base did not skip cleanly | `skills/ship/scripts/draft-deploy-plan.sh` — a degraded read must report its reason and leave the note untouched, never half-write |

A red `plan_idempotent` is the one to act on first: it does not break a single ship, it
breaks the *periodic* property the whole refresh rests on.

## 5c. The `[Prepare Release]` read

`verify-status` needs no seed, no fire and no issue number either, and it writes
nothing anywhere — which is the routine's whole contract, so a drill that asserted it by
construction is the point rather than a convenience.

`[Prepare Release]` (repository scope, `45 * * * *`, configured by `/setup-repo-routines`
from **one** account) runs `/prepare-release`, a pure read. On a healthy quiet repository
its correct output is *no Slack message at all*, which makes "did it work?" unanswerable
by watching the channel. Five load-bearing rows:

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `status_read` | the consolidation could not read this checkout | `skills/ship/scripts/report-deploy-status.sh` over `read-deploy-state.sh` — an unresolvable base, or no `.workaholic/deployments/` target |
| `status_stable` | two reads of an unchanged base returned different digests | `skills/ship/scripts/report-deploy-status.sh` — something varying leaked into the digest input; the routine would now post every hour, which is the idle tick `workaholic:notify`'s bright line refuses |
| `status_degraded` | an unreadable base did not refuse cleanly | `skills/ship/scripts/report-deploy-status.sh` — a refusal must name its reason and yield an empty digest, never a digest over partial rows |
| `status_refs` | the read reported no `refs` field | `skills/ship/scripts/report-deploy-status.sh` — the freshen and its report were removed or renamed; without them the count silently inherits whatever refs the container holds |
| `status_refs_optout` | `WORKAHOLIC_DEPLOY_FETCH_TIMEOUT=0` did not report `skipped` | `skills/ship/scripts/report-deploy-status.sh` — the offline opt-out is load-bearing for a container behind a filtering proxy, and a fetch it cannot skip is one that can hang the tick |

`status_stable` is this stage's `plan_idempotent`: a single read is still correct when it
is red, and the *hourly* property is what breaks. The most likely regression is the base
sha finding its way into the digest input — it is excluded on purpose, because a base
that merely advanced is not news.

`status_refs` and `status_refs_optout` are newer (2026-08-18) and cover the failure the
other three could not see: the reader never fetched, so the boundary came from whatever
refs the clone arrived with. Measured in a live container — **no tags** and an
`origin/main` five days stale — one unchanged repository reported 2721 commits
(`full_history`), then 2950 (`full_history`), then the true 4 (`latest_tag:v1.0.185`),
with a different `deploy:<digest>` each time. `status_stable` stayed green throughout,
because *within one container* the digest was perfectly stable; what moved was the answer
*between* containers. Read a red row here as "the tick's number is now only as good as
the clone", and the degraded rendering (`refs: stale|skipped` ⇒ the post withholds the
count) as the part that keeps a wrong number from being published as a right one.

## 5d. The daily note cadence

`verify-cadence` needs no seed, no fire and no issue number, calls no network, and writes
nothing. It exists for the same reason as `5c`: the behaviour it covers is otherwise only
observable by **waiting a day** and then reading a GitHub draft release.

The generation rides the same `[Prepare Release]` tick (one repository-scoped routine, both
jobs — `workaholic:ship` §7, *The cadence*). It is bounded to once per `Asia/Tokyo` day,
refreshes immediately whenever the release stage advances, and writes only a GitHub
**draft** release — never a file, a commit or a branch. Four load-bearing rows:

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `cadence_renders` | no draft body rendered for a declared target | `skills/ship/scripts/draft-release-note.sh` over `read-deploy-state.sh` — an unresolvable base, or no `.workaholic/deployments/` target |
| `cadence_idempotent` | two renders of an unchanged base differ | `skills/ship/scripts/draft-release-note.sh` — something non-derived reached the body; a periodic generator would now rewrite the draft on every tick |
| `cadence_clockfree` | a render a second later differs | the same script — a clock leaked into the body. This is the specific failure the whole design refuses: a timestamp is what turns an idempotent drafter into a write treadmill |
| `cadence_stage` | the release stage was not derived | `skills/ship/scripts/run-note-cadence.sh` — the stage comes from git and `.workaholic/releases/`, never a stored cursor |

`cadence_idempotent` and `cadence_clockfree` are this stage's `plan_idempotent`: a single
render is still correct when either is red, and the *periodic* property is what breaks.
They are separated because they fail for different reasons — the first catches anything
non-derived (a network read, an unordered set), the second catches a clock specifically,
which is why the drill takes the two renders a second apart.

## 5e. The `[Standup]` read

`verify-standup` needs no seed, no fire and no issue number either, and it writes nothing
anywhere. On a repository with **no strategy authored — which is this one today** — the
correct output is *no Slack message at all*, so "did it work?" is unanswerable by watching
the channel; that is exactly why the stage exists.

`[Standup]` (repository scope, `5 0 * * *` — 09:05 Asia/Tokyo, configured by
`/setup-repo-routines` from **one** account, the second routine in that scope) runs
`/standup`, a pure read. Four load-bearing rows:

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `standup_read` | the digest could not be computed from this checkout | `skills/standup/scripts/digest.sh` over `skills/strategy/scripts/attributed-work.sh` — a missing script, or a malformed strategy record |
| `standup_noop_named` | a quiet morning produced `noop: true` with no reason | `skills/standup/scripts/digest.sh` — a nameless empty digest is indistinguishable from a read that failed, and the whole silence rule rests on the distinction |
| `standup_writes_nothing` | the working tree changed across two reads | `skills/standup/scripts/digest.sh` — the routine's contract is that it writes nothing; a daily unattended tick that writes is a new class of write on `main` |
| `standup_degraded` | an absent knowledge root did not answer cleanly | `skills/standup/scripts/digest.sh` — a degraded read reports `no_strategies` and exits 0, because a non-zero exit is a silent morning nobody explains |

`standup_writes_nothing` is this stage's `plan_idempotent`: the digest can be perfectly
correct and still be the wrong artifact if it left something behind. The likeliest
regression is a helper that starts caching its answer to a file "to be idempotent", which
is the opposite of what a reader needs.

## 5f. The `[Moderate]` tick (the `/moderate` run)

**The drill stages are named after the commands, and this one was renamed on 2026-08-21**
(issue #555). It was `verify-propose` — the verb the maintenance tick kept from the name
it held before the 2026-08-19 rename — and the 2026-08-19 decision to leave it alone was
right at the time, because the freed name was claimed by nobody and moving an operator's
muscle memory for no behaviour is a bad trade. That is no longer the situation: `/propose`
is a real, different command with its own drill below, so the old verb named the wrong
command outright, which is worse than an ugly one. `verify-specificate` is untouched and
still drills `/specificate`. Read a stage name as the command it runs, never as the
routine that schedules it.

`verify-moderate` needs no seed, no fire and no issue number, and it runs the tick against
a **throwaway root** so a drill never appends to the operator's own
`.workaholic/moderations/` log.

`[Moderate]` (repository scope, `50 * * * *`, configured by `/setup-repo-routines` from
**one** account) runs `/moderate`: one log line per registered step. **The drill no longer
carries the number** (2026-08-26): it was a literal here and in `loop-drill.sh`, it went stale
on every step the tick gained — nine, then ten, then a fifteen-step tick still drilled against
ten — and a drill that is red for its own bookkeeping teaches people to ignore it. Both rows
now derive the count from `run.sh`'s own `STEPS`, so a step added tomorrow needs no edit and a
step that stops reporting still fails. On a healthy quiet repository its correct output is again
*no Slack message at all*, so the channel cannot tell you whether it worked. Five load-bearing
rows:

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `moderate_steps` | fewer steps reported than `run.sh` registers | `skills/moderate/scripts/run.sh` — the step list is the contract, and a step that goes missing must still emit a `degraded` row rather than vanish |
| `moderate_built` | a step still reports `not_implemented` | this checkout carries a half-landed mission — the step's own ticket names what is missing |
| `moderate_log` | the tick wrote no log, or more than one section, or not one line per registered step plus the persist | `skills/moderate/scripts/log-append.sh` — one `## <tick>` section per tick, idempotent per (tick, step) |
| `moderate_persist` | the throwaway root was not skipped by name | `skills/moderate/scripts/persist-log.sh` — a drill must never publish |
| `moderate_clean` | the tick changed the checkout | a maintenance tick that dirtied the tree would be writing to `main` hourly; findings become records and tickets through the publish seam, never a direct edit |

`moderate_steps` is this stage's `status_stable`: a single tick is still useful when it is
red, and what breaks is the *coverage* property — an hourly report that silently covers all
but one of its steps reads exactly like one that covers every step.

## 5g. The `[Propose]` brake (the `/propose` run)

`verify-propose` needs no seed, no fire, no issue number and **no network**: it builds a
throwaway strategy tree, hands the survey a synthetic open-proposal list through
`--open-proposals`, and checks that each gate refuses **by name**.

It is the drill that matters most on this routine, and for a reason none of the others
have: `/propose` is the one routine here that drops the standing *when unsure, record
only* bar on purpose, so what bounds it is not a judgment but this gate list. **Since
2026-08-26 the bounded thing is a mission**: a proposal plans a whole mission with an
ordered ticket set, and `work_waiting` reads an *active attributed mission* as well as a
queued ticket — so the drill covers the case the change-grain gate left open (a mission
whose queue is drained while its work is at a pull request) and the case that proves the
gate still releases (a closed mission). The chain end to end is
`verify-propose` plus `verify-specificate <issue>`; only the first runs with no network. A gate that
quietly stops gating looks exactly like a routine working normally — right up to the hour
it opens one issue per strategy per tick.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `propose_nearest_first` | the tick took a direction other than the one whose `target_date` is nearest | `survey-strategies.sh` — eligible strategies sort by `days_to_target` ascending |
| `propose_gate_<slug>` | a strategy that should have been refused was not, or was refused as something else | the gate table in `workaholic:propose`; each row names one of `not_active`, `not_mine`, `past_target_date`, `no_feedback_refs`, `over_cap` |
| `propose_in_flight` | a strategy whose last proposal is still open was proposed against again | the in-flight half of the brake — with `work_waiting` it gives *one **mission** per strategy at a time* (2026-08-26; *one proposal* while the unit was a change), and losing it is what would make the dropped bar unbounded |
| `propose_mission_in_flight` | a strategy whose attributed mission is active with a **drained** queue was proposed against again | the window the change-grain gate left open: the mission's last ticket is at a pull request, so no ticket is queued and a second mission would be proposed |
| `propose_mission_released` | a strategy whose mission has been closed is still gated | "one mission at a time" has to release, or it is a stall rather than a brake |
| `propose_floor_mission_shape` | a body naming no `## Experience` and no `## Tickets` was accepted | the proposal's unit is a mission, so a body that names neither has not planned one |
| `propose_floor_two_tickets` | a proposal naming fewer than two tickets was accepted | the proposing seam's own ticket floor, mirroring `check-floor.sh` at the publish seam |
| `propose_floor_alternative` | the `under_planned` refusal states only the rule | a refusal that does not name the alternative leaves the caller retrying the same thing |
| `propose_unreadable_inbox` | an unreadable open-proposal list did not refuse the whole tick | a gate that cannot be read is not a gate; the tick must never fall through to a permissive default |
| `propose_floor_sections` | a body naming no fork it is chosen against was accepted | the anti-housekeeping floor — "tidy this up" is chosen against nothing |
| `propose_floor_move` | a proposal declaring no `depth`/`breadth`/`contraction` move was accepted | a proposal that cannot say which evolutionary move it is has made no claim on the strategy |
| `propose_clean` | the drill changed the checkout | `/propose` writes nothing into the repository; its only write is a GitHub issue |

`propose_in_flight` and `propose_unreadable_inbox` are this stage's `status_stable` pair:
either one going red means the routine is no longer bounded, which is the only failure here
that gets worse every hour it runs.

## 5h. The direction layer's own health (the `direction-health` step)

`verify-direction-health` needs no seed, no fire, no issue number and **no network**: it
builds a throwaway strategy tree — one direction **past its date**, one live and unanswered,
and one carrying **no `target_date` at all** — hands the survey a synthetic open-proposal
list through `--open-proposals`, and reads `direction-state.sh` and
`step-direction-health.sh` over it.

The undated direction is the drill's **breaker**, and it is there because the boundary it
pins is one jq will silently invert: `overdue` is `days_to_target < 0` **and the date
resolves**, and an undated direction's `days_to_target` is `null` — which jq answers `null
< 0` with `true`. Drop the null guard and an undated direction earns an hourly
`direction-overdue` question about a date it never had. Neither other fixture can notice:
one has a past date and one a future date, so both read the same with the guard or without
it.

The overdue fixture is the one that matters: it is the case `pace` *cannot* carry, because
`late` requires nothing to have landed, so a direction that sailed past its date while
producing work reads `on_course` and used to be told to nobody. And the failure mode this
drill exists for is the one no channel can show you: **an hour with no post looks exactly
the same whether the reading fired and found everything healthy or the step is broken.**

The open-proposal read is **supplied, not stubbed** — `survey-strategies.sh` refuses the
whole tick rather than proceed without it, so faking the transport would drill a path that
does not exist.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `direction_state_gone` | a direction past its `target_date` does not read `overdue` | `survey-strategies.sh`'s `overdue`, projected by `direction-state.sh`; check `days_to_target` first |
| `direction_state_quiet` | a live, in-date, legible direction with nothing landed and nothing waiting does not read `dormant` | the `dormant` conjunction in `survey-strategies.sh` — one term of it stopped holding |
| `direction_state_none` | a tree with no `active` strategy does not read `none` at the repository level | `direction-state.sh`'s repository field, which reads the survey's `active_count` |
| `direction_state_unreadable` | a survey that refused was not reported `unreadable` | `direction-state.sh`'s degrade path — a reader that could not read must never render as quiet |
| `direction_health_undated_is_never_overdue` (**breaker**) | a direction with no `target_date` reads anything but `dormant` — `overdue` above all | the `overdue` derivation in `survey-strategies.sh`: its `(.days_to_target != null)` guard has gone, and jq answers `null < 0` with `true` |
| `direction_health_keys` | the step's question keys are not exactly `direction-overdue:<slug>` and `direction-dormant:<slug>` | `step-direction-health.sh`; the keys are what the asked-once ledger keys on, so a drifted key is a question asked twice or never |
| `direction_health_key_none` | an empty tree does not ask `direction-none` | the repository-level branch of the same step |
| `direction_health_asked_once` | the same key is asked again on a later tick | `ask-question.sh`'s ledger, not this step — the step supplies subjects and the check-in owns the gate |
| `direction_health_writes_nothing` | the drill changed the checkout | the reader and the step are pure reads; the strategy artifact has three writers (`create.sh`, `amend.sh`, `close.sh`) and none of them is here |
| `direction_health_overdue_names_the_revision` | the `overdue` body does not offer re-dating, names `amend.sh` instead of the operator's own act, or breaks the 25-word bound | `step-direction-health.sh`'s `subjects` block — the act is named in the operator's vocabulary, and the script is not theirs to run |
| `direction_health_dormant_unchanged` | the `dormant` body was widened by reflex | the same block; a direction nothing is answering is not thereby mis-dated, so its question keeps two acts |
| `direction_health_fixtures_intact` | the seeded `strategies/` area changed | the same refusal, measured on the tree the step actually looked at rather than on the checkout |

**Two proofs, and they are not the same one.** This drill is the **operator's**, run on
demand in a checkout; the hermetic suite's `testDirectionHealthRefusals` is what **CI**
enforces on every change. The drill exercises the real script closure end to end with the
real survey beneath it; the suite pins the three refusals mechanically (nothing written
under `.workaholic/strategies/`, no reach to `close.sh` or `open-proposal.sh`, exactly two
writers, no `/propose` gate outcome moved). Neither replaces the other: the drill ships to
no other agent and CI never runs it, and the suite cannot prove an operator's checkout
behaves.

## 5i. The direction that has arrived (`verify-arrival`)

`verify-arrival` needs no seed, no fire, no issue number and **no network**: it builds a
throwaway strategy tree — and, unlike `verify-direction-health`'s, that tree is a **git
repository**, because `landed[]` is a `git log --since` reading and a fixture that is only a
directory would yield an empty `landed[]` for every strategy, making every arrival row pass
while proving nothing.

Five directions, one per reading: `arrived` (work landed, nothing waiting), `latearrived`
(the same, **past its date** — the case the whole mission exists for), `quiet` (nothing
landed → `dormant`), `gone` (past its date with nothing landed → `overdue`), and `busy`
(landed work **and** a queued ticket → `live`). The last is the **deliberately broken
seam**: if `quiescent` ever stopped reading the waiting terms, `busy` is the only fixture
that would notice, and every other row here would still pass.

The failure this drill exists for is the loop reporting a **success as a failure**: a
direction whose work is all in used to read `overdue` once its date passed, so the operator
was asked hourly to re-date or close something that had already finished.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `arrival_fixture` | the fixture produced no attributed work inside the window | the fixture is not a git repository, or `attributed-work.sh`'s `changed_in_window` read moved — every row below would be vacuous |
| `arrival_state_arrived` | a legible, live, cited direction with work landed and nothing waiting does not read `arrived` | the `quiescent` conjunction in `survey-strategies.sh`, projected by `direction-state.sh` |
| `arrival_state_latearrived` | a direction both **arrived and overdue** does not read `arrived` | `direction-state.sh`'s precedence — `arrived` outranks `overdue` on purpose, and reordering it is the change this row catches |
| `arrival_state_quiet` | a direction with nothing landed stopped reading `dormant` | the `dormant` conjunction; `landed` empty versus non-empty is the one term separating the two readings |
| `arrival_state_gone` | a direction past its date with nothing landed stopped reading `overdue` | `survey-strategies.sh`'s `overdue`; check `days_to_target` first |
| `arrival_waiting_work_is_not_arrival` | a direction with work still waiting reads `arrived` | the waiting terms of `quiescent` — **the broken seam**: arrival is being asserted over work in flight |
| `arrival_state_unreadable` | a survey that refused was not reported `unreadable`, or reported an arrival anyway | `direction-state.sh`'s degrade path and its `counts` zero-object |
| `arrival_question_keys` | the step's keys are not exactly `direction-arrived:<slug>` for each arrived direction, beside the existing two | `step-direction-health.sh`'s `subjects` block; the key is what the asked-once ledger keys on |
| `arrival_body_describes_the_reading` | the body does not name what landed and the date, breaks the 25-word bound, or asserts the direction is finished | the same block — the reading is a **candidate**, never a verdict, because "Reached when" is prose no script reads |
| `arrival_event` | the arrival does not reach the `🔎 Moderation` root, or is not linked | the step's `event` phrase; `arrived` leads it, in the reader's own precedence order |
| `arrival_all_live_renders_no_line` | a tick with nothing but `live` directions supplies a non-empty `event` | the step's early `emit ok` — the independent guard against a "nothing happened" line reaching the root |
| `arrival_asked_once` | the same key is asked again on a later tick | `ask-question.sh`'s ledger, not this step — the step supplies subjects and the check-in owns the gate |
| `arrival_closes_nothing` | the step's or the reader's closure reaches `create.sh`, `amend.sh` or `close.sh` | a reading that says a direction looks finished is one step from a routine that closes it; the strategy artifact has three writers and neither of these is one |
| `arrival_writes_nothing` | the drill changed the checkout | both scripts are pure reads; the fixtures live outside the checkout |
| `arrival_fixtures_intact` | the seeded `strategies/` area changed | the same refusal, measured on the tree the step actually looked at |

**Two proofs, and they are not the same one** — the split `verify-direction-health` records
above holds here unchanged. `arrival_closes_nothing` is the drill's half of the rule; the
hermetic suite's `testDirectionHealthRefusals` is CI's, and since 2026-08-27 it also pins
that `strategy/scripts/close.sh` is reached from exactly one place in the plugin —
`/specificate`'s *ended* route.

## 5j. What the direction could not see (`verify-residue`)

`verify-residue` needs no seed, no fire, no issue number and **no network**: it builds a
throwaway **git** strategy tree — git-backed for `verify-arrival`'s reason, since `landed[]`
is a `git log --since` read — carrying one `active` direction whose attributed work has all
landed, beside an **unattributed** active mission holding two queued tickets.

The failure it exists for is the loop calling a direction **arrived** over a tree it could
not see. Measured on this repository at 2026-08-28 00:41 UTC: the strategy
`an-autonomous-improvement-loop-run-by-the-routines` read `quiescent: true` with 125 landed
items while four active missions and ten queued tickets read `attributed: false` — an
arrival is the one reading whose next act is to **close** a direction, so a blind one is the
one that costs something.

The **deliberately broken seam** is `residue_reads_the_active_area`. The fixture carries an
archived, unattributed mission (`retired`) that must never reach the residue: wiring the
reader at the archive area instead of the active one is the single edit that would leave
every other row here green while the residue named finished work nobody can act on. Break it
by pointing `mission-strategy.sh` at `missions/archive` and this row fails.

The degraded read is exercised over a **copy of the plugin tree with `mission-strategy.sh`
removed**, deliberately: `all_strategies_unreadable` would make the strategy itself
unreadable too, and the assertion would then pass on `unreadable` without ever exercising the
term under test.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `residue_honest_read` | the residue does not name the unattributed active mission with its queued count | `unattributed-work.sh`; check `mission-strategy.sh`'s `attributed` first, then the `read-relation.sh` walk of `tickets/todo` |
| `residue_reads_the_active_area` | an **archived** mission reaches the residue | **the broken seam** — the reader is walking the wrong area, and every other row would still pass |
| `residue_degraded_is_named` | a read that could not be made is not named, or reports zeroed counts | `unattributed-work.sh`'s `emit_unreadable` — `mission_count: null`, never `0` |
| `residue_nonempty_leaves_the_arrival` | a non-empty but **readable** residue refuses the arrival | the `quiescent` block — only an unreadable residue refuses, and widening that is the tempting over-reach |
| `residue_blind_refuses_the_arrival` | an arrival is claimed over a residue that could not be read | the same block's `.residue.readable` term |
| `residue_named_in_the_question` | the `direction-arrived:<slug>` question does not name the residue by slug and count | `step-direction-health.sh`'s `$residue_phrase`; the residue is carried, never re-read |
| `residue_asked_once` | the same key is asked again on a later tick | `ask-question.sh`'s ledger — changing a body must never re-ask a question |
| `residue_moves_no_gate` | emptying the residue changes `selected` | the residue is emitted **before** `refusal` and read by no gate; check the gate chain has not gained a term |
| `residue_carry_lands` | the operator's ruling does not append the direction's refs, or drops the mission's own | `carry-attribution.sh` — it appends, it never authors or removes |
| `residue_carry_is_idempotent` | a re-run is not a byte-identical no-op | the `already` return, before any write |
| `residue_carry_refuses_a_closed_direction` | a closed direction acquires new work, or a refusal wrote | `not_active`, and the candidate-under-a-temp-directory discipline `amend.sh` sets |
| `residue_writes_nothing` | the drill changed the checkout | every reader here is pure and every fixture lives outside the checkout |

**Two proofs, and they are not the same one**, as everywhere else here: this drill is the
operator's half; `testResidueGatesNothing`, `testResidueOnSurveyRows` and
`testCarryAttribution` in the hermetic suite are CI's.

## 5j-bis. The closing link past the corpus boundary (`verify-corpus-boundary`)

`verify-corpus-boundary` needs no seed, no fire, no issue number and **no network**: it builds
a throwaway **git** strategy tree — git-backed for `verify-arrival`'s reason, since `landed[]`
is a `git log --since` read — carrying one `active` direction, the mission that cites it and
the ticket naming that mission, then grows filler until the corpus **path list** spans more
than one `xargs` batch.

The failure it exists for is the closing link going **silent** as the corpus grows. Both hops
of `attributed-work.sh` prefilter with one `grep` per batch, and the shape that shipped —
`xargs grep -lFf … > cand || : > cand` — truncated everything the earlier batches had already
found whenever a later batch matched nothing. Measured on this repository 2026-08-29: 1411
corpus paths / 132292 bytes against a 131072-byte buffer, 0 candidates where an appending walk
found 26, and `no_citing_artifacts` for a direction with 26 citing artifacts.

**The boundary is derived from the running system, never hard-coded.** `xargs`'s command
buffer is a property of the machine (~128 KiB on GNU, unrelated to `ARG_MAX` — 2 MiB here), so
a filler count pinned at "1400 files" would quietly stop exercising the split on a machine with
a different limit and the row would pass while proving nothing. The probe counts how many times
`xargs` invokes its command over exactly the corpus the reader builds, and the filler grows
until that count exceeds one. What must be large is the **path list**; the file bodies stay
three lines.

The **deliberately broken seam** is in **two halves, one per hop**, and both are written
against **behaviour** rather than a return shape: each runs a copy of the reader with the
truncating `||` restored on one hop and requires the citation to be **lost**. A breaker keyed
on a field would pass a refactor that keeps the output shape and reintroduces the bug, which is
exactly the failure mode this row exists to catch. The two halves are separate because
reverting hop 1 hides hop 2 behind it — with no attributed mission there is nothing for the
second hop to walk — and hop 2 carries every ticket's `via_mission:` attribution, so its loss
is the larger one.

The degraded direction is built from a corpus entry the walk genuinely **cannot consume**: a
filename containing a space, which `xargs` splits into two non-existent paths so `grep` exits
2. A permission bit is not usable here and the ticket's own considerations said so — this drill
routinely runs as uid 0, where `chmod 000` still reads fine (measured: `grep -lFf` over a
000-mode file exits 1, not 2).

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `corpus_spans_more_than_one_batch` | the fixture never crossed the boundary, so every row below proves nothing | the probe, and `|| :` on each `find` in it — under `set -e` a missing area aborts the group before the second `find` runs |
| `corpus_both_hops_attribute` | a citation in an early batch is lost to a later batch that matched nothing | `attributed-work.sh`'s `prefilter` — it appends across batches and a no-match batch is a success |
| `corpus_batching_tolerance_holds` | restoring the truncating branch on **hop 1** does not lose the citation | **the broken seam**, half one — if this passes, the row above proves nothing |
| `corpus_batching_tolerance_holds_on_hop_2` | restoring it on **hop 2** does not lose the `via_mission:` attribution | **the broken seam**, half two — hop 1 must survive it, which is what makes the halves independent |
| `corpus_survey_row_is_real` | the survey row is not derived from a completed walk | `survey-strategies.sh` — a real `work_waiting` brake, never `attribution_unreadable` |
| `corpus_residue_excludes_the_citing_mission` | the residue names a mission the tree attributes | `mission-strategy.sh`'s `attributed`, over the same walk |
| `corpus_no_arrival_over_attributed_work` | an arrival question is asked about work the tree attributes | `step-direction-health.sh`, over `quiescent` |
| `corpus_degraded_names_its_reason` | a walk that could not read reports `no_citing_artifacts` instead of its own reason | `note_walk_failure` and `emit_unreadable` — `readable: false`, `reason: corpus_unreadable` |
| `corpus_degraded_refuses_the_row` | the survey derives a reading from a walk it could not complete, or selects it | the `$blind` term and the `attribution_unreadable` rung, ahead of `work_waiting` |
| `corpus_degraded_residue_lists_nothing` | the residue is rendered off a blind walk | `unattributed-work.sh`'s `strategy_unreadable` / `all_strategies_unreadable`, with null counts |
| `corpus_degraded_asks_no_arrival` | an arrival question is produced from a walk that did not complete | the same `quiescent` chain, one degradation earlier |
| `corpus_writes_nothing` | the drill changed the checkout | every reader here is pure and every fixture lives outside the checkout |

**Two proofs, and they are not the same one**, as everywhere else here: this drill is the
operator's half; `testStrategyAttributedWorkPastBatchBoundary`, `testAttributedWorkWalkOutcome`,
`testSurveyRefusesADegradedWalk`, `testResidueRefusesADegradedWalk` and
`testRunReportsNameADegradedReading` in the hermetic suite are CI's.

## 5j-ter. The direction warned before its date (`verify-expiry`)

`verify-expiry` needs no seed, no fire, no issue number and **no network**: it builds a
throwaway **git** strategy tree — git-backed for `verify-arrival`'s reason, since `landed[]`
is a `git log --since` read — carrying five directions whose only differences are their dates
and their work: one inside the window with work in flight, one with runway left, one past its
date, one inside the window whose work is all in, and one a week out for the breaker row.

**Its dates come from the run clock, never from literals.** This is the one drill whose whole
subject is a date, so a fixture with hard-coded dates would rot the moment they passed.

The failure it exists for is a direction silenced by its **own date, unwarned**. Every reading
in the layer answers backwards — `late`, `overdue`, `dormant`, `arrived` — so a live, in-date,
`on_course` direction one day from its `target_date` produced no reading and no question
anywhere; the day after, `past_target_date` refused the proposal and the only signal was
`direction-overdue`, asked in arrears. Measured on
`an-autonomous-improvement-loop-run-by-the-routines` at the hour the ask was written:
`days_to_target: 2`, `pace: on_course`, `overdue: false`, `dormant: false`.

The **deliberately broken seam** is `expiry_window_is_the_surveys_own`. It reads the same
fixture through a **narrower** window and requires the reading to narrow with it. Wire the
window to a fresh constant — the one shortcut the design exists to refuse, because a new number
is one nobody can defend — and that row fails while every other row here stays green. Break it
by replacing `$window_days` with `14` in the `expiring` block and this row reports
*the window did not move the reading*.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `expiry_fixture` | no attributed work landed in the window | without it every direction reads `dormant` and every row below passes for the wrong reason |
| `expiry_state_soon` | a direction inside the window does not read `expiring` | `survey-strategies.sh`'s `expiring` block, then `direction-state.sh`'s precedence |
| `expiry_state_later` | a direction with runway left stopped reading `live` | the boundary is `0 <= days <= window`, not *has a date* |
| `expiry_state_gone` | a direction past its date stopped reading `overdue` | `overdue` outranks `expiring`, and `expiring` is `false` past the date anyway |
| `expiry_state_finished` | a quiescent direction inside the window does not read `arrived` | the precedence pair a severity ordering would invert — the two ask for **different acts** |
| `expiry_window_is_the_surveys_own` | a narrower window does not narrow the reading | **the broken seam** — the window has become a constant |
| `expiry_question_keys` | the step asks the wrong set of keys | `step-direction-health.sh`'s subject `select`; a key that drifts is a question asked twice or never |
| `expiry_question_names_the_date` | the heading omits the days left or the date, or the act exceeds 25 words | a warning that does not say how long somebody has is not a warning (`workaholic:notify`'s body bound) |
| `expiry_names_the_leaving` | the question does not name what the direction never reached | `direction-state.sh --with-leaving`; the step carries it and composes nothing |
| `expiry_event` | the reading does not reach the root, or links no direction | the step's `event` phrase, which follows the reader's own precedence |
| `expiry_asked_once` | the same key is asked again on a later tick | `ask-question.sh`'s ledger — every existing gate applies unchanged |
| `expiry_writes_no_direction` | the step or the reader can reach a strategy writer | the artifact keeps its three writers; a reading that a direction is about to expire is one step from a routine that re-dates it |
| `expiry_fixtures_intact` | the seeded strategies area changed | both are pure reads |
| `expiry_writes_nothing` | the drill changed the checkout | every fixture lives outside it |

**Two proofs, and they are not the same one**, as everywhere else here: this drill is the
operator's half; `testExpiringDirectionIsRead`, `testExpiringBoundary`,
`testExpiringPrecedence`, `testExpiringCarriesTheLeaving`, `testExpiringQuestion` and
`testExpiringGatesNothing` in the hermetic suite are CI's.

## 5j-bis. The standing rulings, drafted rather than asked (`verify-rulings`)

`verify-rulings` needs no seed, no fire, no issue number and **no network**: it builds a
throwaway repository against a **bare local origin** with `gh` stubbed, holding exactly one
unattributed active mission and exactly one queued ticket owned by an address no mapping entry
names.

The failure it exists for is a ruling the loop cannot make reaching the operator as an **hourly
question naming a repair to perform by hand on `main`** — editing a mission's `feedback:` line,
completing a line in `.claude/git-identities` — which is the one act this repository still left
to a person editing the base directly. Drafted instead, **merging is the ruling and closing is
the refusal**.

The **deliberately broken seam is in two halves**, and the mission's safety rests on both:

- `rulings_no_script_judges` — the fixture holds **exactly one** active direction beside
  **exactly one** unattributed mission, which is the shape an inference would resolve without
  being asked. Wire any inference into `list-standing-rulings.sh` and this row fires. Proved
  able to fail: a copy that resolves the single strategy turns the row red.
- `rulings_seam_never_merges` — `WORKAHOLIC_AUTO_MERGE=1` is **set**, deliberately. Delete the
  `ruling_touching` derivation from `publish-tree-pr.sh` and a machine merges the operator's
  ruling; an unset variable would let that pass unnoticed. Proved able to fail the same way.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `rulings_read_names_both_kinds` | the composed set does not name both an attribution and a mapping candidate | `list-standing-rulings.sh`; check `unattributed-work.sh` and `audit-identity-coverage.sh` in turn — a degraded source contributes no entries |
| `rulings_no_script_judges` | a candidate carries a decision nobody handed in | **the first broken seam** — the reader stores an answer and derives none, and the `repair` keeps its `<strategy>` / `<login>` placeholder |
| `rulings_seam_never_merges` | a ruling merges under `WORKAHOLIC_AUTO_MERGE=1` | **the second broken seam** — `publish-tree-pr.sh`'s `ruling_touching`, derived from the tree rather than from the caller |
| `rulings_both_kinds_drafted` | the attribution and the mapping do not ride one diff | `draft-standing-rulings.sh` §3 and §3b; a per-kind pull request would be two asks about one decision |
| `rulings_second_tick_is_a_no_op` | a second tick drafts while a ruling is open, or the base's mapping gains a line | `list-open-rulings.sh` — the brake is the open pull request itself, with no cursor anywhere |
| `rulings_undecided_still_asks` | a subject the ruling does not name goes silent, or says nothing about why | `step-undrivable-units.sh`'s `unjudged` flag; an unjudged subject is the one that most needs a person |
| `rulings_named_subject_is_held` | a subject the diff already carries still draws its question | `ruling-suppression.sh` — keyed on the subject, never on the existence of a ruling |
| `rulings_refusals_write_nothing` | one of `carry-attribution.sh`'s five refusals is misnamed, or any of them wrote | that script's candidate-under-a-temp-directory discipline, `amend.sh`'s verbatim |
| `rulings_absent_mapping_refuses` | an absent `.claude/git-identities` is written rather than refused | `draft-standing-rulings.sh` §3b — the file's absence is a **bootstrap** repair and `apply-bootstrap.sh` owns the header it scaffolds |
| `rulings_writes_nothing` | the drill changed the checkout | every fixture lives outside it; the act writes only in a publish tree |

**Two proofs, and they are not the same one**: this drill is the operator's half;
`testStandingRulingsReader`, `testStandingRulingsJudgement`, `testDraftStandingRulings`,
`testStepStandingRulings`, `testRulingQuestionSuppression` and
`testPublishTreePrRulingExemption` in the hermetic suite are CI's.

## 5k. A direction's end as a turn of the loop (`verify-succession`)

`verify-succession` needs no seed, no fire, no issue number and **no network**: it builds a
throwaway **git** tree — git-backed for `verify-arrival`'s reason, since `landed[]` is a
`git log --since` read — carrying one dated direction, the work that landed under it, and an
active mission no direction claims.

The failure it exists for is a direction's end being the loop's **stop**. Every reading in
the direction layer is bounded to `status: active`, so closing the last live direction leaves
`/propose` refusing `not_active`, the inbox empty, and `direction-none` — addressed to
nobody — as the only signal. The walk crosses six seams no single unit test crosses: close a
direction → read what it leaves → announce a successor by **explicit slug** → the
predecessor's own refs land on the successor → `attributed-work.sh` attributes the
predecessor's work to it → `/propose` proposes against it on the next tick.

The **deliberately broken seam** is `succession_carry_is_wired_at_the_ask_line`. Wiring the
carry inside `create.sh` is the single edit that would leave every other row green while
giving the strategy artifact's writer a second job — and the row proves it can fire, by
running the same detection against a copy of `create.sh` with the succession wired into it.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `succession_leaving_before_the_close` | the leaving is not composed, or claims to be exhaustive | `closing-residue.sh` — three blocks, each from that fact's own single reader |
| `succession_leaving_after_the_close` | a closed direction reads as a degradation rather than `not_active` | the lifecycle block's absent-row branch; the reader is bounded to the `active` set **by design** |
| `succession_carries_the_predecessor_refs` | the successor does not cite the announcement's record **and** the predecessor's own | `ask-feedback-line.sh --refs-only`, then `create.sh`'s fifth argument |
| `succession_adds_no_field` | any artifact gains a `predecessor:`, `successor:` or `strategy:` key | the carry is a **citation**, and the retired relation stays retired |
| `succession_attribution_reads_through` | the predecessor's landed work is not the successor's | `attributed-work.sh` — the citation that already existed, no second walker |
| `succession_successor_is_not_dormant` | a fresh successor reads `dormant` | the whole point of the carry: a direction born citing records is not one nothing is answering |
| `succession_propose_resumes` | the next tick does not propose against the successor | `survey-strategies.sh`'s gate chain — `no_feedback_refs` first, then `work_waiting` |
| `succession_carry_is_wired_at_the_ask_line` | the carry reached `create.sh`, or step 9b stopped composing it | **the broken seam** — every other row would still pass |
| `succession_readers_reach_no_writer` | `closing-residue.sh` or `direction-state.sh` reaches a writer of the artifact | a reading that closes a direction is the failure the whole pin was built against |
| `succession_publish_never_merges` | a strategy-touching publish merges under `WORKAHOLIC_AUTO_MERGE=1` | `publish-tree-pr.sh`'s `strategy_touching` — the seam's rule, not the caller's |
| `succession_writes_nothing` | the drill changed the checkout | every reader here is pure and every fixture lives outside the checkout |

**Two proofs, and they are not the same one**: this drill is the operator's half;
`testClosingResidueReader`, `testDirectionHealthLeaving` and
`testSuccessionCostsNoFourthWriter` in the hermetic suite are CI's.

## 5r. The thread reconciliation (does a finished item's thread stop calling it in flight?)

`verify-reconcile` needs no seed, no fire, no issue number and **no network**: a git fixture under
the OS temp dir and a `gh` stub on `PATH`. The drill asserts the stub is what `gh` resolves to
rather than assuming it, and the stub answers only the calls the reader makes — a query the drill
did not anticipate fails loudly rather than returning a plausible empty answer. The Slack half is
**fixture data on purpose**: what is under test is which items are named and what bar the reply is
held to, not the transport.

**Nobody posted the finish.** A finish line is posted by the run that *finishes* a unit, so a pull
request a person merges or closes by hand gets its finish posted by nobody — the item's thread
keeps `🔵 Proposed` or `🟡 Handoff` while the work is long merged. No other step could see it:
`stuck-prs` and `merge-conflicts` read **open** pull requests, `handoff-units` a standing claim,
`stalled-units` a stale tip.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `reconcile_no_network` | `gh` resolves to anything but the drill's stub | the drill is reaching the network, so every row below it proves nothing about the offline contract |
| `reconcile_merged_named` | the hand-merged unit is not a candidate, or loses its stems, its pull request or who merged it when | the reply's sentence is built from exactly those facts; a candidate that cannot name them cannot be posted without inventing one |
| `reconcile_closed_is_its_own_state` | a pull request closed without merging reads `merged` | the two states get two shapes because they ask a reader for different things. **A tab is IFS whitespace**, so an empty `merged_at` used to collapse and shift `closed_at` into it — the jq sentinel is what keeps the distinction |
| `reconcile_both_shapes_named` | the catalog stops naming either reply, or `/moderate`'s copy diverges | the command is the ceiling: a shape the command does not name may not be posted, and a second wording is a drift to fix |
| `reconcile_thread_bar` | the stated bar misclassifies one of the four fixture threads | the bar is the whole narrowing — only `🔵`/`🟡` is stale-able, a `🟢`-ended thread and one this loop already reconciled are never touched, and no thread means nothing to correct |
| `reconcile_two_queries` | the handed-back bound stops forbidding a channel-history read, or names a window | a window is a channel read wearing the step's name, and `workaholic:notify` forbids a full-channel read at any point |
| `reconcile_case4_refused` | case 4's description root stops being refused by name | posting a root would announce a merge nobody was ever told about — `[Consent]`'s retired job |
| `reconcile_one_outcome_each` | a not-posted reason goes missing, or the one-outcome rule does | no mechanical check tells a real thread read from a claimed one; what the rule buys is that a report naming no outcome is visibly wrong |
| `reconcile_cap_reported` | the cap is exceeded, or the remainder is dropped silently | a bound nobody can see is indistinguishable from a repository with nothing waiting |
| `reconcile_second_tick_silent` | a second tick hands the same items back | the ledger saves the lookup; the **structural** dedup (read before write) is what guarantees one reply, so neither may be traded for a cursor |
| `reconcile_degrades_by_name` | a refused read hands back candidates, or is not named | *nothing was looked at* must never render as *nothing is stale* |
| `reconcile_acts_on_nothing` | either script gains a merge, close, branch, commit or claim call | the step reads and the agent replies; nothing here acts on a pull request or a claim |
| `reconcile_writes_only_its_log` | the step writes into the tree beyond the tick's own log line | the tick's standing contract, unchanged by this step |
| `reconcile_breaker` | a candidate reader wired at the **channel** still names the candidates | **the deliberately broken row, and the one to look at first on a red drill.** Deriving candidates from the channel is the design inverted — it breaks the no-full-channel-read bound outright and makes the reader's cost grow with the channel rather than with the work |
| `reconcile_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout |

**Two proofs, and they are not the same one.** This drill is the **operator's**; the hermetic
suite's `testReconcileCandidates` and `testThreadReconcileStep`, and the catalog↔template drift pin
inside `testModerateRoutineTemplate`, are what **CI** enforces on every change. The drill ships to
no other agent and CI never runs it.

## 5s. The check-in's delivery (does a machine finding actually reach a person?)

`verify-checkin-delivery` needs no seed, no fire, no issue number and **no network** — no `gh`, no
Slack post, no touch of the working tree. Everything is a tick-log fixture under the OS temp dir,
written through `log-append.sh` so it is the shape the tick actually produces, and the day comes
from the **tick id** with `--hour`/`--weekday` injected, so the drill does not pass or fail by the
date it is run on.

**Why the path and not the parts.** The hermetic suite pins `ask-question.sh` in isolation and it
passed throughout the eleven days the channel was jammed: each part was internally consistent and
the delivery failed **in the seams** — an unbounded day count in the gate, an alphabetical order in
the step, and a root with no event to carry the failure. This walks gate → ordering → step → event
→ root over one fixture.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `checkin_held_lands` | a question held on an earlier day is still refused | `moderate/scripts/ask-question.sh` — the day bound (`--since "$TODAY"`) is gone, so `asked_today` is the log's whole history again |
| `checkin_not_reasked` | the same key is asked twice | the `already_asked` gate: asked once, not once an hour. Silence is not a reason to re-ask |
| `checkin_drain_order` | the arrears do not come back oldest-held first | `moderate/scripts/step-human-checkin.sh` — the earliest `(day, tick)` per key, or the `LC_ALL=C` sort, has been lost |
| `checkin_drain_capped` | the tick asks more or fewer than `max_per_tick` | `ask-question.sh`'s `tick_cap`. **The step must not enforce it**: if this fails at *fewer*, look for a second `human-checkin-ask*` line per ask — two lines count one ask twice |
| `checkin_remainder_held` | what did not fit is lost, or the asked ones come back | held is not dropped; the ask is the resolution of the hold |
| `checkin_spent_day_holds` | a day genuinely spent stops refusing | **the cap was kept, not removed.** A repair that raised the cap fails here, which is the point of the row |
| `checkin_failure_is_an_event` | a tick with candidates and none delivered names no reason, or supplies no event | `step-human-checkin.sh`'s delivery reading; `cap_spent` and `cap_unbounded` are the two states that earn an event |
| `checkin_root_carries_it` | the root stays silent about a tick that reached nobody | `moderate/scripts/render-tick-post.sh` — the third gate beside the question gate and the digest, or the removed `human-checkin` skip |
| `checkin_quiet_hour_silent` | a tick with no event posts anyway | the guard that keeps the gate from becoming a status line: *a step with no event renders no line* |
| `checkin_arrears_depth_and_age` | the arrears report no oldest day, or the wrong whole-day distance | `step-human-checkin.sh` — `held_oldest_day` is the **minimum** of the first-held day the drain ordering already derives, over the keys **still** held; `held_days` is civil-day arithmetic in `awk` against the tick's own day |
| `checkin_held_names_its_refusal` | a held entry carries no refusal word, or a re-worded one | the per-candidate probe of `ask-question.sh`. The word is the gate's own, **verbatim** — a normalised one sends a reader to a string no script printed |
| `checkin_outlived_hold_is_an_event` | an `all_held` tick past the working-day boundary says nothing | `step-human-checkin.sh`'s `all_held` arm. This is the measured failure the mission exists to close: 24 consecutive ticks, 13 questions, a silent root |
| `checkin_hold_inside_the_window_is_silent` | a hold **inside** the boundary earns a line | the boundary composition. A designed hold is not news, and a line every tick is what `📦 Release Preparation` was retired for |
| `checkin_degraded_arrears_are_null` | a degraded read reports `0` rather than `null`, or supplies an event | `unattributed-work.sh`'s rule applied here: a zero reads as *this just started* for a reading nobody made |
| `checkin_unchanged_reading_renders_once` | two consecutive ticks with the same reading render two lines | `render-tick-post.sh`'s diff rule, or a summary that stopped being a function of the reading alone (a clock, a timestamp, an age in the **summary**) |
| `checkin_breaker` | an unbounded day count still asks the held question | **the deliberately broken row, and the one to look at first on a red drill.** It is written against the **count**, not the gate's output shape, so a refactor that keeps the shape and loses the bound still fires it |
| `checkin_boundary_breaker` | a boundary wired at a fresh constant still earns the outlived line | **the second deliberately broken row.** Written against the **behaviour**: it changes no field and no key, so a refactor that keeps the JSON shape and loses the composition still fires it |
| `checkin_writes_nothing` | the drill changed the checkout | every fixture lives outside it, and the drill posts nothing anywhere |

**Two proofs, and they are not the same one.** This drill is the **operator's**; the hermetic
suite's `testCheckInDayCapIsToday`, `testCheckInHeldOrder` and `testCheckInDeliveryReading`, plus
the root-gate cases inside `testModerateTickPost`, are what **CI** enforces on every change. The
drill ships to no other agent and CI never runs it.

## 5t. The tick's findings, turned into work (does the loop drive its own debt?)

`verify-findings-to-work` needs no seed, no fire, no issue number and **no network**. Everything
is a throwaway git repository under the OS temp dir with `gh` stubbed: the stub serves the issues
listing, applies `--jq` with real jq so the reader's own parse is what is exercised, records the
one POST the filing makes, and **exits non-zero on any other call** — a drill that silently
reached the network would prove nothing about an offline container.

**Why the path and not the parts.** The gap this closes lived entirely in the seams: every part
was internally consistent while a finding had two destinations and neither became work. The drill
walks classification → brake → filing → dedup → suppression over one fixture, with one repairable
finding carrying an `event`, one repairable finding that **degraded**, one repairable step that
found nothing, and one `needs_ruling` step shouting as loudly as it can.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `findings_classified` | a repairable finding is not a candidate, or a step that found nothing is | `moderate/reference/workflow.md`'s classification table, and `step-file-findings.sh`'s read of it |
| `findings_ruling_never_filed` | a `needs_ruling` finding reaches the filing act | **the mission's whole safety property.** The table's default is `needs_ruling`, so this fails only if a row moved or the filter inverted |
| `findings_brake_holds` | a second finding is filed while one issue is open | `moderate/scripts/list-finding-issues.sh` (`any_open`) and the step's brake |
| `findings_brake_releases` | closing the issue does not release the brake, or the dedup forgets the finding it carried | `held` projects from the **open** issues, `filed_ids` from open **and** closed — two questions, one walk |
| `findings_brake_unreadable` | an unreadable ledger files anyway, or reports `brake_held` | a brake that cannot be read is not a brake, and *in flight* versus *could not look* are different facts |
| `findings_marker_written` | the filed body carries no `finding:` line | `propose/scripts/file-inbound-ask.sh` — still the one writer of a marker. Without it the next tick re-files every hour |
| `findings_direction_carried` | the body carries no `feedback:` line or the wrong `source:` | `feedback/scripts/ask-feedback-line.sh` stays the one writer of that line; `source: moderate` is what the finding route means |
| `findings_second_tick_files_nothing` | the same finding is offered again | the dedup is **structural**: the issues are the memory and no cursor exists to forget |
| `findings_question_held` | a filing silences a step it does not name, or silences nothing | `moderate/scripts/finding-suppression.sh` — keyed on the **subject**. Suppressing on `any_open` silences the whole question queue behind one filing |
| `findings_unreadable_holds_nothing` | an unreadable suppression read suppresses something | an over-eager question is better than a silently dropped one |
| `findings_reported_three_ways` | filed, held and left collapse into one reading | `step-file-findings.sh`'s `held`, `already_filed` and `left` |
| `findings_event_empty` | the step supplies an event | the agent files **after** `run.sh` returns, so an event here announces an act not taken |
| `findings_breaker` | widening the classification to every finding changes nothing | **the deliberately broken row, and the one to look at first on a red drill.** It is written against the **behaviour** — a `needs_ruling` finding reaching the filer — not against a return shape, so a refactor that keeps the shape and loses the bound still fires it. The whole plugin tree is copied, because the step reaches its ledger which reaches `gather/scripts/gh-rest.sh` |
| `findings_writes_nothing` | the drill changed the checkout | every fixture lives outside it |
| `findings_touches_no_claim` | a branch, worktree or publish tree appeared | the tick creates none of them; its only outward act is one issue |

**Two proofs, and they are not the same one.** This drill is the **operator's**; the hermetic
suite's `testFindingToWorkGap`, `testFindingClassification`, `testFileFindingsStep`,
`testFindingBrakeAndDedup` and `testFindingSuppression` are what **CI** enforces on every change.
The drill ships to no other agent and CI never runs it.

## 6. Abort playbook

Read the outcome first, then act. Three cases are not `reset`'s business, and running it
on them destroys recoverable work:

1. **`pr_failed` / `no_gh` — the branch is pushed.** Open the pull request by hand against
   that branch, carrying the same `Closes #<N>` line. **Never re-publish**: the artifact
   is already on the remote and a second publish duplicates it.
2. **A half-driven unit — the claim is live.** Merge its pull request, or discard it
   explicitly with `skills/drive/scripts/release-claim.sh`. `reset` will not touch it: it
   deletes only branches whose diff names a drill issue, and reports the rest as
   `not_drill_owned`.
3. **A `secret` finding.** Not a drill failure — a credential reached a pushed branch.
   Handle it as an exposure; the drill's residue is the least of it.

Everything else: `sh scripts/e2e/loop-drill.sh reset`. It closes the drill's own open
issues, deletes the branches it can prove are drill-owned, names everything it left alone,
and re-runs the preflight so one invocation tells you whether the base is drillable again.
It is idempotent — a second consecutive run is a no-op that still exits 0 — and it **never
writes under `.workaholic/`**.

`seed` refusing is the drill working, not a fault:

| Refusal | Exit | Fix |
| ------- | ---- | --- |
| `inbox_dirty` | 3 | an open assigned issue would be taken as the ask (discovery has **no title filter**). Close or reassign it, or finish the pass it belongs to |
| `claim_dirty` | 3 | an unmerged `work-*` branch is both a live claim and a dedup ref. Land it, or leave the drill for later |
| `identity_unresolved` / `gh_unavailable` / `list_failed` | 4 | the environment could not answer; `detail` carries the underlying message |

## 7. Residue, and why re-runnability is fresh minting

A **clean pass deliberately leaves artifacts on `main`**: the feedback record, the
archived ticket, the story, the closed issue, and the merged pull requests. That is the
loop's own history, and it is immutable — the drill never edits or deletes it.

So a second drill does not clean up after the first; it **mints a fresh issue**. That also
means a pass is finished only once its issue is **closed** (the merged proposal's
`Closes #<N>` does that). Until then `seed` refuses with `inbox_dirty`, correctly: an open
assigned issue is an ask the next discovery would take again.

`reset` exists for the other case — an **aborted** run, where residue was minted and no
pass completed. It is a recovery path, never a cleanup step of a healthy drill.

## 8. Drill log

§7 keeps every pass's artifacts on `main`; this log is the operator-readable **index over
them** — which passes were run, when, and how each ended — so the history is legible
without walking closed issues and merged pull requests by hand. A row is appended by
whoever ran the pass, at the end of it, using the run id `seed` minted.

| Run id | Date | Issue | Outcome |
| ------ | ---- | ----- | ------- |
| `20260812-215314` | 2026-08-12 | [#419](https://github.com/qmu/workaholic/issues/419) | exercised the propose–implement loop end to end |
| `20260812-221056` | 2026-08-12 | [#423](https://github.com/qmu/workaholic/issues/423) | exercised the propose–implement loop end to end |

## 5i. The merged-claim readings (the claim oracle's two grains)

`verify-merged-claim` needs no seed, no fire, no issue number and **no network**: it builds a
throwaway repository whose mission claim and batch claim are both **squash-merged** onto the
base, then reads `list-claims.sh` over it with the GitHub transport stubbed on `PATH`.

**The squash is the whole fixture.** A normal merge takes `base..ref` to zero and
`claims_scan` drops the branch before any verdict is reached, so the drill would pass while
proving nothing. A squash leaves the content on the base and the commits unreachable, which is
the state that made a finished unit look claimed forever — measured here on 2026-08-26: three
of five claims headed pull requests #521, #537 and #546, all merged, all mission units, one
offered `resumable: true` five days after its own pull request merged. `merged_claim_fixture`
asserts the premise before anything else, so a `git merge --squash` behaviour change turns the
drill red rather than hollow.

**The two grains are answered by different means, and the drill keeps them apart.** A batch
claim is answered from the tree (its tickets are archived on the base), so it needs no
transport at all; a mission claim stamps only `mission.md`, which driving never archives, so
only a merged pull request can answer — and that is the one network read, stubbed here.

**And the reading is not the point — the claim is** (2026-09-01, ticket `20260826144228`).
The four readings above prove the oracle can *see* a superseded claim; not one of them proves
the work it frees can be *taken*. `plan-units.sh` resurveys that work and `workaholic:drive`
§1 says in as many words *a fresh claim drives them, because the old branch cannot land* — so
a drill stopping at the reading passes while the unit is reachable by no path at all. Measured
2026-08-27: mission `make-workaholify-converge-the-account-s-routines` was offered and named
in `resurveyed[]` while a fresh claim answered `already_claimed` and `claim.sh resume`
answered `superseded`, both refusals by design. `merged_claim_live_refuses` and
`merged_claim_fresh_claim` differ in **one fact** — whether the stubbed lookup answers
`merged` — with the fixture, the identity and the collapsed heartbeat window held constant, so
what the breaker breaks is the behaviour rather than a return shape. A `claim.sh` that had
lost the reason test entirely would pass the second row and fail the first.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `merged_claim_fixture` | the claim branch is not still ahead of the base | the fixture is not a squash merge; every row below it would prove nothing |
| `merged_claim_batch` | a squash-merged batch claim does not read `superseded` with no transport | `claims_superseded`'s local test in `lib/claims.sh` — the archived-on-the-base filename match |
| `merged_claim_live` | a claim with no merged pull request does not keep its local verdict | the lookup answered `merged` for a branch with none, or the verdict chain short-circuited above `superseded` |
| `merged_claim_mission` | a merged pull request does not make a mission claim `superseded` | `claim-merged.sh` and the non-ticket branch of `claims_superseded` — the behaviour this mission exists for |
| `merged_claim_unanswerable` | a refused lookup changed the verdict | the degradation contract: a wrong `merged` releases work still in flight, a wrong `in flight` only delays a claim, so an unread answer must change nothing |
| `merged_claim_named` | the claim the lookup could not answer for is not named with its reason | `list-claims.sh`'s `merged_lookup_unanswered`, fed by `claims_note_unanswered` |
| `merged_claim_live_refuses` (breaker) | a fresh claim over a **live** claim is not refused `already_claimed` | `claim.sh` §3's refusal loop lost the reason test and now steps over every row, not only the one proved empty |
| `merged_claim_fresh_claim` | a fresh claim over a **superseded** claim is refused | `claim.sh` §3's `superseded` skip — the claim half of the 2026-08-26 change; without it the resurveyed work is reachable by no path |
| `merged_claim_branch_untouched` | the superseded branch is gone from the origin | something acted on a verdict that is only ever *reported*: the fresh claim frees the work, never the branch |
| `merged_claim_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout; the oracle is a pure read |

**Two proofs, and they are not the same one** — the same split as §5h. This drill is the
**operator's**, exercising the real closure in a checkout; the hermetic suite's
`testMergedClaimShapeAtBothGrains`, `testMergedLookupDegradesByName` and
`testMergedClaimIsNeverResumable` are what **CI** enforces on every change. The drill ships to
no other agent and CI never runs it; the suite cannot prove an operator's checkout behaves.


## 5k. The closing seam (does a unit the loop finishes actually close?)

`verify-close` needs no seed, no fire, no issue number and **no network**. The closing seam is
the one the loop cannot prove by running: a real refusal needs a real session class, and waiting
for a tick to reproduce one is exactly what let four undelivered pull requests (#622, #625, #633,
#635) accumulate unnoticed on 2026-08-27 while every run reported `ok`.

**The whole vocabulary is a pure function**, which is what makes all four outcomes reachable
offline: `merge-reason.sh` classifies a refusal string, `gate-decision.sh` reads a scan's tiers,
and `record-merge-outcome.sh` → `claims_merge_outcome` carries the answer from the run that
attempted the merge to the oracle that reads it back. The fixture builds three units driven to
the **same** shape — drained queue, story at the tip, pull request open — because that identity
is the defect: `claimed_reported` covered all of them.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `close_retryable_refusal` | the session-type refusal does not reach its own rung | `merge-reason.sh` — keyed on the message, with a bare 403 behind it, because that one is a missing permission a different transport does not fix |
| `close_unretryable_refusals` | any other rung does not classify to its own word | the four remaining rungs are four different next actions; collapsing them is what `merge_failed` alone would do |
| `close_scan_held` | a `hard` finding and an `override` one are not separated | `gate-decision.sh`'s `override_only` — the route merges on `pass` **or** `override_only`, never on the binary verdict |
| `close_fixture` | the three units are not claimed, drained and reported | the fixture is not the shape under test; every row below it would prove nothing |
| `close_refused_is_undelivered` | a refused merge does not read `report_undelivered` | `claims_merge_outcome` and the drained fork in `lib/claims.sh` — the split this mission exists for |
| `close_held_is_unchanged` | a scan-held pull request does not still read `queue_drained` | the carve-out that keeps `ok` reachable: that pull request waits on a person **by design** |
| `close_asks_about_the_refused_one` | the tick asks about the wrong unit, or about none | `step-undelivered-units.sh` — the merged outcome is proved as an **absence** here, since a merged claim is released by its merge and the oracle never sees it |
| `close_unrecorded_stays_silent` | an **unrecorded** outcome does *not* fall back to `queue_drained` | **the deliberately broken seam.** The new verdict is claimed only on positive evidence, so with nothing recorded the old silence must return — proving this drill can fail |
| `close_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout |

**The deliberately failing row is the point of the drill, not a curiosity.** A drill that only
walks the happy path would have passed throughout the days those four pull requests sat open,
and would have converted an unproven claim into a believed one. Breaking any seam this mission
touched turns `close_refused_is_undelivered` and `close_asks_about_the_refused_one` red together
— verified by removing the `merge_refused*` branch from `lib/claims.sh` and watching both fail.

## 5k-bis. The catch-up (does a unit the base moved under come back?)

`verify-catch-up` needs no seed, no fire, no issue number and **no network**: a local bare origin
and a `gh` stubbed on `PATH`. It drills the act that repairs the shape measured on 2026-08-29 —
4 of 7 open pull requests conflicting with `main`, three of them units recorded
`report_undelivered` two days earlier, with 4 active missions and 10 queued tickets behind them.
`retry-undelivered.sh` re-attempts the **merge**, which is the right act for a refused transport
and no act at all for a base that has moved.

**It drills a writer that pushes onto a claim branch**, which is exactly the act the claim
protocol's standing rule refuses for a third party. What makes it safe is that the claim is
**this identity's own**, that a live one is refused `claim_active`, and that the act is a
**merge** rather than a history rewrite — and the drill's job is to show that nothing but those
gets through.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `catch_up_no_network` | `gh` does not resolve to the stub | the drill would reach the network; every row below it would be measuring GitHub rather than the seam |
| `catch_up_fixture` | the reader does not answer `mechanical` and `content` over the two branches | the fixture is not the shape under test; every row below it would prove nothing |
| `catch_up_offers_a_drained_claim` | `list-catchable-claims.sh` does not offer the `queue_drained` + `mechanical` unit | **the second deliberately broken seam** (2026-08-30), written against the behaviour: wire the candidate reader back at the delivery verdict alone — `report_undelivered` only, the pre-widening set — and `batch-drained` disappears from the offer while every other row stays green. Verified red, then reverted. Asserting a return shape would survive exactly that narrowing, which is why the assertion is on the **unit being named** |
| `catch_up_offers_a_content_prediction` | `list-catchable-claims.sh` does not offer the `content`-classed unit | **the third deliberately broken seam** (2026-09-02, mission `resolve-a-conflicted-pull-request-in-the-tick-not-report-it`): narrow the reader back to `mechanical` alone and `batch-content` leaves the offer while every other row stays green. `mergeability` is a **prediction** — the reader computes with the repository's `.gitattributes` out of reach, because its job is to predict GitHub, which applies no merge driver, while the writer merges in a real checkout where they are in force — so the act tests it rather than deferring on it. Asserted on the **unit being named**, for `catch_up_offers_a_drained_claim`'s reason |
| `catch_up_offer_is_bounded` | a colleague's claim is offered | the identity bound, which did **not** move with the 2026-09-02 widening: a foreign claim is untouchable at any age and at any class, and may never reach a writer that pushes. Split from the `content` row above on purpose — they are different facts, and collapsing them is how this one would be lost silently the next time the other is widened |
| `catch_up_degraded_reads_null` | a scan that could not be made yields an empty candidate list with a **zeroed** count | a healthy quiet run and a scan that could not reach the remote would otherwise be byte-identical, and the second has not found "nothing to catch up" — it has found nothing at all |
| `catch_up_drained_caught_up` | a `queue_drained` unit still `mechanical` and unreviewed is not caught up and pushed | the widening's own subject: before 2026-08-30 no run would touch it, because `catch-up-claim.sh`'s only caller was the `undelivered[]` loop |
| `catch_up_reviewed_refused` | a pull request carrying a submitted **human** review is caught up, or the branch tip moves | the one bound the widening added: an `undelivered` unit's pull request was refused by a transport and nobody is looking at it, while a `queue_drained` unit's may be one a person is mid-review on — and a push resets an approval. A **bot's** review is not a person's, which row 1's own pull request proves by being caught up with one |
| `catch_up_mechanical_delivered` | a mechanical conflict is not merged, validated and pushed, or the manifest does not converge on the **higher** semver | `catch-up-claim.sh` over `catchup-main.sh --resolve-mechanical` — taking one side of a version collision wholesale silently drops the other side's edits, so both sides are raised to the higher version and merged normally |
| `catch_up_content_refused` | a `content` conflict is not refused by its own word, or the branch tip moves | the contested case stays a person's; a refusal that writes anything is not a refusal |
| `catch_up_scan_held_refused` | a `merge_not_attempted: <tier>` unit is caught up | the catch-up is **not a route around a gate**: a `hard`/`confirm` finding holding a pull request open is the gate working |
| `catch_up_second_run_noop` | a branch that already contains the base does not report `already_current`, or a ref moves | idempotence, and the reason `already_current` is checked before liveness: reporting a no-op protects nothing |
| `catch_up_conflict_asks_nobody` | a surface still defers a conflict to a claim holder — the retired step is back, its key is emitted somewhere, or the registry names it again | `step-catchup-blocked.sh` should not exist (retired 2026-09-02); the residue of a merge the writer could not settle is reported by the **act**, in `/implement`'s run report, not asked about |
| `catch_up_refuses_a_foreign_claim` | a colleague's claim branch tip **moves**, or the refusal is not named | **the deliberately broken seam**, written against the behaviour rather than a return shape. Verified by dropping `foreign_identity` from the verdict gate and neutering the `not_my_claim` comparison: the drill merged into `work-20260101-000004` and pushed it, failing exactly this row while the other eight stayed green — and restoring both turned it green again |
| `catch_up_checkout_untouched` | the drill changed the checkout | every fixture lives outside the checkout |

**One fixture trap is worth naming**, because it silently turns every row into a different test:
`.workaholic/stories/` holds only the previous unit's story, so checking `main` out removes the
file and git prunes the empty directory. Without an explicit `mkdir -p` the redirect fails
silently, the branch carries no story, and every claim reads `report_incomplete` rather than the
drained state the rows are about.

## 5l. The retirement (does a claim proved empty leave the table?)

`verify-retire` needs no seed, no fire, no issue number and **no network**: a local bare origin
and a `gh` stubbed on `PATH`, so every act is real against the fixture and none of them leaves
the machine. A `superseded` batch claim is reachable offline by construction — its tickets are
archived on the base — which is what makes the whole drill local.

**It drills a destructive, outward-facing act**: a pull request closed, a branch deleted, a
worktree reaped. That is the last thing that should be proved by waiting for a tick to perform
one. What makes it safe is the **proof** — `superseded` means the unit's content already reached
the base, so the branch can never land and holds no work — and the drill's job is to show that
nothing but the proof gets through.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `retire_fixture` | the fixture does not hold one `superseded` claim beside a live one | the fixture is not the shape under test; every row below it would prove nothing |
| `retire_acts_on_the_proof` | the three acts do not run, or one is not named | `retire-claim.sh` — each act reports its own word, so a partial retirement is never a bare `false` |
| `retire_not_twice` | a second run over a retired unit attempts anything | a completed retirement **deletes the branch**, and the oracle is the set of unmerged remote branches — so the row is simply gone and `no_such_claim` is the honest answer |
| `retire_already_closed_is_success` | an already-closed pull request is treated as a degradation | the idempotence that matters in practice: a cloud container may PUSH but not DELETE a branch (measured 2026-08-05), so a partial retirement must be finishable by the next tick |
| `retire_ambiguous_refused` | a unit held by two live claims is picked between | `claims_unit_resolution` — the protocol settles a race by the push, so this state cannot arise from the sanctioned path and choosing silently tears down work another run is driving |
| `retire_step_asks_nothing` | the step carries a question | `step-retire-claims.sh` — a retirement is *proved*, so there is nothing for a person to rule on; it acts and reports |
| `retire_step_renders_an_event` | a tick that retired a claim supplies no `event` | a retirement **is** a repository event — a pull request closed, a branch deleted — and the step supplies the phrase because it knows what its finding means and the renderer does not |
| `retire_idle_renders_no_line` | a tick that retired **nothing** still supplies an `event` | the half that is easy to leave unasserted, and exactly the 2026-08-23 failure: `no new documentation drift` announced that nothing happened while the diff rendered it as a change |
| `retire_refuses_a_judgement` | a **live** claim is not refused by its own verdict word | **the deliberately broken seam.** Widen the gate to any claim and this row goes red while every other row stays green — verified by replacing `retire-claim.sh`'s verdict test with `if false`, which retired `batch-live`'s branch and failed exactly this row |
| `retire_no_network` | `gh` does not resolve to the stub | the drill would reach the network; every row below it would be measuring GitHub rather than the seam |
| `retire_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout |

**And the blocked delete — the case that is true in production on every tick** (2026-08-27,
mission `finish-the-retirement-the-loop-cannot-complete`). Act 2 is refused in the container the
loop runs in, and the drill covered only the happy path; a behaviour nothing drills is a behaviour
the next change can lose. The refusal is reproduced by the **bare origin's own `update` hook**,
scoped to one ref — the same receive-side path a remote refusal takes, still with no network — so
a retirable claim can be retired in the same tick and the narrowing below is provable rather than
asserted. The blocked phase runs three superseded claims to three different outcomes:
`batch-blocked` refused **on the delete**, `batch-retirable` **retired**, and `batch-closefail`
refused on an act that is **not** the delete.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `retire_blocked_fixture` | the three held-back claims do not all read `superseded` | the blocked fixture is not the shape under test; every row below it would prove nothing |
| `retire_blocked_names_the_act` | a refused delete does not report `branch_delete_failed`, or the acts that stand are wrong | `retire-claim.sh`'s closing branch — `partial_retirement` collapsed a refused close, a refused delete and a dirty worktree into one word, so the reader could not learn which act was blocked |
| `retire_blocked_undoes_nothing` | a re-run re-opens the pull request, loses the branch, or loses the `superseded` verdict | the retirement is resumable: a re-run takes only the one remaining act, and nothing already done is undone |
| `retire_blocked_reports_what_stands` | the refused row drops the acts that succeeded | `step-retire-claims.sh` — a re-run of one act read as a re-run of three, and three units whose pull requests had closed days earlier read as bare refusals on every tick |
| `retire_blocked_asks_the_holder` | the blocked unit reaches nobody, or the question omits the branch | `step-retire-claims.sh` — a question that does not name the branch does not say what to delete; the addressee is the claim holder, never the running identity |
| `retire_blocked_only_the_blocked` | a unit that was **retired**, or one refused on the **close**, also draws a question | **the deliberately broken seam.** The rule is narrowed, not reversed: widen the candidate set to every superseded row and the first fires; widen it to every refusal and the second does — verified by replacing the `remote_branch_deleted == "failed"` test with `if true`, which failed exactly this row and nothing else |
| `retire_blocked_summary_stable` | two ticks over an unchanged blocked set render different summaries, or a held block supplies an `event` | the root calls a step changed when its summary moves, so a term that varies on its own makes a standing block an hourly restatement — verified by prefixing the summary with `$(date +%s)`, which failed exactly this row |
| `retire_blocked_asked_once` | the same key is asked on a later tick | `ask-question.sh`'s asked-once ledger, exercised with this step's `retire-blocked:<unit>` key over two consecutive ticks — the bound on the question's repetition, and deliberately the only one (a second per-unit ledger is how the two drift) |

## 5l-ter. The CI retirement (does the act the container is refused actually get taken?)

`verify-ci-retirement` needs no seed, no fire, no issue number and **no network**: a local bare
origin and a `gh` stubbed on `PATH`. Act 2 of the retirement — the remote branch delete — is
refused in the container the loop runs in by both available transports (measured 2026-08-27), so
it moves to a different **executor**, `.github/workflows/claim-retirement.yml`, on
`release-note-draft.yml`'s precedent. That split spans two processes and one destructive act,
which is the last thing that should be proved by waiting for a workflow run.

**The two executors are told apart by transport, and that distinction is the fixture's rather
than GitHub's.** The container's Act 2 is a `git push origin --delete`, refused server side by
the bare origin's own `update` hook — the same receive-side path a remote refusal takes. The CI
act is a REST `DELETE` through `gh-rest.sh`, which the stub performs for real against the same
bare repository. A bare origin cannot tell a "CI" pusher from a container one on identity alone,
and pretending otherwise would drill a fiction.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `ci_retirement_no_network` | `gh` does not resolve to the stub | the drill would reach the network; every row below it would be measuring GitHub rather than the seam |
| `ci_retirement_container_refused` | the container's delete is not refused, or the branch does not survive it | the production condition on every tick, and the whole reason the act moved executor — if this row goes green on its own the refusal is gone and the split has no premise |
| `ci_retirement_candidates` | the candidate set is not exactly the `superseded` units, or names a live one | `list-retirable-claims.sh` — the derivation stays the claim oracle's; a workflow that matched `work-*` itself would delete branches nothing proved empty |
| `ci_retirement_ci_takes_the_act` | CI does not delete the branch the container was refused | the mission's whole point: the act happens where the write is permitted |
| `ci_retirement_idempotent` | a second CI turn over the same unit is not a no-op | a completed delete removes the claim row, and `already_gone` is a **success** — a re-run over a set already taken must be clean, not a run full of errors |
| `ci_retirement_refuses_a_judgement` | a live claim's branch is not refused `not_superseded:<verdict>`, or does not survive | acting on `claim_active` is how a workflow tears down work a run is still driving; the refusal carries the verdict's **own** word so the reader learns which judgement it was |
| `ci_retirement_bounds` | `release_branch`, `not_a_work_branch`, `pull_request_open` or `not_on_base` fails to refuse by name | on top of the proof. `claims_scan` walks **every** remote head, so a claim commit on a `release/*` or a hand-named branch really is a claim row — which is why the shape bounds are not decoration |
| `ci_retirement_always_exits_zero` | any refusal, degradation or reader exits non-zero | a refusal is an answer the workflow reports, never one it dies on |
| `ci_retirement_pending_suppresses` | a `pending` CI turn still produces a question | `ci-retirement-turn.sh` — asking a person for an act a workflow is about to perform is not merely noisy, the ask is wrong. The blocked set is non-empty here, so the row isolates the reading rather than an empty candidate list |
| `ci_retirement_taken_asks_the_holder` | the unit CI also refused reaches nobody, or a CI-deleted unit draws a question | the narrowing in both directions: CI saw this tree and one branch survived it, while the other is no longer a claim at all |
| `ci_retirement_asked_once` | the same key is asked on a later tick | `ask-question.sh`'s asked-once ledger, exercised with `retire-blocked:<unit>` — unchanged by the narrowing, which touches only the candidate set |
| `ci_retirement_breaker` | removing the re-proof changes nothing | **the deliberately broken seam.** The act with **both** halves of its re-proof removed must delete a live claim's branch. Written against the verdict gate alone this row did **not** break — `not_on_base` caught the live claim on its own — so the two guards are independent rather than one written twice, and the drill says so by needing both removed |
| `ci_retirement_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout |

## 5l-quater. The act's effect (did what the loop did actually happen?)

`verify-act-effect` needs no seed, no fire, no issue number and **no network**: a local bare
origin, a `gh` stubbed on `PATH`, and a record served out of a control file so each row can put
the turn in one state without rebuilding the fixture.

**Every reading in this repository answered *what did I find*; none answered *did what I did
happen*.** Measured 2026-08-29: `claim-retirement.yml` was green on every run while three
proved-`superseded` claims stood on origin, and the tick log recorded, hour after hour,
*"ci_turn: taken so CI could not take the delete either"* — an assertion about a second executor
that nothing established. The turn now **records** what it attempted and each act's answer, and
the reading answers from that record instead of from a run's existence.

**The reported symptom and the measured one differ, and the drill is written against the
reading.** The report assumed the question was suppressed; it was not — the step suppressed on
`pending` and asked on `taken`, and what held the three units was the working-day hold, the gate
working. What was wrong was the **sentence**, in the one durable audit trail the tick keeps.

**The live cause was localized rather than assumed.** Under an Actions-style credential (`gh api
user` refused, which is what a `GITHUB_TOKEN` installation token answers for `GET /user`), the
two executors' candidate readers **agree** — both name all three units — while
`delete-retired-claim-branch.sh` refuses `gh_unavailable` before its proof gate. The
candidate-divergence cause is drilled beside it anyway: it is the one the report assumed, and a
drill covering only the live cause would pass a repository where the other one is.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `act_effect_no_network` | `gh` does not resolve to the stub | the drill would reach the network; every row below it would be measuring GitHub rather than the seam |
| `act_effect_unnamed_candidate` | a turn whose candidate reading named this unit nothing reads `taken` | the cause the report assumed. The reading carries the candidate reader's **own** reason through rather than inventing one |
| `act_effect_refused_act` | a refused act does not read `refused:<its own word>` | the cause measured live here. `gh_unavailable` must reach the reading verbatim — a reader sent to a translated word is sent to a string no script printed |
| `act_effect_never_taken_from_existence` | a completed run that recorded **nothing** reads `taken` | the measured failure itself: a reading that cannot be made must never be dressed as one that was |
| `act_effect_record_names_the_reading` | the turn's candidate reading is not recorded, degraded one included | a turn that found nothing and a turn that found three and was refused are different facts; the first is the one the report assumed |
| `act_effect_record_names_each_act` | a candidate's entry drops its unit, branch, `state` or `reason` | `record-ci-retirement-turn.sh` copies the act's words and owns no vocabulary |
| `act_effect_record_bounded` | a truncated record does not say it truncated | the candidate set is unbounded in principle and GitHub caps annotations; a truncated record must never read as a short one |
| `act_effect_workflow_records` | the workflow does not reach the recorder on every path | the degraded branch used to `exit 0` **before** recording — precisely the turn whose silence was measured |
| `act_effect_one_reader_retirement` | the composition and the act's own source disagree | `act-effect.sh` owns the assembly and no act's vocabulary; it must be visibly unable to answer on its own |
| `act_effect_one_reader_delivery` | the retry's recorded word is not carried verbatim, or an unattempted branch does not read `pending` | the delivery half is read off the branch story blob the claim scan already fetched — no network call, no second derivation |
| `act_effect_changed_word_reasks` | an unchanged word re-asks, or a changed word does not | asked once per **(unit, refusal word)**. The gate is untouched: the narrowing lives in what the key is made of, so one mechanism cannot drift from itself |
| `act_effect_event_names_the_units` | a blocked tick names no units, a tick whose acts took supplies an `event`, or the summary moves | the root's two guards, split: the empty event holds the healthy hour, the summary diff holds a standing block — which is why the summary carries no CI term |
| `act_effect_breaker` | restoring the run-existence inference changes nothing | **the deliberately broken seam.** Answering `taken` from a completed run's existence must drop the question for a unit CI refused `gh_unavailable`. Written against the return shape this would pass a refactor that keeps the JSON and loses the reading, so it asserts the **damage** instead |
| `act_effect_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout |

## 5l-bis. The revision (can the operator revise a live direction through the loop?)

`verify-revision` needs no seed, no fire, no issue number and **no network**: the strategy half
is local files, and the publish half runs against a local bare origin with `gh` stubbed on
`PATH`. The stub answers a **successful** merge on purpose — a stub that refused would let the
auto-merge exemption pass for the wrong reason.

**This is the first write into `.workaholic/strategies/` a machine makes on the operator's
behalf**, and its whole safety is a set of refusals. So the refusals are drilled by name and each
one asserts the artifact is byte-identical afterwards: write-then-revert is not the contract, and
a row that only checked the reason word would pass a writer that wrote and rolled back.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `revision_fixture` | `create.sh` did not leave a live direction | the fixture is not the shape under test; every row below it would prove nothing |
| `revision_date_moved` | the date does not move in both the frontmatter and the `Target:` line, or no line records it | `amend.sh` — `target_date:` and `## Schedule` are one revisable part, so a strategy states its date once, not twice |
| `revision_aim_sharpened` | the stdin form does not replace the Aim, or it moves something else | the `--aim -` path, the shape `create.sh` uses for the same prose |
| `revision_assignee_changed` | the owner does not move, or the record is out of order | the append-only `Revised …` block: a previous line is never rewritten and never reordered |
| `revision_noop_appends_nothing` | a re-applied revision writes | the `already` return sits **before** the append, so the file cannot grow a line on every tick that re-ran the same ask |
| `revision_no_revision_refused` | an ask naming nothing revisable is not refused `no_revision` | "this is going well" is an announcement, not a revision |
| `revision_floor_breach_refused` | a floor breach is not refused by `create.sh`'s own name with nothing written | the write-time hook **grandfathers git-tracked files**, so it is silent on exactly these writes and `amend.sh` carries the floor itself |
| `revision_immutable_field_unreachable` | a flag reaches a field the model calls immutable | **the deliberately broken seam.** Widen the interface — a `--status`, a `--feedback`, a `--slug` — and this row goes red while every other row stays green; verified by adding a `--status` case to the option loop, which turned exactly this row red |
| `revision_not_active_refused` | a closed direction is amended | `close.sh` stays the only writer of an end state, and re-opening is offered nowhere |
| `revision_publish_never_merges` | a strategy-touching publish merges under `WORKAHOLIC_AUTO_MERGE=1` | `publish-tree-pr.sh` → `merge_reason: strategy_touching`. This is the premise the third writer rests on: the operator's merge is what authors the artifact, so the exemption had to move from prose into the seam |
| `revision_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout |

## 5m. The delivery retry (does an undelivered unit get its merge re-attempted?)

`verify-delivery-retry` needs no seed, no fire, no issue number and **no network** — the same
local bare origin and the same `PATH` stub as §5l.

**Naming the state was only half the repair.** `report_undelivered` (2026-08-27) made a unit the
loop finished and could not merge *visible*, and nothing then offered it its one remaining
action: `plan-units.sh` excluded it `claimed_undelivered` at every later survey and `claim.sh
resume` refused it by name, so it was delivered by nobody until a person opened the pull request.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `retry_fixture` | the fixture does not hold a `report_undelivered` unit beside a scan-held one | the fixture is not the shape under test |
| `retry_offered_in_its_own_field` | the survey does not offer the unit in `undelivered[]`, or stops excluding it | **both halves are asserted**: loosening `claimed_undelivered` would return the unit's *archived* tickets to `backlog[]`, where a run would re-drive work already written and pushed |
| `retry_reaches_the_transport` | the undelivered unit does not get past both gates to the merge seam | with an empty stub answer the attempt stops at `no_open_pull_request`, which is precisely the proof that the gates passed and no network call was made |
| `retry_scan_held_never_tried` | a scan-held unit reaches the retry | the gate *working* is not the loop stopping; the verdict chain keeps it out entirely, and the writer's own second gate is the backstop |
| `retry_unrecorded_never_tried` | an **unrecorded** outcome reaches the merge seam | **the deliberately broken seam.** With nothing recorded the verdict falls back to `queue_drained`, so the retry must refuse — a retry that acted there would be merging on an assumption. Verified by removing the verdict test, which turned this row **and** `retry_scan_held_never_tried` red together |
| `retry_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout |

**The broken-seam proof found something.** Widening the verdict gate turned `scan_held:hard`
into the refusal that stopped the scan-held unit — so the writer's second, "redundant" gate is
the live backstop rather than dead code, which is why its header says to keep it.

## 5n. The base's health (did the base survive what the loop merged?)

`verify-base-health` needs no seed, no fire, no issue number and **no network**: a local bare
origin, and a `gh` stub on `PATH` answering per commit out of a fixture directory. The drill
asserts the stub is what `gh` resolves to rather than assuming it — a drill that silently reached
the network would prove nothing about the offline contract it claims to check.

**A green base and a base nobody looked at were one reading.** The loop merges its own work onto
`main` every half hour and nothing in this plugin read a check run; no `/moderate` step saw it
either, because `stuck-prs` and `merge-conflicts` read **pull requests** and find nothing wrong
with one that already merged.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `base_health_offline` | `gh` resolves to anything but the drill's stub | the drill is reaching the network, so every row below it proves nothing about the offline path |
| `base_health_reads_green` | every completed check passing does not read `green` | `read-base-checks.sh`'s success path |
| `base_health_reads_red_with_names` | a failing check does not read `red`, or the failing check is unnamed | a red tip with no names sends a person to the Actions tab to re-derive what the reader already knew |
| `base_health_unanswerable_by_name` | a running check, a **checkless** commit or an unknown commit does not read `unanswerable` under its own reason | the three-valued shape: each of these is a reading about **us**, and collapsing any into `green` is the defect the reader exists to close |
| `base_health_walks_past_a_checkless_tip` | a tip **no workflow ran on** does not resolve to the newest checked ancestor, or the verdict does not say which commit it rests on and how far back | `attribute-base-red.sh`'s tip `case`. This loop commits to its own base constantly and every workflow filters `.workaholic/` out, so the tip is *usually* checkless: when this row is red the step that exists to notice a broken base is dark exactly when the loop is busiest — measured over a day and a half of `base_unreadable:tip_no_checks` on a base that was green throughout |
| `base_health_only_no_checks_is_walked_past` | an `unanswerable` that is a fact about **us** (a reader that failed, a rate limit, a refused transport) is walked past, or names a checked ancestor | the same `case`'s `*)` arm. `no_checks` is a statement about the **commit** and has a defined answer one step back; every other reason means we could not look, and walking past one reports an older commit's colour as though it were current — the collapse the three-valued reader exists to prevent |
| `base_health_attributes_the_merge` | the oldest red commit after the last green one is not named, with its pull request and author | `attribute-base-red.sh`'s walk, and its pull-request lookup |
| `base_health_unattributable_tail` | a walk that exhausts its bound names a culprit anyway | **never the tip by default**: blaming the head because the walk ran out of room is what `unattributable` exists to prevent |
| `base_health_step_asks_once_per_commit` | the step's question is not keyed `base-red:<attributed commit>` | the key is what makes *exactly once per broken commit* mechanical rather than a rule somebody remembers |
| `base_health_asked_once` | a second tick over the same red commit is not refused | `ask-question.sh`'s ledger — the step gained no ledger of its own |
| `base_health_degraded_asks_nothing` | a read we could not make asks somebody, or renders a line | our own blindness is not a finding about the repository (`strategy-pace`'s rule) |
| `base_health_green_is_silent` | a green base asks or renders anything | *a step with no event renders no line* — the renderer's independent guard |
| `base_health_survey_unmoved` | the survey differs between a red base and a green one | the terminal token is derived from the **survey**, so a survey that cannot see the reading is a token that cannot move with it |
| `base_health_gates_nothing` | any script in the driving chain reaches either reader | there is nothing for a gate to be built out of. `main` is the continuously auto-merged development branch and the `release/*` window owns quality |
| `base_health_can_fail` | a commit with **no checks at all** reads `green` | **the deliberately broken row, and the one to look at first on a red drill.** An empty check list looks exactly like *nothing failed*; if the reader ever agrees, a base nobody looked at becomes indistinguishable from a base that passed |
| `base_health_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout |

**Both failure modes were observed, not asserted.** Making the reader answer `green` for a
checkless commit turned `base_health_can_fail`, `base_health_unanswerable_by_name` and
`base_health_degraded_asks_nothing` red together; adding a reference to `read-base-checks.sh`
inside `plan-units.sh` turned `base_health_gates_nothing` red and named the script.

**Two proofs, and they are not the same one.** This drill is the **operator's**; the hermetic
suite's `testReadBaseChecks`, `testAttributeBaseRed`, `testBaseHealthStep` and the extended
`testProofJudgementSplit` are what **CI** enforces on every change. The drill ships to no other
agent and CI never runs it.

## 5j. The identity hand-off (issue assignee → stamped address → survey)

`verify-identity-handoff` needs no seed, no fire, no issue number and **no network**: it builds
a throwaway repository whose committed mapping names one person's two addresses, then walks the
real writers and the real survey over it.

**It drills a seam, not a component.** The link runs across three of them — the issue's
assignee, the address `/specificate` stamps, and the survey that offers the unit — and it broke
*between* them: each component was internally consistent, nothing tested the walk, and the break
was invisible for five days while every hourly tick reported a clean survey. Measured
2026-08-26: `backlog_size: 10` with `backlog: []` and `owned_by_other` ×7, including the mission
whose own job was to repair the other half of the defect.

**The mission half and the loose half are drilled for different things.** A mission is not
drivable until it carries an acceptance plan (`no_plan`), and that plan is a human's
interrogation rather than anything this seam writes — so the mission is checked for the address
it *stamps*, and a loose ticket for the address the survey *acts on*.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `identity_handoff_canonical_mission` / `_stamped` | an issue assigned to the canonical address does not stamp it | `identity.sh`'s login/address pass, and the writer passing its `canonical` through |
| `identity_handoff_canonical_offered` | the survey does not offer that unit | `owns.sh` over `owners.sh` — the ownership chain the survey filters on |
| `identity_handoff_alias_mission` / `_stamped` | a **mapped alias** does not resolve to the canonical address | `identity.sh`'s pass 2, the reading the whole change exists for |
| `identity_handoff_alias_offered` | the alias's unit is not offered | `owns.sh`'s canonicalisation of both sides |
| `identity_handoff_unmapped_team_owned` | an unmapped login stamps anything at all | `/specificate`'s refusal to guess: `assignees: []` is claimable, a wrong address is not |
| `identity_handoff_unmapped_offered` | team-owned work is not offered | `owners.sh`'s empty-means-team-owned rule |
| `identity_handoff_fails_when_dropped` | an address the mapping does not name is still offered | **the drill's own honesty**: a test that only proves the happy path would have passed throughout the five stranded days |
| `identity_handoff_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout |

**Two proofs, and they are not the same one** — the same split as §5i. This drill is the
**operator's**; the hermetic suite's `testIdentityReader`, `testOwnsResolvesAliases` and
`testSpecificateStampsResolvableAddresses` are what **CI** enforces on every change. The drill
ships to no other agent and CI never runs it.

## 5p. The declared handoff's question (does the one act reach the person?)

`verify-handoff-question` needs no seed, no fire, no issue number and **no network**: a local
bare origin and a `gh` stub on `PATH`. The drill asserts the stub is what `gh` resolves to
rather than assuming it, and its result is unchanged with networking unavailable.

**Nothing read the verdict.** `awaiting_verification` appeared nowhere outside `drive/` until
2026-08-27. `workaholic:drive` §6 leaves such a unit's pull request open and its claim standing
on purpose, and then no surface addressed anybody again — while `stalled-units`, once the tip
went stale, asked *a claimed unit has not moved for a day or more*, which sends a person to look
at a claim instead of telling them the one act it waits on.

**The fixture reaches the verdict through the real derivation.** Reported (a branch story at the
tip), work still queued, and the declaration on that **queued** work. A drill over a forced
verdict proves the renderer and nothing about the oracle, so `handoff_question_fixture` is
load-bearing and stops the drill: a failure below it is then attributable to the step rather
than to a mis-built fixture.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `handoff_question_no_network` | `gh` resolves to anything but the drill's stub | the drill is reaching the network, so every row below it proves nothing about the offline contract |
| `handoff_question_fixture` | the oracle does not read `awaiting_verification`, or no ordinary parked claim sits beside it | the fixture is not the shape under test; every later row would pass while proving nothing |
| `handoff_question_asked` | the question is missing, misaddressed, or does not carry the declared reason **verbatim** | a boolean says a unit is waiting; only the string says what for, and the addressee is the claim **holder**, never the running identity |
| `handoff_question_releases_on_drive` | a unit whose declaring ticket has been driven is still asked about | **the deliberately broken row, and the one to look at first on a red drill.** The declaration is read from the work still **queued**, which is what makes the reading self-releasing with nothing stored anywhere; a reading that consulted the archived work would ask forever |
| `handoff_question_asked_once` | a second tick over the same unit is not refused | `ask-question.sh`'s ledger — the step gained no ledger of its own |
| `handoff_question_stalled_silent` | `stalled-units` asks about the same unit, stops counting it, or stops asking about the ordinary parked claim beside it | one step asks and the other filters, and either half alone is a defect: with the filter gone one unit draws two differently-worded questions, and with the asking step gone the filter turns the finding into silence |
| `handoff_question_clears_nothing` | the claim's verdict moved, a branch vanished, or the fixture checkout was written to | `awaiting_verification` is a **judgement**: nothing here clears a handoff, retries a verification, merges or closes the pull request, or touches the claim |
| `handoff_question_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout |

**The broken-seam row was observed to fail, not asserted able to.** Changing
`claims_declared_reading` to read the claim's **artifacts** (whose tip path is the archived one)
instead of `claims_remaining_tickets`' still-queued set turned `handoff_question_releases_on_drive`
red and the drill's verdict to `fail`, with every other row still passing — which is exactly how
a drill without that row would convert an unproven claim into a believed one.

**Two proofs, and they are not the same one.** This drill is the **operator's**; the hermetic
suite's extended `testProofJudgementSplit` is what **CI** enforces on every change. The drill
ships to no other agent and CI never runs it.

## 5q. The return path (does an answer in the thread reach the loop's work?)

`verify-return-path` needs no seed, no fire, no issue number and **no network**: local fixtures
under the OS temp dir and a `gh` stub on `PATH`. The drill asserts the stub is what `gh` resolves
to rather than assuming it, and its result is unchanged with networking unavailable. The Slack
half is **fixture data on purpose** — what is under test is which writer sees a reply, not the
transport.

**Nothing reached the writer.** `record-answer.sh` was the only writer of the answered line from
2026-08-23 and no script executed it: the documented flow was the developer opening the session
link and answering inside the moderator's own session, one session per answer. A reply typed into
the `🔎 Moderation` thread — where the question is — reached nothing at all: it is not a channel
message, so `unanswered-asks` cannot see it, and the `:40` sweep excludes answers to the tick's
own questions by rule.

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `return_path_no_network` | `gh` resolves to anything but the drill's stub | the drill is reaching the network, so every row below it proves nothing about the offline contract |
| `return_path_coordinate_recorded` | the coordinate does not round-trip from the ask line by the question's key | `ask-question.sh --record-ask` and `question-state.sh` disagree about the line's shape — the format has one home, `lib/question-coordinate.sh` |
| `return_path_read_names_thread` | the candidate set is wrong, or a coordinate-less question is treated as readable | the step names what to read and what it cannot; a candidate with no coordinate is **named**, never searched for |
| `return_path_no_channel_read` | the handed-back bound stops forbidding a search, or names a window | the read is one thread per candidate on a known coordinate; a window is a channel read wearing the step's name |
| `return_path_answer_recorded` | the state does not become `answered`, or the words are lost | a recorded answer nobody can read is the same failure at one remove — the next run must be able to act on it |
| `return_path_machine_post_excluded` | the judgement's bar is not carried to the agent | the exclusion is **by shape**, and it is the one thing standing between the tick and recording its own post as a person's answer |
| `return_path_issue_filed` | the filing does not go through `file-inbound-ask.sh` | one filer, no second inbox: the work rides the existing issue ledger and `[Specificate]` ingests it like any other ask |
| `return_path_filed_once` | a later tick would read the same answer again | the dedup is **structural** — an `answered` question is not a candidate — so no cursor and no second ledger exist |
| `return_path_stamp_is_a_reaction` | the catalog stops naming the emoji exactly once, the template stops authorizing it, or a reply creeps back in | a reply into a thread the person is already reading is the hourly restatement this repository has retired posts for twice |
| `return_path_stamp_not_load_bearing` | the recording depends on the stamp having landed | the answer is recorded and any issue filed **before** the stamp is attempted; `ack_failed` changes nothing else |
| `return_path_breaker` | a step wired at the **channel** still passes the bound check | **the deliberately broken row, and the one to look at first on a red drill.** Wiring the read at the channel is the mistake that silently reintroduces the history read this design avoids; a drill that cannot catch it would convert an unproven claim into a believed one |
| `return_path_outcome_pending_silent` | an answer whose outcome is not known yet yields a reply | *received* is not *acted on*: replying before the outcome is known tells somebody their answer was acted on when nobody knows |
| `return_path_outcome_named` | a settled outcome does not reach the agent carrying the recorded words and the coordinate | the reply says what **the person actually wrote** and lands on a coordinate already in hand — a paraphrase, or a lookup, is a different post |
| `return_path_outcome_bounded` | the handed-back bound stops forbidding a lookup, or admits a mention token | it closes a loop rather than demanding attention, exactly as `✅ 解消を確認` does |
| `return_path_outcome_once` | a later tick would post the outcome reply again | the dedup is the `human-checkin-outcome-<slug>` ledger line **plus** the reading — never a cursor |
| `return_path_outcome_shape_single_sourced` | the catalog stops naming `🧾 対応結果`, the template stops authorizing it, or it gains a mention | one shape, one home, and it is deliberately **not** the stamp's emoji: *received* and *acted on* are two events |
| `return_path_outcome_changes_nothing` | the outcome half moves the question's state | it re-asks nothing, confirms nothing and merges nothing; the recording, the filing and the stamp all happened in earlier ticks |
| `return_path_outcome_breaker` | a step keyed on the answer's **existence** rather than its outcome still stays silent over an unknown one | **the second deliberately broken row.** Written against the *behaviour*, so a refactor that keeps the return shape and loses the outcome gate still fires it |
| `return_path_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout |

**The outcome rows were added by widening this drill rather than staging a second one**
(2026-08-31, mission `make-the-tick-s-questions-readable-and-close-them-in-the-thread`). The
fixture already reaches recording and filing, which is exactly what the outcome half needs, so
the whole addition is **one filing line and one extra question** — *one fixture, two questions*.
A near-identical second repository would have been a second thing to keep in step with the first.

**Two proofs, and they are not the same one.** This drill is the **operator's**; the hermetic
suite's `testAnswerReturnPath` and the catalog↔template drift pin inside
`testModerateRoutineTemplate` are what **CI** enforces on every change. The drill ships to no
other agent and CI never runs it.

## 5r. The condition age (how long has this been standing?)

```sh
sh scripts/e2e/loop-drill.sh verify-condition-age [--json]
```

Walks log → reader → bound → question → report for the age of a standing blocker (2026-08-30,
mission `say-how-long-the-loop-has-been-stuck`). It needs **no seed, no fire, no issue number
and no network**: it builds a throwaway tick log, drives the real ledger writer over it, and
runs the one step that is fully local.

**What it proves.** A key first named days ago reads that tick with a count above one; a key
nobody has asked about is an ordinary absence carrying **no** `readable` field; a log that
exists and cannot be read is named with **null** counts, never zeroed ones. A walk cut by
`WORKAHOLIC_CONDITION_AGE_MAX_DAYS` reports a **floor** with real counts and no degradation,
while an uncut one is byte-identical to an unbounded walk. `step-undrivable-units.sh` attaches
the age with its **summary and its candidate keys byte-identical**, so no question is re-asked
by the changed wording and the root renders no new line. And no gate, no driving survey and no
proposing survey reaches the reader.

**Why the ledger lines are written by the real writer.** `ask-question.sh --record-ask` is
driven rather than hand-authored, so the drill cannot pass against a line shape the writer never
produces — `verify-ci-retirement`'s measured lesson, where a fixture that configured for itself
the one term production lacked stayed green while production was silent.

**Why only one step runs end to end.** The other three age consumers read the claim oracle,
which fetches; standing up a bare origin per step would drill the oracle rather than the age, so
for those the drill asserts the **composition** and `scripts/test-workflow-scripts.mjs` carries
the acting-call-site bans.

**Its breaker** is written against the **behaviour**: the walk wired at a single tick, so every
age must collapse to `1` — not merely return a different shape. That is the exact regression
that would make an eleven-day blocker read as one that just started.

| Row | What a failure means |
| --- | -------------------- |
| `age_reads_the_earliest_tick` | `condition-age.sh` or `log-read.sh` — the walk is not finding the ledger line the writer produced |
| `age_absent_is_readable` | `condition-age.sh` — an absent key is being reported as a degradation |
| `age_unreadable_is_named` | `condition-age.sh` — a read we could not make is rendering as one we did |
| `age_bound_is_not_a_degradation` / `age_uncut_is_byte_identical` | `condition-age.sh`'s bound |
| `age_rides_the_question` / `age_key_did_not_move` | `step-undrivable-units.sh` |
| `age_stays_out_of_the_summary` / `age_summary_is_stable` | a step summary gained an age, which marks it changed hourly by construction |
| `age_reaches_every_consumer` | one of the four question steps stopped composing the reader |
| `age_gates_nothing` | a gate or a survey now reads the age — a judgement has become a gate |
| `age_breaker` | the drill can no longer fail, so every row above proves nothing |

## 5s. The directed notification (does the question reach a person?)

```sh
sh scripts/e2e/loop-drill.sh verify-directed-notification [--json]
```

Walks transport → rule → call site → template for the two posts whose whole purpose is to
**reach** somebody (2026-08-31, mission `notify-the-person-a-directed-question-addresses`). It
needs **no seed, no fire, no issue number, no credential and no network**: `curl` is stubbed on
`PATH`, so what is asserted is the **bytes that would have gone out**.

**What it proves.** The tokened transport carries a coordinate verbatim, so a bot can reply
*into* the thread the connector resolved; a post with no flag is byte-identical to the
pre-repair builder's, compared against that builder **re-run**, never against a literal typed
into the drill; a malformed coordinate is refused `bad_thread_ts` with **nothing posted**,
because a root sent silently where a reply was asked for is invisible from the caller's side;
and with no bot token the directed post is a reported `no_token` no-op at exit 0 — the
connector fallback, never a drop. The rule **enumerates** its directed set, names both shapes
and makes extending it a deliberate edit; both call sites and both routine templates state the
same rule, the addressee and what an unresolved address does.

**The gate's immunity is proved by execution, not by reading a diff.** The same key on the same
fixture must answer **byte-identically** with a bot token and without one, and `ask-question.sh`
must name no transport at all — the structural half, so a future gate cannot start branching on
a token while still answering identically today.

**What no drill can prove** is that a human's phone buzzed. That half is the mission's handoff
ticket, deliberately separate so the mechanical proof is not held hostage to a credential.

**Its breaker is in two halves, each written against the behaviour.** One restores the
pre-repair **transport** (`--thread-ts` removed, so the bot can only ever post a root — and the
broken copy still posts successfully, so the row catches a regression rather than a crash); one
restores the pre-repair **rule** (the enumerated directed set removed, so availability alone
decides the carrier). Either alone would leave the other half unproved.

| Row | What a failure means |
| --- | -------------------- |
| `directed_reply_carries_the_thread` | `notify-slack.sh` — the bot can no longer reply into a resolved thread |
| `undirected_post_is_unchanged` | `notify-slack.sh` — every caller that passes no flag has silently changed what it sends |
| `malformed_coordinate_posts_nothing` | `notify-slack.sh` — a bad coordinate is being dropped into a root instead of refused |
| `no_token_falls_back_and_is_reported` | `notify-slack.sh` — a missing token stopped being a reported no-op |
| `rule_enumerates_the_directed_set` / `rule_keeps_every_other_shape_on_the_connector` | `notify/SKILL.md` — the carrier became a post-time judgement |
| `call_sites_state_the_same_rule` | `moderate/reference/workflow.md` or `drive/reference/routing.md` — two consumers reading one rule differently |
| `templates_name_shape_and_carrier` | `/moderate` or `/implement` — the command is the ceiling, so a shape it does not name cannot be posted (the shapes lived in the routine templates until 2026-09-01) |
| `gate_is_transport_blind` / `gate_never_reads_the_transport` | `ask-question.sh` — which questions are asked started depending on which surface would carry them |
| `directed_notification_breaker_transport` / `directed_notification_breaker_rule` | the drill can no longer fail, so every row above proves nothing |

## 5t. The stranded publication (does the loop repair what a generator can settle?)

```sh
sh scripts/e2e/loop-drill.sh verify-stranded-publication [--json]
```

Walks reader → act → delivery → re-run → question for a **publish-tree publication** the loop
opened and could not merge (2026-08-31, mission
`repair-a-mechanically-resolvable-conflict-instead-of-reporting-it`). It needs **no seed, no
issue number, no credential and no network**: the origin is a bare local repository and the
GitHub transport is a stub on `PATH`, so the fixture is a real collision on a real generated
index rather than a shape that resembles one.

**What it proves.** A publication — a `work-*` branch with **no claim commit**, which is exactly
what `publish-tree-pr.sh` pushes — is read at all, with each of the three classes derived through
the one derivation; a collision only a person can settle is refused by its own word with its
branch **byte-identical**; a collision a generator settles is caught up, **regenerated so both
sides' records survive**, pushed and delivered with no person; **a publication that collides with
nothing is delivered with no catch-up at all** — nothing merged, regenerated, validated or
pushed, and no ref written before the merge; no path leaves a worktree behind; a re-run moves no
ref, and a re-run over the *delivered* publication refuses by name because the merge closed its
pull request; and the content one reaches a person as exactly one keyed question.

**Its two breakers both run before anything is settled**, deliberately: afterwards the settleable
branch contains the base and the delivered one is closed, so there is nothing left to misclassify
or refuse. The first strips the generated-region proof out of
`ship/scripts/lib/conflict-class.sh` and asserts the settleable collision then reads `content` —
reported rather than repaired. The second (2026-09-01, mission
`deliver-a-stranded-publication-that-needs-nothing-but-a-merge`) narrows the act's class gate back
to `mechanical` alone and asserts the clean publication is then refused `not_mechanical:clean`
with nothing attempted — five green publications read, named and delivered by nothing. Each is the
measured incident reproduced on demand, and each runs against its **own** broken copy of the
skills tree so neither confounds what the other asserts.

**What this drill does not prove** is that the consuming repository's own incident is gone. That
repository may be on a different plugin version; this exercises this checkout's scripts only.

| Row | What a failure means |
| --- | -------------------- |
| `stranded_reader_sees_a_publication` | `list-stranded-publications.sh` — a publication is invisible again, or its class is no longer the one derivation's |
| `stranded_content_is_refused` | `settle-stranded-publication.sh` — the act is resolving a collision only a person may, or it moved a branch it refused |
| `stranded_mechanical_is_settled` | `settle-stranded-publication.sh` or `catchup-main.sh` — the repair stopped firing, or the regeneration stopped re-deriving the index from the merged source |
| `stranded_leaves_no_worktree` | `settle-stranded-publication.sh` — the teardown stopped running |
| `stranded_rerun_is_a_noop` | `settle-stranded-publication.sh` — the act is no longer idempotent |
| `stranded_clean_is_settled` | `settle-stranded-publication.sh` — the class gate narrowed back to `mechanical`, or the `clean` path started taking a catch-up it has nothing to do |
| `stranded_clean_rerun_is_a_noop` | `settle-stranded-publication.sh` or `list-stranded-publications.sh` — a delivered publication is being acted on a second time, or the reader started naming a pull request nobody has open |
| `stranded_content_asks_nobody` | `step-stranded-publications.sh` — a content collision is deferring to the publication's author again (retired 2026-09-02), or it stopped being counted in the summary |
| `stranded_breaker` / `stranded_clean_breaker` | the drill can no longer fail, so every row above proves nothing |

## 5t-b. The stranded claim branch (does the loop refuse to delete work nothing else has?)

```sh
sh scripts/e2e/loop-drill.sh verify-stranded-claim-branch [--json]
```

The one mechanism in this loop whose regression **destroys work rather than delaying it**
(2026-09-02, mission `prove-a-claim-branch-is-empty-before-deleting-it`). `superseded` licenses
`retire-claim.sh` to delete a remote branch; until 2026-09-01 it proved only that the unit's
tickets were archived on the base, and that implies *the branch holds no work* only when a branch
carries nothing but its own unit's tickets. Measured: two branches whose tickets had landed
through **different** branches still held ~300 lines of code and a documentation section present
on no other ref, and the tick was asking for both to be deleted. Only a 403 on `push --delete`
had prevented the loss, for five days — which is precisely why the drill is owed: **the day the
transport is repaired is the day a regression here becomes a silent loss instead of a reported
nuisance.**

It needs **no seed, no issue number, no credential and no network**: the origin is a bare local
repository and the GitHub transport is a stub on `PATH` — stubbed for the pull-request half
alone. **The branch delete is real**, over the file transport, so a regression actually removes
the refs and the rows below can see it.

**What it proves.** Three seeded cases at both grains: a branch differing from the base only
inside `.workaholic/` — the ordinary superseded twin, which a bare `diff --quiet` would wrongly
call stranded — is still proved empty and is really deleted from origin; a branch holding a file
that is on no other ref reads `stranded` at the batch grain *and* at the mission grain, is
refused `not_superseded:stranded` by the act, and **its file is still on origin afterwards**; an
emptiness nobody could read answers `unknown` and the verdict answers `stranded`, so no delete is
licensed by an absence. The row a person is asked from carries the **file names**, because a
holder cannot rule on work they cannot see.

**The breaker asserts surviving content, not a return word.** It hands the work-holding branches
straight to the act at both grains with the delete permitted, and asserts the refs and their file
**contents** are still on origin. Measured with the diff term reverted: both branches came back
`retired: true, remote_branch_deleted: deleted` — the loss reproduced on demand — and restoring
the term turns it green. A row asserting the JSON shape instead would have passed over exactly
that.

**What this drill does not prove** is the transport. It cannot show that the production 403 is
gone, or that a real remote delete behaves identically to a file-transport one; it proves the
refusal and the derivation behind it.

| Row | What a failure means |
| --- | -------------------- |
| `stranded_empty_branch_is_superseded` | `lib/claims.sh` — the `:(exclude).workaholic` term went, so the ordinary retirement stopped firing and every claim reads stranded |
| `stranded_holding_branch_is_stranded` | `lib/claims.sh` — the emptiness term left `claims_superseded` at one of the two grains |
| `stranded_row_names_the_files` | `list-claims.sh` or `claims_branch_emptiness` — the question can no longer say what the branch holds |
| `stranded_unreadable_is_never_superseded` | `lib/claims.sh` — an absence of a reading started licensing the act |
| `stranded_proved_branch_is_deleted` | `retire-claim.sh` — the act stopped acting on a real proof |
| `stranded_holding_branch_survives_the_act` | the drill can no longer fail, **or work was actually deleted** — the one row here whose red means loss rather than doubt |
| `stranded_branch_checkout_untouched` | the drill wrote outside its own fixture |

## 5t-c. The claim race (is it settled at the remote, and does the loser write nothing?)

```sh
sh scripts/e2e/loop-drill.sh verify-claim-race [--json]
```

**Measured 2026-08-30**: `work-20260830-055314` and `work-20260830-055318` were both claimed for
one unit four seconds apart and each drove the same four tickets for over an hour. `create.sh`
mints `work-$(date …)`, so two runners that survey before either pushes name **two different
refs** and both win — the protocol contended for nothing.

It needs **no seed, no issue number, no credential and no network**: a bare local origin, two
clones, and the GitHub transport stubbed to answer nothing (so every mission-grain row below is
about the **local** test rather than the merged-pull-request fallback).

**How the window is staged**, which is the whole difficulty: A claims for real, then A's branch is
removed from the origin so B's oracle sees exactly what A saw. No sleep, no concurrency — both
runs are the real claim act, in the interval the defect lived in.

**What it proves, in two halves.** First the **repair** (2026-09-02): B is refused
`claim_race_lost` at the remote, and holds no worktree, no local `work-*` branch and nothing on
origin; a lock a **live** claim stands behind survives the sweep however old it is, because the
oracle is the sweep's first term and the age only its second. Then the **bounded-later** repair,
which still has to work wherever the arbitration is `unavailable` (every routine-fired container,
whose proxy refuses the ref write): with A's lock released the same claim wins, two branches hold
one unit, `list-raced-units.sh` names both, `/moderate`'s `raced-units` asks once, `stalled-units`
stays silent on it, and `archive.sh` refuses the first write that the base would see.

**The breaker is that release.** Repeating B's claim verbatim with the contended ref given back is
the pre-repair contention — two clock-derived names and no unit-keyed ref — and B must then win.
If it did not, every refusal row above would be passing for some reason other than the
arbitration. **Proved able to fail, not argued**: pointing `claim.sh` at a non-existent arbiter
turns five rows red including the breaker, with the loser leaving `worktrees=1 branches=1
remote=1` — the defect itself — and restoring it turns them green.

| Row | What a failure means |
| --- | -------------------- |
| `claim_race_loser_refused` | `claim.sh` §3b or `claim-arbitrate.sh` — the arbitration stopped running, or its refusal stopped being its own word |
| `claim_race_loser_wrote_nothing` | `claim.sh` — the arbitration moved after §4, so the loser now has a teardown to get right |
| `claim_race_lock_survives_its_own_claim` | `claim-arbitrate.sh`'s reap — the oracle term was dropped and the sweep is eating live claims' locks |
| `claim_race_breaker_arbitration` | the drill can no longer fail, so every refusal row above proves nothing |
| `claim_race_two_branches` / `claim_race_one_unit_twice` | the pre-repair state cannot be staged, so the bounded-later repair is no longer covered |
| `claim_race_reader_names_both` / `claim_race_question_asked` / `claim_race_question_asked_once` | `list-raced-units.sh` or `step-raced-units.sh` — a live race reaches nobody, or reaches them repeatedly |
| `claim_race_siblings_filter` | `step-stalled-units.sh` — one unit, two questions, two vocabularies |
| `claim_race_archive_refuses` / `claim_race_refusal_writes_nothing` | `archive.sh`'s claim re-check — the last gate before a duplicated write reaches the base |

**What it does not prove** is the transport. The arbitration is exercised against a **local bare
origin**, where the ref write is permitted; whether a given remote permits it is what
`claim-arbitrate.sh` answers `unavailable` for, and that path is the one every cloud routine
takes.

## 5u. The retirement candidates (does the loop offer only branches it may delete?)

```sh
sh scripts/e2e/loop-drill.sh verify-retirement-candidates [--json]
```

Walks the two 2026-09-01 candidate readings and the act they feed (mission
`leave-only-live-work-in-the-unmerged-branch-list`). It needs **no seed, no issue number, no
credential and no network**: the origin is a bare local repository placed where its last two path
segments read as the slug, and the GitHub transport is a stub on `PATH` answering per branch.

**The reading and the act are one verb, deliberately.** The failure this drill exists to catch
lives in the **gap** between them — a candidate list that was right when it was made and wrong by
the time CI ran — and two separate drills would each pass over exactly that gap.

**What it proves.** Seven branches, one per case: a merged pull request and a hand-closed one are
each offered under their own `candidate_reason`; an open pull request, a branch that never had
one, and a branch whose unit holds a **live** claim are offered under none — the last however
loudly its own pull request says merged; an unreadable read contributes no candidate **and names
its reason**; and the `branch_empty` reading on each row really distinguishes a bookkeeping-only
branch from one holding work found on no other ref. Then the act: a candidate whose pull request
re-opened between the list and the act is refused `not_merged:open`, a hand-closed branch still
holding work is refused `branch_holds_work`, a live claim is refused at the act too, and a branch
already gone from origin answers `already_gone` — every one of them with no ref moved.

**Three breaker rows, written against the behaviour.** Each asserts a refusal the act must make,
so a regression that lets any of them through fails the drill rather than changing a return
shape. Measured on the day it shipped: deleting the live-row skip from
`list-retirable-claims.sh` makes `retirement_reader_offers_nothing_else` fail with the live
claim's branch offered as a `pull_request_merged` candidate — the shape the reader's own header
names as the one that would hand CI a branch a run is still driving.

| Row | What a failure means |
| --- | -------------------- |
| `retirement_reader_names_both_classes` | `list-retirable-claims.sh` — a class stopped being offered, or the two classes collapsed into one word |
| `retirement_reader_offers_nothing_else` | `list-retirable-claims.sh` — a branch that must not be deleted is being offered; the live-row rule or a state test is gone |
| `retirement_unreadable_names_its_reason` | `list-retirable-claims.sh` or `branch-pull-request-state.sh` — a degraded read is being dropped, which reads exactly like a branch whose pull request is open |
| `retirement_row_carries_the_emptiness` | `claims_branch_empty_against_base` or the row that carries it — the evidence the closed-unmerged act gates on stopped being derived |
| `retirement_act_refuses_a_moved_proof` | `delete-retired-claim-branch.sh` — the act is trusting the candidate list instead of re-deriving at the moment of the act |
| `retirement_act_refuses_a_branch_holding_work` | `delete-retired-claim-branch.sh` — the term that fails closed is gone, and a hand-closed branch holding work can be deleted |
| `retirement_act_refuses_a_live_claim` | `delete-retired-claim-branch.sh` — a run's own branch can be deleted out from under it |
| `retirement_act_is_idempotent` | `delete-retired-claim-branch.sh` — a second CI turn over a set already taken errors instead of answering `already_gone` |
## 5u. The tick's standing thread (does an hour add to the day, or restate it?)

```sh
sh scripts/e2e/loop-drill.sh verify-tick-thread [--json]
```

Drives the day-keyed root and the stabilized post gate (2026-09-01, mission
`let-the-tick-add-to-a-standing-thread-instead-of-restating-itself`). It needs **no seed, no issue
number, no credential and no network**: the key derivation is a pure function of a tick id and a
zone, the gate's whole input is a JSON document on stdin plus a tick log the fixture writes through
`log-append.sh` — the real writer — and `step-stuck-prs.sh` is driven against a stub `gh` inside a
throwaway git repository.

**Why it has to exist.** Both behaviours are observable only through Slack, which no hermetic test
can reach, so a regression that returns the tick to an hourly root is invisible until somebody
reads the channel and counts. Measured before the change: 14 roots in one window, 12 of them
carrying no question, and `stuck-prs` opening a root on a `<number>:<blocked_by>` list GitHub
merely answered differently across nine consecutive ticks in which the repository did not move.

**Every row asserting a silence is paired with its opposite**, because both behaviours here are
about something *not* being posted and a drill that only proved the silence would pass a change
that silenced everything: one day keys one root **and** the day boundary still opens a new one; a
transport re-shuffle is silent **and** a pull request entering the stuck set still speaks. The
zone is named rather than inherited, so the drill does not pass or fail by geography.

**The breaker is written against both behaviours at once** — the per-tick key restored *and* the
pair list put back into the compared summary — because reverting either one alone must turn this
drill red. Its copy of the skills tree keeps the plugin's own `skills/<name>/scripts` shape, since
`pulls-state.sh` reaches `../../gather/scripts` for the one GitHub transport; a flat copy would
fail for the wrong reason and the breaker would "break" without proving anything.

| Row | What a failure means |
| --- | -------------------- |
| `tick_thread_one_day_one_key` | `lib/tick-thread-key.sh` — the key names the hour again, so the lookup can never find the standing root |
| `tick_thread_day_boundary_splits` | `lib/tick-thread-key.sh` — the key got coarser than a day and a week is landing in one thread |
| `tick_thread_key_is_stable` | `lib/tick-thread-key.sh` — the key started reading a clock of its own, so a re-entered tick threads somewhere new |
| `tick_thread_reshuffle_is_silent` | `step-stuck-prs.sh` or `render-tick-post.sh` — a transport's answer is back inside the compared string, or `stabilize()` was widened |
| `tick_thread_set_change_speaks` | `render-tick-post.sh` — the gate went quiet on a real change, which is the opposite defect |
| `tick_thread_reply_has_no_head` | `render-tick-post.sh` — the delta reply restates the day, so the thread is the hourly root under another name |
| `tick_thread_carries_no_mention` | `render-tick-post.sh` — an orientation post is waking the channel; the mention belongs on the question |
| `tick_thread_held_tick_posts_neither` | `render-tick-post.sh` or `lib/speaking-window.sh` — a gate above the post stopped holding it |
| `tick_thread_summary_drops_the_pair_list` | `step-stuck-prs.sh` — the per-pull state list is back in the summary the gate compares |
| `tick_thread_ask_key_keeps_the_detail` | `step-stuck-prs.sh` — the coarsening reached `ask_key`, so the ledger can no longer tell one state from another |
| `tick_thread_breaker` | the drill can no longer fail, so every row above proves nothing |

## 5v. The plan the loop adjusts (does it hold, and does it order?)

```sh
sh scripts/e2e/loop-drill.sh verify-plan-adjust [--json]
```

Drives the two mechanisms the planner added (2026-09-01, mission
`adjust-the-plan-hourly-not-only-report-it`): `/propose`'s repository-wide `wip_limit` rung and
`plan-units.sh`'s derived offer order. It needs **no seed, no issue number, no credential and no
network** — the fixture is a throwaway git repository the drill builds, the limit is an
environment variable it sets, and the open-proposal read is supplied as a file, which is the seam
`/propose` and `direction-health` already take.

**The two are drilled together because they fail in opposite directions.** A regression that
*ignores* a declared limit puts six missions in flight again — the measured state the gate exists
for. A regression that *holds* a repository which declared nothing stops the loop **silently**,
which is the more dangerous of the two and is why `plan_adjust_absent_holds_nothing` carries the
same weight as the hold itself rather than riding as a footnote.

**The fixture's commit is dated into the past, and that is load-bearing.** `landed` is a
`git log --since` read over the survey's window, so a fixture committed *now* falls inside any
window: the eligible direction then reads `quiescent` and is refused `arrived` by the rung
*above* the one under test. Measured while writing this drill — it passed or failed depending on
whether a second had elapsed between the commit and the survey. `GIT_COMMITTER_DATE` is the same
control `verify-cadence-lapse` uses, for the same reason.

**The breaker wires the `wip_limit` rung out of the ladder**, and the held direction must
originate again. Without it, the hold row could pass against a survey that never had the gate at
all.

| Row | What a failure means |
| --- | -------------------- |
| `plan_adjust_holds_above_the_limit` | `survey-strategies.sh` — the `wip_limit` rung is gone or unreachable, so N directions can put N missions in flight together again |
| `plan_adjust_below_the_limit_proceeds` | `survey-strategies.sh` — the bound is off by one or the comparison inverted; a repository with room is being held |
| `plan_adjust_absent_holds_nothing` | `survey-strategies.sh` — a repository that declared nothing is being braked by default, which stops the loop with no one told |
| `plan_adjust_unreadable_limit_holds_nothing` | `survey-strategies.sh` — our own failed read became a gate, so a typo in the declaration silences origination |
| `plan_adjust_offer_is_ordered` | `plan-units.sh` — the offer is back to walk order, so which direction converges is whatever the directory listing produced |
| `plan_adjust_offer_set_unchanged` | `plan-units.sh` — the ordering dropped or added a unit; ordering must change order, never eligibility |
| `plan_adjust_offer_says_why` | `plan-units.sh` — a row is ordered with no `order_reason`, so a derived order and a silent walk order look alike |
| `plan_adjust_unreadable_order_is_named` | `plan-units.sh` — a failed resolution falls back to an unannotated walk order instead of naming every row `direction_unreadable` |
| `plan_adjust_writes_nothing_outside_the_fixture` | the drill itself — a reader acquired a write |
| `plan_adjust_breaker` | the drill can no longer fail, so every row above proves nothing |

## 9. The drill register

**One table, three columns, one reader** (2026-08-29, mission
`run-the-loop-s-own-proofs-on-every-turn`). Every question the drill set is asked about
itself is answered here: *can this drill run with no server?* (`Kind`), *can this drill
fail?* (`Breaker`), *which earlier turn does a failure belong to?* (`Mission`). It is read
by exactly one script —
`plugins/workaholic/skills/drive/scripts/drill-register.sh` — which `verify-all`, the
`/moderate` tick's `drill-health` step and the archive gate all compose rather than
re-parse. A second parser is how two readings of one fact start to disagree.

**`Kind` was measured, not read off a header.** Every `verify-*` command the dispatcher
names was run on 2026-08-29 with **no `gh` on `PATH`, no `qfs`, no `ANTHROPIC_API_KEY` and
no proxy** (so no outbound HTTPS), twice, and classified from its **exit code and reason
word** rather than from what its own comment claims. The drill file's header said the whole
of it *assumes the server's full `gh` and `qfs`*; that turned out to be true of two rows out
of thirty. The three kinds are distinguished by name and **`reads_checkout` is never
recorded as `hermetic`**:

| Kind | What it means | What `verify-all` does with it |
| ---- | ------------- | ------------------------------ |
| `hermetic` | builds its own throwaway fixture and exits 0 with no network, no `gh` and no credential | runs it |
| `reads_checkout` | needs no network either, but its verdict depends on **this working tree** (its deployment targets, its strategies, its commit range) rather than on a fixture it built | runs it |
| `needs_server` | reads the real issue and the real remote, and takes an issue number no fixture can mint | **`skipped:needs_server`**, never invoked |

**`Breaker` is recorded here for a person and derived by the machine.** A breaker row
asserts that a *deliberately broken copy* of the seam fails; the machine finds them by the
`bearing: "breaker"` field the rows themselves carry, never by this column. A drill with no
breaker is **`unproved`** — a gap in coverage rather than a broken mechanism — and
`verify-all` counts it separately, outside the passing total.

**`Mission` is resolved, never invented.** Each row was resolved by `git log -S
'cmd_verify_<x>()' -- scripts/e2e/loop-drill.sh` → the adding commit → the tickets that
commit's branch archived → their `mission:` relation, read through
`mission/scripts/read-relation.sh`. Two rows are hand-corrected with their evidence because
a **rename** defeats that derivation (`verify-propose` → `verify-specificate` and
`verify-housekeep` → `verify-moderate`, 2026-08-19), and one is left unresolved on purpose
rather than guessed. **No artifact gained a field**: the slug lives here and nowhere else.

| Drill | Kind | Breaker | Mission |
| ----- | ---- | ------- | ------- |
| `verify-specificate` | `needs_server` | no | `make-the-propose-implement-loop-drillable-on-demand` |
| `verify-implement` | `needs_server` | no | `make-the-propose-implement-loop-drillable-on-demand` |
| `verify-plan` | `reads_checkout` | no | `draft-deployment-plans-in-the-release-note-before-deploying` |
| `verify-status` | `reads_checkout` | no | `split-routine-setup-into-developer-and-repository-scopes` |
| `verify-cadence` | `reads_checkout` | no | `correct-the-release-note-automation-to-its-intended-design` |
| `verify-planner` | `reads_checkout` | no | `make-the-draft-release-note-an-agent-s-release-plan` |
| `verify-standup` | `reads_checkout` | no | `add-the-standup-daily-per-strategy-summary` |
| `verify-moderate` | `reads_checkout` | no | `add-the-housekeep-hourly-operations-routine` |
| `verify-propose` | `hermetic` | no | — |
| `verify-direction-health` | `hermetic` | no | `say-when-the-loop-has-run-out-of-direction` |
| `verify-arrival` | `hermetic` | yes | `say-when-a-direction-has-arrived` |
| `verify-residue` | `hermetic` | yes | `say-what-the-direction-could-not-see-before-calling-it-arrived` |
| `verify-corpus-boundary` | `hermetic` | yes | `keep-the-closing-link-readable-as-the-corpus-grows` |
| `verify-expiry` | `hermetic` | yes | `warn-a-direction-before-its-date-silences-the-loop` |
| `verify-rulings` | `hermetic` | yes | `put-the-loop-s-standing-rulings-on-one-pull-request` |
| `verify-succession` | `hermetic` | yes | `make-a-direction-s-end-a-turn-of-the-loop-not-its-stop` |
| `verify-revision` | `hermetic` | yes | `let-the-operator-revise-a-live-direction-through-the-loop` |
| `verify-merged-claim` | `hermetic` | yes | `tell-a-merged-claim-from-a-live-one-at-both-grains` |
| `verify-identity-handoff` | `hermetic` | yes | `drive-the-work-the-loop-wrote-one-resolution-of-who-a-person-is` |
| `verify-close` | `hermetic` | yes | `close-the-units-the-loop-already-finished` |
| `verify-catch-up` | `hermetic` | yes | `land-the-loop-s-own-work-when-the-base-moves-under-it` |
| `verify-retire` | `hermetic` | yes | `deliver-and-retire-what-the-loop-already-proved-finished` |
| `verify-ci-retirement` | `hermetic` | yes | `finish-a-proved-retirement-where-the-write-is-permitted` |
| `verify-delivery-retry` | `hermetic` | yes | `deliver-and-retire-what-the-loop-already-proved-finished` |
| `verify-handoff-question` | `hermetic` | yes | `ask-for-the-one-act-a-declared-handoff-is-waiting-on` |
| `verify-base-health` | `hermetic` | yes | `read-whether-the-base-survived-what-the-loop-merged` |
| `verify-return-path` | `hermetic` | yes | `let-an-answer-in-the-thread-turn-back-into-the-loop-s-work` |
| `verify-reconcile` | `hermetic` | yes | `reconcile-a-stale-thread-with-the-unit-s-real-state` |
| `verify-checkin-delivery` | `hermetic` | yes | `deliver-what-the-loop-already-knows-to-the-person-who-can-act` |
| `verify-findings-to-work` | `hermetic` | yes | `let-the-tick-s-own-findings-become-the-loop-s-work` |
| `verify-act-effect` | `hermetic` | yes | `read-back-whether-the-loop-s-own-act-took-effect` |
| `verify-operator-pulls` | `hermetic` | yes | `follow-the-pull-requests-the-loop-opens-for-a-person` |
| `verify-stage` | `hermetic` | yes | `make-a-direction-s-lifecycle-a-declared-stage` |
| `verify-condition-age` | `hermetic` | yes | `say-how-long-the-loop-has-been-stuck` |
| `verify-claim-race` | `hermetic` | yes | `stop-two-runs-from-claiming-and-driving-one-unit` |
| `verify-directed-notification` | `hermetic` | yes | `notify-the-person-a-directed-question-addresses` |
| `verify-impairment` | `hermetic` | yes | `name-the-steps-a-tick-could-not-read` |
| `verify-plan-adjust` | `hermetic` | yes | `adjust-the-plan-hourly-not-only-report-it` |
| `verify-cadence-lapse` | `hermetic` | yes | `notice-a-periodic-artifact-that-stopped-being-produced` |
| `verify-blocked-tick` | `hermetic` | yes | `stop-an-unattended-tick-from-waiting-on-a-person` |
| `verify-stranded-publication` | `hermetic` | yes | `repair-a-mechanically-resolvable-conflict-instead-of-reporting-it` |
| `verify-stranded-claim-branch` | `hermetic` | yes | `prove-a-claim-branch-is-empty-before-deleting-it` |
| `verify-retirement-candidates` | `hermetic` | yes | `leave-only-live-work-in-the-unmerged-branch-list` |
| `verify-retired-claim` | `hermetic` | yes | `retire-a-claim-whose-work-is-finished-or-abandoned` |
| `verify-tick-thread` | `hermetic` | yes | `let-the-tick-add-to-a-standing-thread-instead-of-restating-itself` |
| `verify-announced-asks` | `hermetic` | yes | `announce-an-ask-that-landed-outside-a-unit-route-in-its-own-thread` |

### The evidence behind the classification

Measured 2026-08-29 over `bb9196c6`, twice, with the environment named above. **No row was
unstable across the two runs.** Every row not named below exited `0` against its own
throwaway fixture and is `hermetic`.

- `verify-specificate` / `verify-implement` — exit `2` (`usage`): each takes an issue number
  that only `seed` can mint against the real remote. **`needs_server`**, and the only two
  rows for which the drill file's original header claim still holds.
- `verify-plan`, `verify-status`, `verify-cadence`, `verify-planner`, `verify-standup`,
  `verify-moderate` — exit `0` with no network, but each reads **this checkout**: its
  declared deployment targets, its strategies, its commit range against `origin/main`. They
  pass offline and their verdict is a fact about the tree they were run in, so they are
  `reads_checkout` rather than `hermetic`. `verify-status` reports `refs: stale` offline and
  passes; `verify-cadence` reports `gh_unavailable` and passes, which is the row asserting
  that an unreachable transport is a named refusal rather than a silent write.
- `verify-planner` — exited **`1`** on the first measurement, on the unmodified tree, and
  had done so since the row shipped: the drill's own stub planner was written by a `printf`
  of an escaped one-liner that put the awk program inside double quotes, so awk answered
  `runaway string constant` and no plan was ever authored. `planner_authors` and
  `planner_arranges` were `false` on every run nobody made. The stub is now a quoted
  heredoc, which cannot regress the same way, and the row passes. **This is the mission's
  own premise measured on its first day**: a drill nothing runs is a drill nothing believes.

### Two rows are unresolved, and both say why

- `verify-propose` — added by `0aa4cd79` (*Drill the brake and record the thirteenth
  round*, 2026-08-21), a hand-typed commit on a branch that archived no ticket, so there is
  no `mission:` relation to read. Recorded as unresolved rather than attributed to the
  mission that happened to be in flight that day; `drill-register.sh` answers
  `mission_unresolved` for it and every consumer names that word.
- `verify-moderate` — the same commit renamed `verify-housekeep`, whose own origin is the
  mission that shipped the maintenance tick. Hand-corrected to
  `add-the-housekeep-hourly-operations-routine` with that evidence, because the derivation
  stops at the rename.
