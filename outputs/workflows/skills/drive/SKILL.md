---
name: drive
description: Use when the user runs `/drive`, asks to "implement the queued tickets", "work through the todo list", or "drive the backlog". Surveys the claimable missions and the unclaimed backlog, partitions them into PR-units, claims each unit on a pushed branch, implements it in the claim's own worktree, reports, and routes it by the unit's effective merge policy — identically in an interactive session and on the every-5-minutes routine.
allowed-tools: Bash
---

# Drive

`/drive` is the project's **sole executor**. One command picks the work up, whether a developer typed it or a cron tick invoked it, and behaves the same either way: it surveys what is claimable, partitions it into units that each deserve one merge, claims each unit on a pushed branch, implements it in that claim's worktree, reports it as a PR, and routes it by the merge policy the artifacts already recorded.

**There is no drive-time confirmation** (`docs/loop-engineering-workflow.md` G1–G2). The interactive run *reports* its partition; it never asks the developer to approve it, and it never asks per ticket. Approval did not disappear — it moved to where the work was decided (see *Where the per-ticket approval prompt went*). What an interactive invocation adds is narration, not decisions.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent. **The unified run issues no the agent's selection prompt at any point** — that is the contract, not an accommodation, so the only Claude-Code mechanism below is an optimization:

- **Parallel fan-out** — a run may drive several claimed units at once by spawning one parallel workers per unit worktree. On other agents (and by default), drive the claimed units **sequentially**; the outcome is identical. Real throughput comes from the claim protocol rather than from in-run fan-out: several runners, or several ticks, take different units and never collide.
- The interactive and headless shapes are **one shape**. `/drive night` is a synonym retained for muscle memory: the unified run *is* the unattended shape, so the token changes nothing.

## The Unified Run

**The model first, because the steps only implement it.** Work arrives as artifacts (missions merged to `main`, queued tickets). A unit of *execution* is not an artifact but a question — **what deserves one merge** — so the run's whole job is to turn the artifact stream into merge-sized units, take each one visibly, finish it, and route it by a policy the artifacts already carry:

```
survey → partition → claim → drive → report → route → account
```

Each arrow crosses a boundary worth naming. **Survey → partition** crosses from derivation into judgment (a script says what is available; the executor says what belongs together). **Partition → claim** crosses from private intent into published fact (until the claim is pushed, no other runner can see the decision). **Report → route** crosses from "the work is done" into "who may merge it", which is the one thing the run is never allowed to decide for itself.

### 1. Survey

First, confirm the plugin install the run is about to trust:

```bash
bash check-deps/scripts/check.sh
```

If `ok` is `false`, print the `message` and stop — a run on a broken install produces damage, not work. If `missing_guards` is non-empty, **warn and continue**: a stale or partial build is loaded and the listed `PreToolUse` guards are not registered, which matters more here than anywhere else because this run commits, pushes, and may merge without a human in the loop. Record the warning in the run report rather than only printing it.

If `version_drift` is `true`, **warn and continue** the same way, naming both `version` (installed) and `checkout_version` in the run report. Drift is deliberately not a stop — see `check-deps`, *Why drift is a warning, not a stop* — but it is the single most useful line in the report when a tick later dies on `dirty_workspace`, because an installed build running an obsolete always-on migration is what produces that dirty tree. Note the check runs **before** the fast-forward below, so a runner whose clone is itself behind the base can see a falsely-matching pair on this tick and the real drift on the next.

Then **freshen the checkout before reading it** (decision J3):

```bash
bash branching/scripts/sync-main.sh
```

Artifacts are published to `main` (J1) but the survey reads *this working tree*, and nothing else in the run fast-forwards it — `claims_fetch` updates remote-tracking refs only. A runner behind `origin/main` therefore surveys yesterday's queue and reports it confidently, which on a five-minute tick looks healthy and does nothing. The step runs identically interactively and on cron: one code path. Each `ok: false` is a reported decision, never a prompt — `commands/drive.md` step 0 holds the table; `not_on_main`, `dirty_workspace` and `diverged` terminate `pending`, while `no_origin` and `origin_unreachable` survey locally and forbid `ok`.

Then survey what is claimable:

```bash
bash drive/scripts/plan-units.sh
```

Emits `{fetched, shallow, base, surveyed_sha, base_sha, current, user_slug, backlog_error, claimed[], resumable[], missions[], backlog[], excluded[]}` — the unclaimed active missions this runner may take and this developer's unclaimed todo tickets, with everything a claim already holds subtracted through the shared reader (*Claims*). `excluded[]` names every mission and ticket it dropped and why (`claimed_active`, `claimed_reported`, `claimed_by_other`, `claimed_resumable`, `owned_by_other`, `no_plan`, `no_tickets`, `queue_drained`, `mission_member`), so nothing leaves the offer silently. It does **not** read `status` for the offer: a mission on `main` was accepted when its pull request merged (K1), so the *area* is the authority and the retired `not_approved` reason is gone. `no_plan`, `no_tickets` and `queue_drained` are deliberately distinct, because each names a different next action: write the acceptance criteria, emit the ticket set, or **decide the close** — a mission whose every ticket was driven and archived is finished, not unplanned, and reporting both as `no_tickets` left four missions (15 archived tickets, 4.66 recorded agent-hours) reading as never-planned for four days.

**`resumable[]` is a third offer, not a report — and it has two tiers.** A claim whose run stopped is claimable work — take it over with `claim.sh resume <unit-id>` (see *Claims → Resume a dropped unit*). Its members are already stamped and already partly driven, so it skips steps 2-3 entirely and enters at step 4 in the worktree the resume adopted or created. Read each row's `resume_reason`:

- **`heartbeat_lapsed` — a run that died mid-drive.** Take it over **before claiming anything fresh**: finishing a half-driven unit beats starting another, and nothing else routes anyone to it. **Left untaken it forbids `ok`** (§7), exactly as an unclaimed ticket does.
- **`parked_with_pr` — a unit that reached its PR and has follow-up work on its branch** (its story file is committed at the tip). Also legitimately resumable, but **reportable rather than mandatory**: it does **not** outrank fresh work and **does not forbid `ok`** when left untaken. Report it and the reason for deferring it. This tier exists because the mandatory reading was measured to be humanly wrong — an attended run spent its first ~40 minutes reopening a pull request the developer considered finished and parked, while their actual WIP waited, and they interrupted twice to ask why. From the operator's seat an open PR means "waiting for a human", and a runner reopening it reads as redoing finished work.

Both tiers stay a *takeover*, never a fresh claim: the unit is already claimed, and resuming continues from the pushed branch tip.

**Missions are offered by ownership.** A mission is claimable when the runner's `git config user.email` is among its owners, or when it has no owners at all (team-owned = claimable); one owned solely by others is dropped as `owned_by_other`. Ownership resolves through `mission/scripts/mission-owners.sh` — the same oracle the mission lens, `list.sh`'s `relation`, `summary.sh` and `ship`'s concern lane read — so the queue a runner drains and the roadmap a developer is shown cannot disagree about whose work it is.

**An unreadable backlog is not an empty one.** `backlog_error` is `""` when the queue was genuinely read, and names the reason otherwise: `identity_unresolved` (no `git config user.email`, so there is no `todo/<user>/` to name — nothing at all is known about the backlog) or `unreadable`. `user_slug` reports *whose* queue was surveyed, empty when unresolvable. A non-empty `backlog_error` **forbids `ok`** (§7), exactly as `current: false` does: a run that never learned the queue's contents has established nothing about it. This is a property of the survey, not of an artifact, which is why it is a top-level key rather than an `excluded[]` entry — `excluded[]` names items the survey *saw and dropped*.

