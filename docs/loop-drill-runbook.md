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
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-merged-claim --json` | a throwaway repository carrying a **squash-merged** mission claim and batch claim — proves all four merged-claim readings (merged batch, merged mission, live, unanswerable) with the transport stubbed, so no `gh` call is made |
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
| `direction_health_writes_nothing` | the drill changed the checkout | the reader and the step are pure reads; the strategy artifact has exactly two writers and neither is here |
| `direction_health_fixtures_intact` | the seeded `strategies/` area changed | the same refusal, measured on the tree the step actually looked at rather than on the checkout |

**Two proofs, and they are not the same one.** This drill is the **operator's**, run on
demand in a checkout; the hermetic suite's `testDirectionHealthRefusals` is what **CI**
enforces on every change. The drill exercises the real script closure end to end with the
real survey beneath it; the suite pins the three refusals mechanically (nothing written
under `.workaholic/strategies/`, no reach to `close.sh` or `open-proposal.sh`, exactly two
writers, no `/propose` gate outcome moved). Neither replaces the other: the drill ships to
no other agent and CI never runs it, and the suite cannot prove an operator's checkout
behaves.

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
