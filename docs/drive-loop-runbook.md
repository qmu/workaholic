# Drive Loop Runbook

How the execution loop runs `/implement` headlessly, so merged missions and queued
tickets are claimed, implemented, reported, and — per the artifacts' recorded merge
policy — shipped or merged at a PR (`docs/loop-engineering-workflow.md` G4).

**The primary trigger is the `[Implement]` Claude Code Web routine**, which fires on
a fixed hourly schedule (`30 * * * *`) from the shipped template
`plugins/workaholic/skills/workaholify/routines/implement.md`. It is the execution
sibling of the `[Specificate]` routine, which fires hourly at `15 * * * *`
(`docs/proposal-loop-runbook.md`), and deliberately mirrors its shape. §3's server
cron is the **machine-local fallback shape** for a runner outside the routines
account; standing it up remains a developer's act (decision C1 — server cron first,
Claude Code Web later — describes the order the two arrived in, not today's default).

**Precondition (decision I9):** the repository must be **private** wherever the
feedback stream may carry customer material (H4). Do not wire this loop on a public
repository that receives customer context.

**Precondition (the executor's own gate):** the runner needs a reachable `origin`.
A claim is a *pushed* branch, so a runner that cannot push cannot claim, and a tick
without origin surveys, refuses to claim, and exits `pending` — by design (see
*Failure modes*).

## 1. What the routine actually does

Each tick is one full `/implement` run — survey, partition, claim, drive, report,
route (`plugins/workaholic/skills/drive/SKILL.md`, *Unified Run*). **The command
name is load-bearing** (decision P1, 2026-08-06, superseding O1's two invocation forms of `/drive`):
`/implement` is the **unattended** executor, which issues no `AskUserQuestion` at
any step, so nothing can block a tick waiting for a person. `/drive` is the
**attended** command and asks once which units to take whenever more than one is
claimable — correct for a developer at a terminal, fatal for a cron tick, which
would sit on the prompt until its window closed. Attendance follows from *which
command was invoked* and is never inferred from the environment, so a tick pointed
at `/drive` gets the prompt no matter how headless its container is. The same
applies to a caller-side loop: write `/goal /implement ok`, never `/goal /drive ok`.
O1's `auto` and `night` first words are retired — a behaviour selected by an
argument a caller might forget to pass is not a contract a loop can rest on.

Two things the loop never does, and both are deliberate:

- **It never ships anything a policy did not authorize.** `merge_policy` decides the
  *route*, not whether a merge happens: a unit whose members all record `auto` goes
  through the full `/ship` doctrine (catch up with `main`, deploy, confirm in
  production, record the evidence, *then* merge), while a `review` unit — which is
  also what an absent policy means — merges its pull request as soon as `/story`
  opens it and the scan passes. Since 2026-08-11 `main` is the continuously
  auto-merged development branch and **quality is gated at the `release/*` QA
  window**, so what a `review` policy withholds is the deploy-and-confirm doctrine,
  not the merge. (Until then a `review` unit stopped at its PR to wait for a person.)
- **It never overrides a gate.** A blocking scan finding leaves a `review` unit's PR
  open instead of merging it; on an `auto` unit a size/leak finding or a missing
  deployment confirmation demotes it to the PR path, and a secret hard-stops it. "No
  approval needed" is not "no gate applies". Since 2026-08-14 the same holds one step
  earlier: a unit whose mission or ticket declared `verification_handoff:` at creation
  — the verification needs a credential the runner does not have — is routed to
  `handoff` before the merge-policy table is consulted at all, so it never merges and
  never announces `🟢 Implemented`.

## 2. Wire the environment (per runner)

The only environment the loop needs is the Slack notifier's, and it is optional —
it is the machine fallback by which a unit's finish line, carrying its PR URL,
reaches the team. (A routine session uses the account's Slack connector instead;
`workaholic:notify`, *The transport*, is the one place that states the order.)

```sh
export SLACK_BOT_TOKEN=<your bot token>   # chat:write scope
export WORKAHOLIC_SLACK_CHANNEL=<channel id>
```

Both unset is valid: the run behaves identically and records
`{"notified": false, "reason": "no_token"}` instead of posting. Reuse the proposal
loop's bot (`docs/proposal-loop-runbook.md` §1) — one bot per workspace is enough.

Optional knob:

```sh
export WORKAHOLIC_CLAIM_STALE_HOURS=24              # when a claim is *reported* stale (default 24)
export WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=30  # when a claim of YOUR OWN becomes resumable (default 30)
```

These two look alike and do opposite things. **Staleness is reported, never
auto-broken**: nothing in the loop reclaims a stale unit, because a runner that
reclaims on its own verdict can silently duplicate a *colleague's* in-flight work.
**Resumability acts**, and is deliberately narrower — it applies only to a claim
whose author is this runner's own `git config user.email`, and only once its
heartbeat has lapsed. Keep the heartbeat window well under the tick interval you
care about recovering within: at the default 30 minutes an hourly routine reclaims
its own dropped unit on the next tick. See *Failure modes*.

## 3. The machine-local fallback: a server cron entry

This section is the **fallback shape** for a runner outside the routines account —
the primary trigger is the hourly `[Implement]` routine (§1). The interval below is
a working example, not a contract; the routines API's own minimum is one hour.

The run works **in the repository checkout**, claiming into `.worktrees/<unit-id>/`
worktrees of that checkout. A working shape (adjust the claude invocation to the
installed CLI):

```cron
*/5 * * * * . "$HOME/.workaholic-drive.env" && claude -p "/implement" --cwd /path/to/repo >> "$HOME/.workaholic-drive.log" 2>&1
```

- Keep the token in a `0600` env file (`~/.workaholic-drive.env` with the exports
  above), never in the crontab line itself.
- **Several runners are safe, and that is the point.** The claim protocol makes the
  repository the coordination medium: every runner fetches, reads the unmerged
  remote branches for claims, and takes only unclaimed units. Two runners racing for
  the same unit end with one `claimed: true` and one `already_claimed` refusal —
  which is the protocol working, not an error. This supersedes the proposal loop's
  one-runner-per-repo rule, which exists only because *that* loop's cursor is
  runner-local state.
- A tick that overruns the 5-minute interval is fine: the next tick surveys, sees
  the in-flight claim, and works on something else or exits with nothing to do.
- Do not install the crontab from an agent session — applying a standing
  outward-facing process is the developer's act; this page is the instruction.
  The rule generalized beyond cron on 2026-08-03: an agent may not bring a
  standing outward-facing process into existence, or re-point one, without a
  human seeing exactly what it will be. **The 2026-08-06 reading of that bar —
  "`/setup-routines` renders copy-paste setup sheets and manages nothing" — is
  superseded** (mission `configure-routines-automatically-via-remotetrigger`):
  the setup commands now *configure* the routines on every run through a
  `RemoteTrigger`-family tool — list the account's routines, diff each against its
  template, apply the create/update that converges them, report the per-routine
  changes. The setup sheets remain, as the recovery path when no such transport is
  reachable (`no_transport`), not as the product (`skills/workaholify/SKILL.md` §5).
  Since 2026-08-14 `/setup-routines` itself is **split by routine scope**:
  `/setup-dev-routines` converges the two developer-scoped routines and
  `/setup-repo-routines` the repository's single `[Prepare Release]`, run by one
  account. Same flow, same one refusal; only the template set differs.
  The bar itself is unchanged for **cron**: a server crontab is still installed by
  the developer, from this page, never from an agent session.

### The routine fires on a clock; no repository-event trigger exists

**The `[Implement]` routine fires on the hourly schedule `30 * * * *`.** A routine
cannot subscribe to a repository event at all: the API's whole trigger surface is
`cron_expression`, `run_once_at`, and an API token, so there is nothing for a merge to
attach to. The server cron in §3 is the fallback shape for a machine-local loop, and
standing it up stays a developer's act.

> **Superseded (2026-08-06): "The cloud routine is merge-triggered; the clock in this
> runbook is the fallback."** That section held that the routine **fires when a
> proposal's pull request merges** — the developer's original ask — and retracted two
> earlier clock arguments, the first of them "a merge trigger does not exist", on the
> grounds that the trigger wiring lived in the routines UI and was invisible to the API
> record both readings relied on. The retraction was itself wrong: the trigger surface
> was later read directly and carries no event field, so the first argument had been
> right. The recovery argument that section answered still holds and still matters —
> the survey offers everything claimable, not only the work a particular event
> produced, so nothing is stranded by an hourly cadence.

The announcement half changed too: **the start post is retired** (2026-08-11) — a drive
run posts its **one finish line** into the feedback item's thread and nothing else (§5,
and `skills/notify/SKILL.md`, *One thread per feedback item*).

## 4. What feeds the loop

The routine consumes what other flows produce, and produces nothing to prime it
with:

- **Missions on `main` owned by this runner, or unowned** — a mission becomes
  claimable the moment its pull request merges; there is no approval flip any more
  (decision K1). It must also be this runner's to take: its `git config user.email`
  is among the mission's `assignees`, or the mission has none — team-owned work is
  claimable by anyone. A mission owned solely by a colleague is excluded as
  `owned_by_other`, so a runner never drives someone else's plan to `main`. A
  proposal `/specificate` registers reaches the executor as soon as its pull request
  merges — which now happens **on opening**, so the next tick can already see it;
  the human judgment is the `merge_policy` recorded on what was published (absent
  reads as `review`) and the `release/*` QA window, not the merge itself.
- **Backlog tickets** — anything in `.workaholic/tickets/todo/` this runner owns,
  or that nobody owns, with no `mission:` relation. A missioned ticket is driven
  inside its mission's unit. Ownership is the ticket's `assignees` field (P2,
  2026-08-06), not its directory.

Both floors are enforced in the survey, not in prose: a mission with an
empty `## Acceptance` is excluded as `no_plan`, because a merge with no plan behind
it authorizes nothing concrete.

Both halves are filtered by the runner's git identity against each artifact's
`assignees`, through one oracle. The identity is a precondition of **claiming**,
not of surveying: a runner without one still reads the whole queue, reports
`owner_unresolved` with the queue's size, offers the unowned half, and forbids `ok`
(see *Failure modes*).

## 5. Observability

- **Claims** are the live picture of what is in flight, readable from any clone:

  ```sh
  bash plugins/workaholic/skills/drive/scripts/list-claims.sh
  ```

  Each entry names the unit, its branch, the claimed artifacts, whether the branch
  tip has gone stale, and whether the unit is **resumable**. `resume_reason` is never
  empty and names either a resumable verdict — `heartbeat_lapsed` (a run that died
  mid-drive) or `report_incomplete` (a run that died with its queue drained and no
  pull request opened: the work is pushed and nobody was told) — or the condition
  that refused it: `claim_active` / `foreign_identity` / `identity_unresolved` /
  `shallow_history` / `queue_drained` (drained **and reported**, so a human is what
  it waits for). Both resumable verdicts are mandatory takeovers and forbid `ok`;
  `plan-units.sh`'s `resumable[]` adds the third, softer tier, `parked_with_pr` —
  reportable rather than mandatory, and it does not forbid `ok`. The top-level `shallow` says whether
  this clone's history was complete enough to answer at all. `Claim <unit-id>`
  commits on unmerged branches are the loop's ledger — `git log --oneline --all
  --grep='^Claim '` reads it from git alone.
- **Claim notices** are the loop's *first* signal, minutes ahead of any PR: `claim.sh`
  posts one Slack line naming the unit and branch the moment the claim is pushed. It
  is never load-bearing, so its absence proves nothing on its own — check
  `announced` / `announce_reason` in the tick's own output before concluding the
  runner is dead.
- **The per-unit finish post** lands in the **feedback item's own thread**, so an
  item's ask, its proposal and its run read as one conversation instead of scattered
  lines. The unit's stems come from
  `drive/scripts/unit-feedback-stems.sh` (the mission's `mission.md`, or the batch's
  tickets); a unit tracing to no record keys on `unit:<unit-id>` rather than posting
  keyless. **Exactly one post per unit** — the start post (`🟠 Implementing`) is
  retired (2026-08-11) — its shape following the outcome (`🟢` implemented, `🚀`
  shipped, `🟡` handoff, `🔴` blocked); a handoff *is* the finish. The rules are in
  `skills/notify/SKILL.md`, *Which thread an `/implement` unit's posts land in*. These are the session's posts through the Slack
  connector; the bot-token notice above is a separate surface and neither is
  load-bearing.
- **Handoffs** are units a run half-drove and could not finish. They are readable
  where a person actually looks: the PR body's `## Handoff` section states what is
  done, what is not, the next step, and any command attempted with its raw output.
  A handoff tick terminates `pending`, and the unit is exactly the shape a later run
  resumes (below) — one story, not two mechanisms.
- **PRs** are the loop's output: one per unit, and **both routes merge on the tick
  that opened them**. A `review` unit's PR is merged as soon as `/story` opens it and
  the branch-safety scan passes — a scan finding is the one thing that leaves it open,
  and that open PR is then the unit's reported outcome. An `auto` unit's PR is merged
  through the full `/ship` doctrine instead. Either way the URL rides the unit's finish
  line, and the worktree and claim branch are removed afterwards. Quality is gated
  downstream at the `release/*` QA window, not at merge time.
- **Terminal tokens** end every tick in the cron log: the reconciliation line
  (`N units: X shipped, Y PR'd, Z blocked`) and then `ok` or `pending`. Grepping the
  log for `^pending` is the fastest way to find the ticks that need a human;
  a healthy idle loop prints `0 units: 0 shipped, 0 PR'd, 0 blocked` / `ok`.
- **The notification outcome** rides the run report, per unit: the surface the finish
  line went out on and whether it landed, or the reason it did not (`no_surface`,
  `no_token`, `slack_<error>`). It does **not** move the terminal token — a
  notification is never load-bearing — so a tick can read `ok` with its Slack output
  missing; the report is where that shows. Grep a tick's report for the outcome before
  concluding from Slack's silence that the loop is dead (`workaholic:drive` §7).
- **Worktrees** left in `.worktrees/` are in-flight or stale claims by definition —
  the same fact `list-claims.sh` reports, visible on the filesystem.
- **`release/*` branches are not the loop's output and never appear because of a tick.**
  The release tier (decisions L1-L3) is a *batch-level promotion* over `main`, cut and
  confirmed deliberately by `workaholic:ship` §6 — `/drive` neither cuts nor confirms one.
  An `auto` unit merging is unchanged by the tier: it lands on `main`, and a later
  promotion decides when what has landed becomes a production release. If a `release/*`
  branch appears, a promotion made it, not a tick. It is also invisible to the claim
  reader, because the scan keys on a `Claim a PR-unit` subject / `Unit:` trailer and a
  release branch carries no commits at all.

## 6. Failure modes

| Symptom | Cause | Fix |
| ------- | ----- | --- |
| every tick refuses with `origin_unreachable` / `no_origin` | the runner cannot reach the remote | a claim must be pushed to exist; fix the remote/credentials — the loop correctly does nothing until then |
| `gh: command not found`, or a unit reporting `pr_error: gh_unavailable` after its branch was pushed | the cloud container the routine runs in has no GitHub CLI | the work is pushed and safe: the seams report `gh_unavailable` and exit 0 rather than dying, the unit is demoted to the PR path, and the pull request is opened by hand (or by an agent through its MCP server). Installing `gh` in the runner image is the real fix; the guards are the floor, since a container can always lose it again |
| `pre-check.sh` reporting `found: false` | either the branch genuinely has no PR, **or** `gh` is absent | read `reason`: `gh_unavailable` means PR state could not be read at all. The two were once the same output, and a ship flow read the second as the first |
| a unit sits claimed for days, `stale: true` | the runner died mid-run, or the work genuinely stalled | nothing auto-breaks a claim on staleness alone — reclaiming a *colleague's* work can silently duplicate it. If the claim is **yours**, the loop already recovers it: once the heartbeat lapses the survey offers it in `resumable[]` and the next tick takes it over with `claim.sh resume <unit-id>`, continuing from the pushed branch tip. Otherwise inspect the branch and leave it to its owner |
| a unit is **not** offered as resumable although its run is clearly gone | its `resume_reason` says which condition failed | `claim_active` = the tip is still inside the heartbeat window (wait it out, or shorten `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES`); `foreign_identity` = the claim is another developer's and is never resumable here at any age; `identity_unresolved` = this checkout has no `git config user.email`; `shallow_history` = the clone is truncated and origin was unreachable, so "is this branch merged" could not be answered — restore network access and re-run, and the reader deepens itself; `queue_drained` = every ticket was driven **and** the branch carries a story, so its pull request is open and a human is what it waits for (check the PR) |
| a unit's tickets are all archived and pushed, but no pull request exists and no tick ever picks it up | the run died between §4 and §5 — it never wrote the story and never opened the PR | `list-claims.sh` reports it `resume_reason: report_incomplete`, `resumable: true`, and the survey offers it: the next tick takes it over with `claim.sh resume <unit-id>` and enters at §5 with an empty queue, re-driving nothing. Before 2026-08-19 it read `queue_drained` and was reachable by no path at all (measured: `batch-20260819063000`, four ticks that drove nothing while its two tickets sat undelivered) |
| a **merged, shipped** unit is offered as `resumable`, or the tick never reports `ok` | the clone is shallow, so `base..ref` cannot be reduced and a merged branch counts as ahead (measured 2026-08-04: 154 ahead while shallow, 0 after `--unshallow`) | the reader now deepens itself before scanning, so this should self-heal on the next tick. If `shallow: true` persists, origin is unreachable — fix that first; `git fetch --unshallow` by hand is the manual equivalent |
| `resume_race_lost` in the log | two runners saw the same unit as resumable and both pushed a takeover | expected; git rejected the loser's push and it took nothing. The winner is driving the unit |
| `release-claim.sh` used to "recover" an interrupted unit | it is the **discard** path, not the recovery path — it deletes the remote branch | use `claim.sh resume <unit-id>` to continue an interrupted unit. Reserve `release-claim.sh` for a unit that will genuinely not be finished |
| `already_claimed` in the log | another runner or tick took the unit first | expected; no action |
| `branch_collision` | two runners minted the same second's `work-*` branch name | nothing was claimed; the next tick succeeds |
| a unit reported **demoted to PR** | an `auto` unit hit an overridable gate (size/leak block, no confirmation method, content conflict with `main`) | the demotion is the design — review and merge the PR, or fix the diff and let the next tick re-drive |
| a unit reported **blocked** on a `secret` finding | a credential reached the branch diff | non-overridable: remove the credential from the diff. The branch is already pushed, so treat it as an exposure, not just a gate failure |
| a unit reported **blocked** on a failed production confirmation | the deploy did not verify | the unmerged branch is the rollback; diagnose the deploy, do not force the merge |
| every tick reports 0 units / `ok` but the queue is full | **cannot happen since P2 (2026-08-06)** — the queue is flat and readable by anyone, so a runner with no `git config user.email` reads it and says so instead of finding no directory | `plan-units.sh` reports `backlog_size` (what the queue actually holds) plus `owner_unresolved: true`, excludes each owned ticket as `owner_unresolved`, still offers the unowned ones, and forbids `ok`. Configure the runner's identity — claiming needs one and fails loudly without it, which is the claim protocol's question and is unchanged |
| missions exist on `main` but nothing is claimed | the mission has an empty `## Acceptance` (`no_plan`), **no ticket names it** (`no_tickets` — an acceptance sketch is not a plan; emit the set with `/mission <instruction>`), a claim already holds it (`claimed_active` / `claimed_by_other`, or `claimed_resumable` if it is yours to take over), or its `assignees` name only another developer (`owned_by_other`) | check `plan-units.sh`'s `excluded[]` — every drop states its reason. `owned_by_other` means nothing to do here: the mission is a colleague's, and their runner will take it. Two old causes cannot occur any more: "its tickets live in an unmerged worktree" (missions and tickets are published for merge, decision J1/J4) and `not_approved` (the draft gate was retired, K1) |
| the tick reports nothing to do, but you can see a queued ticket on GitHub | the runner's checkout is behind `origin/main`, so the survey never learned the artifact exists | the freshness step (`sync-main.sh`, the drive skill §1) fast-forwards before surveying, and `plan-units.sh` reports `current: false` when it could not. If it keeps reporting `not_on_main` / `dirty_workspace` / `diverged`, the runner checkout is being used for other work — keep it dedicated and reconcile by hand |
| a tick terminates `pending` with `not_on_main` or `dirty_workspace` | the runner checkout is on a branch, or holds uncommitted work | the run refuses to survey a branch rather than surveying the wrong queue. Return the checkout to a clean `main` |
| `dirty_workspace` naming **staged mission files nobody edited** (`M .workaholic/missions/active/*/mission.md`) | the **installed plugin is older than the checkout**, and its always-on `mission-lens.sh` is running an obsolete living migration backwards — the pre-K1 build folds `active` → `draft` and `git add`s the result, on every prompt | check `check-deps/scripts/check.sh`: `version_drift: true` with `version` (installed) beside `checkout_version` names it outright. Restore with a **targeted** `git restore` of the listed files — never `git clean` / `git reset --hard` — then refresh the install (`claude plugin update workaholic@workaholic`) or start a fresh session, which re-runs the version-gated bootstrap. Do **not** edit the plugin cache: it is outside the repository, and a fix that lives in one container is not a fix |
| `version_drift: true` but nothing is dirty | the installed build is simply behind; most releases touch nothing a given run reaches | **a warning, not a stop** — by decision, a runner that refuses to work because its plugin is old is as useless as one that works wrongly. The run continues and reports the drift. Drift is answered by *selecting the newest tree* (`plugin-src.sh`, §1), not by refusing to run — the row below has the same shape and the same answer; the one termination left in §1 is `no_plugin_source`, where no tree could be resolved at all |
| `loaded_version_behind_registry: true` (or `registry_unreadable: true`) | the session bound a **superseded plugin cache directory**. `plugin update` unpacks the new version beside the old and deletes neither, and a SessionStart hook may not refresh a running session, so nothing repairs it mid-flight | **a warning, not a stop** (2026-08-12, the developer's ruling — it was the one stop in §1 until then). The run reports `version`, `registry_version`, and the `source`/`degraded`/`bound_version` that `plugin-src.sh` chose, and drives from the newest tree on the machine. What the old stop protected against is real and unchanged — on 2026-08-04T22:58Z a tick bound to 1.0.112 (registry: 1.0.129) ran a pre-rename-resolution `claims.sh`, read five already-driven tickets as fresh backlog and **claimed one**, a double-pick on a pushed ref — but that is a property of *which scripts a run executes*, which §1 now answers directly by resolving `src` before anything else; a run executing the registry's own version is not running stale code, whatever the harness bound. **Why the stop had to go**: the binding is taken at startup, strictly before the bootstrap hook runs, and the cloud container binds a *project-scope* install baked into its image while the bootstrap updates the *user* scope — so `claude plugin update` reports "for scope user", the pin never moves, and every tick is a fresh container off the same image. The gate reproduced hourly and never self-healed: four consecutive ticks in 2026-08-05, then twelve in 2026-08-12, all stopping before the survey with a claimable queue. Sweeping the superseded cache directories is *not* the fix and was rejected with its reasoning in `bootstrap/session-start.sh`'s header: the registry names exactly one directory, so nothing ever picked the wrong one. A fresher image, or a harness that rebinds after SessionStart, is what actually clears the drift itself — the run no longer waits for either |
| `check.sh` output carrying **neither** `loaded_version_behind_registry` **nor** `registry_unreadable` | the loaded build predates the field — which is, by construction, exactly the stale build the field exists to catch | treat it as the condition itself — which is now the warning above, not a termination. Report it and drive from the `src` §1 resolved. Reading a missing key as "no drift" would still let the defect suppress its own alarm; what changed is the consequence, not the reading |
| a tick terminates `pending` with `diverged` | the runner's local `main` has commits the base does not, or the histories parted | a human's call; nothing is merged or reset. `detail` says `local_ahead` or `both_diverged` |
| a merged `/specificate` proposal drives nothing | its `## Acceptance` is a provisional sketch with no tickets behind it | the survey reports `no_tickets` and the mission is not offered. Replan it (`/mission <instruction referencing it>`) to emit the ticket set, and merge that delta |
| `claim.sh` refuses with `mission_missing` | the slug is wrong, or the checkout is behind the base | absence is a real error since J1. Run `sync-main.sh`, then re-check the slug against `mission/scripts/list.sh` |
| `{"notified": false, "reason": "no_token"}` on every review unit | env file missing/unsourced in cron | check the `. …/.workaholic-drive.env` prefix and file perms |
| tickets pile up untouched | they carry a `mission:` relation naming a mission that is still **active**, so they are driven only inside that mission's unit (`mission_member`) — and the mission itself is not being offered | read the mission's own row in `plan-units.sh`'s `excluded[]` (`no_plan`, `owned_by_other`, a live claim) and fix that; there is no approval flip to perform (K1 — merging the mission's pull request was the approval). A ticket that should stand alone drops the relation and becomes ordinary backlog |
| a ticket of a **closed** mission piles up | it used to be dropped `mission_member` forever: only `missions/active/` yields units, so once every mission it named had closed it was offered by neither path and the queue read as drained (fixed 2026-08-12, qmu/workaholic#382) | nothing to do — the survey now offers it as ordinary backlog with `mission_closed` naming the closed missions it still carries. Closing a mission `abandoned` therefore surfaces its unfinished tickets as claimable work; if that work really is withdrawn, ice the tickets or drop the relation |