**Truncated history is the third thing that forbids `ok`.** `shallow` reports whether this clone could answer "which branches reached the base at all" — a different axis from `current`, which asks only whether the checkout saw the base's latest commit, and a survey can fail either independently. The shared reader *deepens* a shallow clone before scanning, so `shallow: true` survives only when origin is unreachable; a claim scan computed over truncated history has established nothing about what remains claimable, so it terminates `pending` (§7). See *Claims* for the measurement.

**The survey states its freshness and does not repair it.** `current` is whether the surveyed checkout matches the base; `current: false` means the survey could not see everything on the base, and **`ok` is then forbidden** (§7). The repair belongs to the caller because a script named "plan units" that mutated the checkout would surprise every other caller, and this one must stay side-effect-free — it is called inside claim worktrees too. Note there is no `excluded` reason for staleness: a stale checkout does not drop a *named* item, it never learns the item exists, so the condition is a property of the survey rather than of an artifact.

`fetched: false` means origin was unreachable and the claim set is the last-known one. Survey anyway, but expect the claim step to refuse: **the reader degrades offline, the writer does not.**

If `missions` and `backlog` are both empty **and `backlog_error` is empty**, there is nothing claimable — report that plainly, print the reconciliation line and the terminal token (§7), and stop. An empty queue is a normal tick outcome, not a failure and not a reason to ask the developer for something to do. With a non-empty `backlog_error` the same two empty lists mean the opposite thing: report the reason, and terminate `pending`.

### 2. Partition into PR-units

A **PR-unit** is one merge: one unit ↔ one claim ↔ one branch ↔ one worktree ↔ one PR.

- **Each claimable mission is exactly one unit** (unit id = the mission slug). Its ticket set was designed together and its acceptance list is the bar for the whole batch; splitting it across PRs splits the plan.
- **Related backlog tickets group into one batch unit** (unit id minted by `claim.sh` as `batch-<YYYYMMDDHHMMSS>`). Relatedness is *this run's judgment*, from the signals the survey already carries: the same subsystem or overlapping Key Files, the same `layer`, a `depends_on` chain.

**Group conservatively — when unsure, one ticket per unit.** The failure mode is asymmetric and reviewers pay for it: a PR that bundles unrelated changes cannot be reviewed as one thing, and its reviewer has to reconstruct which diff belongs to which motivation. Splitting too finely costs one extra PR. So group only on a reason you could state in one sentence in the PR body; a hunch that two tickets "feel adjacent" is not one. `depends_on` is the one signal strong enough to group on by itself — a dependent ticket in a separate PR is a PR that cannot merge.

**Never mix merge policies to force a route.** Batching an `auto` ticket with a `review` one does not make the review ticket merge; it makes the auto ticket wait (§6). Policy is not a grouping input — group on relatedness and let the route fall out.

**Report the partition, never ask it.** State each unit, its members, and the reason it is one unit. An interactive developer reads that and can stop the run; the same text goes to the log on a cron tick.

### 3. Claim

```bash
bash drive/scripts/claim.sh mission <slug>
bash drive/scripts/claim.sh batch <ticket-file>...
```

Claim **before** driving, one unit at a time, and read the refusal rather than working around it. `already_claimed` means another runner got there between the survey and now — drop that unit and continue with the rest; that race is the protocol working, not an error. `branch_collision` means two runners minted the same second's branch name: nothing was claimed, and the next tick succeeds. `origin_unreachable`/`no_origin` end the run's claiming entirely (an unpublished claim is not a claim).

The claim creates `.worktrees/<unit-id>/`. **All of the unit's work happens there** — every command wrapped `( cd <worktree_path> && … )` or absolute-pathed, every write confined to it.

**Claiming announces.** `claim.sh` posts one line to Slack after its push succeeds — the unit id, the branch, the member count — and reports the outcome as `announced` / `announce_reason` in its JSON. This is the operator's first signal that a run started: before it existed the first human-visible artifact was the PR at step 5, leaving a window of tens of minutes in which a working fleet and a dead one looked identical. **The notice is never load-bearing**: a missing token, an unreachable Slack, or an outright broken notifier leaves the claim intact and the run unchanged, and only a *successful* claim announces — a refusal announces nothing. Report `announced: false` in the run report rather than treating it as a failure.

### 4. Drive the unit

Inside the unit's worktree, run each ticket through the **Workflow** section: read the ticket (including its `## Policies` and `## Quality Gate`, and the gate of every mission it names), implement, verify against the gate, update effort, append the Final Report, and `archive.sh`. Order the tickets with *Ordering within a unit* below.

**Keep the unit's heartbeat alive while driving it.** The claim branch tip is the liveness signal every other runner reads (*Claims*), so a long stretch with no commit makes a working unit look abandoned and eligible for takeover. Each `archive.sh` refreshes it for free; when a single ticket runs long without one, beat explicitly:

```bash
bash drive/scripts/heartbeat.sh <unit-id>
```

Roughly every ten minutes, or once per ticket, keeps it comfortably inside the default 30-minute window. The beat is an empty commit — no file changes, nothing in the PR diff — **and that is now true rather than merely intended**: `commit.sh --allow-empty` builds the commit against a scratch index seeded from `HEAD`, because git's own `--allow-empty` only *permits* a changeless commit and otherwise commits whatever is staged. Mid-ticket the index is routinely non-empty, and a beat fired over a staged `git rm` swept three real deletions into a commit subjected `Refresh heartbeat` (measured 2026-08-04) — content correct, message wrong, and the story then attributed real work to coordination noise. Beating over a dirty index is deliberately still allowed: that is precisely when a missed beat makes a working unit look abandoned. The beat is **never load-bearing**: a failed beat is reported and the run continues, because the cost of a missed beat is bounded (a takeover race that git resolves) while the cost of aborting a working run is the whole run.

There is **no per-ticket prompt** and no gate-skipping decision to make: the unit was claimable because its artifacts were already authorized. The failure contract below governs everything that can go wrong from here.

**The per-ticket authorization floor did not disappear — it moved up to the unit.** `mission/scripts/drive-authorized.sh` answered, per ticket, "is this ticket's queue pre-authorized?", and its floor is being in flight (not ended) **plus** a non-empty `## Acceptance` — it was `status: approved` plus that acceptance until the draft gate was retired (K1). The survey applies that floor to the mission before it is ever offered — and a **second** one the acceptance count cannot express: at least one ticket must actually name the mission (`no_tickets`, from `mission/scripts/queue-size.sh`). Both are needed, because `/propose` writes a provisional acceptance *sketch*, so an item count is satisfied with zero tickets; a mission in that state was offered as claimable on 2026-07-30 under `merge_policy: auto`. With both floors, every ticket in a claimed mission unit passes the authorization floor by construction *and* the unit has something to drive. The resolver remains the authority for any caller that needs a per-ticket answer; the unified run does not need one, because it never assembles a queue whose authorization it has not already established.

A mission unit's dev environment, when the project declares one, is started inside that worktree on its allocated ports (`mission/scripts/gate.sh` reports `dev_port`), so declared gates run against something live, and is stopped at run end **if this run started it** — never one it found already running.

### 5. Report

Compose the branch story and open the PR, scoped to the claim branch, from inside the worktree:

```bash
( cd <worktree_path> && … generate the story per report's Write Story flow,
  run the branch-safety scan (warn tier — fold findings into the PR body, never a prompt),
  then: bash report/scripts/create-or-update.sh <branch> "<title>" )
```

**Compose `/report`; never fork or absorb it.** The report flow stays independently usable on a hand-driven branch, and this step is the same flow called non-interactively. If its context detection misreads inside a claim worktree, scope it explicitly by branch — do not write a second story generator.

