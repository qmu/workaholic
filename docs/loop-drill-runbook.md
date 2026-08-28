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
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-direction-health --json` | a throwaway strategy tree, one overdue direction and one dormant one — proves the four lifecycle readings, the three question keys, the asked-once gate, and that nothing was written |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-arrival --json` | a throwaway **git** strategy tree carrying landed work — proves `arrived`, that it outranks `overdue`, that `dormant`, `overdue` and `live` are unchanged, the `direction-arrived:<slug>` key and its asked-once gate, and that no reading closes a direction, with no network and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-residue --json` | a throwaway **git** strategy tree whose attributed work has all landed beside an **unattributed** active mission — proves the honest and the degraded residue read, that only an unreadable residue refuses the arrival, that the question names the residue by slug, the asked-once gate, that no gate moved, and the attribution carry landing and refusing, with no network and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-succession --json` | a throwaway **git** tree carrying one dated direction, its landed work and an unattributed mission — walks close → read the leaving → announce a successor by explicit slug → the carried refs land → `attributed-work.sh` attributes the predecessor's work to it → `/propose` proposes against it, and proves nothing closed, authored or auto-merged a direction, with no network and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-revision --json` | a throwaway strategy tree and a local bare origin — proves the three revisions land, that every refusal leaves the artifact byte-identical, and that a strategy-touching publish never auto-merges, with the transport stubbed and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-merged-claim --json` | a throwaway repository carrying a **squash-merged** mission claim and batch claim — proves all four merged-claim readings (merged batch, merged mission, live, unanswerable) with the transport stubbed, so no `gh` call is made |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-identity-handoff --json` | a throwaway repository with a two-address mapping — walks issue assignee → the address the writer stamps → the survey that offers the unit, for a canonical address, a mapped alias and an unmapped login, with no network and no credential |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-close --json` | a throwaway repository carrying three finished units — proves all four closing outcomes (merged, session-type-refused-then-retryable, refused-and-unretryable, scan-held) with the transport stubbed, plus one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-retire --json` | a throwaway repository holding a `superseded` claim, a live one and a unit held by two — proves the retirement's three acts, that a judgement is refused by its own verdict word, and that the step asks nobody anything, with the transport stubbed and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-delivery-retry --json` | a throwaway repository holding three units finished in the identical shape — proves the survey offers an undelivered unit in a field of its own, that only the proof reaches the merge seam, and that a scan-held or unrecorded one never does, with the transport stubbed and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-handoff-question --json` | a throwaway repository holding a reported claim whose still-queued work declares `verification_handoff:` — proves the declared reason reaches its holder verbatim exactly once, that `stalled-units` asks nothing about the same unit, and that nothing is cleared, with the transport stubbed and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-base-health --json` | a throwaway repository whose base is red at a mid-walk merge — proves the reader's three states, the attribution walk's two outcomes, that one broken commit costs exactly one question, and that the reading gates nothing, with the transport stubbed and one row that deliberately breaks the seam |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-return-path --json` | a throwaway repository holding one asked question with its coordinate recorded — walks ask → reply → record → file → stamp, proves the read is bounded to the question's own thread, that a second tick files and stamps nothing, and that the stamp is never load-bearing, with the transport stubbed and one row that deliberately breaks the seam |
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
| `already_captured` | `skills/specificate/scripts/list-inbound-issues.sh` — a feedback record already names `/issues/<N>`; the ask is in flight, not new |
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
builds a throwaway strategy tree — one direction **past its date while carrying landed
work**, one live and unanswered — hands the survey a synthetic open-proposal list through
`--open-proposals`, and reads `direction-state.sh` and `step-direction-health.sh` over it.

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

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `merged_claim_fixture` | the claim branch is not still ahead of the base | the fixture is not a squash merge; every row below it would prove nothing |
| `merged_claim_batch` | a squash-merged batch claim does not read `superseded` with no transport | `claims_superseded`'s local test in `lib/claims.sh` — the archived-on-the-base filename match |
| `merged_claim_live` | a claim with no merged pull request does not keep its local verdict | the lookup answered `merged` for a branch with none, or the verdict chain short-circuited above `superseded` |
| `merged_claim_mission` | a merged pull request does not make a mission claim `superseded` | `claim-merged.sh` and the non-ticket branch of `claims_superseded` — the behaviour this mission exists for |
| `merged_claim_unanswerable` | a refused lookup changed the verdict | the degradation contract: a wrong `merged` releases work still in flight, a wrong `in flight` only delays a claim, so an unread answer must change nothing |
| `merged_claim_named` | the claim the lookup could not answer for is not named with its reason | `list-claims.sh`'s `merged_lookup_unanswered`, fed by `claims_note_unanswered` |
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
| `return_path_writes_nothing` | the drill changed the checkout | every fixture lives outside the checkout |

**Two proofs, and they are not the same one.** This drill is the **operator's**; the hermetic
suite's `testAnswerReturnPath` and the catalog↔template drift pin inside
`testModerateRoutineTemplate` are what **CI** enforces on every change. The drill ships to no
other agent and CI never runs it.
