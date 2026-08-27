# The survey — reference

Companion to [`../SKILL.md`](../SKILL.md) §1. Full contracts for the three survey scripts and the
trustworthiness vocabulary.

## The install check (`check-deps/scripts/check.sh`)

Two drift axes with different consequences (full field semantics: `check-deps`):

- **`loaded_version_behind_registry: true` is a WARNING** (2026-08-12, the developer's ruling)
  — report `version`, `registry_version`, and the `source`/`degraded` that `plugin-src.sh`
  chose, then continue. It was a hard stop until the loop it protected stopped running at all:
  the drift it names is real (a stale `claims.sh` once called five already-driven tickets fresh
  backlog and claimed one — a double-pick reaching a pushed ref, 2026-08-04), but the property
  that matters is *which scripts this run actually executes*, and §1 now answers that directly
  by resolving the newest tree on the machine before the check runs. A run whose `src` is at the
  registry's version is not running stale code, so terminating on the *binding* punishes the run
  for a fact it has already routed around. Treat `registry_unreadable: true` and the absence of
  the field the same way. Measured cost of the old rule (2026-08-12): the cloud container binds a
  **project-scope** install baked into its image (v1.0.133) while the SessionStart bootstrap runs
  `claude plugin update`, which reports "for scope user" and updates only the **user**-scope entry
  (v1.0.159) — the bound pin is never touched, and since every tick is a fresh container off that
  same image the gate fired hourly and could not self-heal. Twelve consecutive `[Implement]` ticks
  terminated before surveying while three claimable tickets sat in `todo/`.
- **`no_plugin_source` from `plugin-src.sh` is the STOP that replaces it** — no checkout, no
  registry install path, no clone and no binding carries a plugin tree, so the run cannot read its
  own workflow. This is the honest form of the old stop: not "the binding is dated" but "there is
  nothing to run".
- **`version_drift: true` is a warning** — name `version` (installed) and `checkout_version` in
  the run report and continue. It is the most useful line in the report when a tick later dies on
  `dirty_workspace` (an installed build running an obsolete always-on migration is what dirties
  the tree). Note the check runs **before** the fast-forward, so a clone behind the base can show
  a falsely-matching pair on this tick and the real drift on the next.
- **`unbound_in_claude_session: true` is a warning, not a stop** (2026-08-10, ticket
  `20260810090005`, generalizing the developer's live correction recorded in FB `20260810070110`) —
  this is `/drive`'s instance of the general unbound-skill-surface fallback rule
  (`plugins/workaholic/rules/general.md`); the concrete detail below is specific to the survey step.
  A genuine Claude Code session (`CLAUDE_CODE_SESSION_ID` present) where the harness's own registry
  confirms this plugin is installed, yet no plugin root was ever bound: every skill, command and
  hook the plugin ships is invisible to the Skill/Command tool abstraction for the whole run. FB
  `20260807104046` measured this on a fresh-install `[Implement]` run — `session-start.sh` installed
  the plugin and printed the developer-facing `/reload-plugins` reminder, but the very next
  `Skill(...)` call failed `Unknown skill: drive`. There is no fix inside the plugin:
  Claude Code exposes no supported mechanism to make a SessionStart-time install effective
  mid-session other than a human typing `/reload-plugins`
  (https://code.claude.com/docs/en/plugins-reference.md#plugin-updates-and-caching), and an
  unattended routine never types it — but unlike the superseded-binding axis above, the *scripts*
  are not stale here: only the Skill/Command binding is missing, and the plugin's own scripts under
  `plugins/workaholic/skills/` stay directly runnable via `bash` from the checkout path, with the
  PreToolUse safety hooks registered and active independent of that binding (the developer's live
  correction, FB `20260810070110`: "the plugin's own scripts stay runnable via Bash from the
  checkout, and the safety hooks stay active, independent of whether the Skill/Command tool binding
  itself resolved — so refusing to survey at all is disproportionate to what is actually broken").
  Name the condition and its values in the run report and continue, invoking every remaining script
  in this run on its checkout-relative path rather than `${CLAUDE_PLUGIN_ROOT}` (which resolves to
  nothing when unbound) — reading the checkout directly carries none of the staleness risk
  `loaded_version_behind_registry` names above, since there is no cached binding to be behind.
- `ok: false` → print the `message` and stop. Non-empty `missing_guards` → warn, continue, and
  record it in the run report — it matters most here because this run commits, pushes, and may
  merge without a human in the loop.

## The freshness step (`branching/scripts/sync-main.sh`)

Artifacts are published to `main` but the survey reads *this working tree*, and nothing else in
the run fast-forwards it — a runner behind `origin/main` surveys yesterday's queue and reports it
confidently (decision J3). Each `ok: false` is a reported decision, never a prompt:

| reason | what the run does |
| ------ | ----------------- |
| `no_origin` | Survey the local tree, say so, continue. The terminal token may not be `ok`. |
| `not_on_main` / `dirty_workspace` | Not a surveyable state. Report the reason, terminate `pending` — never silently survey a branch. **Narrowed 2026-08-12**: a checkout parked off the base entirely but standing on the base's **exact tip** with a **clean tree** no longer refuses — `sync-main.sh` §1a returns `ok: true` with `off_base: true` and the parked `branch`, because the tree it is about to survey is byte-identical to the one it would survey on the base. Report `off_base` in the run report; it is not a stop and does not by itself forbid `ok`. Every way that proof fails — dirty, ahead, divergent, no origin — still refuses `not_on_main` unchanged. **Sequel 2026-08-18** (tickets `20260818070000` / `20260818075500`): "behind" left that list. §1a admitted the container's checkout only while it stood on the *exact* tip, so a run that **merged** its first unit advanced the base out from under itself and every later freshen in the same run refused — an `/implement` tick drove at most **one** PR-unit, penalised precisely for succeeding, while the survey went on offering the ticket the run had just archived. `sync-main.sh` §1b now **fast-forwards** the one shape that provably holds nothing to lose: a **detached**, clean HEAD that is a strict **ancestor** of the base tip. It rides `ok: true` with `advanced: true`, `fast_forwarded: true` and `previous_sha`, so the run reports that the checkout **moved** rather than implying it never needed to. A **named** off-base branch that is behind is a developer's branch and still refuses — moving it would rewrite a ref a person created. |
| `origin_unreachable` | Like `no_origin`: survey locally, say so, token may not be `ok`. |
| `diverged` | A human's decision (`detail`: `local_ahead` / `both_diverged`). Report, terminate `pending`. Never merge or reset. One divergence is *not* a human's: a base branch carrying **no local commits at all** (a single creation entry in its reflog) that parted from origin only because upstream history was rewritten under it. `sync-main.sh` realigns that one itself and returns `ok: true` with `realigned: true` and a `backup_ref` holding the old tip — report it, do not treat it as a stop. |

## The survey (`drive/scripts/plan-units.sh`)

Emits `{fetched, shallow, base, surveyed_sha, base_sha, current, user_slug, backlog_error,
backlog_size, owner_unresolved, claimed[], resumable[], resurveyed[], missions[], backlog[],
excluded[], backlog_all_excluded}`,
each backlog row `{path, title, merge_policy, depends_on, mission_closed}` —
the unclaimed active missions this runner may take and the unclaimed todo tickets, with
everything a claim already holds subtracted through the shared claim reader.

**`excluded[]` names every drop and why**: `claimed_active`, `claimed_reported`,
`claimed_by_other`, `claimed_resumable`, `claimed_superseded`, `owned_by_other`, `no_plan`,
`no_tickets`, `queue_drained`, `mission_member`. **`claimed_superseded`** (2026-08-26) names a
claim with nothing in it: the unit's work already reached the base — every one of its tickets
archived there, or (at the mission grain) a merged pull request with that branch as its head —
so the branch is unmerged forever and holds no work. It is reported and never acted on —
nothing deletes the branch or closes its pull request — and it does **not** forbid `ok`.

**`resurveyed[]` is what the survey stepped OVER, and it has its own field for a reason**
(2026-08-26). A claim proved empty must not hold its work either, so the queued tickets behind
a `superseded` claim — and the mission they belong to — are offered again as ordinary backlog.
`excluded[]` is the wrong home by its own definition (it names what the survey saw and
*dropped*), so each freed unit is reported as `{kind, id, claim}` instead, naming the dead claim
branch: **a unit that came back is never mistaken for one that was never claimed.** This frees
the work and does not revive the branch — the claim row stays `superseded` and
`resumable: false`, and a run takes the freed tickets on a **fresh** claim, because the old
branch cannot land. Every other reason still excludes: `claimed_active` is being driven now,
`claimed_by_other` is not this runner's, `claimed_reported` waits on a human, and
`claimed_resumable` is taken over rather than re-claimed. Measured: a mission sat `active` at
2/3 acceptance with queued tickets behind a claim whose pull request had merged five days
earlier, and no survey would offer any of it. It does not read `status` for the offer — a mission on `main`
was accepted when its pull request merged (K1); the area is the authority. `no_plan`,
`no_tickets`, and `queue_drained` are deliberately distinct because each names a different next
action: write the acceptance criteria, emit the ticket set, or decide the close — a mission whose
every ticket was driven and archived is finished, not unplanned.

**`mission_member` is a premise with an expiry, and its repair is an annotation, not a reason**
(2026-08-12, qmu/workaholic#382). The exclusion says "this ticket arrives inside its mission's
unit instead", and only `missions/active/` yields units — so once the last mission a ticket names
has closed, the premise is false and the ticket was offered by *neither* path: it stayed in
`todo/` while the queue read as drained rather than as broken (six tickets unreachable for weeks
in one repository, five of them genuinely open work). A ticket is now excluded `mission_member`
only while **at least one** mission it names is still active — the test is ANY, not ALL, so a
ticket naming one live mission and one closed one is still a member and is never double-offered.
Liveness is asked of `mission/scripts/read-active-relation.sh`, a pure reader beside
`read-relation.sh` whose contract is untouched; it keys on the **area**, so a `status: draft`
mission still in `active/` counts as alive and `/specificate`'s safety property (a ticket proposed
under a not-yet-driven mission is unclaimable) holds unchanged. A ticket whose missions have all
closed appears in **`backlog`** carrying `mission_closed` — the closed slugs that used to suppress
it. It is deliberately not an `excluded` reason: `excluded[]` means the survey saw an item and
dropped it, and a repaired ticket is offered, so recording it there would state the opposite of
what happened. A dangling slug reads as closed for the same reason — a mission that resolves
nowhere in this tree cannot offer the ticket a unit either.

**Ownership.** Every artifact is offered by ownership — a ticket exactly as a mission (P2,
2026-08-06). Claimable = this runner's `git config user.email` is among the owners, or there are
no owners at all (team-owned); owned solely by others = `owned_by_other`. Resolution goes through
`gather/scripts/owns.sh` over `gather/scripts/owners.sh` — the same oracle every other ownership
consumer reads — so the queue a runner drains and the roadmap a developer sees cannot disagree.
The claim protocol's identity use is unchanged: claim authorship and resumption key on
`git config user.email` and fail loudly without one.

**Trustworthiness fields.** An unreadable backlog is not an empty one. These are top-level keys,
not `excluded[]` entries, because `excluded[]` names items the survey saw and dropped:

| field | meaning |
| ----- | ------- |
| `current` | the surveyed checkout matches the base. `false` **forbids `ok`** — the survey never learned what exists. The survey states its freshness and does not repair it: the script must stay a side-effect-free reader (it runs inside claim worktrees too); the repair is the caller's `sync-main.sh`. |
| `shallow` | `true` = the claim scan ran over truncated history (a shallow clone whose origin was unreachable, so it could not deepen). **Forbids `ok`** on a different axis from `current`: "can I tell which branches reached the base at all". See [`claims.md`](claims.md). |
| `backlog_error` | `""` when the queue was read; `unreadable` otherwise. **Forbids `ok`** — a run that never learned the queue's contents has established nothing about it. |
| `backlog_size` | ticket count before filtering — what makes *nothing for me* and *nothing at all* distinguishable from outside. |
| `backlog_all_excluded` | `{excluded, backlog_size, reasons[{reason, count}]}` — a **derived reading** over the fields above: the queue holds tickets, the survey offers none of them, and something was excluded. Reported by both entry points' run reports so *the queue is empty* and *the queue is full and I can offer none of it* never render alike. The **per-reason counts** are what make it actionable — a queue emptied by claims is the protocol working, one emptied by `owned_by_other` is work nothing can drive. A genuinely empty queue (`backlog_size: 0`) and a survey offering some of its backlog both read `excluded: false`. It is a top-level key rather than an `excluded[]` entry for the reason `resurveyed[]` is: `excluded[]` names what the survey saw and *dropped*, and this drops nothing of its own. **It moves no token** — whether it forbids `ok` belongs to the mission that owns §7's table, and two missions editing one table is how a table stops meaning one thing. Measured 2026-08-26: `backlog_size: 10`, `backlog: []`, `owned_by_other` x7, reported `ok` hourly for five days. |
| `owner_unresolved` | the queue **was** read but this runner has no identity to judge ownership against: unowned artifacts are still offered, owned ones excluded as `owner_unresolved`. **Forbids `ok`** but does not terminate the run. (`identity_unresolved` left this vocabulary with the per-user directory layout, P2.) |

`fetched: false` means origin was unreachable and the claim set is the last-known one — survey
anyway, but expect the claim step to refuse: the reader degrades offline, the writer does not.

## The resumable offer — three tiers

`resumable[]` is a third offer, not a report. Its members are already stamped and partly driven,
so a takeover (`claim.sh resume <unit-id>`) skips steps 2-3. Read each row's `resume_reason`:

- **`heartbeat_lapsed`** — a run that died mid-drive. Take it over **before claiming anything
  fresh**; left untaken it **forbids `ok`** exactly as an unclaimed ticket does. Enters at
  **step 4**: its remaining tickets are whatever is still in `todo/` on that branch.
- **`report_incomplete`** — a run that died **between step 4 and step 5**: every ticket archived
  and pushed, no story at the tip and therefore no pull request. Equally **mandatory**, and left
  untaken it **forbids `ok`** — nothing is waiting on a human here, because no human was ever
  told the work exists. Enters at **step 5**, with an empty queue: write the story, run the scan,
  open the pull request, route normally at step 6. It re-drives no archived ticket.
- **`parked_with_pr`** — a unit that reached its PR and has follow-up work on its branch (its
  story file is committed at the tip). Legitimately resumable but **reportable rather than
  mandatory**: it does not outrank fresh work and does not forbid `ok` when left untaken. (The
  mandatory reading was measured humanly wrong — an attended run spent ~40 minutes reopening a
  PR the developer considered parked while their actual WIP waited, 2026-08-05.) Enters at
  **step 4** for the follow-up tickets.

All three tiers are takeovers, never fresh claims: resuming continues from the pushed branch tip.

**The third tier narrows the drained gate; it does not reverse it.** A drained queue used to be
one word (`queue_drained`, `resumable: false`) whatever the branch carried, so a unit that
reported and one that died before reporting were equally untouchable — and the second was
reachable by nothing at all, since its tickets were excluded `claimed_reported` at every later
survey too. Measured 2026-08-19 on this repository: `batch-20260819063000` had two tickets
archived and pushed at 06:48 UTC with no story and no pull request, and the four `[Implement]`
ticks that followed each surveyed a clean, current checkout, found `missions: []`, `backlog: []`,
`resumable: []`, and drove nothing while that work sat undelivered. The signal is the story file
`/story` commits when it opens the pull request — the same offline check `parked_with_pr` already
read one branch below — so a unit that **did** report keeps `queue_drained` and stays a human's
business, which is exactly what the 2026-08-01 fix protects.