A PR-creation failure is **its own report item**. It never changes a unit's outcome classification, the reconciliation counts, or the terminal token.

**A missing `gh` is exactly that item, not a failure of the unit.** The Claude-Code-on-the-web container the hourly routine runs in has no GitHub CLI, so `create-or-update.sh` reports `{"pr": null, "reason": "gh_unavailable"}` and exits 0 rather than dying at exit 127 after the branch is already pushed. Record `pr_error: gh_unavailable` in the run report. The work itself is fine and pushed, so the unit is **never** `blocked` for this — but a unit that was going to ship is **demoted to the PR path** (§6), because `merge-pr.sh` cannot merge without the CLI either and a run must not report a merge it did not make. The agent can still reach GitHub through its MCP server; a shell script cannot, which is the whole reason the script degrades and hands the problem up.

### 6. Route by effective merge policy

```bash
bash drive/scripts/effective-policy.sh mission <slug>
bash drive/scripts/effective-policy.sh tickets <ticket-file>...
```

The derivation is a script, not prose, because the answer decides whether machinery merges to `main` (decision G5):

| Unit | Policy source | Effective policy |
| ---- | ------------- | ---------------- |
| Mission unit | the mission's `merge_policy`, recorded at creation (K2) | `auto` iff the mission says `auto` |
| Batch unit | each member ticket's own `merge_policy`, recorded at ticket creation | `auto` iff **every** member says `auto` |
| Any member says `review` | — | `review` (any review member wins — the unit is one merge) |
| Any member records nothing | — | `review` (**absent means review**) |

**Absent means review, and the asymmetry is deliberate.** Defaulting to review costs a human one look at a PR; defaulting to auto merges work nobody authorized merging. Every artifact predating the field lands on the reviewable side.

**`review` → stop at the PR** and post its URL to Slack so the human loop picks it up:

```bash
bash propose/scripts/notify-slack.sh "<message with the PR URL>"
```

The notifier is never load-bearing: without a token it records `{"notified": false, "reason": "no_token"}` and the run continues identically. The worktree and the claim **stay** — the unit is unfinished until its PR merges.

**`auto` → ship it** through `ship`'s Ship Flow with no prompts (ship's *Unattended routing* section factors each interactive seam), which means the full evidence-gated doctrine and not a shortcut around it: catch up with `main`, prove the deploy contract, confirm in production, record the evidence, **then** merge, then release and extract concerns.

**An unattended run never overrides a gate.** `auto` means "no *approval* needed"; it never means "no *gate* applies". So:

| Gate outcome on an `auto` unit | What the run does |
| ------------------------------ | ----------------- |
| `secret` finding (non-overridable) | **Hard stop.** No merge, and no laundering it into the PR path as if it were routine. Report the finding, mark the unit `blocked`, leave the claim in place. |
| `size`/`leak` finding (overridable interactively) | **Demote to the PR path.** The override is a human ruling; an unattended caller does not have one. |
| No confirmation method (ship §1-4) | **Demote to the PR path.** The accepted-risk bypass is explicitly a developer's conscious choice — never an unattended default. |
| A confirmation that ran and **failed** | **Hard stop**, unit `blocked`. The branch staying unmerged is the rollback. |
| A `content` conflict catching up with `main` | **Demote to the PR path.** (A `mechanical` conflict is routine reconciliation — ship resolves it itself and continues.) |
| Dirty workspace in the claim worktree | **Demote to the PR path** and report it; something left work behind. |

A demotion is reported as a demotion, with the gate that caused it — "shipped" and "demoted to PR because the size gate blocked" are different outcomes and the report must not blur them.

**After an `auto` unit merges, tear the claim down** (decision I6 — the worktree is claim-born and ship-torn), from the **main checkout**, because git cannot remove the worktree you are standing in:

```bash
bash branching/scripts/cleanup-mission-worktree.sh <unit-id>
git push origin --delete <claim-branch>
```

The cleaner refuses a dirty worktree and never discards uncommitted work; if it refuses, leave the claim alone and report it. The remote claim branch is deleted after the merge for hygiene only — the merge already released the claim by definition (its commits are on the base), so a failure to delete the branch is a note, not a blocker.

### 7. Account, reconcile, and the terminal token

**Agent-hours.** For each **mission** unit, record the run's wall-clock once (decision I7 — the seam absorbed from the retired parallel-mission executor). Mint one **run-id** per invocation (a branch-safe timestamp, e.g. `20260729-034500`) and reuse it, so a mission driven across several passes of one invocation records its time exactly once:

```bash
bash mission/scripts/record-run-hours.sh "<slug>" "<hours>" "<run-id>"
```

The recorder is idempotent per run-id and is the **only** writer of `actual_hours` — never hand-edit the field. Report predicted vs actual per mission unit so the estimate can be judged against reality over time.

**A unit may also end in `handoff`.** Beside shipped / at-a-PR / demoted / blocked, this is the state for a unit that was genuinely half-driven — the run left its window, or met something it decided not to decide. It used to have nowhere to go: it was reported as prose in the run report, which is a log nobody re-reads, and the PR body had no section for it either (section 6 is Concerns, section 9 is Notes; neither is "here is where this stands and what to do next"). That matters most for a cloud runner, whose worktree dies with its sandbox — the pushed branch and its PR are the entire inheritance, so recording the handoff in stdout is recording it nowhere.

**The boundary test, so it cannot absorb the others.** A unit is `handoff` when **all three** hold: its queue is **not drained**, the work that exists is **pushed**, and continuing it **requires a person or another session**. Contrast:

| Not `handoff` | Because |
| ------------- | ------- |
| `blocked` | A **named external blocker** was hit and *nothing further is possible* — the attempted command and its raw output are recorded. A handoff unit could be continued; a blocked one could not. |
| A `review` unit at a PR | Its queue **is** drained. The work is *done* and awaiting a look, not awaiting continuation. |
| A unit the run simply did not want to attempt | Not a state at all. *Attempt every ticket* governs first: size, complexity and "this looks like it needs a human" are never skip reasons, and `handoff` must never become their soft landing. |

