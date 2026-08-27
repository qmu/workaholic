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
  `workaholic:notify` (*One thread per feedback item*), the transport ordering in the same skill
  (*The transport* — connector primary, tokened script the machine fallback). The posts are
  never load-bearing and a failure to post changes nothing about the claim — but it does change
  the run report, which names the outcome per unit (below).

`claim.sh`'s own one-line bot notice (token-gated CLI surface) is a different thing and is not
grown into the threaded post — see [`claims.md`](claims.md).

## Report (§5)

Compose the branch story per `workaholic:story`'s Write Story flow inside the worktree, run the
branch-safety scan (warn tier — findings fold into the PR body, never a prompt), then
`bash ${CLAUDE_PLUGIN_ROOT}/skills/story/scripts/create-or-update.sh <branch> "<title>"`. If
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

- **The verification axis is read before the merge-policy table** —
  `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/verification-handoff.sh mission <slug>` /
  `… tickets <ticket-file>...`. See *The declared handoff* below.
- **`review` → merge the PR immediately** (mission `auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`,
  2026-08-11, superseding the earlier stop-at-the-PR route): once `/story` has opened the unit's
  pull request, read the scan through `release-scan`'s `gate-decision.sh` — never the raw
  `verdict` — and merge it when that reader says `decision: pass` or `override_only: true` (REST
  `PUT repos/{owner}/{repo}/pulls/{n}/merge` with `merge_method: merge`, through
  `gather/scripts/gh-rest.sh` — never the GraphQL-backed `gh pr merge`, which a web session
  may 403) with
  no human confirmation and tear the claim down exactly as `auto` does below — quality is gated
  downstream at the `release/*` QA window, not at merge time. A `hard` (`secret`) or `confirm`
  (`leak`) finding is what leaves the PR open instead (there is no human here to override — the
  demotion doctrine below is unchanged); an `override_only` scan does **not** hold the merge, and
  its findings are reported in the run report and in the pull-request body `/story` writes.
  The tier, never the binary verdict, is what this route reads — `workaholic:drive` §6 carries the
  measurement that made the distinction load-bearing. Under `/implement`, post the one `🟢 Implemented` finish line with the PR URL on the
  transport `workaholic:notify` selects (*The transport*): the account's Slack connector where the
  session has one — the only surface that can run the thread lookup and reply into a thread — and
  `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/notify-slack.sh "<message with the PR URL>"`
  as the machine fallback for a caller with no connector, which can post a keyed root only. Never
  load-bearing either way: with no surface (or no token — the script records
  `{"notified": false, "reason": "no_token"}` and exits 0) the run continues and **reports the
  notification outcome** in its per-unit report below. Under `/drive` the developer is the human
  loop — report the URL in the session and post nothing.

  **The merge attempt's result is carried into the run report, per unit** (2026-08-27, mission
  `close-the-units-the-loop-already-finished`). This route reported **which route it took** and
  never **whether the merge landed**, so a run refused the merge produced the same line as one
  that merged — measured 2026-08-27, four green units (#622, #625, #633, #635) sitting open with
  `ok` in a report nobody opens. The outcome is one of three, and they are three because they are
  three different next actions:

  | Outcome | What it means |
  | ------- | ------------- |
  | `merged` | the `PUT` succeeded; the claim is released by the merge |
  | `merge_refused: <word>` | the `PUT` was attempted and refused. `<word>` is `merge-reason.sh`'s, unchanged in derivation and format: `merge_not_allowed` / `head_moved` / `session_type_cannot_merge` / `merge_forbidden` / `merge_failed` |
  | `merge_not_attempted: <tier>` | a `hard` (`secret`) or `confirm` (`leak`) finding held the pull request, so no merge was attempted at all |

  **An outcome that is not `merged` is recorded on the branch, not only in the run report**
  (2026-08-27, mission `close-the-units-the-loop-already-finished`): from inside the worktree,
  `bash ${CLAUDE_PLUGIN_ROOT}/skills/story/scripts/record-merge-outcome.sh
  .workaholic/stories/<branch>.md "<outcome>"`, then commit and push it. The run report dies
  with the container, and without a durable answer the claim oracle cannot tell this unit from
  one legitimately waiting on a person — both are drained, both reported, both at an open pull
  request, and `claimed_reported` covered both. The writer is idempotent per outcome and
  replaces rather than stacks, and `lib/claims.sh` reads that one line out of the story blob it
  already fetches: no network call, no second derivation, and it cannot disagree with the run
  that made the attempt. **A merged unit records nothing** — the merge releases the claim, so
  the oracle never sees it.

  **The third is not a merge failure and must never be reported as one.** A scan-held pull
  request is the gate working; a refused one is the loop stopping. Collapsing them would hide
  exactly the failure this row exists to surface, and is the same distinction the `auto` route
  already draws between "shipped" and "demoted to PR, with the gate that caused it" — the wording
  is reused rather than a parallel vocabulary minted for one difference.

  **`session_type_cannot_merge` is the one refusal with a second attempt, and that attempt is a
  step of this route** (2026-08-27, mission `close-the-units-the-loop-already-finished`). It was
  a sentence in `rules/shell.md` and nothing more, so the closing act was one the agent could
  simply not take with nothing anywhere recording that it had not — measured 2026-08-27, four
  pull requests the loop opened on 2026-08-26 green and unmerged, `ok` reported over all of them.
  It is now numbered, mandatory and reported, which is the shape the Open-Decision contract
  already uses for a prose rule no script can enforce ([ticket-workflow.md](ticket-workflow.md)
  §1): no mechanical check tells a real attempt from a claimed one, and what it buys is that a
  report naming no attempt is visibly wrong.

  1. **Precondition, and nothing else.** The REST `PUT` returned `merge_reason ==
     session_type_cannot_merge`. Every other word — `merge_not_allowed`, `head_moved`,
     `merge_forbidden`, `merge_failed` — is reported as-is and **never** retried: those name a
     conflict, a race, a permission or an unclassified failure, none of which a different
     transport fixes.
  2. **One attempt, one tool.** `mcp__github__merge_pull_request`, at most once. No other
     connector tool, no second try, and nothing else moves to the connector — reads, writes and
     pull-request creation stay REST (`rules/shell.md`, *The one qualification*: one named tool,
     one named precondition, one act).
  3. **Report the outcome of that attempt.** `merged` when the connector merged it; otherwise the
     pull request stays open and **both** refusals are named — the REST one
     (`session_type_cannot_merge`) and the connector's own. Reporting the REST refusal after a
     successful connector merge would name a failure that did not happen; reporting only the REST
     one after a failed retry hides that the retry was made.

  **A run that reports `session_type_cannot_merge` and no retry outcome is non-conformant on its
  face.** That is the whole enforcement, and it is deliberate: the rule that a script cannot call
  an MCP tool is what created this step, so a wrapper shelling out to one would be the same gap
  with more moving parts. **A merge through the connector is measured only in an interactive
  session** — a routine container is measured only for the connector's *read* tools — which is
  why step 3 reports both outcomes by name rather than assuming the retry succeeds.
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

## The declared handoff — a unit whose verification cannot run here (§6)

Some work is requested already knowing that an unattended run cannot prove it: the credential,
the device, or the third-party account the verification needs is not in the routine's
environment. Before 2026-08-14 nothing in the run read that, so such a unit drained its queue
like any other, merged on the `review` route, and announced `🟢 Implemented` — a line that says
the work was verified when only the code was written. **The routing path was never the defect;
the missing input was.** `effective-policy.sh` reads `merge_policy` and nothing in the route
table reads a Quality Gate at all, which is exactly why the fix is a second declared field
rather than a smarter router.

**The signal is `verification_handoff:`, optional frontmatter on a ticket or a mission, whose
value is the reason.** Non-empty means "the real-world verification this work needs cannot run
where an unattended run executes", and the value names what cannot run — free text, because an
enum could not say *which* verification is missing and the value is quoted verbatim into the
pull request. Absent or empty is the ordinary route. It is recorded **at creation** by whoever
writes the artifact (`workaholic:create-ticket`, `workaholic:specificate`) and read at route time
by `verification-handoff.sh`; like `merge_policy` it is never edited mid-run — a run that could
declare its own unit unverifiable would have handed itself the soft landing `handoff` is
written never to become. Any member declaring it carries the whole unit, because the unit is
one merge.

**What the run then does**, whatever the merge policy says — `auto` does not outrank it, for
the same reason `auto` has never meant "no gate applies":

| | Declared handoff |
| - | - |
| Merge | **No.** The pull request opens and stays open. |
| Tickets | Archived as `implemented` as usual — the work *is* done. |
| Claim | **Left standing**, so the unit is still owned while it waits. |
| PR body | `## Handoff`, non-droppable, naming the verification verbatim. |
| Finish line | `🟡 Handoff` naming the assignee, never `🟢 Implemented`. |
| Token | `pending` (`../SKILL.md` §7 — `handoff` already forces it). |

**Why this widened `handoff` instead of adding a fourth route** (the ticket's Open Decision,
ruled 2026-08-14 — issue #452). Every consequence in that table is already exactly what
`handoff` produces, and an outcome is defined by its consequences rather than by how it was
reached; a second name reaching the same PR section, the same 🟡 line and the same token would
be two words for one state, and the daily aggregation the ask foresees — "every pull request
currently in the Handoff state" — would have to query both. What the three-condition definition
was protecting is the *soft landing*, and that is preserved by a stricter guard than "queue not
drained": the declaration must exist on the artifact **before** the drive, so no run can reach
this path by giving up. The cost accepted: "half-driven" is no longer a synonym for `handoff`,
so `../SKILL.md` §7 now states two entry paths explicitly rather than three conditions.

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

**Handoff.** A handoff unit writes the Handoff section (`workaholic:story`, *Story Content
Structure*), opens or updates its PR with the partial work pushed — an unpublished handoff is not
a handoff — and, under `/implement`, posts the PR URL through the same notifier the `review`
route uses; its 🟡 line is the unit's one finish post. On the **half-driven** path its undriven
tickets stay stamped and stay in `todo/`, so merging that PR carries a `claim:` onto the base —
expected, and history rather than
a claim (M1). Do **not** strip the stamp: the stamp at the tip is what keeps the ticket claimed
while the PR is open. On the **declared** path (*The declared handoff*) nothing is left in
`todo/` — every ticket archived normally, and what waits is the verification, not the work.
The PR section is the authoritative record; the run report is the log. A
later run resumes exactly this shape — a handoff and a resumption are one story told at two
moments.

**The run report is the deliverable** — always emitted, terminal or not (`workaholic:implementation`
/ `observability`). Before the reconciliation line, state:

- Per unit: members, effective policy, route taken, ticket outcomes reconciling to the queue it
  was handed, and the commits.
- PR per unit — the URL, or the `pr_error` if creation failed.
- **Merge outcome per `review` unit** (2026-08-27): `merged`, `merge_refused: <merge-reason.sh
  word>`, or `merge_not_attempted: <hard|confirm>` when a scan finding held the pull request. The
  three are defined in §6's `review` route above and are never collapsed — a scan-held pull
  request is the gate working, a refused merge is the loop stopping, and reporting the route
  alone made those two identical at the only surface that records the run. An `auto` unit reports
  `shipped` or its demotion exactly as before; this row is the `review` route's equivalent and
  adds nothing to that one.
- **Notification outcome per unit** (`/implement` only — an attended `/drive` posts nothing, so it
  reports nothing): for the one thread the unit posted into, the surface used and the result —
  `posted` with the thread it landed in, or the failure named (`no_surface` when the session has
  neither connector nor token, `no_token` / `no_channel` / `http_<code>` / `slack_<error>` as the
  fallback script reports them, `posted_as_root` when no thread was found and a keyed root was
  started instead). The shape follows `/specificate`'s `notified` flag, which already reports this way.
  **A post that did not happen is stated, never omitted**: silence in this list read as success is
  the whole defect (measured 2026-08-12, issue #406 — the 18:48 UTC `[Implement]` run got
  `{"notified": false, "reason": "no_token"}` and nothing downstream said so).
- **Missions closed at the archive gate** (2026-08-23), one line each: the slug, the accepted count,
  and that the queue was empty. `archive.sh` closes a mission `achieved` — through `close.sh`, the
  only writer of an end state — when archiving a ticket leaves its acceptance fully checked
  (`progress.sh`) and nothing queued (`queue-size.sh`). Only `achieved`, because it is the one of
  the three outcomes that is arithmetic; `abandoned` and `carried` assert intent and stay the
  operator's. **A refusal from `close.sh` is reported by name**, never swallowed: a mission that
  could not be closed must not read as one that was. A mission failing any part of the proof is
  untouched and the run says nothing about it.
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
