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
  `bash ../drive/scripts/unit-feedback-stems.sh <artifact>...` (a
  mission's `mission.md`, or the batch's ticket files; a mission with empty `feedback:` resolves
  through its queued tickets) — for reuse at the finish.
- **The thread is found, never carried** (Q1, 2026-08-07 — a merged pull request names no
  target, and no body line is read back). Find each stem's thread by the stateless lookup in
  `notify` (*One thread per feedback item*): exact-string searches only —
  `fb:<stem>`, then the Issue/PR URL — at most two queries, no full-channel read, and a new
  keyed root when nothing matches; never a similarity or recency match. Resolve the target
  **once per run** and reuse it for the finish.
- **Finish (§6/§7):** one finish line per thread, shape following the outcome — 🟢 Implemented
  (the ordinary case: PR opened and merged, or an open PR a scan finding held), 🚀 Auto Merge,
  🟡 handoff, 🔴 blocked. A handoff's 🟡 **is** the finish, never a third post. Every route owes
  the finish, including a demotion — the unit reports the shape it actually reached. A human
  merge of a `review` unit posts no finish line of its own — that was `[Consent]`'s retired job
  (`notify`, *Which thread an `/implement` unit's posts land in*).
- **Per unit, never per run** ("a run started" names no item, so it has no thread); with no stems
  at all, key on `unit:<unit-id>` — never keyless. The routing rules live in
  `notify` (*One thread per feedback item*), the transport ordering in the same skill
  (*The transport* — connector primary, tokened script the machine fallback). The posts are
  never load-bearing and a failure to post changes nothing about the claim — but it does change
  the run report, which names the outcome per unit (below).

`claim.sh`'s own one-line bot notice (token-gated CLI surface) is a different thing and is not
grown into the threaded post — see [`claims.md`](claims.md).

## Report (§5)

Compose the branch story per `story`'s Write Story flow inside the worktree, run the
branch-safety scan (warn tier — findings fold into the PR body, never a prompt), then
`bash ../story/scripts/create-or-update.sh <branch> "<title>"`. If
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
  `bash ../drive/scripts/verification-handoff.sh mission <slug>` /
  `… tickets <ticket-file>...`. See *The declared handoff* below.
- **`review` → merge the PR immediately** (mission `auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`,
  2026-08-11, superseding the earlier stop-at-the-PR route): once `/story` has opened the unit's
  pull request, read the scan through `release-scan`'s `gate-decision.sh` — never the raw
  `verdict` — and merge it when that reader says `decision: pass` or `override_only: true` (REST
  `PUT repos/{owner}/{repo}/pulls/{n}/merge` through `gather/scripts/gh-rest.sh` — never the
  GraphQL-backed `gh pr merge`, which a web session may 403 — carrying **three read, never
  spelled** fields: `merge_method` from `gather/scripts/merge-method.sh` (it answers `squash`),
  and `commit_title` / `commit_message` from `gather/scripts/merge-commit-body.sh`. Without the
  last two the forge concatenates every commit on the branch into the trunk's record, which is
  how the claim stamp and the heartbeats reached `main` — measured, 48 such squash bodies here,
  the longest 11,515 lines. A composer answering `unreadable:<reason>` still yields a fallback
  body, so the merge is **never held on it**; its `source` is reported beside the merge outcome
  and moves no token) with
  no human confirmation and tear the claim down exactly as `auto` does below — quality is gated
  downstream at the `release/*` QA window, not at merge time. A `hard` (`secret`) or `confirm`
  (`leak`) finding is what leaves the PR open instead (there is no human here to override — the
  demotion doctrine below is unchanged); an `override_only` scan does **not** hold the merge, and
  its findings are reported in the run report and in the pull-request body `/story` writes.
  The tier, never the binary verdict, is what this route reads — `drive` §6 carries the
  measurement that made the distinction load-bearing. Under `/implement`, post the one `🟢 Implemented` finish line with the PR URL on the
  transport `notify` selects (*The transport*): the account's Slack connector where the
  session has one — the only surface that can run the thread lookup and reply into a thread — and
  `bash ../specificate/scripts/notify-slack.sh "<message with the PR URL>"`
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
  `bash ../story/scripts/record-merge-outcome.sh
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

  **A LATER run re-attempts a unit an earlier one could not deliver** (2026-08-27, mission
  `deliver-and-retire-what-the-loop-already-proved-finished`). Everything above covers the run
  that made the attempt. Nothing covered the hour after: `plan-units.sh` excluded the unit
  `claimed_undelivered` at every later survey and `claim.sh resume` refused it by its own name,
  so the unit was delivered by nobody until a human opened the pull request. Naming the state
  (2026-08-27) made it visible and left it unreachable — measured 2026-08-26, four green pull
  requests still open a day later.

  **AND THE BASE MAY HAVE MOVED UNDER IT** (2026-08-29, mission
  `land-the-loop-s-own-work-when-the-base-moves-under-it`). The retry re-attempts the *merge*,
  which is the right act for a refused transport and no act at all for a base that has moved:
  GitHub refuses the same merge every hour, forever, and no other reader looked either —
  `/moderate`'s `merge-conflicts` step reports the pull request and says in its own header that
  it never rebases. Measured 2026-08-29: 4 of 7 open pull requests conflicting with `main`,
  three of them units recorded `report_undelivered` two days earlier, with 4 active missions and
  10 queued tickets behind them.

  So each entry gets a catch-up **first**, once, never a loop:

  ```bash
  bash ../drive/scripts/catch-up-claim.sh <unit-id>
  ```

  It merges the base into the claim branch **in the unit's own worktree** — never a rebase, an
  amend or a force-push, because a merge commit keeps the claim holder's checkout valid — then
  regenerates the derived files with the repository's own tooling, runs its fast checks and
  pushes. Three outcomes: `caught_up`, `already_current` (the branch already contains the base;
  no worktree, no merge, no ref touched) and `catch_up_refused: <word>`. Every refusal writes
  nothing and leaves the branch byte-identical, and each has its own word — `content_conflict`,
  `not_my_claim`, `foreign_identity`, `identity_unresolved`, `claim_active`, `dirty_worktree`,
  `scan_held:<tier>`, `not_a_work_branch`, `ambiguous_claim`,
  `mergeability_unanswerable:<reason>`, `validation_failed:<check>`, `push_failed`.

  **It overrides no gate and resolves no judgement.** A `content` conflict is a person's, and
  is reported by the act's own report — `/implement` names `catch_up_refused: content_conflict` with the colliding files where the attempt happened, and **no step asks anybody about it** (`catchup-blocked` retired 2026-09-02); a scan-held
  pull request is refused by name; a colleague's claim is untouchable at any age; a branch a run
  is still committing to is left alone. This **narrows** the standing rule that resolving a
  conflict on a claimed branch is nobody's job here — to the mechanical case, on this identity's
  own claim, with the contested case still a person's ([claims.md](claims.md)).

  Then, and **only on `caught_up`**, the delivery — a refused catch-up produces no retry, because
  the refusal is the outcome:

  ```bash
  bash ../drive/scripts/retry-undelivered.sh <unit-id> --own-tip
  ```

  `--own-tip` is passed **only** immediately after this run's own `caught_up`. The catch-up's
  push makes the tip fresh, so the next verdict reads `claim_active` and the delivery the
  catch-up exists to unblock would be refused by the act that unblocked it. The flag relaxes
  that **one term**, by re-asking the same oracle with `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0`
  — every other term stays the oracle's own answer, computed in one place, and the scan-held
  refusal is untouched. Without the flag the script is byte-identical to what it always was:

  ```bash
  bash ../drive/scripts/retry-undelivered.sh <unit-id>
  ```

  It **drives nothing**: the unit's queue is drained and every ticket is archived and pushed, so
  there is no work to do and no ticket to re-claim, and a takeover would push an empty `Resume`
  commit onto a branch whose pull request is open (the 2026-08-01 gate). No branch, no worktree,
  no claim; one `PUT .../merge` on a pull request the loop itself opened, through the same REST
  seam that refused it.

  **Two gates, and both refuse by name.** The verdict must be `report_undelivered` — one of the
  two the claim protocol classifies as a **proof** ([claims.md](claims.md), *Proofs and
  judgements*), where the refusal is recorded on the branch rather than inferred — so every other
  verdict returns `not_undelivered:<verdict>` and `queue_drained` is never widened into it. And
  the recorded outcome must be a refusal: `merge_not_attempted: <tier>` returns
  `scan_held:<tier>` and is never attempted. The second gate is redundant by construction (a
  scan-held unit's recorded outcome routes the chain to `queue_drained`, so it never reaches the
  verdict) and is kept anyway — the cost of the check is a string compare, the cost of its
  absence is an unattended merge past a secret finding.

  **The new outcome replaces the old one on the branch.** A still-refused unit keeps a *current*
  answer to "why is this pull request still open", because that word feeds the next survey's
  report and `/moderate`'s question and a stale one sends a reader after the wrong transport.
  There is no worktree to commit from, so the story blob is fetched, handed to
  `record-merge-outcome.sh` (still the one writer of that section's format) and committed back
  with plumbing against a scratch index — nothing is checked out and the caller's index and
  working tree are untouched. An unchanged outcome writes nothing; a **merged** unit records
  nothing, because the merge releases the claim. Recording is never load-bearing: a failed record
  is reported and never turns a landed merge into a failure.

  **A `session_type_cannot_merge` from the retry takes the same numbered connector step**, on the
  same bounds — the script reports the word and stops, because no script may call an MCP tool.

  **A run that reports `session_type_cannot_merge` and no retry outcome is non-conformant on its
  face.** That is the whole enforcement, and it is deliberate: the rule that a script cannot call
  an MCP tool is what created this step, so a wrapper shelling out to one would be the same gap
  with more moving parts. **A merge through the connector is measured only in an interactive
  session** — a routine container is measured only for the connector's *read* tools — which is
  why step 3 reports both outcomes by name rather than assuming the retry succeeds.
- **AND EVERY OTHER REPORTED CLAIM THIS RUN CAN STILL CATCH UP** (2026-08-30, mission
  `catch-a-reported-claim-up-before-its-conflict-hardens`). The block above walks
  `undelivered[]`, which is a **delivery** verdict — so the catch-up, whose whole subject is
  whether the *base* still accepts a branch, ran only on units the *transport* had refused. A
  `queue_drained` claim is the other half of the same shape: finished, pushed, at an open pull
  request, waiting on a person — and its conflict hardens from `mechanical` to `content` while
  nothing looks. `/moderate` used to **ask** about both verdicts; only
  the acting side was narrow. Measured live: one claim mechanical for four days, another content
  for twelve.

  ```bash
  bash ../drive/scripts/list-catchable-claims.sh
  ```

  It composes `list-claims.sh` — one walk of the refs, never a second oracle — and answers this
  identity's **reported** claims (`report_undelivered` **or** `queue_drained`) whose
  `mergeability` is **`mechanical`**, resolved through the live-row rule. `clean` is
  deliberately not a candidate (nothing to catch up), `content` is a person's, and
  `unanswerable` is the absence of a reading. A **degraded** scan yields no candidates, its
  reason and **null** counts — never a bare empty set, which is byte-identical to a healthy
  quiet run.

  Run `catch-up-claim.sh <unit-id>` **once per candidate**, never batched and never retried
  inside the run: a refusal is reported, not worked around. **A unit in both sets is caught up
  once** — the `undelivered[]` loop takes it, because that loop must catch up *before* its
  retry, and the outcome is reported there; this walk skips any unit that loop already named. A
  second run over the same unit would answer `already_current` and cost a worktree for nothing.

  **Both entry points walk it.** The Unified Run shares every step below §2, the act asks
  nothing and needs no ruling, and a `content` conflict is refused rather than put to the
  operator — so an attended `/drive` run behaves identically here and simply reports the
  outcomes in the session.

  **The writer is untouched by this.** `catch-up-claim.sh` re-derives its own verdict at the
  moment of the act and applies its own bounds, which is exactly why widening the *caller* is
  safe — the rule that makes it safe is written down once in [claims.md](claims.md), *When a
  bounded act may read a judgement*. Nothing about the survey, the claim oracle, any gate or any
  token moves: **no route, demotion, claim, merge, survey, refusal or sort reads this set**, and
  a run with no candidates behaves byte-identically to one before the widening existed.
- **`auto` → ship** through `ship`'s Ship Flow with no prompts (its *Unattended
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
writes the artifact (`create-ticket`, `specificate`) and read at route time
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
| Finish line | `🟡 Handoff` naming the assignee, never `🟢 Implemented`. The name is a **resolved `<@U…>`** since 2026-08-31 (mission `notify-the-person-a-directed-question-addresses`) — from the unit's own `assignees` through `gather/scripts/identity.sh`, **omitted rather than guessed** when the address does not resolve — and it rides the **bot** when that addressee is the posting identity, per `notify`, *Which transport carries which shape, and why*. This row has read *naming the assignee* since 2026-08-14; between 2026-08-23 and then the shape carried no token at all, so the line named nobody. |
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
bash ../drive/scripts/land-unit.sh <unit-id> --developer-present [--override-scan]
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

**Handoff.** A handoff unit writes the Handoff section (`story`, *Story Content
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

**The run report is the deliverable** — always emitted, terminal or not (`implementation`
/ `observability`). Before the reconciliation line, state:

- **The base's own reading, first and once** (2026-08-27, mission
  `read-whether-the-base-survived-what-the-loop-merged`): `green`, `red` — naming the attributed
  merge (commit, pull request, author) and the failing checks, or `unattributable` with its
  reason — or `unanswerable` with the reader's own reason. It sits **before** the per-unit
  outcomes because it is context for everything that follows rather than an outcome of any one
  unit, and it is read **once per run**: one fact about the repository, where a per-unit read
  would spend N calls to say the same thing. A degraded read is reported as degraded and **never
  as green**. **It moves no token and gates nothing** — see §7's table row and §1.
- **How long each standing blocker has been standing, once** (2026-08-30, mission
  `say-how-long-the-loop-has-been-stuck`): for each subject this report already names — an
  undelivered unit, a stalled claim, a blocked retirement, a queued artifact nothing can drive —
  `moderate/scripts/condition-age.sh --key <subject-key>` answers `age.ticks` ticks since
  `age.first_seen`, *at least* that when `age.first_seen_is_floor`. Read **once per run**, on the
  ground the base's reading above stands on. What it answers is the age of the **question**, a
  lower bound on the age of the condition, so the report says *asked about since* and never
  asserts how long the subject itself has been stuck. A subject nobody has been asked about yet
  reads `first_seen: null` and nothing is said about its age — an ordinary absence. A
  `readable: false` reading is named **as unreadable, by its reason**, and never as *nothing
  standing*. **It moves no token and gates nothing** — §7's table gains no row for it, and no
  route, demotion, claim, merge, survey, refusal or sort reads it.
- **A race this run met, with BOTH branches** (2026-08-30, mission
  `stop-two-runs-from-claiming-and-driving-one-unit`): a run whose `archive.sh` refused
  `claim_taken_over` or `ambiguous_claim` at the first write the base would see has lost a race,
  and names the unit, both branches and the refusal it got — rather than reporting it as one
  ordinary refusal among others, which is how the measured hour of duplicated implementation
  went unrecorded. **Neither branch is picked**: that is `ambiguous_claim`'s standing everywhere
  in the protocol. The loss is detected at the archive re-check rather than at the claim push
  because a fresh claim's push arbitrates nothing and the arbitration that would fix it is
  refused by this container's transport (`claims.md`, *What the claim contends for*). **It moves
  no token and gates nothing** — the run wrote nothing and the protocol worked; the claim
  holders are reached by `/moderate`'s `raced-unit:<unit>` question.
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
- **Catch-up outcome per `undelivered[]` entry** (2026-08-29, mission
  `land-the-loop-s-own-work-when-the-base-moves-under-it`): one of three words — `caught_up`,
  `already_current`, `catch_up_refused: <word>` — **beside** the delivery outcome below rather
  than inside it. A catch-up and a merge are different acts: one moves the branch, the other
  moves the pull request, and collapsing them would leave a reader unable to tell a unit the
  loop could not reconcile from one the transport would not merge. A **fourth** word for
  *caught up and then delivered* is refused for the opposite reason — that is two facts, and
  two vocabularies already report them. **A run that names an entry and reports no catch-up
  outcome for it is non-conformant on its face**, the retry row's enforcement for its reason.
  **No artifact gains a `caught_up` field**: the branch carries the merge commit and this report
  carries the reading, so a field would be a third store of a fact two places already hold.
  **`catch_up_refused: content_conflict` moves no token** — the `claimed_awaiting_verification`
  precedent, written down here so it is not re-derived: a unit waiting on a person's judgement
  is the gate working, and making it `pending` would put `ok` out of reach on exactly the runs
  where the machinery did its job. Every other refusal moves no token by itself either; what
  withholds `ok` is the unit's *delivery* outcome, which a refused catch-up leaves unchanged.
- **And the same three words per `list-catchable-claims.sh` candidate** (2026-08-30, mission
  `catch-a-reported-claim-up-before-its-conflict-hardens`): one line each — the unit, and one of
  `caught_up` / `already_current` / `catch_up_refused: <word>`, the word being
  `catch-up-claim.sh`'s own, **verbatim**. A normalised word sends a reader to a string no
  script printed. **The same three words, never a second set**: the outcome of a catch-up on a
  `queue_drained` claim and on a `report_undelivered` one are the same kind of fact, and two
  vocabularies for one fact is how the two drift. **A run that names a candidate and reports no
  outcome for it is non-conformant on its face** — the retry row's enforcement, for its reason:
  no mechanical check tells a real attempt from a claimed one, and what the rule buys is that a
  silent report is visibly wrong. One line per candidate and no per-claim block: the steady
  state is zero candidates and the interesting case is one or two. **It moves no token and gates
  nothing** — the `content_conflict` reasoning above applies unchanged, and every other refusal
  leaves the unit's *delivery* outcome exactly where it was. **No artifact gains a field.** A run
  with no candidates reports nothing new.
- **Each reported claim's `mergeability`, off the row the oracle already renders** (2026-08-30,
  the same mission): one word per **reported** claim — `clean`, `mechanical`, `content`, or
  `unanswerable` **as unanswerable, by its reason**. A claim decaying from `mechanical` to
  `content` is the moment the loop's own work becomes a person's, and until this it was visible
  only *after* the decay, when `/moderate`'s question fired. Naming the class makes the decay
  visible the hour it happens. **Nothing is derived**: `list-claims.sh` renders `mergeability`
  and `mergeability_reason` on every row and the run has already made that scan, so this costs
  no network call and no second walk. Rendering `unanswerable` as `clean` is the one collapse
  that must not happen — it makes a decaying claim look healthy. Bounded to **reported** claims:
  naming the class for every claim on every tick turns the report into a claim table, and the
  fact is actionable only where the unit is finished and waiting. **Evidence, never a verdict**
  — no gate, sort, claim, route, demotion or token reads it, the standing this repository gives
  `pace`, `overdue`, `expiring`, `arrived` and the base's own health.
- **Retry outcome per `undelivered[]` entry** (2026-08-27, mission
  `deliver-and-retire-what-the-loop-already-proved-finished`): the unit, the **recorded refusal it
  was retrying**, and the **new outcome** in §6's existing three words — `merged` when the retry
  delivered it, `merge_refused: <word>` when it did not. Both words are named on a still-refused
  unit, because *the same refusal again* means the transport has not changed and a person must
  look at the pull request, while *a different refusal now* means the new word is where to look.
  **No second vocabulary**: the outcome of a first attempt and of a second are the same kind of
  fact. The script's own refusals are reported by name too (`not_undelivered:<verdict>`,
  `scan_held:<tier>`, `no_open_pull_request`, `gh_unavailable`, `no_such_claim`, …), and a
  `recorded: false` is named beside the outcome — it never turns a landed merge into a failure,
  but it does mean the branch's answer is now stale. **A run that names an entry and reports no
  outcome for it is non-conformant on its face**, the same enforcement the connector retry
  carries and for the same reason. **No artifact gains a `retried` field**: this report is the
  surface, and the branch story already holds the durable answer.
- **Notification outcome per unit** (`/implement` only — an attended `/drive` posts nothing, so it
  reports nothing): for the one thread the unit posted into, the surface used and the result —
  `posted` with the thread it landed in, or the failure named (`post_refused` when a surface that
  exists declined the call, `no_slack_transport` / `no_surface` when the session has
  neither connector nor token, `no_token` / `no_channel` / `http_<code>` / `slack_<error>` as the
  fallback script reports them, `posted_as_root` when no thread was found and a keyed root was
  started instead). **A refusal is per call and an absence is per session** (2026-09-03, mission
  `deliver-a-post-the-transport-refused-or-say-it-reached-nobody`): the first leaves a line that is
  still sendable, so the run carries it on the unit's own story through
  `story/scripts/record-unposted-line.sh` and a later tick sends it once
  (`drive/scripts/list-unposted-lines.sh` → the transport → `clear-unposted-line.sh` on a landed
  send); the second cannot be repaired inside the run at all. Reporting the first as the second is
  what made a run whose every call was denied say the post did not exist.
  The shape follows `/specificate`'s `notified` flag, which already reports this way.
  **A post that did not happen is stated, never omitted**: silence in this list read as success is
  the whole defect (measured 2026-08-12, issue #406 — the 18:48 UTC `[Implement]` run got
  `{"notified": false, "reason": "no_token"}` and nothing downstream said so).
- **And a `🟡 Handoff` line names its carrying surface and its mention outcome beside that**
  (2026-08-31, mission `notify-the-person-a-directed-question-addresses`), because it is the one
  finish shape whose whole purpose is to reach a person. Two facts, never blended into one:
  **which account spoke** — `bot` (the tokened transport, because the addressee resolved to the
  posting identity) or `connector` (every other case, including no bot token, which is the
  fallback and not a failure) — and **whom it named**: the resolved address, or
  `mention_unresolved: <address>` when `identity.sh` could not resolve it and the token was
  therefore **omitted rather than guessed**. A line that named nobody and a line that reached its
  person must not read alike, which is precisely how three units sat waiting on operator input
  since 2026-08-18, 2026-08-19 and 2026-08-26 with the run reporting the post as sent. Both ride
  the notification outcome above rather than replacing it: *posted*, *by whom*, and *at whom* are
  three questions. **No artifact gains a field** — the report is the surface.
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
  is the QA seam `development` / `qa-engineering` requires: the developer's
  looking-through relocates to this report and each unit's PR, never to a mid-run prompt.
- Units the developer deferred at the attended selection, one line each as `deferred_by_operator`
  — naming them keeps a narrowed run distinguishable from a drained queue.
- Units another runner holds, and units the survey excluded with their reasons.
- Stashed partial work and where to find it.
- Predicted vs actual hours per mission unit.