`handoff` is a property of the **unit**, computed from its tickets — **the four ticket outcomes stay four**. That arithmetic (every ticket ends as exactly one, and the totals reconcile to the unit's queue) is load-bearing here in §7, and "a person continues from here" is a statement about the unit, not a verdict on any one ticket.

A handoff unit **writes the Handoff section** (`report`, *Story Content Structure*), **opens or updates its PR** through the ordinary `create-or-update.sh` with the partial work pushed — an unpublished handoff is not a handoff — and posts the PR URL through the same notifier the `review` route uses. **Its tickets stay stamped and stay in `todo/`**, so merging that PR carries a `claim:` onto the base: that is expected and is history, not a claim (*Claims*, decision M1). Do **not** strip the stamp to keep the base clean — the stamp at the tip is what keeps the ticket claimed while the PR is open (M1a). The PR section is the **authoritative** record and the run report is the log; they overlap deliberately and neither is redundant. A later run resumes exactly this shape (*Claims → Resume a dropped unit*), so a handoff and a resumption are one story told at two moments, not two mechanisms.

**The run report is the deliverable** — always emitted, terminal or not, because a run nobody can read is a run nobody can trust (`implementation` / `observability`). Before the reconciliation line, state:

- **Per unit**: its members, its effective policy and the route it took (shipped / at a PR / **demoted to PR, with the gate that caused it** / **handoff** / blocked), its ticket outcomes (implemented / failed / blocked) **reconciling to the queue it was handed**, and the commits.
- **PR per unit** — the URL, or the `pr_error` if creation failed (its own item, affecting nothing else).
- **Tickets minted mid-run** (`deferred`), one line each: what was found, which ticket provoked it, and the new filename. These are *additional* to the unit's queue and do not affect its reconciliation — but a run that quietly mints tickets is a run that quietly changes the plan, so they are never silent.
- **Deferred decisions** — every judgment call the run met and recorded instead of asking, one line each. This list is the QA seam `development` / `qa-engineering` requires: the developer's looking-through relocates to this report and to each unit's PR, never to a mid-run prompt.
- **Units another runner holds**, and units the survey excluded with their reasons.
- **Stashed partial work** and where to find it.
- **Predicted vs actual hours** per mission unit.

**Then the reconciliation line, then the token — in that order, as the last two lines of the run.**

```
N units: X shipped, Y PR'd, Z blocked
ok
```

The token is **derived, never self-asserted**:

| State at the end of the run | Final line |
| --------------------------- | ---------- |
| Every unit this run claimed reached its routed end (`auto` merged, `review` at an open PR) **and** a fresh survey offers nothing claimable | `ok` |
| Any claimed unit is `blocked` (hard-stopped gate, failed confirmation, unrecovered failure) | `pending` |
| Any claimed unit ended in **`handoff`** — a person or another session must continue it | `pending` |
| Any claimed unit was **demoted** and is waiting at a PR it was meant to ship | `pending` |
| Any unit was left with tickets undriven (failed/blocked tickets remain in its queue) | `pending` |
| The survey still offers a claimable mission or ticket (including a unit another runner holds) | `pending` |
| The survey offers a **resumable** unit with `resume_reason: heartbeat_lapsed` that this run did not take over | `pending` |
| The survey offers a **resumable** unit with `resume_reason: parked_with_pr` that this run did not take over | *not by itself* `pending` — it reached its PR and is waiting on a human; report it and the reason for deferring it |
| The survey ran against a checkout **not** known current with the base (`current: false`, or `sync-main.sh` reported `no_origin`/`origin_unreachable`) | `pending` |
| The survey could not read the backlog at all (`backlog_error` non-empty — e.g. `identity_unresolved`) | `pending` |
| The claim scan ran over **truncated history** (`shallow: true` — a shallow clone whose origin was unreachable, so merged branches cannot be told from live ones) | `pending` |
| Nothing was claimable at all and nothing is in flight, over a **current** survey that read the backlog | `ok` |

"I stopped" is not "it's done": a blocked unit is `pending`, not `ok`. This is verbatim the contract a caller-side loop such as `/goal /drive ok` waits on (decision I4 — `/goal` is a harness feature, not a command of this plugin; the token is the whole contract). A confident `ok` over an incomplete run is the masked failure `implementation` / `observability` forbids, which is why the reconciliation line always precedes it: the outcome must be graspable from outside without a debugger.

## The failure contract

Everything below is what an unattended unit may and may not do when a ticket goes wrong. It is the contract the overnight run always had; it now applies to every run, because every run is this shape.

**Attempt every ticket.** Size, complexity, "all-or-nothing" scope, and "this looks like it needs a human" are **not** skip reasons. Neither is a run being long, heavy, or wanting exclusive use of a local service — that is *preferred* unattended work (below). A skip is legitimate only after a real attempt, and only as one of the outcomes below.

**A closed set of four outcomes.** Every ticket handed to a unit ends as exactly one, and the totals reconcile to the unit's queue. There is no "declined" category:

- **implemented** — verified against its `## Quality Gate`, archived, commit hash recorded.
- **failed** — implemented, but its checks went red (or its frontmatter update failed). `git stash` the partial work so it cannot contaminate the next commit, leave the ticket in `todo`, record the reason and the stash.
- **blocked** — a **named** hard external blocker, with **the command that was attempted and its raw output** recorded.
- **`deferred`** — an unqueued problem was met and became a ticket (below); the run continued.

**"Blocked" is a finding, not a forecast.** Before recording it, run the thing: start the service, invoke the command, call the tool, and record what came back. An abstract verdict reached without executing anything — "this needs a human", "the credentials probably aren't here" — is **not** a blocker; it is an unattempted ticket, and the report must say so. The morning review can act on `deploy.sh → exit 127: gh: command not found`; it can do nothing with "deployment seemed human-only."

Exactly two buckets may be deferred **without** an attempt:

- **Safety floor** — genuinely irreversible outward actions an unattended run must never take: production sends to third parties, force-push, destructive data operations.
- **A genuinely external blocker** — work waiting on something no local attempt can produce: a credential or approval a **third party** must issue, or a decision requiring a named human's professional judgement. State **concretely** what is missing and who must provide it.

**"Missing credentials" is a checked claim, not an observation.** An env loader fails *silently* on a missing file (`node --env-file-if-exists` sets nothing, no warning, no non-zero exit), so "the variables are unset" is equally consistent with "no credentials exist" and "this worktree never carried the file that holds them" — a provisioning gap that reads as a durable, plausible, wrong finding. The worktree creator reports `env_files_carried` (`branching` / `create-mission-worktree.sh`; a project declares its layout in a repo-root `.worktree-env`), and an empty carry is the tell. Confirm the files are present *and still hold no usable credential*, and name the file you checked.

**Heavy, exclusive, long-running work is what an unattended window is for.** A verification that takes thirty minutes, needs exclusive use of a shared local service, or loads the machine hard is **preferred** unattended work, not work to avoid. "It would take a long time", "it wants the port to itself", "better in a daytime window" are reasons to do it **now**. Resource contention bounds **how many units run at once** — it is the run's dial, never a unit's licence to skip its own work.

**If you background a job, you own reporting its outcome — either way.** "I'll report when it's done" must fire on **failure** exactly as on success, and a run may not go idle while a terminal result sits unreported: a caller that hears nothing cannot tell a job still working from one that died in the first seconds. Before reporting yourself finished, read every background job's declared output artifact and exit state. Give a detached job an **explicit, self-contained environment** (a background process does not inherit an interactive shell's PATH, so a command that works when typed can exit instantly when detached, unable to find a CLI) — and treat that early exit as a real `failed` with the captured error.

**Safety floor on any failure** — never negotiable:

- Stash the failed ticket's partial work before continuing, and note the stash in the report.
- Leave the ticket in `todo`. A red check means **failed → recorded**, never force-committed.
- **NEVER** auto-move a ticket to icebox, auto-abandon it, or run destructive git (`git restore .` / `git clean` / `git reset --hard` / `git stash drop`). Those need a human.

### Take the initiative: an unqueued problem becomes a ticket

When the run meets a problem the queue does not cover — a defect found while implementing, a missing prerequisite, an assumption that proves false — write a **ticket** for it and continue (`deferred`).

**An observation is not an obligation. Only a ticket is.** A run that notices a problem and writes prose about it has, in practice, discarded it: this repo shipped a known defect that was recorded verbatim in a story because *"no ticket, no concern — so the corpus never carried it"*, and it resurfaced two days later.

The boundary decides everything, so hold it exactly:

- **Inside the current ticket's scope** → **implement it.** Not new, and not a defer. This must never become a way to avoid work.
- **Outside it** → **write a ticket, continue.** Do **not** fix it opportunistically: an unqueued fix rides into a commit whose message describes something else, and that is the "unverified inferences pile up in the code" that `development` / `overnight-ai` names as the limit on a blank cheque.
- **Blocks the current ticket** → write the ticket, then record the current one **`blocked`**, naming the minted ticket as what would unblock it.

