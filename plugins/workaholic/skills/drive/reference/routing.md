# Partition, report, route, account — reference

Companion to [`../SKILL.md`](../SKILL.md) §2, §3, §5, §6, §7: the judgment detail, the Slack-post
contract, the routing mechanics, and the run report's full shape.

## Partition judgment (§2)

- **Group conservatively — when unsure, one ticket per unit.** The failure mode is asymmetric: a
  PR bundling unrelated changes cannot be reviewed as one thing; splitting too finely costs one
  extra PR. Group only on a reason you could state in one sentence in the PR body. `depends_on` is
  the one signal strong enough to group on by itself — a dependent ticket in a separate PR cannot
  merge.
- **Never mix merge policies to force a route.** Batching an `auto` ticket with a `review` one
  does not make the review ticket merge; it makes the auto ticket wait. Policy is not a grouping
  input.
- **Why the choice among units is asked (attended) and the composition never is:** composing a
  unit is derivation over signals the run already read; choosing among peers is a statement about
  what matters today, and only the person present holds it.

## One unit at a time (§3)

Claim a unit, drive it, report it, route it, and only then survey again and take the next — never
claim several up front. An unfinished claim is recoverable only after its heartbeat lapses
(default 30 minutes untouched and invisible to every other runner, plus a resume round trip);
claiming N units up front puts N-1 through that wait. There is **no per-run unit limit** in the
other direction: keep going until the survey offers nothing claimable or the session ends —
for an hourly runner the tick *is* the throughput. Prefer a mission over backlog tickets when
both are offered.

## The threaded Slack posts are `/implement`'s only

The threaded posts exist so an **absent** operator can tell a working fleet from a dead one. A
developer attending a `/drive` session is already watching the run, so **an attended `/drive` run
posts nothing to Slack, at any step** (scoped 2026-08-07). Under `/implement`:

- **Resolve stems (§3):** the start post is retired (2026-08-11) — a unit posts its finish only.
  Still resolve the unit's artifacts to their deduped feedback stems —
  `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/unit-feedback-stems.sh <artifact>...` (a
  mission's `mission.md`, or the batch's ticket files; a mission with empty `feedback:` resolves
  through its queued tickets) — for reuse at the finish.
- **The thread is found, never carried** (Q1, 2026-08-07 — a merged pull request names no
  target, and no body line is read back). Find each stem's thread by the stateless lookup in
  `workaholic:notify` (*One thread per feedback item*): exact-string searches only —
  `fb:<stem>`, then the Issue/PR URL — at most two queries, no full-channel read, and a new
  keyed root when nothing matches; never a similarity or recency match. Resolve the target
  **once per run** and reuse it for the finish.
- **Finish (§6/§7):** one finish line per thread, shape following the outcome — 🟢 Implemented
  (the ordinary case: PR opened and merged, or an open PR a scan finding held), 🚀 Auto Merge,
  🟡 handoff, 🔴 blocked. A handoff's 🟡 **is** the finish, never a third post. Every route owes
  the finish, including a demotion — the unit reports the shape it actually reached. A human
  merge of a `review` unit posts no finish line of its own — that was `[Consent]`'s retired job
  (`workaholic:notify`, *Which thread an `/implement` unit's posts land in*).
- **Per unit, never per run** ("a run started" names no item, so it has no thread); with no stems
  at all, key on `unit:<unit-id>` — never keyless. The routing rules live in
  `workaholic:notify` (*One thread per feedback item*). The posts go through the session's
  Slack connector, are never load-bearing, and a failure to post changes nothing about the claim.

`claim.sh`'s own one-line bot notice (token-gated CLI surface) is a different thing and is not
grown into the threaded post — see [`claims.md`](claims.md).

## Report (§5)

Compose the branch story per `workaholic:report`'s Write Story flow inside the worktree, run the
branch-safety scan (warn tier — findings fold into the PR body, never a prompt), then
`bash ${CLAUDE_PLUGIN_ROOT}/skills/report/scripts/create-or-update.sh <branch> "<title>"`. If
report's context detection misreads inside a claim worktree, scope it explicitly by branch — do
not write a second story generator.

- A PR-creation failure is its own report item; it never changes a unit's outcome classification,
  the reconciliation counts, or the terminal token.
- **A missing `gh` is that item, not a failure of the unit**: `create-or-update.sh` reports
  `{"pr": null, "reason": "gh_unavailable"}` and exits 0 (the cloud container has no GitHub CLI).
  Record `pr_error: gh_unavailable`. The unit is never `blocked` for this — but a unit that was
  going to ship is **demoted to the PR path**, because `merge-pr.sh` cannot merge without the CLI
  either and a run must not report a merge it did not make.

## Routing mechanics (§6)

- **`review` → merge the PR immediately** (mission `auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`,
  2026-08-11, superseding the earlier stop-at-the-PR route): once `/report` has opened the unit's
  pull request and the branch-safety scan verdict is `pass`, merge it (REST
  `PUT repos/{owner}/{repo}/pulls/{n}/merge` with `merge_method: merge`, through
  `gather/scripts/gh-rest.sh` — never the GraphQL-backed `gh pr merge`, which a web session
  may 403) with
  no human confirmation and tear the claim down exactly as `auto` does below — quality is gated
  downstream at the `release/*` QA window, not at merge time. A scan finding is the one thing that
  leaves the PR open instead (there is no human here to override — the demotion doctrine below is
  unchanged). Under `/implement`, post the one `🟢 Implemented` finish line through
  `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/notify-slack.sh "<message with the PR URL>"`
  (never load-bearing: without a token it records `{"notified": false, "reason": "no_token"}` and
  the run continues). Under `/drive` the developer is the human loop — report the URL in the
  session and post nothing.
- **`auto` → ship** through `workaholic:ship`'s Ship Flow with no prompts (its *Unattended
  routing* section factors each interactive seam): catch up with `main`, prove the deploy
  contract, confirm in production, record the evidence, **then** merge, then release and extract
  concerns. A demotion is reported as a demotion, with the gate that caused it — "shipped" and
  "demoted to PR because the size gate blocked" must not blur.
