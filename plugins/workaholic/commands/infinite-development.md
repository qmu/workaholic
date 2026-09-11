---
name: infinite-development
description: Observe inbound Slack and feedback issues, answer people, dispatch due work, and end without waiting.
---

# Infinite Development

Execute one short tick. Use Japanese for human-facing free text. Keep identifiers, URLs,
commands, slugs, and established technical terms unchanged. Read plugin files with the Read
tool because shell reads from an installed plugin may require unattended permission.

## Coordinator decisions

This tick is unattended: never call `AskUserQuestion`. Apply the Recommended-label test here,
where the coordinator reads it: if an option could honestly be marked “Recommended”, decide
within the existing authorization, record the reason, and let the developer veto. A real missing
authority or preference is recorded for the existing moderation decision path; it does not stop
observation or independent work. A recommendation never authorizes overriding a merge gate.

Before diagnosing a defect or filing the loop's own finding, read the responsible implementation
and its caller, and verify the claimed cause. Distinguish observations from hypotheses. Compare
blobs before saying they are identical; inspect a script's usage before constructing its call.
After a refusal, inspect its reason and arguments before retrying the same operation.

Readability precedes counting. A null, failed, malformed, inaccessible or incomplete read is
unknown, never zero. Slack `channel_not_found` or an empty channel search does not prove that a
channel or thread is absent: establish access to the declared channel first, otherwise report
`channel_unreadable`. Only a successful, complete read establishes an empty result.

For agent-composed operations, call `branch-checks.sh` / `gate-decision.sh` separately from the
subsequent merge, push or deletion. Read and validate the returned decision before constructing
the write call; shell exit zero alone is not a passing JSON gate. Never put an unconditional
write after the gate in the same tool call. Existing delivery scripts may check and act in one
invocation because they branch on the gate internally and bind the merge to the observed head.
Prefer `drive/scripts/deliver-unit.sh <unit>` for reported units; a direct ship uses
`ship/scripts/merge-pr.sh <pr-number> [base-branch]` from the PR's worktree. The second argument
is a branch name, never a head SHA. Re-read checks after catch-up changes the head.

**A refused delivery names which capability refused it, and an authorized route that exists is
used.** This tick merges for itself through the two scripts above, so `commands/implement.md`'s
connector-retry step — which a `[Implement]` worker reaches by executing that body — was never on
this path at all: measured 2026-09-08, two runners stopped on `merge_refused:
session_type_cannot_merge` and an operator-authorized squash merge then succeeded on the same
pull request. Read the class rather than spelling it: `bash
${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/refusal-capability.sh <refusal-word> <route>`
answers `capability` (`no_capability` / `call_errored` / `not_permitted` / `none`), `route` and
`authorized_route`. Report every refused delivery as `merge_refused: <word> (<capability> on
<route>)` — **one refused call is never reported as this session having no delivery**. Where
`authorized_route` is non-empty, take it: `mcp__github__merge_pull_request`, **at most once**, on
that one word and no other, and report **both** outcomes by name — `merged`, or the pull request
left open with the REST refusal and the connector's own. Naming a `session_type_cannot_merge` and
reporting no retry outcome is non-conformant on its face. **An authorization denial stays a
refusal**: a `not_permitted` class carries no authorized route, and no alternate command spelling,
parent delegation or second account is used to get past it. Reads, writes and pull-request
creation stay REST (`rules/shell.md`, *The one qualification*).

## Observe

**Native parent / same-chat tick, before other work:** read `runtime/reference/native-loop.md`
on first use. Call `runtime/scripts/coordinator.sh --instance <session-id> --input <event.json>`
with `{"event":"tick","now":<epoch-seconds>}`. Handle the live conversation first: wait is
`hold`, explicit resumption is `resume`, and stop is `stop`, with `explicit:true`. If `held`,
capture terminal child results silently and end this timer tick without observation, dispatch
or reports. If `stopped`, cancel the schedule and stop its named children. Keep the same anchor.
Read `resumed` beside `control`: a tick whose reading is `resumed: false` reports its
`resumed_reason` and re-establishes the continuation through `continued` before it may call
the loop resumed.