**Mint only for an observed problem — never a passing thought.** A ticket per speculative improvement turns the queue into a diary and buries the real ones, which is worse than a report paragraph because it looks like a plan. The threshold: the run **actually hit** it. A refactor idea, a "we might also want", a thing you noticed but did not run into — **not a ticket**.

The minted ticket goes through the sanctioned path: the `create-ticket` structure, written to `todo/<user>/`, with its mandatory `## Policies` and `## Quality Gate` (`validate-ticket.sh` rejects it otherwise), and it inherits the provoking ticket's `mission:` relation (read via `mission/scripts/read-relation.sh`, never re-parsed). **Report every minted ticket** as its own line: what was found, which ticket provoked it, and the new filename — a run that quietly mints tickets is a run that quietly changes the plan.

**Do not append an acceptance item to the mission for a minted ticket.** `## Acceptance` is the plan the developer agreed to, and its `checked ÷ total` is the mission's progress; auto-appending would move the goalposts so that every minted ticket lowers completion against criteria nobody accepted — a mission could recede as it works. Promoting a minted ticket into the definition of done is the developer's call. (Consequence, accepted knowingly: a mission's ticket set can drift from its `## Acceptance`. That is the honest state — the queue reflects reality, the acceptance list reflects the agreement.)

### Where the per-ticket approval prompt went

This is where `/drive` used to stop and ask "Approve this implementation?" after every ticket. **The prompt is retired, and approval is relocated, not removed** (`docs/loop-engineering-workflow.md` G2/G5, phase 3):

- **A mission unit** was authorized when a human **merged the mission's pull request** (K1): a mission reaches `main` no other way, and the merge is the project accepting *these tickets*, against gates the developer co-authored. The write-time floor (`hooks/validate-mission.sh`: a real `## Experience`, at least one `## Acceptance` item) holds on every active mission, so what merged was never a blank plan.
- **A batch unit** was authorized when each ticket was created: `/ticket` records the ticket's own `merge_policy`, and writing a ticket is the instruction to implement it.

**What is removed is the completeness check inside the drive loop — nothing else.** "Did it do the thing?" was already answered, about this exact work, against a stated gate. The qualitative **looking-through** that `development` / `qa-engineering` makes non-delegable is **not** eliminated: it relocates to the PR, which is what `development` / `review` prescribes — the story is still written, and a `review` unit still stops there for a human. Eliminate the completeness check and you are on policy; eliminate the looking-through and you are in the state three policies exist to prevent.

**And the run does not relay decisions upward either.** A unit that turns an evidence-resolvable choice — which fixable failure to retry, whether to finalize now or push one step further, how to recover a stale environment — into a developer question has not honored the no-prompt contract; it has moved the offloading one level up. Decide it from the evidence and the stated intent, record the decision in one line, and proceed. A genuine developer-only ruling that surfaces mid-run (authorization for an irreversible outward action, a security-boundary value, an unfabricatable secret, a true evidence-free fork) is **deferred and recorded** in the final report — once — never asked. If you cannot name which of those you are missing, you are not blocked on the developer; you are declining to decide (`rules/interaction.md`).

**This governs execution-time choices only — never planning-time requirements.** Drawing out the developer's requirements *before* a plan is committed — what a user must be able to do, what a good output looks like, the real workflow — is **mandatory** and is the opposite of offloading: the developer holds the *what*, and the agent cannot derive it (`mission`'s *Elicit the requirements first* gate). Decide the *how*; never assume the *what*. A plan built without the invited questions cannot be rescued by any amount of downstream verification, and an unattended run will faithfully amplify it into hours of unusable output.

## Claims

**The repository is the coordination medium.** Before driving a unit, a runner *claims* it on a pushed branch; every runner reads the claims in flight from the unmerged remote branches. There is no run-lock, no lock file, and no server — so nothing leaks when a runner dies mid-run, and a runner on another machine coordinates through exactly the same artifact a runner on this one does.

State the model before the scripts, because the scripts only implement it:

- **PR-unit.** The thing a runner takes. It is either one approved **mission** (unit id = the mission slug) or one **batch** of related backlog tickets (unit id = `batch-<YYYYMMDDHHMMSS>`, minted at claim time). One unit ↔ one branch ↔ one worktree ↔ one PR.
- **Claim.** A commit whose subject is `Claim <unit-id>`, on a fresh `work-*` branch cut from `origin/main` by the standard creator, whose content stamps `claim: <branch>` into the claimed artifacts' frontmatter — the mission's `mission.md`, or each batched ticket file — **pushed immediately**. **The stamp is written only on the branch, and a stamp that reaches the base is history, never a claim** (decision M1). No merge un-stamps anything: a merged branch has left the unmerged set, so the *scan* already reports its claim as released, and whatever frontmatter rode in with the merge is a record of which unit last held the artifact. This matters because a **handoff** or **blocked** unit merges its PR with tickets still in `todo/` (§7), so a base-side stamp on a live queue item is now an ordinary, expected state. **Never read it as a claim** — `list-claims.sh` is the only oracle. The artifact must actually be present in the claiming checkout: a mission with no `mission.md` is refused as `mission_missing`, since after J1 absence means either a wrong slug or a checkout behind the base — never the "it lives on an unmerged branch" case the claim writer used to tolerate.
- **Reader.** Fetch, enumerate the `origin/*` branches carrying commits not on `origin/main`, and for each read the unit from its newest `Claim …` subject and the claimed artifacts from the branch tip's `claim: <branch>` stamps — **reading each stamp at the file's current path, not the path the claim commit stamped.** `archive.sh` *renames* a driven ticket (`todo/<user>/X.md` → `archive/<branch>/X.md`) and carries the stamp along, so looking the old path up at the tip finds nothing: every batch unit silently lost its whole artifact list the moment its first ticket was archived, and the survey then offered tickets already in flight — the double-pick the protocol exists to prevent (observed live 2026-07-30). One tree-to-tree diff per claim gives the net old→new mapping, so chained renames need no walk — **and when that diff does not report a rename at all, the tip-side path is resolved a second way, exactly rather than statistically.** `git diff --find-renames` pairs a delete with an add only above 50% similarity and abandons inexact detection past `diff.renameLimit`, while `archive.sh` does not merely move a ticket (it stamps `effort` and appends the Final Report), so a short ticket carrying a long report is reported as a plain add + delete and the artifact vanishes exactly as before. The fallback is a lookup by **filename** under `.workaholic/tickets/`, which is unique in the tree by construction, applied only to ticket paths and only when it resolves to exactly one file — `mission.md` is shared by every mission, so an unscoped basename lookup could resolve one mission's claim onto another's file, and ambiguity therefore falls back to the mapped path rather than guessing. **What the reader reports is the base-side path** (the one the claim commit stamped), because that is the coordinate space both consumers compare in: `plan-units.sh` against the working tree's queue, `claim.sh` against paths it resolved in the main tree. A genuine stamp *removal* still drops the artifact, and a *deleted* artifact is not claimed — both deliberate, both pinned by tests.

  **One lost artifact list is two visible failures, which is why the resolution is worth this much care** (measured 2026-08-04). `plan-units.sh` subtracts a claim by its artifact paths, so it stopped subtracting at all — offering a ticket already driven on a pushed branch as fresh backlog, and with **no `excluded[]` row**, because the survey only reports items it *saw* and dropped. And `claims_has_work` fell through to its deliberate "no artifacts means unknown, so assume work remains" branch, flipping a drained unit to `resumable` and inviting a takeover of a branch whose PR was waiting on a human. Both read as separate defects and were one.