- **Teardown after an `auto` merge** (worktrees are claim-born and ship-torn), from the main
  checkout: `cleanup-mission-worktree.sh <unit-id>`, then `git push origin --delete
  <claim-branch>`. The cleaner refuses a dirty worktree; if it refuses, leave the claim alone and
  report it. The branch delete is hygiene only — the merge already released the claim — so a
  failed delete is a note, not a blocker.
- A mission unit's dev environment, when the project declares one, starts inside the worktree on
  its allocated ports (`mission/scripts/gate.sh` reports `dev_port`) and is stopped at run end
  **if this run started it** — never one it found already running.

## The third route: `land-unit.sh` (§6)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/land-unit.sh <unit-id> --developer-present [--override-scan]
```

`review` publishes a unit but does not make it **claimable**: a ticket minted mid-run sits on the
claim branch, invisible until a human merges the PR out of band. "Wrap this up so a fresh session
can resume immediately" is served by neither run-chosen route, so this composes the sanctioned
steps: catch up with the base in the unit's own worktree (`catchup-main.sh`), run the gates, push
the branch tip onto the base ref, tear the claim's housing down, and fast-forward the landing
checkout so the very next survey offers the leftover tickets.

**The developer is the review, which is why it refuses headless** — two refusals, in this order:

| Refusal | When |
| ------- | ---- |
| `headless_context` | `CLAUDE_CODE_REMOTE=true`, non-empty `CI`, or `WORKAHOLIC_HEADLESS=1`. Checked **first and not overridable by any flag**. |
| `no_developer_instruction` | `--developer-present` absent. The flag is the *instruction*, not a proof of presence — what it buys is that the route is never taken by omission. |

**Neither entry point calls it** — the route exists for a developer typing it in a session. Gates
apply unchanged: `secret` refuses with no override; `size`/`leak` refuse unless `--override-scan`
is passed, reported as `scan_verdict: "overridden"`. Remaining refusals are facts: `not_claimed`,
`worktree_missing`, `dirty_worktree`, `no_origin`/`origin_unreachable`, `catchup_conflict`,
`diverged`. Two mechanics not to re-derive: it pushes the branch tip **onto the base ref**
(`git push origin <branch>:main`) rather than merging into a local `main` (a rejected push after
a local merge leaves the checkout repairable only by the forbidden `git reset --hard`; a
rejection here changes nothing — re-fetch, re-catch-up, retry **once**); and its order is the
inverse of `release-claim.sh`'s — the work lands first, because a failed teardown after a
successful land loses nothing, while tearing down first would destroy the branch still to be
pushed.

## Account and the run report (§7)

**Agent-hours.** Per mission unit, record the run's wall-clock once: mint one run-id per
invocation (a branch-safe timestamp) and reuse it, so a mission driven across several passes
records its time exactly once. The recorder is the **only** writer of `actual_hours` — never
hand-edit the field. Report predicted vs actual per mission unit.

**Handoff.** A handoff unit writes the Handoff section (`workaholic:report`, *Story Content
Structure*), opens or updates its PR with the partial work pushed — an unpublished handoff is not
a handoff — and, under `/implement`, posts the PR URL through the same notifier the `review`
route uses; its 🟡 line is the unit's one finish post. Its tickets stay stamped and stay in
`todo/`, so merging that PR carries a `claim:` onto the base — expected, and history rather than
a claim (M1). Do **not** strip the stamp: the stamp at the tip is what keeps the ticket claimed
while the PR is open. The PR section is the authoritative record; the run report is the log. A
later run resumes exactly this shape — a handoff and a resumption are one story told at two
moments.

**The run report is the deliverable** — always emitted, terminal or not (`workaholic:implementation`
/ `observability`). Before the reconciliation line, state:

- Per unit: members, effective policy, route taken, ticket outcomes reconciling to the queue it
  was handed, and the commits.
- PR per unit — the URL, or the `pr_error` if creation failed.
- Tickets minted mid-run (`deferred`), one line each: what was found, which ticket provoked it,
  the new filename. Additional to the unit's queue; never silent.
- Deferred decisions — every judgment call the run met and recorded instead of asking. This list
  is the QA seam `workaholic:development` / `qa-engineering` requires: the developer's
  looking-through relocates to this report and each unit's PR, never to a mid-run prompt.
- Units the developer deferred at the attended selection, one line each as `deferred_by_operator`
  — naming them keeps a narrowed run distinguishable from a drained queue.
- Units another runner holds, and units the survey excluded with their reasons.
- Stashed partial work and where to find it.
- Predicted vs actual hours per mission unit.