A routine interruption — an ordinary question, correction or follow-up — is handled in
commentary and the coordinator returns to the same loop: the same instance ID, the same
startup anchor, the same schedule, no second `start` event and no final response. A
review-required handoff — the final comment carries information the human genuinely needs to
review before work may continue — persists `hold` (`explicit:true`) first, then asks exactly
「ループを再開してよろしいですか？」 as the final response's own text, never through
`AskUserQuestion`, and stays held until the human's explicit `resume`; time never resumes it.
The final response is reserved for exactly three events: an explicit stop, a named inability
to continue, and a review-required handoff. When the run is unsure, the interruption is
routine. `work/scripts/final-response-contract.sh --input <facts.json>` owns the facts of the
turn.

A turn that handled a mid-loop comment names the continuation it returns to — its `kind`
(`interruptible_parent` or `same_chat_schedule`) and `id` — **before** the response ends, and
proves it through the same reader: `final-response-contract.sh` refuses `continuation_unproved`
for a routine turn that names none, and the coordinator's `resumed` is `true` only while
`control` is `running` **and** a recorded continuation's `next_due` has not passed
(`resumed_reason`: `continuation_unproved`, `continuation_lapsed`, or the control mode). `running`
alone is never a resumed loop; a report that calls the loop resumed while `resumed` is `false` is
non-conformant on its face, and a missing continuation mechanism is a refusal to say *resumed*,
never a sentence in the report.

Read `git status --porcelain` once. Report a dirty checkout and its file count because this
tick is already executing that unreviewed plugin behavior. Do not block, modify, or commit it.

Read the repository's declared Slack binding **before** any Slack selection, read, or write:
`bash ${CLAUDE_PLUGIN_ROOT}/skills/transport/scripts/read-declared-binding.sh --root .`.
Read its output whole: a projection that drops `binding` keeps the workspace and channel out of
this tick's context entirely, which is how a session comes to answer where it posts from memory.
A declaration is the destination; the environment variables below are the fallback for a
repository that declares nothing (`declared: false`, an ordinary answer). Report
`binding_contradictory`, `binding_incomplete`, or `binding_unreadable:<source>` and select no
route on any of them — a contradictory declaration is two destinations, and guessing between
them is the failure the declaration exists to prevent.

Observe both inbound sources before dispatch:

1. Read the declared channel — or `WORKAHOLIC_INBOUND_SLACK_CHANNEL` (default: repository
   name) when nothing is declared — through `transport/scripts/observe-channel.sh`. Read
   `transport/SKILL.md` once. Every read, reply, reaction and root uses its `resolve-target.sh`
   → `perform.sh` path; only an exact `needs_parent` result permits a connector call, returned
   via `accept-observation.sh`. Capture before advancing the cursor. Never run ad-hoc QFS.