- **Release = merge or branch deletion.** A merged branch's commits are on the base, so its claim leaves the unmerged set *by definition* — the normal path needs no script at all. Deliberately **discarding** an unfinished unit is the other path, and that one is explicit. `release-claim.sh` is **not** how an interrupted unit is recovered — it deletes the remote branch, which is the opposite of recovery; resumption is below.
- **Resumable ≠ stale, and only one of them acts.** A claim whose branch tip is older than `WORKAHOLIC_CLAIM_STALE_HOURS` (default 24) is marked `stale: true`, and **nothing acts on that** — a runner that reclaims a *colleague's* work on its own verdict can silently duplicate it over a long lunch. Resumption is the narrower, safe case: **your own** claim, whose **heartbeat** has lapsed. Both conditions are computed in the shared scan and reported by `list-claims.sh` as `resumable` + `resume_reason`.
  - **Liveness is the branch tip**, refreshed by `heartbeat.sh` (an empty commit) and by every ordinary work commit. No lock file, no server, nothing to leak when a runner dies — the signal rides the branch a merge or a release already cleans up, and changes no file so it never reaches the PR diff. The window is `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES` (default 30): **minutes, not the 24-hour `stale`**, because an hourly routine that recovers its own dropped unit only after a day is not a recovery path.
  - **Something left to drive.** At least one of the unit's tickets must still be undriven *on that branch* — under `.workaholic/tickets/todo/` at the tip (for a mission unit: at least one ticket at the tip still names the mission). Without this the verdict cannot tell a run that **died** from a unit that **finished**: a `review` unit stops at its PR by design, its branch correctly stays unmerged, so its tip stops advancing and its heartbeat lapses exactly like an abandoned one. Measured hours after resumption shipped, the hourly runner re-took one such unit three times and only the first pass did any work — the other two added an empty `Resume` commit to a branch a human was reviewing. It does not terminate; a review PR can sit for days. Such a unit reports `queue_drained` and is excluded as `claimed_reported`.
  - **Complete history, or no verdict at all.** "Unmerged" is `git rev-list --count <base>..<ref>`, which cannot be reduced across a shallow graft — so in a **shallow clone** a fully merged branch still counts as ahead and the scan reports a unit that shipped days ago. Measured 2026-08-04 on the cloud runner, whose container always clones shallow: a branch merged as PR #109 counted **154** ahead while shallow and **0** after `--unshallow`, and was offered as `resumable` past *both* gates above — the identity matched because this runner had claimed it, and the heartbeat had lapsed precisely because the work finished. So the reader **repairs first**: `claims_fetch` deepens a shallow clone before anything reads ancestry (a plain `git fetch --prune` never does). When origin is unreachable and it cannot, it **degrades loudly**: `shallow: true` goes out to both consumers and the branch reports `resumable: false` with reason `shallow_history`, because an unanswerable question must not render as `heartbeat_lapsed`. The claim is still *listed* — over-reporting makes a runner wait, under-reporting double-picks work — so the **verdict** is suppressed, never the row.
  - **Same identity only.** The claim commit's author must be this runner's `git config user.email`. The principle (developer, 2026-08-01): *a pushed claim is the loop's work* — merging to `main` means the runner implemented it, and work you mean to keep in your own hands should never have been pushed as a claim. A colleague's claim is `foreign_identity` and untouchable at any age; an unresolvable identity resumes nothing. **Note the consequence**: a runner configured with a developer's email inherits that developer's claims. That is the intended reading of "the runner is `a@qmu.jp`" — but it means a *shared* identity across people would let one person's runner take another's work, so never configure one.
- **Worktree lifecycle.** A worktree is **claim-born and ship-torn**: `claim.sh` creates `.worktrees/<unit-id>/`, and it is removed when the unit ships (§6) or when its claim is released. `/mission close` no longer tears worktrees down — a lingering worktree is an in-flight or stale *claim*, which is the reader's business.

**The reader degrades offline; the writer does not.** With origin unreachable, `list-claims.sh` reports `fetched: false` and answers from the last-known remote-tracking refs, while `claim.sh` refuses to claim at all. The asymmetry is deliberate: a stale reader over-reports claims, which merely makes a runner wait, but a claim nobody else can see is not a claim, and driving on one is the double-pick the protocol exists to prevent.

### Read the claims in flight

```bash
bash drive/scripts/list-claims.sh
```

Pure read. Emits `{fetched, shallow, stale_hours, heartbeat_stale_minutes, base, claims: [{unit, branch, artifacts, last_commit_at, stale, author, resumable, resume_reason}]}`. The unified run's survey (`plan-units.sh`) reads the **same scan** through the shared library rather than re-parsing this output, so the surveyor can never offer a unit the writer would refuse — and the resumability verdict is computed there too, for the same reason: a writer free to decide it independently could take over a unit the reader still calls active. This script takes nothing over; it exists so the state is readable without running a survey.

### Claim a unit

```bash
bash drive/scripts/claim.sh mission <slug>
bash drive/scripts/claim.sh batch <ticket-file>...
```

Never prompts. Verifies the unit is unclaimed **through the reader's own scan** (`scripts/lib/claims.sh`, which `list-claims.sh` merely renders — a writer carrying its own scan would be free to disagree with the reader, which is the one state a coordination protocol must not have), then creates the worktree, stamps, commits, and pushes. Emits `{claimed, unit, branch, worktree_path, artifacts}`, or refuses with a `reason`: `already_claimed` (naming the holding branch and unit), `no_origin`, `origin_unreachable`, `branch_collision`, `push_failed`, `artifact_missing`, `no_frontmatter`.

The stamp rides the **worktree** checkout, never the main tree — the runner's main checkout stays clean between ticks, which the `/propose` batch depends on. A refused claim leaves nothing behind: the half-made worktree and its branch are removed, because an unpublished claim is not a claim.

### Resume a dropped unit

```bash
bash drive/scripts/claim.sh resume <unit-id>
```

Takes over a claim the survey reported in `resumable[]`. It **adopts this machine's existing `.worktrees/<unit-id>/`** when that worktree is on the claim's branch at the very tip the resumability decision observed, and only **creates** one otherwise — **at the pushed branch tip**, not from the base — so the resumed run sees the earlier run's commits and does not re-drive the tickets that branch already archived. It then publishes the takeover as an empty `Resume a PR-unit` commit and pushes it. From there the unit re-enters the Unified Run at step 4: its remaining tickets are whatever is still in `todo/` **on that branch**, and step 5's `create-or-update.sh` updates the existing PR rather than opening a second one.

**Adoption exists because same-machine resume is the common case, and it used to be the broken one.** Resumption's whole safe case is "your own claim" — which is exactly when `.worktrees/<unit-id>/` is still on disk, so the creator refused with `worktree already exists` and every such resume returned `worktree_creation_failed`. The observed cost was a run hand-rolling the takeover — the empty commit, the push, the notifier — by replicating this script's internals, which is the failure the sanctioned scripts exist to prevent. Adoption is gated on the same pinned tip the race check uses, so a worktree sitting on any other commit is *not* the thing that was judged resumable and still falls through to the creator. An abort **never tears down an adopted worktree**: destroying local state this run did not create, to report a race it merely lost, would be worse than the race.

Emits `{claimed, resumed, unit, branch, worktree_path, adopted_worktree, resume_reason, announced, announce_reason, artifacts}`, or refuses with `not_claimed`, `claim_active` (naming the tip time — a run is still on it), `queue_drained` (it finished; its PR is waiting on a human, not a runner), `foreign_identity`, `identity_unresolved`, or `resume_race_lost`. `resume_reason` carries the offer's tier (`heartbeat_lapsed` or `parked_with_pr`) into the takeover, so what was reopened — and why — is answerable from the resume's own output.

