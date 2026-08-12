---
name: drive
description: Use when the user runs `/drive` or `/implement`, asks to "implement the queued tickets", "work through the todo list", or "drive the backlog". Surveys the claimable missions and the unclaimed backlog, partitions them into PR-units, claims each unit on a pushed branch, implements it in the claim's own worktree, reports, and routes it by the unit's effective merge policy — identically in an interactive session and on the routine.
skills:
  - commit
  - system-safety
  - workaholic:notify
  - workaholic:design
  - workaholic:implementation
  - workaholic:operation
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Drive

The project's execution knowledge: one run with **two entry points that share every step below §2** (decision P1). **`/drive [<unit>]`** is **attended** — it asks which units to take (§2) and nothing else at any step. **`/implement [<unit>]`** is **unattended** — no `AskUserQuestion` anywhere; it is what the `[Implement]` routine and every `/goal /implement ok` loop invoke. Attendance is a property of which command was invoked — never of a TTY, an environment variable, or a guess. The optional argument names one unit: a **scope**, not a mode. On an agent with no question mechanism, run `/implement`'s shape; drive claimed units sequentially by default (per-unit parallel subagents are a Claude Code option, not the contract — throughput comes from the claim protocol).

Relocated detail: [survey contracts](reference/survey.md) · [claim protocol](reference/claims.md) · [partition/routing/report](reference/routing.md) · [per-ticket workflow & archive](reference/ticket-workflow.md) · [failure contract](reference/failure-contract.md)

## The Unified Run

A unit of execution is **what deserves one merge**. The run turns the artifact stream into merge-sized units, takes each visibly, finishes it, and routes it by a policy the artifacts already carry: `survey → partition → claim → drive → report → route → account`.

### 1. Survey

**Resolve the plugin source before anything else**: `bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/plugin-src.sh` — reachable on the checkout path (`plugins/workaholic/skills/...`) too, which is what a session with no usable binding uses. It returns `src`, the **newest plugin tree present on this machine** (checkout, registry installPath, clone, bound — newest version wins, and an **equal version goes to the immutable, version-addressed candidate**), and from here **every script path in this run is `<src>/skills/...`**, never `${CLAUDE_PLUGIN_ROOT}`. Its `ok: false` (`no_plugin_source`) is the only terminal stop this step still has: the run cannot read its own workflow. Record `source`, `version`, `src_immutable` and `degraded` in the run report. **This resolution is what the whole run executes, and the freshen below moves the working tree** — so a `src` reported `src_immutable: false` must be **re-resolved after `sync-main.sh`** before any later step reads it (the tie-break makes that the exception; the contract and its measured origin are `workaholic:check-deps`, *Resolving the source to run from*).