2. Run
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/list-inbound-issues.sh`.
   These are assigned, open GitHub feedback issues not already captured on main or an open
   branch. An unreadable result is reported and is never treated as an empty inbox.

**A new reply inside an existing thread is inbound activity, and it is discovered rather than
assumed.** Slack channel history does not carry a reply under an older root, so a reply whose
thread the loop has not touched today is invisible to the channel delta by construction.
`observe-channel.sh` asks which **threads** changed inside the same bounded overlap window,
reads each changed thread whole, and only then routes each reply: `moderation_answer` (under
the loop's own `🙋`), `answer_to_loop` (under another of its shapes), `reaction_only`, or
**`needs_judgement`** — a reply under a human root, which this tick reads in its thread context
and treats as a question or an ask exactly as it would a top-level message. Never classify a
reply from its own text alone; what a reply is depends on what it is a reply to.

**Say `covered` only when the discovery operation ran.** `coverage.threads.status` is `covered`
when replies whose coordinates were *not already known* could have been found, and `partial`
with its reason otherwise (`operation_unavailable`, a refused read, a truncated fan-out). Report
the reason; a channel delta that happens to carry a broadcast reply is not thread coverage, and
reporting it as coverage is how a missed reply looks exactly like a quiet hour.

New human Slack activity — top-level **or** a discovered thread reply — or a new assigned
feedback issue resets adaptive observation to the short interval. A successful quiet observation advances the idle backoff. If either configured
source is unreadable, preserve the quiet streak and use provider retry. A new feedback issue
makes propose-then-specificate due on this tick.

`formation_pending: true` is the intake/implementation ownership boundary. Dispatch
propose-then-specificate for the whole oldest-first page and allocate **zero new implement
runners on this tick**. This is derived from unsettled issues and proposal branches by the
reader, not from a timer or ticket-count guess. Existing implement runners continue; they are
never killed. A later tick may implement only after the reader says formation is settled.

## Answer Slack

Fetch the dedup ledger with
`bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-swept-slack-refs.sh`. If it is
unreadable, skip ask capture as `sweep_dedup_unreadable`.

Collect every unswept message written by a person from this observation page before rendering
receipts. File each ask first, then write one facts item for it and validate the whole page with
`work/scripts/acknowledgement-contract.sh --input <facts.json>`. The facts keep the subject, issue
URL, actual workflow state and source coordinate outside prose. `related_as` is the shared intended
outcome only when that relationship is clear; an uncertain or unrelated ask uses `null` and stays
separate. The page is the batching boundary — never wait for a timer or an arbitrary item count.

For each unswept message written by a person:

- Skip Workaholic's own posts by their shapes: `📝 FB`, `🔎 Moderation`, `🔵 Proposed`,
  `🟢 Implemented`, `📥 受理`, and `💬`.
- For a repository question, read its thread. If this loop has not answered, reply:

```
💬 [<質問を一行で>]
<80語以内の平易な日本語による回答と根拠の場所>
<session URL>
```

- For an ask to build, change, fix, or redirect work, write it through:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/file-inbound-ask.sh \
  --slack-ref <channel>:<ts> --permalink <url> \
  --subject 'person:<name>' --assignee <running-login> \
  [--feedback '<direction refs>'] <owner/name> "<title>" <body-file>
```

  Record `workflow_state: captured_for_specification`; filing an issue does not earn
  `proposed_for_queue` or an implementation promise. After all asks in the page are filed, render
  each validated `receipts[]` group once in its `thread_ref`, and add `:inbox_tray:` to every
  coordinate in `reaction_refs`. A singleton keeps this shape:

```
📥 受理 - [#123 [FB] Issue title](<repo-url>/issues/123)
<件名が分かる自然な返答。依頼をどう受け取り、記録済みの状態と次の実際の工程をどう理解したか。80語以内>
<session URL>
```

  A related group uses one compact reply instead of repeating the sentence for every message:

```
📥 受理 - <N>件を一つのまとまりとして記録しました
- [<その人の言葉で表した件名>](<issue URL>)
- [<その人の言葉で表した件名>](<issue URL>)
<共通して何を求められたと理解したか。記録済みの状態と次の実際の工程だけを述べ、80語以内>
<session URL>
```

  The heading and links are required facts; the connective sentence is composed naturally in the
  person's language and register. Never claim implementation, readiness, a date, or a schedule that
  the structured `workflow_state` does not establish. A reaction or reply failure is still
  `ack_failed` per source and never changes the filed issue. An ask arriving during composition is
  outside this page and remains discoverable by the next overlapping observation.

- A reply under the loop's own `🙋` question is an answer, not a new ask; moderate records it.
- React to other human messages with `:eyes:` and do not reply.

Never answer at the channel root when a thread was requested. A mid-loop question or correction
preserves the objective and anchor; an explicit wait enters hold before dispatch. An explicit stop prevents further dispatch and names
the roles still running.

## Announce landed asks

Run
`bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-unannounced-closed-asks.sh`.
For each readable item, reconcile its feedback, queued tickets, implementation PR and actual
review surface. A timeline cross-reference or merged proposal is not implementation evidence.
Pass the per-item facts through `work/scripts/feedback-outcome.sh --input <file>` before composing
a finish line. Report every item, including queued, unverified and surface-mismatched work.
Resolve the exact `fb:<stem>` thread. A complete lookup proving it missing earns the description
root through the same durable transport, then the finish reply at its verified returned timestamp.
An ambiguous, partial or failed lookup stays `thread_unresolved`; never silently discard it or
invent a root timestamp. Read the thread and post only if there is no prior finish from this loop.
Read the finish-line shape from
`skills/notify/reference/notifications.md` only when a reply is due, and use it exactly. Report `announced`, `already_announced`,
`thread_unresolved:<reason>`, `post_failed:<reason>`, or `held:<reason>`.