**The race is settled by git, never by a clock.** Two runners can both see a unit as resumable in the same instant, both build a worktree at tip *T*, and both push a takeover. The first push wins; the second is rejected non-fast-forward, tears its worktree down, and reports `resume_race_lost` having taken nothing — the same way `branch_collision` settles two fresh claims. Nothing compares timestamps to pick a winner, which is what keeps this correct across a local runner and a cloud one with skewed clocks.

### Release a claim deliberately

```bash
bash drive/scripts/release-claim.sh <unit-id>
```

For a unit that will **not** be finished. Tears the worktree down first (the cleaner refuses a dirty worktree and never discards uncommitted work), then deletes the remote claim branch — that order matters: dropping the claim first would publish "this unit is free" while the worktree still holds unpushed work. Emits `{released, unit, branch, worktree_removed, remote_branch_deleted, local_branch_deleted}`. Run it from the main checkout; git cannot remove the worktree you are standing in.

## Ordering within a unit

Once a unit is claimed, its tickets are driven in a considered order. This is derivation, not a decision to confirm — the order is **reported, never asked**.

List the unit's queue from inside its worktree:

```bash
bash drive/scripts/list-todo.sh
```

For each ticket read the frontmatter — `type` (bugfix > enhancement > refactoring > housekeeping), `layer`, `depends_on` — and order by, in precedence:

1. **Dependency ordering** — build the graph from `depends_on` and topologically sort it. On a cycle, warn in the report and fall back to type priority for the cycled tickets.
2. **Severity** — within a dependency tier, bugfixes precede enhancements.
3. **Context grouping** — tickets touching the same layer/files run together.
4. **Implicit dependencies** — if A modifies files B reads, A first.

Handle missing metadata gracefully: absent fields mean normal priority, and an empty `depends_on` means no dependencies.

On Claude Code this ordering may be delegated to a parallel workers (preloading `drive`, returning `{tickets[], tiers{}, cycle_warning}`); inline is equally correct and is the default elsewhere. That subagent issues no the agent's selection prompt — nothing in this run does.

**Sweep strays first**, so root-level tickets are routed even when `/drive` runs before any `/ticket`:

```bash
bash create-ticket/scripts/sweep-todo.sh
```

The sweep routes each root-level `todo/*.md` into `todo/<author-slug>/` by the stray's own `author:` frontmatter, git-staging each move (these staged moves ride into the next archive commit, which runs `git add -A`). It never moves a ticket to the icebox.

### The icebox is developer-curated

```bash
bash drive/scripts/list-icebox.sh
bash drive/scripts/promote-icebox.sh <icebox-path>
```

The unified run **never** reads the icebox for work, never promotes from it, and never moves anything into it. A ticket is in the icebox because a developer put it there; promotion is their act, and these scripts serve it on request. Automating either direction would let a run quietly change what the project has decided to defer.

## Workflow

Step-by-step workflow for implementing a single ticket. Implementation only: archiving and the unit's routing are handled by the Unified Run around it.

### Steps

#### 1. Read and Understand the Ticket

- Read the ticket file to understand requirements
- Identify key files mentioned in the ticket
- Understand the implementation steps outlined
- **Read the ticket's `## Policies` section.** It is the recorded list of standard engineering policies (synced from qmu.co.jp) this ticket answers to. Note every `workaholic:<pillar>` / `policies/<slug>.md` entry — Step 3 opens each one before writing code.
- **Read the ticket's `## Quality Gate` section** (if present). It is the developer-agreed acceptance criteria, verification method, and the gate that must pass before the ticket is archived — captured at `/ticket` time. Implement *to* this gate, and run its verification before archiving. Carry its acceptance criteria into the Step 4 return, and into the archive `<verify>` arg so the commit `Verify:` key records what cleared the gate.
- **If the ticket carries a `mission:` relation, also read the quality gate of EVERY mission it names** — `bash mission/scripts/gate.sh <mission-slug>`, once per slug (the relation is a list; a bare scalar is one). A mission gate is **optional and normally absent** — a mission's substance is its `## Experience` section (the demanded behavior) plus its ticket plan, not a check fixed at kickoff before the work existed. When a mission *does* declare `type: documentation` or `live-app`, the change must move it toward passing: run the project's dev/docs server on the worktree's `dev_port` (from the gate reader) and drive `target` with the Playwright plugin to check `assert`. When it declares `type: check`, run `target` as a command in the worktree — it must exit 0. When it declares none — the common case — **read the mission's `## Experience` and judge the change against the behavior it demands** instead; there is no mission-level check to run, and that is not a defect.

  **All of them must pass, not the most convenient one.** A ticket naming two missions claims to advance both, so it answers to both bars — naming a mission is a commitment, not a label. If the change cannot meet one mission's gate, the fix is to drop that mission from the ticket's relation, not to skip its gate.

  Note this is about **gates**, not placement: the relation is many-valued, execution stays single-homed. A ticket is still driven in exactly one worktree, and a claim's worktree is keyed 1:1 to its unit. "Which missions does this advance" and "where does this work happen" are separate questions.

#### 2. Apply Patches (if present)

If the ticket has a "## Patches" section:

1. For each patch in the section:
   - Write patch content to a temporary file
   - Validate with `git apply --check <patch-file>`
   - If valid, apply with `git apply <patch-file>`
   - Clean up temporary file
2. Report which patches applied successfully
3. For failed patches, note them and proceed with manual implementation

If no Patches section exists, skip to step 3.

#### 3. Implement the Ticket

- **Load the policy lens first (when the standards plugin is installed).** `/drive` preloads `design`, `implementation`, and `operation`, so the three index `SKILL.md` files are in context. Before writing code, open every policy hard copy the ticket's **`## Policies`** section lists — that recorded list (synced from qmu.co.jp) is authoritative for which policies this implementation answers to. Read each `policies/<slug>.md` it names. If a ticket predates the `## Policies` section (it is absent or empty), fall back to deriving the set from the ticket's `layer` field via the Policy Lens mapping: UX → `design` plus `implementation`, Domain/DB → `implementation`, Infrastructure → `implementation` plus `operation`, Config → the skill whose policies the config touches. Either way, judge the change's **design** (interaction and behavior), **implementation** (code structure and correctness), and **operation** (delivery, runtime, and recovery) against each applicable policy's Goal (目標), Responsibility (責務), and Practices (実践). If the standards plugin is not installed, proceed without it.
- Follow the implementation steps in the ticket
- Use existing patterns and conventions in the codebase
- For areas where patches applied, verify and adjust as needed
- Run type checks (per CLAUDE.md) to verify changes
- Fix any type errors or test failures before proceeding

#### 4. Return Summary (DO NOT COMMIT)

After implementation is complete, return a summary:

```json
{
  "status": "implemented",
  "ticket_path": "<path to ticket>",
  "title": "<Title from H1>",
  "overview": "<Summary from Overview section>",
  "changes": ["<Change 1>", "<Change 2>", "..."],
  "quality_gate": "<acceptance criteria + what passed, from the ticket's ## Quality Gate, with the verification you ran against it — omit if the ticket has no Quality Gate>",
  "repo_url": "<repository URL>"
}
```

Then update effort, append the Final Report, and archive (below).

### Critical Rules

- **NEVER commit outside the sanctioned scripts** — `archive.sh` and `commit.sh` own the commit seam.
- **NEVER use the agent's selection prompt** — the unified run has no interaction point at all.
- **NEVER archive tickets manually** — `archive.sh` is the only authorized method.
- **NEVER autonomously move tickets to icebox.** Moving tickets is a developer decision.
- After implementation, proceed to Final Report and Archive.

### Prohibited Operations

**Context**: This repository may have multiple contributors (developers, other agents) working concurrently. Uncommitted changes in the working directory may not belong to you.

