# Loop Drill Runbook

How to exercise the propose–implement loop **on demand** instead of waiting for its
hourly ticks: seed an ask, fire each routine by hand, and read a machine verdict per
stage. One command owns the mechanics — `scripts/e2e/loop-drill.sh` — and this document
is the only one an operator needs from seed to a clean pass.

**This runbook documents the drill, not the loop.** Every rule about how the loop itself
behaves lives in the skill that owns it (`workaholic:propose`, `workaholic:drive`,
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
| 2 | Fire `[Propose]` | run the `[Propose]` routine by its trigger id | — |
| 3 | Verify propose | `sh scripts/e2e/loop-drill.sh verify-propose <issue> --json` | `origin/main`, REST issue + pull requests |
| 4 | Fire `[Implement]` | run the `[Implement]` routine by its trigger id | — |
| 5 | Verify implement | `sh scripts/e2e/loop-drill.sh verify-implement <issue> --json` | `origin/main`, REST pull requests, unmerged `work-*` branches |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-plan --json` | this checkout's deployment targets and commit range — proves the plan refresh `[Implement]` carries |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-status --json` | the same targets read the `[Release Status]` way — proves the repository tick reads soundly and stays silent when nothing changed |
| — | Any time | `sh scripts/e2e/loop-drill.sh verify-cadence --json` | the same targets' **draft notes** — proves the daily generation renders, is idempotent and clock-free, and derives its stage |
| — | Any time | `sh scripts/e2e/loop-drill.sh status` | the drill's residue: issues, claim branches, tickets |
| — | After an abort | `sh scripts/e2e/loop-drill.sh reset` | closes/deletes **drill-minted** residue only |

`seed` prints `{"ok": true, "run_id", "issue_number", "issue_url", "assignee",
"slack_posted", …}`. The `issue_number` is the argument every later stage takes; nothing
else is carried between stages, because each relation is read back out of the artifacts.

**Firing a routine by hand.** The routines are account-scoped configuration, so their
**trigger ids** come from the trigger API's list (a `RemoteTrigger`-family tool, exposed
to interactive sessions only — `workaholic:workaholify`, *Direct-apply when
`RemoteTrigger` is exposed*), never from a value written down here. List the account's
routines, take the id of `[Propose]` / `[Implement]`, run it, then read its session: the
run list first, then that run's log. A **scheduled** tick that happens to take the ask
first verifies identically — the drill asserts artifacts, and the artifacts do not record
which fire produced them.

## 2. Timing

Both routines fire hourly on explicit non-zero minutes (the API's minimum interval is one
hour, and a bare `:00` is rewritten to server jitter):

| Routine | Cron | Avoid firing by hand around |
| ------- | ---- | --------------------------- |
| `[Propose]` | `15 * * * *` | **:10–:20** |
| `[Implement]` | `30 * * * *` | **:25–:40** |

Inside those windows a scheduled tick and your manual fire can both take the same ask.
Nothing corrupts — `[Propose]` dedups on the feedback stream and on unmerged branches, and
`[Implement]`'s claim protocol lets exactly one runner hold a unit — but the loser's
session log reads like a failure (`already_captured`, `already_claimed`), which is a
diagnosis you did not need. Fire in the quiet half of the hour and both logs stay
readable.

Between stages 2 and 3, wait for the `[Propose]` session to finish. A verify run against a
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

## 4. Blame table — the `[Propose]` stage

Every abort reason the propose workflow can report, and the **one file to read** for it.
The reasons themselves are defined in `plugins/workaholic/skills/propose/SKILL.md` and
[`reference/workflow.md`](../plugins/workaholic/skills/propose/reference/workflow.md).

| Reason | Read |
| ------ | ---- |
| `nothing_in_hand` | `skills/propose/scripts/list-inbound-issues.sh` — the inbox was genuinely empty (did `seed` really assign the issue to the running identity?) |
| `not_mine` | `skills/propose/SKILL.md` (*Clock-fired discovery*) — the ask is assigned to somebody else; a `/propose` run never takes it |
| `gh_unavailable` | `skills/gather/scripts/gh-rest.sh` — no `gh` on the runner's PATH |
| `identity_unresolved` | `skills/gather/scripts/gh-rest.sh` — `gh api user` returned nothing; the session's credential is the problem |
| `list_failed` | `skills/gather/scripts/gh-rest.sh` — REST itself failed; the `detail` carries the API's own message |
| `already_captured` | `skills/propose/scripts/list-inbound-issues.sh` — a feedback record already names `/issues/<N>`; the ask is in flight, not new |
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
| `branch_collision` on claim | `skills/drive/scripts/claim.sh` — nothing was claimed; the next tick succeeds |
| `origin_unreachable` / `no_origin` | `skills/drive/scripts/claim.sh` — an unpushed claim is not a claim; the run correctly claims nothing |
| `mission_missing` | `skills/drive/scripts/claim.sh` — wrong slug, or the checkout is behind the base |
| `pr_error: gh_unavailable` | `skills/report/scripts/create-or-update.sh` — the work **is** pushed; only the pull request is missing |

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

## 5c. The `[Release Status]` read

`verify-status` needs no seed, no fire and no issue number either, and it writes
nothing anywhere — which is the routine's whole contract, so a drill that asserted it by
construction is the point rather than a convenience.

`[Release Status]` (repository scope, `45 * * * *`, configured by `/setup-repo-routines`
from **one** account) runs `/release-status`, a pure read. On a healthy quiet repository
its correct output is *no Slack message at all*, which makes "did it work?" unanswerable
by watching the channel. Three load-bearing rows:

| Row | Fails when | Read |
| --- | ---------- | ---- |
| `status_read` | the consolidation could not read this checkout | `skills/ship/scripts/report-deploy-status.sh` over `read-deploy-state.sh` — an unresolvable base, or no `.workaholic/deployments/` target |
| `status_stable` | two reads of an unchanged base returned different digests | `skills/ship/scripts/report-deploy-status.sh` — something varying leaked into the digest input; the routine would now post every hour, which is the idle tick `workaholic:notify`'s bright line refuses |
| `status_degraded` | an unreadable base did not refuse cleanly | `skills/ship/scripts/report-deploy-status.sh` — a refusal must name its reason and yield an empty digest, never a digest over partial rows |

`status_stable` is this stage's `plan_idempotent`: a single read is still correct when it
is red, and the *hourly* property is what breaks. The most likely regression is the base
sha finding its way into the digest input — it is excluded on purpose, because a base
that merely advanced is not news.

## 5d. The daily note cadence

`verify-cadence` needs no seed, no fire and no issue number, calls no network, and writes
nothing. It exists for the same reason as `5c`: the behaviour it covers is otherwise only
observable by **waiting a day** and then reading a GitHub draft release.

The generation rides the same `[Release Status]` tick (one repository-scoped routine, both
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