## Dispatch

List current role workers once. Release completed native children after recording their result.
Propose and moderate each have one slot; implement is bounded by its validated PR-unit partition
and configured fanout. Never dispatch the same unit to two receipts.

On native/same-chat hosts, use `coordinator.sh` receipts: `reserve` before launching, `started`
with the returned child ID, `finish` with a readable terminal result, then `reported` after its
commentary. Idle without a result is `unknown` and still occupies its slot. The finish seam
writes the `loop-finish-<role>-<receipt-hash>` log, including failed attempts; duplicate results
do not advance its time. Native `due` comes from the receipts. The legacy log read below is for
supervisor compatibility; never maintain a second in-memory cadence for native children.

Count live workers across **all three roles** before each launch. The native coordinator's
`WORKAHOLIC_MAX_WORKERS` defaults to **2**; intersect its remaining slots with the runtime's
actual available child capacity. This is a per-coordinator bound, not a count of other sessions
or a claim about machine-wide load. Existing workers are never killed to meet a lower bound.
The configured limit must be a positive integer; report an invalid value and use the default.
If native child discovery is unreadable, report `capacity_unreadable` and retry discovery before
launching anything; unknown worker identities cannot establish a free slot.
Reserve a slot immediately on dispatch, including propose and moderate. Due roles deferred for
capacity remain due; offer them oldest-due first (ties: propose, moderate, implement), before
extra implement runners. Record the deferred roles and reason, not a fabricated finish time.

For the external supervisor only, read each cadence from the loop tick log with both filters:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/log-read.sh \
  --owner loop --step-prefix loop-finish-<role> --latest-tick