The following destructive git commands are **NEVER** allowed during implementation:

| Command | Risk | Alternative |
|---------|------|-------------|
| `git clean` | Deletes untracked files that may belong to other contributors | Do not use |
| `git checkout .` | Discards all uncommitted changes including others' work | Use targeted checkout for specific files |
| `git restore .` | Discards all uncommitted changes including others' work | Do not use |
| `git reset --hard` | Discards all uncommitted changes and resets HEAD | Do not use |
| `git stash drop` | Permanently deletes stashed changes | Only with explicit user request |

**Rationale**: You are not the only one working in this repository. Destructive operations affect everyone's uncommitted work, not just your own implementation. Always check `git status` before any operation that discards changes, and be considerate of work that may not be yours.

If an implementation requires discarding changes, use targeted commands that affect only specific files you modified.

### System Safety

Before implementation, check whether the repository authorizes system-wide configuration changes. Run the detection script and respect the result:

```bash
bash system-safety/scripts/detect.sh
```

- If `system_changes_authorized` is `false`: the prohibited operations list in the system-safety skill applies unconditionally. Do not install global packages, edit shell profiles, modify `/etc/` files, manage system services, or use `sudo`.
- If `system_changes_authorized` is `true`: system-wide changes are permitted because the repository is a provisioning repository.

When an implementation step requires a prohibited operation, use a safe project-local alternative (see the system-safety skill's Safe Alternatives table). If no alternative exists, record the ticket `blocked` with the named operation.

## Final Report

After a ticket's implementation passes its gate, update the ticket with effort and final report.

### Update Effort Field

Estimate the actual time this implementation took, then round to the nearest valid value.

**The ONLY valid values are:** `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

Do NOT use t-shirt sizes (S/M/L/XS/XL), minutes (10m/30m), or any other format. The `update.sh` script will reject invalid values.

**Valid values (hour-based only):**

| Value | Use For |
|-------|---------|
| `0.1h` | Trivial changes (typo fix, config tweak) |
| `0.25h` | Simple changes (add field, update text) |
| `0.5h` | Small feature or fix (new function, bug fix) |
| `1h` | Medium feature (new component, refactor) |
| `2h` | Large feature (new workflow, significant refactor) |
| `4h` | Very large feature (new system, major rewrite) |

ALWAYS use one of these exact values: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

#### How to Update

**MUST use update.sh** -- NEVER use the Edit tool to modify the effort field directly.

```bash
bash drive/scripts/update.sh <ticket-path> effort <value>
```

Example:
```bash
bash drive/scripts/update.sh .workaholic/tickets/todo/20260212-example.md effort 0.5h
```

### Final Report Section

Append `## Final Report` section to the ticket file.

**If no insights discovered:**

```markdown
## Final Report

Development completed as planned.
```

**If meaningful insights were discovered:**

```markdown
## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: <what was discovered>
  **Context**: <why this matters for understanding the codebase>
```

### What Makes a Good Insight

Include insights that fall into these categories:

- **Architectural patterns**: Hidden design decisions or conventions not documented elsewhere
- **Code relationships**: Non-obvious dependencies or coupling between components
- **Historical context**: Why something exists in its current form
- **Edge cases**: Gotchas or surprising behaviors future developers should know

### Insight Guidelines

- Keep insights actionable and specific, not vague observations
- Insights should benefit someone reading the ticket months later
- Don't duplicate information already in Overview or Implementation Steps
- If no meaningful insights, omit the subsection entirely

## Archive

Complete commit workflow after a ticket clears its gate. Always use this script - never manually move tickets.

> **CRITICAL: NEVER manually archive tickets.** Do not use `mv` + `git add` + `git commit` to move
> tickets from `todo/` to `archive/`. The `archive.sh` script is the ONLY authorized method.
> Manual moves cause unstaged deletions because agents forget to stage the old path.

### Prerequisites

**CRITICAL**: Before calling the archive script, verify that all required frontmatter fields have been successfully updated:

1. **Verify effort field**: The ticket MUST have a valid `effort:` value (e.g., `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`)
2. **Abort on failure**: If the frontmatter update failed, **DO NOT proceed with archiving** — record the ticket `failed` with the error instead.

**Never archive a ticket without all required frontmatter fields.**

### Usage

```bash
bash drive/scripts/archive.sh \
  <ticket-path> "<title>" <repo-url> "<why>" "<changes>" "<concerns>" "<insights>" "<verify>"
```

Where `<ticket-path>` is the current ticket file path in `todo/`, `<title>` is the commit title, and
`<repo-url>` comes from the gather skill's `git-context.sh` output. Map the ticket and your Final
Report into the body args: `<why>` from the ticket Overview/motivation, `<changes>` from what changed
for users, `<concerns>` from the ticket Considerations (or "None"), `<insights>` from your Discovered
Insights (or "None"), `<verify>` from the verification you ran. These keys feed `/report`
(Motivation / Changes / Concerns / Successful Development Patterns).

Follow the **commit** skill's Message Format section for message format.

### Archive Example

```
Add structured commit message format

Why: Commit messages had two report-dead sections (Test Planning, Release Preparation) that /report never read, while the sections it works hardest to produce -- Concerns and Successful Development Patterns -- got nothing from git log. Re-aimed the body at the report's narrative so the log feeds Motivation/Changes/Concerns/Patterns directly.

Changes: None -- this is an internal change to the commit message format. CLI behavior, command interfaces, and user-facing output remain identical.

Concerns: collect-commits.sh previously dropped the commit body entirely; if that drop is ever reintroduced, the new keys stop reaching /report. Keep the collect-commits body-emission assertion green.

Insights: Aligning the commit body keys one-to-one with the report's section taxonomy means a reviewer reading git log sees the same structure the PR story will have -- the log becomes a draft of the report.

Verify: Ran commit.sh with sample inputs and confirmed the labeled sections, the omit-when-empty behavior for Why/Concerns/Insights, and that archive.sh forwards the body args. Confirmed collect-commits.sh now emits the body as valid JSON via the smoke tests.

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Update Frontmatter

Update ticket YAML frontmatter fields after implementation.

### Usage

```bash
bash drive/scripts/update.sh <ticket-path> <field> <value>
```

### Fields

#### effort

Time spent in numeric hours.

Valid values: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

Invalid: `XS`, `S`, `M`, `10m` (t-shirt sizes and minutes are not allowed)

Update when: After implementation, before archiving.

#### commit_hash

**Not written — derived from git.** `archive.sh` deliberately does not stamp this field: a commit cannot carry its own hash, so writing it and amending the ticket into that same commit changes the hash, leaving a value that points at an orphaned, never-pushed commit (and no stamping order fixes it — re-stamping after the amend regresses forever). `/report` derives the hash from the commit that *added* the archived ticket (its `ticket-commits.sh` script). Do not re-introduce a stamp here, and do not read this field: tickets archived before the fix still carry dead values.

#### merge_policy

**Recorded at ticket creation, read at route time — never written here.** `auto` lets the unit this ticket lands in merge without a human; anything else, including absence, routes to a PR (§6). `/drive` reads it through `effective-policy.sh` and never edits it: changing a ticket's merge policy mid-run would let the run grant itself permission to merge.

#### category

Change category based on commit message verb.

Values:
- **Added**: Add, Create, Implement, Introduce
- **Changed**: Update, Fix, Refactor (default)
- **Removed**: Remove, Delete

Update when: After creating the commit, set automatically by archive script.

### Field Insertion Order

When a field doesn't exist, it's inserted in this order:
1. After `layer:` -> `effort:`
2. After `effort:` -> `commit_hash:`
3. After `commit_hash:` -> `category:`