Then confirm the install: `bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh` (read as `<src>/…`, like every script path below it). `ok: false` → print the `message` and stop. **`loaded_version_behind_registry: true` is a warning, not a stop** (2026-08-12, the developer's ruling, reversing the hard stop ticket `20260810090005` had kept): the double-pick the field exists to catch (2026-08-04) is a property of *the scripts actually run being stale*, and `plugin-src.sh` has already answered exactly that by selecting the newest tree — a run executing a `src` at the registry's own version is not running stale code, whatever the harness happened to bind. Treat `registry_unreadable: true` and the **absence** of the field the same way. Measured origin (2026-08-12): the cloud container binds a *project-scope* install baked into its image while the SessionStart bootstrap updates the *user* scope, so `claude plugin update` reports "for scope user" and the bound pin never moves; every tick is a fresh container off that same image, so the old gate reproduced hourly and never self-healed — twelve consecutive `[Implement]` ticks stopped before surveying with three claimable tickets queued. **`unbound_in_claude_session: true` is a warning, not a stop** (2026-08-10) — `/drive`'s instance of the general unbound-skill-surface fallback rule (`plugins/workaholic/rules/general.md`): a genuine Claude Code session where the harness's own registry confirms this plugin is installed, yet nothing was ever bound: every skill, command and hook this plugin ships is invisible to the Skill/Command tool abstraction for the whole run (`workaholic:check-deps`; no fix exists inside the plugin — Claude Code exposes no supported way to hot-load a plugin mid-session other than a human-typed `/reload-plugins`, which an unattended routine never types). Record it in the run report and continue: the plugin's own scripts under `plugins/workaholic/skills/` stay directly runnable via `bash` from the checkout path regardless of whether that abstraction resolved, and the PreToolUse safety hooks stay registered and active independent of it — the same fact the developer's live correction (FB `20260810070110`) already established for one run. Nothing extra is needed to keep going: `src` above is already the run's script path, and it resolves without any binding at all. `version_drift` or `missing_guards` → warn, continue, record in the run report. **What a degraded run does not repair, and must not claim to**: hooks and the Skill/Command bindings stay whatever the harness bound (older guards when the binding is stale — `guards_present` says whether they are registered at all — and no UserPromptSubmit policy lens when nothing is bound, so load the policy index from `<src>/hooks/policy-index.md` explicitly).

Then **freshen the checkout before reading it** (J3): `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/sync-main.sh`. The step runs identically through both entry points: one code path, and each `ok: false` is a reported decision, never a prompt — `no_origin`/`origin_unreachable` survey locally, say so, and forbid `ok`; `not_on_main`/`dirty_workspace`/`diverged` terminate `pending` (never merge or reset; see [reference/survey.md](reference/survey.md)). One shape that *looks* like `not_on_main` is not one: a checkout parked off the base but standing on its **exact tip** with a **clean tree** returns `ok: true` with `off_base: true` (§1a — the cloud harness hands the session its own branch and checks that out; measured twice on 2026-08-12, each tick contractually finished before it could survey with work queued). Report it and drive on; every failure of that proof still refuses.

Then survey what is claimable: `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/plan-units.sh` — the unclaimed active missions and todo tickets this runner owns or that are unowned (`owned_by_other` drops a colleague's; ownership resolves through the one oracle, `gather/scripts/owns.sh`), minus everything a claim already holds. `excluded[]` names every drop and its reason; nothing leaves the offer silently. Full field and reason vocabulary: [reference/survey.md](reference/survey.md).

- **The survey states its freshness and does not repair it** — the repair is the caller's `sync-main.sh` above. Four conditions **forbid `ok`** (§7): `current: false`, `shallow: true`, non-empty `backlog_error`, and `owner_unresolved`. An unreadable queue never renders as an empty one.
- **`resumable[]` is a third offer with two tiers**: `heartbeat_lapsed` (a run died mid-drive — take it over before claiming fresh; left untaken it forbids `ok`) and `parked_with_pr` (at its PR, waiting on a human — reportable rather than mandatory, does not forbid `ok`). Both are takeovers via `claim.sh resume`, entering at §4.
- Both lists empty with empty `backlog_error` → nothing claimable: report plainly, print the reconciliation and token (§7), stop. With a non-empty `backlog_error` the same emptiness means the opposite: terminate `pending`.

### 2. Partition into PR-units

A PR-unit is one merge: one unit ↔ one claim ↔ one branch ↔ one worktree ↔ one PR. Each claimable mission is exactly one unit (id = the slug); related backlog tickets group into one batch unit — conservatively, on a reason statable in one sentence; `depends_on` alone is grounds ([reference/routing.md](reference/routing.md)). Never mix merge policies to force a route. **Report the partition in full, always** — the composition is never asked through either entry point.

**The choice among units is the operator's, when one is present.** When a developer typed `/drive` and the partition offers **more than one** claimable or resumable target, ask once: one `AskUserQuestion` with `multiSelect: true`, at most once per run — one option per unit (id, kind, one-line summary), the body opening with the project label (`bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`), units in the order the run would have driven them, the total named if the list is narrowed. Drive the selected units in the order selected; report every unselected unit as `deferred_by_operator` (§7) — still claimable, so it **forbids `ok`**. Selecting nothing is legitimate: the run ends `pending`. **Ask nothing when there is nothing to choose** — a single target, an argument that names a unit, or `/implement` (`rules/interaction.md`).

### 3. Claim

Claim with `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/claim.sh mission <slug>` or `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/claim.sh batch <ticket-file>...`. Claim before driving, **one unit at a time** — claim, drive, report, route, then survey again; never claim several up front (an untaken claim sits invisible until its heartbeat lapses). No per-run limit in the other direction: keep going until nothing is claimable. Prefer a mission over backlog tickets. Read a refusal rather than working around it: `already_claimed` → drop the unit and continue (the protocol working); `origin_unreachable`/`no_origin` → end claiming (an unpublished claim is not a claim). All refusals: [reference/claims.md](reference/claims.md). The claim creates `.worktrees/<unit-id>/`; **all of the unit's work happens there**, every command `( cd <worktree_path> && … )` or absolute-pathed.

**Under `/implement` only, resolve the unit's feedback stems** for reuse at the finish post — `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/unit-feedback-stems.sh <artifact>...`, then find each thread by the **stateless lookup** in `workaholic:notify` (*One thread per feedback item*): exact-string searches only, at most two queries, a new keyed root when nothing matches — resolved **once per run** and reused for the finish (the start post is retired; a unit posts its one finish line only). **An attended `/drive` run posts nothing to Slack, at any step** — the operator is present. Post rules: [reference/routing.md](reference/routing.md); `claim.sh`'s own one-line bot notice is a separate token-gated surface, never load-bearing.

### 4. Drive the unit

Inside the worktree, order the queue — dependency toposort → context grouping → implicit deps, reported, never asked ([reference/ticket-workflow.md](reference/ticket-workflow.md)); on Claude Code the ordering may be delegated to a `general-purpose` subagent. That subagent issues no `AskUserQuestion` — nothing in this run below §2 does. Then run each ticket through the **Workflow** below. Keep the heartbeat alive: `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/heartbeat.sh <unit-id>` roughly every ten minutes or once per ticket (each `archive.sh` refreshes it for free; a failed beat is reported, never fatal). There is no per-ticket prompt and no gate-skipping decision: the authorization floor `drive-authorized.sh` states per ticket **moved up to the unit** — the survey applies it before offering ([reference/failure-contract.md](reference/failure-contract.md)).

### 5. Report

From inside the worktree, generate the story per `workaholic:report`'s Write Story flow, run the branch-safety scan (warn tier — findings fold into the PR body, never a prompt), then `bash ${CLAUDE_PLUGIN_ROOT}/skills/report/scripts/create-or-update.sh <branch> "<title>"`. **Compose `/report`; never fork or absorb it** — if context detection misreads, scope by branch, do not write a second story generator. A PR-creation failure (including `gh_unavailable`) is its own report item, never a change to the unit's outcome — though a unit that was going to ship demotes to the PR path ([reference/routing.md](reference/routing.md)).

### 6. Route by effective merge policy

Derive the route with `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/effective-policy.sh mission <slug>` or `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/effective-policy.sh tickets <ticket-file>...` — a script, not prose, because the answer decides whether machinery merges to `main` (G5):

| Unit | Policy source | Effective policy |
| ---- | ------------- | ---------------- |
| Mission unit | the mission's `merge_policy`, recorded at creation | `auto` iff the mission says `auto` |
| Batch unit | each member ticket's own `merge_policy` | `auto` iff **every** member says `auto` |
| Any member says `review`, or records nothing | — | `review` (any review member wins; **absent means review** — review costs a human one look, auto merges work nobody authorized) |

**`review` → merge the PR immediately** (mission `auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`, 2026-08-11, superseding the stop-at-the-PR route): once `/report` has opened the unit's pull request and the branch-safety scan verdict is `pass`, merge it (REST — `gh-rest.sh api repos/<slug>/pulls/<n>/merge --method PUT -f merge_method=merge`; never `gh pr merge`, which is GraphQL-backed, `rules/shell.md`) with no human confirmation and tear the claim down exactly as `auto` does — quality is gated downstream at the `release/*` QA window, not at merge time. **Any scan finding leaves the PR open instead** (there is no human here to override — the demotion doctrine unchanged), and that open PR is the unit's reported outcome. Under `/implement`, post the one `🟢 Implemented` finish line **on the transport `workaholic:notify` selects** (*The transport* — the connector where the session has one, the tokened script as the machine fallback; never load-bearing, and its outcome is reported per §7); under `/drive` report it in the session and post nothing. **`auto` → ship** through `workaholic:ship`'s full evidence-gated doctrine, no prompts and no shortcuts, then tear the claim down from the main checkout (claim-born and ship-torn): `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-mission-worktree.sh <unit-id>` then delete the claim branch. **Under `/implement`, every route posts one finish line** (🟢/🚀/🟡/🔴) into the unit's resolved thread(s); an attended `/drive` run posts no finish line either ([reference/routing.md](reference/routing.md)).

**The run never overrides a gate — through either entry point.** `auto` means "no *approval* needed"; it never means "no *gate* applies", and a present developer recovers no override:

| Gate outcome on an `auto` unit | What the run does |
| ------------------------------ | ----------------- |
| `secret` finding (non-overridable) | **Hard stop.** Unit `blocked`, claim left in place — never laundered into the PR path. |
| `size`/`leak` finding (overridable interactively) | **Demote to the PR path.** The override is a human ruling an unattended caller does not have. |
| No confirmation method (ship §1-4) | **Demote to the PR path.** The accepted-risk bypass is a developer's conscious choice. |
| A confirmation that ran and **failed** | **Hard stop**, unit `blocked`; the unmerged branch is the rollback. |
| A `content` conflict catching up with `main` (a `mechanical` one is routine) / a dirty claim worktree | **Demote to the PR path**, reported. |

A demotion is reported as a demotion, with the gate that caused it. **The third route** — `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/land-unit.sh <unit-id> --developer-present [--override-scan]` — lands a `review` unit on a **present developer's instruction** so the next survey offers its leftover tickets. Neither entry point ever calls it; it refuses `headless_context` first and unoverridably, and the gates apply unchanged ([reference/routing.md](reference/routing.md)).

### 7. Account, reconcile, and the terminal token

Per **mission** unit, record wall-clock once via `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/record-run-hours.sh "<slug>" "<hours>" "<run-id>"` — one run-id per invocation, idempotent per run-id, the only writer of `actual_hours`.

**A unit may also end in `handoff`** — genuinely half-driven, when **all three** hold: its queue is **not drained**, the work that exists is pushed, and continuing it requires a person or another session. Contrast: `blocked` = a named external blocker, *nothing further is possible*; a `review` unit at a PR: Its queue **is** drained; and a unit the run did not want to attempt is not a state at all — *Attempt every ticket* governs, and `handoff` must never become its soft landing. `handoff` is a property of the unit — **the four ticket outcomes stay four** and reconcile to the queue. A handoff unit writes the `## Handoff` section, opens/updates its PR with the work pushed, leaves its tickets stamped in `todo/`, and (under `/implement`) its 🟡 is the unit's one finish post ([reference/routing.md](reference/routing.md)).

**The run report is the deliverable** — always emitted. Per unit: members, policy, route (shipped / at a PR / **demoted to PR, with the gate that caused it** / **handoff** / blocked), ticket outcomes reconciling to its queue, commits, PR URL or `pr_error`, and — under `/implement` — the **notification outcome**: the surface each finish line went out on and whether it landed (`posted` into the resolved thread, `posted_as_root`, or the failure named: `no_surface`, `no_token`, `slack_<error>`, …). **A finish line that did not reach Slack is reported as unposted**, never omitted and never left to read as sent — the `/propose` `notified` flag's shape, extended per unit. Then **Tickets minted mid-run**, deferred decisions (recorded, never asked), `deferred_by_operator` units, exclusions, stashes, predicted-vs-actual hours (full list: [reference/routing.md](reference/routing.md)). Then the reconciliation line, then the token, as the last two lines of the run — `N units: X shipped, Y PR'd, Z blocked` followed by `ok` or `pending`. The token is **derived, never self-asserted**:

| State at the end of the run | Final line |
| --------------------------- | ---------- |
| Every claimed unit reached its routed end (`auto` shipped, `review` merged — or waiting at a PR only because a scan finding held it) **and** a fresh survey offers nothing claimable | `ok` |
| Any claimed unit is `blocked`, or ended in **`handoff`** | `pending` |
| Any claimed unit was **demoted** and is waiting at a PR it was meant to ship, or was left with tickets undriven (failed/blocked tickets remain in its queue) | `pending` |
| The survey still offers a claimable mission or ticket (including a unit another runner holds) | `pending` |
| The developer **deferred** a unit at the attended selection (`deferred_by_operator`) | `pending` — still claimable; a narrowed run is not a finished one |
| The survey offers a **resumable** unit with `resume_reason: heartbeat_lapsed` that this run did not take over | `pending` |
| The survey offers a **resumable** unit with `resume_reason: parked_with_pr` that this run did not take over | *not by itself* `pending` — it is waiting on a human; report it and the reason for deferring it |
| The survey ran against a checkout **not** known current with the base (`current: false`, or `sync-main.sh` reported `no_origin`/`origin_unreachable`) | `pending` |
| The survey could not read the backlog (`backlog_error` non-empty), could not judge ownership (`owner_unresolved`), or the claim scan ran over **truncated history** (`shallow: true`) | `pending` |
| No plugin tree could be resolved at all (`plugin-src.sh` → `no_plugin_source`) — §1 terminated before surveying, the run cannot read its own workflow | `pending` |
| The run bound a **superseded plugin** (`loaded_version_behind_registry`, `registry_unreadable`, or a `check.sh` too old to report either) but §1 resolved a newer `src` and drove from it | *not by itself* `pending` — report `source`/`degraded`/`bound_version`; the token follows the units |
| A unit's **finish line did not reach Slack** (no surface, `no_token`, an API error) | *not by itself* `pending` — a notification is never load-bearing, so the work's outcome decides the token; the report above names the failure and its reason. Deliberate (2026-08-12): making an unposted post flip the token would fail runs whose work landed, and hiding it would leave a run whose whole Slack output vanished reading as a clean `ok`. The report gets more honest; the `/goal /implement ok` contract does not move. |
| Nothing was claimable and nothing is in flight, over a **current** survey that read the backlog | `ok` |

"I stopped" is not "it's done": a blocked unit is `pending`, not `ok`. This table is verbatim the contract a caller-side loop such as `/goal /implement ok` waits on (decision I4); the reconciliation line always precedes the token so the outcome is graspable from outside.

## The failure contract

What an unattended unit may and may not do when a ticket goes wrong — every run, both entry points. Full statement: [reference/failure-contract.md](reference/failure-contract.md).

- **Attempt every ticket.** Size, complexity, and "needs a human" are not skip reasons; heavy, long, exclusive work is *preferred* unattended work. Only two buckets defer without an attempt: the safety floor (irreversible outward actions) and a genuinely external blocker, named concretely.
- **A closed set of four outcomes**, reconciling to the unit's queue: **implemented** (gate passed, archived) / **failed** (checks red — stash the partial work, leave the ticket in `todo`, record reason and stash) / **blocked** (a named external blocker with the attempted command and its raw output — a finding, not a forecast) / **`deferred`** (an unqueued problem became a ticket; the run continued).
- **Safety floor on any failure**: **NEVER** auto-icebox, auto-abandon, or run destructive git (`git restore .` / `git clean` / `git reset --hard` / `git stash drop` / `git checkout .`) — those need a human. "Missing credentials" is a checked claim (confirm `env_files_carried`, name the file). A backgrounded job's outcome is owed to the report either way.
- **An observation is not an obligation. Only a ticket is.** **Inside the current ticket's scope** → **implement it.** **Outside it** → **write a ticket, continue.** Do **not** fix it opportunistically ("unverified inferences pile up in the code" — the `overnight-ai` limit). **Blocks the current ticket** → write the ticket, then record the current one **`blocked`**, naming it. Mint only for an observed problem — speculative minting turns the queue into a diary. A minted ticket passes `validate-ticket.sh` like any other and inherits the provoking ticket's `mission:` relation; report every one. Do **not** append an acceptance item to the mission for it — promoting it into the definition of done is the developer's call.

### Where the per-ticket approval prompt went

The prompt is retired and **approval is relocated, not removed**: a mission unit was authorized when a human **merged the mission's pull request** (K1); a batch unit when **each ticket was created** (`merge_policy` at `/ticket` time). What is removed is the completeness check inside the drive loop — nothing else: the non-delegable looking-through relocates to the PR. The run does not relay evidence-resolvable decisions upward either — decide, record one line, proceed; a genuine developer-only ruling is deferred and recorded, never asked. Requirements elicitation at planning time is the opposite case and stays mandatory ([reference/failure-contract.md](reference/failure-contract.md)).

## Claims

**The repository is the coordination medium.** A runner claims a unit as a `Claim <unit-id>` commit on a pushed `work-*` branch; the unmerged remote branches are the only claim oracle (`bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/list-claims.sh` — pure read). A merge releases by definition; `release-claim.sh` deliberately discards an unfinished unit (never a recovery path); `claim.sh resume <unit-id>` takes over **your own** claim whose heartbeat lapsed — a colleague's is `foreign_identity`, untouchable at any age, and races are settled by the push, never a clock. Staleness (`stale: true`, 24 h) is reported and never acted on. A stamp that reaches the base is history, not a claim (M1). The reader degrades offline; the writer refuses. **The archive commit pushes itself**: `archive.sh` pushes the claim branch immediately after making the archive commit, the same non-blocking convention `heartbeat.sh` uses for the branch tip — an archive commit is a progress signal that must always reach the remote, so this is no longer left to the driving session's discretion; a failed push is reported (never fatal) and the next heartbeat or commit carries it forward. Full protocol, script contracts, and refusal vocabularies: [reference/claims.md](reference/claims.md).

## Workflow

Implementing a single ticket, inside the unit's worktree — the full steps (read the ticket, its `## Policies`, its `## Quality Gate`, and the gate of **every** mission it names; apply patches; implement against the policy lens; return the JSON summary; append the Final Report; archive) live in [reference/ticket-workflow.md](reference/ticket-workflow.md), with the system-safety check (`bash ${CLAUDE_PLUGIN_ROOT}/skills/system-safety/scripts/detect.sh`) and the prohibited-git-operations table.

- **NEVER commit outside the sanctioned scripts** — `archive.sh` and `commit.sh` own the commit seam.
- **NEVER use AskUserQuestion while driving a ticket** — the run's only interaction point is the §2 selection.
- **NEVER archive tickets manually** — `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh` is the only authorized method, and the ticket's `## Final Report` is appended first.
- **NEVER autonomously move tickets to icebox** — the icebox is developer-curated in both directions.