```

An empty or unreadable finish is due. A failed attempt still records its finish time.

| Role | Due | Command |
| --- | --- | --- |
| implement | every work tick, subject to claimable work and fanout | `commands/implement.md` |
| propose | default 15 minutes, immediately after a captured ask or newly observed assigned feedback issue | `commands/propose.md`, then `commands/specificate.md` |
| moderate | 30 minutes | `commands/moderate.md` |

Dispatch due roles in the background and never await them. Native agents use bounded background
children. Other agents call
`sh <work-skill>/scripts/codex-loop.sh --dispatch <role>`.

For implement, derive claimable units with `loops/scripts/claimable-units.sh` only when issue
discovery reports `formation_pending: false`. When formation is pending, report
`implement allocation: 0 (mission_formation_pending)` without running the claimable reader.
Otherwise fanout is:

For a loose backlog, decide its semantic PR-unit partition **before** allocating workers. Keep
one coherent feedback/review batch together. Supply `{groups:[{id,tickets:[<exact paths>],reason}]}`
to `claimable-units.sh --partitions FILE`; it validates complete disjoint coverage and keeps
queued dependencies together. The native receipt's `target` and worker prompt carry that exact
group. Workers claim only their assigned group through the existing arbiter and do not regroup
or absorb another group's tickets. Without a valid partition the legacy conservative count is
one; never label that fallback a measurement of independent work.

`min(WORKAHOLIC_IMPLEMENT_FANOUT default 1, claimable units, available child capacity)`.

A claimable reading of `readable: false` falls back to **one** runner and names the reason; never
turn an unreadable claimable reading into zero capacity. Its counts are `null` rather than `0` for
exactly this reason, and a reading that could not be made says nothing about whether work exists.

Calculate this with `loops/scripts/allocate-implement.sh --input <allocation.json>`, supplying
`formation_pending`, the whole `claimable` reader result, `fanout` (default 1), and the observed
`available_capacity` after other role reservations. Use its `runners` and report its `reason`;
do not coalesce null counts to zero. An unreadable survey grants at most one fallback runner,
subject to actual capacity and the formation boundary. A prior worker's freshen refusal is
not a permanent exclusion: a later eligible tick retries through the executor's freshen seam.

Before each runner beyond the first, apply `WORKAHOLIC_MAX_LOAD_PER_CORE` when configured.
Never stop a running worker because of load, never refuse the first runner, and never turn an
unreadable load into zero capacity. A non-advancing runner may free a fanout slot only when
`loops/scripts/read-runner-advance.sh` proves it; do not kill it.

Resolve the base with `gather/scripts/base-ref.sh`, then start `loops/scripts/tick-progress.sh
<repo-root> --ref <base-ref>` in the background and render the previous completed reading with
its `source_sha`. It may be one tick old. This reads an immutable snapshot and never pulls or
checks out the coordinator's working tree. A failed base lookup is unreadable; never fall back
to checkout counts. Null or unreadable counts stay named and never become zero.

## Report and end

Return one short Japanese block:

- dirty checkout, only when dirty;
- the declared binding this tick resolved, and any `binding_contradictory`,
  `binding_incomplete` or `binding_unreadable:<source>` reading. Name the destination: the
  workspace and channel it resolved, and `channel_id` when the declaration carries one, taken
  from the reader's own `binding` and never from memory, a directory name or a repository name —
  a report that names no destination is **non-conformant on its face**, and an undeclared
  repository names the environment fallback it used instead.
- thread coverage: `covered`, or `partial` with its reason;
- each Slack action or named degradation, naming the `route` it took and — when it left the
  declared one — `degraded_from` and the typed `degradation_reason`. A connector or token
  success is a **degraded** success: it proves delivery and never that the preferred route is
  configured or that the declared sender spoke;
- each assigned feedback issue observation or unreadable issue source;
- each ask announcement result;
- roles spawned or reaped; use `loops: none due` when all were quiet;
- implement allocation and any load, fanout, or advancement refusal;
- total live workers, the configured worker limit, and roles still due but held for capacity;
- the latest progress reading and its observation time;
- each completed worker's `executed`, `outcome`, and `reason`;
- **the reconciled counts a completion claim rests on** — see below;
- where this report is delivered.

If this tick ends having spawned no runner because something it needed was degraded — an
unreadable claimable reading, a freshen refusal, a degraded issue source — post
`workaholic:notify`'s precondition-stop shape under this tick's own signature. Its dedup,
escalation and cool-down apply unchanged. A tick that spawned nothing because nothing was due is
an ordinary idle tick and posts nothing.

Say `idle` alone when nothing happened. Claim completion only from merged work, an empty queue,
and reconciled pull requests. Then end this tick without polling, waiting for workers, or
summarizing work whose result has not arrived.

**A completion claim is reconciled, never relayed, and it names the counts it rests on.** The
report above is assembled from each worker's own `executed` / `outcome` / `reason`; nothing
between a worker and this report asked the tree whether that was true. Measured 2026-09-08: this
tick called implementation complete with **zero merges, six queued tickets and two unreconciled
pull requests**, and read its own runner's claims as another loop's. So before claiming
completion, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/loops/scripts/reconcile-completion.sh
[--claims <file>] [--plan-units <file>] --unit <id>…` over the units **this tick** claims to have
delivered, handing it the claim and survey readings already made rather than paying for them
twice, and report its `merged`, `standing_claims` (with `standing_claims_mine` — whose they are
is part of the answer), `queued` and per-unit `effect`. **A completion claim naming none of these
is non-conformant on its face.**

It is not a second oracle: every number comes from `act-effect.sh`, `list-claims.sh` and
`plan-units.sh`. **A worker's own report is not evidence of completion, and neither is a closed
inbound feedback issue** — a *proposal* pull request closes one before any implementation exists,
so neither is read here and neither may stand in for these counts. **A degraded source is
`complete: null` with null counts and its reason in `degraded[]`, never zero and never
complete**: report the reading as degraded by its reason, exactly as an unreadable base colour is
never reported as green.

**A merge is not a deployment, and completing the queue is not confirming a target.** The
reconciliation says nothing about any deployment; a pending or failed deployment stays its own
visible state in this report, and a failed deployed migration remains a failed deployment even
where the pull request merged and local checks passed.

Base CI health is detection and attribution, not automatic repair. A red reading earns the
existing alert, and failed delivery is reported in this chat; it does not prove anyone was
notified or that a fix was queued. This tick does not create a repair ticket from the red colour
alone. Repair work enters through the existing diagnosed ask and specification path.
