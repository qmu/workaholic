# Drive Loop Runbook

How to stand up the **"Drive Every 5 Minutes"** routine on a server: the cron that
runs `/drive` headlessly so approved missions and queued tickets are claimed,
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
export WORKAHOLIC_CLAIM_STALE_HOURS=24    # when a claim is *reported* stale (default 24)
```

Staleness is **reported, never auto-broken**. Nothing in the loop reclaims a stale
unit; see *Failure modes*.

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
- **The schedule and command are declared in `.workaholic/routines/drive-loop.md`**, which is the source of truth; this runbook explains the routine, it no longer defines it. `/workaholify` surveys whether it is installed for you on this machine and can install it after you confirm the exact line.
- Do not install the crontab from an agent session — applying a standing
  outward-facing process is the developer's act; this page is the instruction.

## 4. What feeds the loop

The routine consumes what other flows produce, and produces nothing to prime it
with:

- **Approved missions** — a mission becomes claimable when `approve.sh` flips it to
  `status: approved` with a `merge_policy`. Drafts (including everything `/propose`
  registers) are invisible to the executor until a human approves them.
- **Backlog tickets** — anything in `.workaholic/tickets/todo/<user>/` with no
  `mission:` relation. A missioned ticket is driven inside its mission's unit.

Both floors are enforced in the survey, not in prose: an approved mission with an
empty `## Acceptance` is excluded as `no_plan`, because a stamp with no plan is no
authorization at all.

## 5. Observability

- **Claims** are the live picture of what is in flight, readable from any clone:

  ```sh
  bash plugins/workaholic/skills/drive/scripts/list-claims.sh
  ```

  Each entry names the unit, its branch, the claimed artifacts, and whether the
  branch tip has gone stale. `Claim <unit-id>` commits on unmerged branches are the
  loop's ledger — `git log --oneline --all --grep='^Claim '` reads it from git alone.
- **PRs** are the loop's output: one per unit. A `review` unit stops there and its
  URL is posted to Slack; an `auto` unit's PR is merged by the same tick that opened
  it, and its worktree and claim branch are removed afterwards.
- **Terminal tokens** end every tick in the cron log: the reconciliation line
  (`N units: X shipped, Y PR'd, Z blocked`) and then `ok` or `pending`. Grepping the
  log for `^pending` is the fastest way to find the ticks that need a human;
  a healthy idle loop prints `0 units: 0 shipped, 0 PR'd, 0 blocked` / `ok`.
- **Worktrees** left in `.worktrees/` are in-flight or stale claims by definition —
  the same fact `list-claims.sh` reports, visible on the filesystem.

## 6. Failure modes

| Symptom | Cause | Fix |
| ------- | ----- | --- |
| every tick refuses with `origin_unreachable` / `no_origin` | the runner cannot reach the remote | a claim must be pushed to exist; fix the remote/credentials — the loop correctly does nothing until then |
| a unit sits claimed for days, `stale: true` | the runner died mid-run, or the work genuinely stalled | nothing auto-breaks a claim (reclaiming can silently duplicate a colleague's work). Inspect the branch, then either resume it or `release-claim.sh <unit-id>` from the main checkout |
| `already_claimed` in the log | another runner or tick took the unit first | expected; no action |
| `branch_collision` | two runners minted the same second's `work-*` branch name | nothing was claimed; the next tick succeeds |
| a unit reported **demoted to PR** | an `auto` unit hit an overridable gate (size/leak block, no confirmation method, content conflict with `main`) | the demotion is the design — review and merge the PR, or fix the diff and let the next tick re-drive |
| a unit reported **blocked** on a `secret` finding | a credential reached the branch diff | non-overridable: remove the credential from the diff. The branch is already pushed, so treat it as an exposure, not just a gate failure |
| a unit reported **blocked** on a failed production confirmation | the deploy did not verify | the unmerged branch is the rollback; diagnose the deploy, do not force the merge |
| approved missions exist but nothing is claimed | the mission has an empty `## Acceptance` (`no_plan`), **no ticket names it** (`no_tickets` — an acceptance sketch is not a plan; emit the set with `/mission <instruction>`), a claim already holds it (`claimed`), or the mission is still `draft` (`not_approved`) | check `plan-units.sh`'s `excluded[]` — every drop states its reason. The old cause here — "its tickets live in an unmerged worktree" — cannot occur any more: missions and tickets are published to `main` (decision J1) |
| the tick reports nothing to do, but you can see a queued ticket on GitHub | the runner's checkout is behind `origin/main`, so the survey never learned the artifact exists | the freshness step (`sync-main.sh`, `commands/drive.md` step 0) fast-forwards before surveying, and `plan-units.sh` reports `current: false` when it could not. If it keeps reporting `not_on_main` / `dirty_workspace` / `diverged`, the runner checkout is being used for other work — keep it dedicated and reconcile by hand |
| a tick terminates `pending` with `not_on_main` or `dirty_workspace` | the runner checkout is on a branch, or holds uncommitted work | the run refuses to survey a branch rather than surveying the wrong queue. Return the checkout to a clean `main` |
| a tick terminates `pending` with `diverged` | the runner's local `main` has commits the base does not, or the histories parted | a human's call; nothing is merged or reset. `detail` says `local_ahead` or `both_diverged` |
| a `/propose` draft was approved and drives nothing | its `## Acceptance` is a provisional sketch with no tickets behind it | the survey reports `no_tickets` and the mission is not offered; `approve.sh` refuses the same shape. Replan it (`/mission <instruction referencing it>`) to emit the ticket set |
| `claim.sh` refuses with `mission_missing` | the slug is wrong, or the checkout is behind the base | absence is a real error since J1. Run `sync-main.sh`, then re-check the slug against `mission/scripts/list.sh` |
| `{"notified": false, "reason": "no_token"}` on every review unit | env file missing/unsourced in cron | check the `. …/.workaholic-drive.env` prefix and file perms |
| tickets pile up untouched | they carry a `mission:` relation whose mission is not approved | approve the mission, or drop the relation so they become backlog |
