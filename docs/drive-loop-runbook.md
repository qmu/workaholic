# Drive Loop Runbook

How to stand up the **"Drive Every 5 Minutes"** routine on a server: the cron that
runs `/drive` headlessly so merged missions and queued tickets are claimed,
implemented, reported, and — per the artifacts' recorded merge policy — shipped or
handed to a human at a PR (`docs/loop-engineering-workflow.md` G4; decision C1 —
server cron first, Claude Code Web later). It is the execution sibling of the
15-minute proposal loop (`docs/proposal-loop-runbook.md`), and deliberately mirrors
its shape.

**Precondition (decision I9):** the repository must be **private** wherever the
feedback stream may carry customer material (H4). Do not wire this loop on a public
repository that receives customer context.

**Precondition (the executor's own gate):** the runner needs a reachable `origin`.
A claim is a *pushed* branch, so a runner that cannot push cannot claim, and a tick
without origin surveys, refuses to claim, and exits `pending` — by design (see
*Failure modes*).

## 1. What the routine actually does

Each tick is one full `/drive` run — survey, partition, claim, drive, report, route
(`plugins/workaholic/skills/drive/SKILL.md`, *Unified Run*). It is **non-interactive
by construction**: `/drive` issues no `AskUserQuestion` anywhere, so nothing can
block a tick waiting for a person.

Two things the loop never does, and both are deliberate:

- **It never merges anything a policy did not authorize.** A unit merges only when
  every member records `merge_policy: auto`, and even then only through the full
  `/ship` doctrine (catch up with `main`, deploy, confirm in production, record the
  evidence, *then* merge). Absent policy means review.
- **It never overrides a gate.** A blocking scan finding or a missing deployment
  confirmation demotes an `auto` unit to the PR path; a secret hard-stops it. "No
  approval needed" is not "no gate applies".

## 2. Wire the environment (per runner)

The only environment the loop needs is the Slack notifier's, and it is optional —
it is how a `review` unit's PR URL reaches the team:

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

## 3. The cron entry (every 5 minutes)

The run works **in the repository checkout**, claiming into `.worktrees/<unit-id>/`
worktrees of that checkout. A working shape (adjust the claude invocation to the
installed CLI):

```cron
*/5 * * * * . "$HOME/.workaholic-drive.env" && claude -p "/drive" --cwd /path/to/repo >> "$HOME/.workaholic-drive.log" 2>&1
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
  human seeing exactly what it will be. `/setup-routines` schedules Claude Code
  Web routines under that same bar — it reads freely, and every create, refresh
  or removal is confirmed verbatim, one routine at a time, in an interactive
  session (`skills/workaholify/SKILL.md` §5).

## 4. What feeds the loop

The routine consumes what other flows produce, and produces nothing to prime it
with:

- **Missions on `main` owned by this runner, or unowned** — a mission becomes
  claimable the moment its pull request merges; there is no approval flip any more
  (decision K1). It must also be this runner's to take: its `git config user.email`
  is among the mission's `assignees`, or the mission has none — team-owned work is
  claimable by anyone. A mission owned solely by a colleague is excluded as
  `owned_by_other`, so a runner never drives someone else's plan to `main`. A
  proposal `/propose` registers is invisible to the executor until a human merges
  its pull request — the PR is the gate, and merging it is the approval.
- **Backlog tickets** — anything in `.workaholic/tickets/todo/<user>/` with no
  `mission:` relation. A missioned ticket is driven inside its mission's unit.

Both floors are enforced in the survey, not in prose: a mission with an
empty `## Acceptance` is excluded as `no_plan`, because a merge with no plan behind
it authorizes nothing concrete.

Both halves are scoped by the runner's git identity, so **the identity is a
precondition of the loop, not a detail** — a runner without one surveys nothing and
says so (`backlog_error: identity_unresolved`; see *Failure modes*).

## 5. Observability

- **Claims** are the live picture of what is in flight, readable from any clone:

  ```sh
  bash plugins/workaholic/skills/drive/scripts/list-claims.sh
  ```

  Each entry names the unit, its branch, the claimed artifacts, whether the branch
  tip has gone stale, and whether the unit is **resumable** (with `resume_reason`:
  `claim_active` / `foreign_identity` / `identity_unresolved`). `Claim <unit-id>`
  commits on unmerged branches are the loop's ledger — `git log --oneline --all
  --grep='^Claim '` reads it from git alone.
- **Claim notices** are the loop's *first* signal, minutes ahead of any PR: `claim.sh`
  posts one Slack line naming the unit and branch the moment the claim is pushed. It
  is never load-bearing, so its absence proves nothing on its own — check
  `announced` / `announce_reason` in the tick's own output before concluding the
  runner is dead.
- **Handoffs** are units a run half-drove and could not finish. They are readable
  where a person actually looks: the PR body's `## Handoff` section states what is
  done, what is not, the next step, and any command attempted with its raw output.
  A handoff tick terminates `pending`, and the unit is exactly the shape a later run
  resumes (below) — one story, not two mechanisms.
- **PRs** are the loop's output: one per unit. A `review` unit stops there and its
  URL is posted to Slack; an `auto` unit's PR is merged by the same tick that opened
  it, and its worktree and claim branch are removed afterwards.
- **Terminal tokens** end every tick in the cron log: the reconciliation line
  (`N units: X shipped, Y PR'd, Z blocked`) and then `ok` or `pending`. Grepping the
  log for `^pending` is the fastest way to find the ticks that need a human;
  a healthy idle loop prints `0 units: 0 shipped, 0 PR'd, 0 blocked` / `ok`.
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
| a unit is **not** offered as resumable although its run is clearly gone | its `resume_reason` says which of the three conditions failed | `claim_active` = the tip is still inside the heartbeat window (wait it out, or shorten `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES`); `foreign_identity` = the claim is another developer's and is never resumable here at any age; `identity_unresolved` = this checkout has no `git config user.email` |
| `resume_race_lost` in the log | two runners saw the same unit as resumable and both pushed a takeover | expected; git rejected the loser's push and it took nothing. The winner is driving the unit |
| `release-claim.sh` used to "recover" an interrupted unit | it is the **discard** path, not the recovery path — it deletes the remote branch | use `claim.sh resume <unit-id>` to continue an interrupted unit. Reserve `release-claim.sh` for a unit that will genuinely not be finished |
| `already_claimed` in the log | another runner or tick took the unit first | expected; no action |
| `branch_collision` | two runners minted the same second's `work-*` branch name | nothing was claimed; the next tick succeeds |
| a unit reported **demoted to PR** | an `auto` unit hit an overridable gate (size/leak block, no confirmation method, content conflict with `main`) | the demotion is the design — review and merge the PR, or fix the diff and let the next tick re-drive |
| a unit reported **blocked** on a `secret` finding | a credential reached the branch diff | non-overridable: remove the credential from the diff. The branch is already pushed, so treat it as an exposure, not just a gate failure |
| a unit reported **blocked** on a failed production confirmation | the deploy did not verify | the unmerged branch is the rollback; diagnose the deploy, do not force the merge |
| every tick reports 0 units / `ok` but the queue is full | the runner has no `git config user.email`, so there is no `todo/<user>/` to resolve and the survey never learned any ticket exists | `plan-units.sh` reports `backlog_error: identity_unresolved` with an empty `user_slug`, and the tick terminates `pending` rather than `ok`. Configure the runner's identity — the plugin cannot invent one, and it deliberately does not fall back to scanning every developer's queue |
| missions exist on `main` but nothing is claimed | the mission has an empty `## Acceptance` (`no_plan`), **no ticket names it** (`no_tickets` — an acceptance sketch is not a plan; emit the set with `/mission <instruction>`), a claim already holds it (`claimed_active` / `claimed_by_other`, or `claimed_resumable` if it is yours to take over), or its `assignees` name only another developer (`owned_by_other`) | check `plan-units.sh`'s `excluded[]` — every drop states its reason. `owned_by_other` means nothing to do here: the mission is a colleague's, and their runner will take it. Two old causes cannot occur any more: "its tickets live in an unmerged worktree" (missions and tickets are published for merge, decision J1/J4) and `not_approved` (the draft gate was retired, K1) |
| the tick reports nothing to do, but you can see a queued ticket on GitHub | the runner's checkout is behind `origin/main`, so the survey never learned the artifact exists | the freshness step (`sync-main.sh`, `commands/drive.md` step 0) fast-forwards before surveying, and `plan-units.sh` reports `current: false` when it could not. If it keeps reporting `not_on_main` / `dirty_workspace` / `diverged`, the runner checkout is being used for other work — keep it dedicated and reconcile by hand |
| a tick terminates `pending` with `not_on_main` or `dirty_workspace` | the runner checkout is on a branch, or holds uncommitted work | the run refuses to survey a branch rather than surveying the wrong queue. Return the checkout to a clean `main` |
| a tick terminates `pending` with `diverged` | the runner's local `main` has commits the base does not, or the histories parted | a human's call; nothing is merged or reset. `detail` says `local_ahead` or `both_diverged` |
| a merged `/propose` proposal drives nothing | its `## Acceptance` is a provisional sketch with no tickets behind it | the survey reports `no_tickets` and the mission is not offered. Replan it (`/mission <instruction referencing it>`) to emit the ticket set, and merge that delta |
| `claim.sh` refuses with `mission_missing` | the slug is wrong, or the checkout is behind the base | absence is a real error since J1. Run `sync-main.sh`, then re-check the slug against `mission/scripts/list.sh` |
| `{"notified": false, "reason": "no_token"}` on every review unit | env file missing/unsourced in cron | check the `. …/.workaholic-drive.env` prefix and file perms |
| tickets pile up untouched | they carry a `mission:` relation whose mission is not approved | approve the mission, or drop the relation so they become backlog |
