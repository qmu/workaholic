---
name: work
description: Run the development loop — observe Slack and feedback issues, answer people, and dispatch due work without waiting for it.
---

# Work

Run one coordinator with two independent clocks:

- the work clock, anchored at startup, advances implement, propose/specificate, and moderate;
- the observation clock watches Slack and assigned feedback issues. Activity shortens it and
  silence gradually lengthens it.

The coordinator owns communication and never performs or waits for the dispatched work.
The live conversation is the highest-priority input: a request to wait suspends dispatch.

## Start

Use the strongest mechanism this session actually has:

1. If it can wait interruptibly, emit commentary, and start background children, keep this
   turn as the native parent.
2. Otherwise, if a same-chat scheduler is callable, schedule this tick in the local project.
3. Otherwise run `scripts/codex-loop.sh`; use `--once` for cron or systemd.

If Codex cannot sustain the native parent in step 1, prefer a Scheduled task attached to the current chat. Do not start `scripts/codex-loop.sh`
from that task because it would create a second clock. Codex CLI uses
`scripts/codex-loop.sh` as its fallback.

For native parents and same-chat schedulers, read `runtime/reference/native-loop.md` and call
`runtime/scripts/coordinator.sh --instance <session-id> --input <event.json>` with a `start`
event before creating the clock. On Claude Code this must be the actual native session ID;
every child prompt includes `workaholic-receipt:<id>` for the launch guard. Reuse the instance ID after compaction. The same entrypoint
handles `hold`, `resume`, `stop`, reservations and terminal results. Persist hold before saying
you will wait. Timer events cannot resume. On stop cancel the schedule and stop named children.
Record each confirmed native cancellation with `cancelled`; it is not a role completion.

State the selected clock, where reports appear, and the continuation it proves — its `kind`
(`interruptible_parent` or `same_chat_schedule`) and `id`, recorded through the coordinator's
`start` event. A missing continuation mechanism is a refusal to say *resumed*, never a sentence
in the report. An explicit interval selects fixed observation. Without one, use adaptive observation:

- activity: 30 seconds;
- successive quiet observations: 60, 120, 240, 480, then 900 seconds;
- cold quiet start: 300 seconds;
- provider failure: retry separately and never count it as quiet.

Do not add quiet hours. Silence naturally backs off at night, and activity at any hour resets
the interval. A scheduler with one-minute precision clamps 30 seconds to 60 and says so.

For an external Codex clock:

```sh
sh <this-skill>/scripts/codex-loop.sh
sh <this-skill>/scripts/codex-loop.sh --once
sh <this-skill>/scripts/codex-loop.sh --status --json
```

## Tick

Read `plugins/workaholic/commands/infinite-development.md` and execute one tick. On an agent
without command dispatch, translate command names as follows:

- read `plugins/workaholic/commands/<name>.md` for implement, propose, specificate, or moderate;
- start due native children in the background, or call
  `scripts/codex-loop.sh --dispatch <implement|propose|moderate>`;
- never run those roles inline and never wait for them;
- use the plugin directory in place of `${CLAUDE_PLUGIN_ROOT}`.

Observe both inputs before deciding the next observation:

- Slack through `transport/scripts/observe-channel.sh`, capturing messages before advancing its cursor;
- `specificate/scripts/list-inbound-issues.sh`, which returns open feedback issues assigned
  to this identity and excludes already captured or self-originated issues.

Report the route each Slack effect actually took. Startup names the declared binding it
resolved, whether the channel and sender were verified, and any `binding_contradictory` /
`binding_incomplete` reading. Name the destination: the
workspace and channel it resolved, and `channel_id` when the declaration carries one, taken
from the reader's own `binding` and never from memory, a directory name or a repository name —
a report that names no destination is **non-conformant on its face**, and an undeclared
repository names the environment fallback it used instead.
A repository is named as declaring nothing **only** when the reader answered `ok: true`: an
`ok: false` reading is reported as `binding_unreadable:<reason>` and never as
`declared: false`, because `declared` is a field on a hard refusal as much as on an empty
answer.
Each effect names its `route` and, when it left the preferred one,
`degraded_from` and the typed `degradation_reason`. A connector or token success is a **degraded
success** — it proves delivery and never that the preferred route is configured — and reporting
it as an ordinary one is how a repository runs for weeks on a route nobody chose.

An observation is quiet only when every configured source was read successfully. Any new
human Slack root or reply, or any new assigned feedback issue, is activity. Bot-authored
messages do not reset the interval. A new feedback issue makes propose-then-specificate due
immediately. Work, exploration, maintenance, and provider retry deadlines stay independent.

An unproved or unreadable observation is **unread, never quiet**: it advances no cursor,
records `unproved_since` on the binding record (the stored cursor, or the read's own time when
none exists), and keeps retrying on the failure streak's own deadline, independent of the work
cadence; the next proved read overlaps the whole unproved interval (`overlap_seconds` is the
greater of 300 and `now − unproved_since`), and only that read's cursor-advancing capture clears
the mark. A report that calls an unproved read quiet is non-conformant on its face.

**And a PROVED observation whose coverage is unfinished is incomplete, never quiet** (2026-09-17,
ticket `20260917123453`). `observe-channel.sh` derives `observation_settled` once and names every
term in `unsettled[]`: **`channel_delta_incomplete`** (`has_more` still true — a page budget was
exhausted or a later page could not be read), **`thread_coverage_partial`** (the discovery
operation refused, a thread read failed, or a reply could not be classified),
**`thread_fanout_truncated`**, and **`sender_identity_unverified`**. While any of them stands the
tick may **not** report the channel quiet, may **not** report that no new reply arrived, and may
**not** report the channel as fully observed: `plan-poll.sh` answers **`observation_incomplete`**
in place of `quiet`, `codex-loop.sh` records that word in the tick status beside `unsettled`, and a
report that calls such a read quiet — or names the word and not the terms — is **non-conformant on
its face**.

It moves the **word and never the cadence**. An unread page already forces an immediate re-poll
through `has_more`; a standing limitation such as a route that will never carry thread discovery
would otherwise shorten the interval forever, which is a spin rather than a repair. `settled`
**absent means settled** (the `merge_policy` convention), so a caller that does not pass it
behaves exactly as it did before this existed.

**A mention outside the read window is discovered, not waited for** (2026-09-17, ticket
`20260917122814`). The mention reading was a text test over the channel delta and nothing else, so
a mention on a root older than the window — or in a reply, which channel history never carries at
all — was invisible until somebody pasted a link, and nothing registered the thread either, so the
next tick looked past it too. `observe-channel.sh` now searches the channel's own history for the
declared sender's mention token through the operation that already exists (`search_exact`), **one
bounded call per tick**, joins every coordinate it finds to the watch set, and **reads each one
immediately** (`WORKAHOLIC_MENTION_FANOUT`, default 3) — a mention is the one discovery that means
a person is waiting. One thread is read **at most once per tick** whichever arm named it, so the
mention arm and the discovery arm never spend two calls to deliver one reply. The search itself
**captures nothing**: capture is per surface, and capturing here would make the thread read see its
own message as a duplicate and drop the reply the arm exists to route. **A search is not an index**
— `coverage.mentions` reports `searched`, `discovered`, `tracked` and `exhaustive: false`, never a
completeness claim, because zero rows certify nothing. An absent `sender_id` leaves the arm unrun
and the reading `unreadable`. **Cost, stated**: one transport call per tick.

**And a human reply discovered in a thread is activity.** `new_input_ids` is the channel delta's
own list, so a tick that found somebody answering the loop's own question read `activity: false`
and backed its interval off. The cadence term reads the discovered replies too, a `reaction_only`
one excluded.

**The delta is drained inside the call, and what it discovers is remembered.** Reading one page
and calling the rest *next tick* made the coverage claim false for as long as the channel was
busy, so `observe-channel.sh` pages `read_channel_delta` until `has_more` is false or the
`WORKAHOLIC_CHANNEL_PAGES` budget (default 5) is spent — each page captured before the next is
asked for, so page N+1's lower bound is page N's own advanced cursor with **no** overlap, and the
boundary message is dropped by the capture's existing provider-id dedup. `window_since` rides the
first page only, because the capture is the one writer of the unproved mark. Every root the delta
named and every explicit Slack permalink in a message's text go into a **durable, bounded watch
set** (`watch_threads` on the binding record, newest `WORKAHOLIC_WATCH_SET_MAX`, default 50),
written in one revision-checked update after the captures; a refused write is named
`watch_set_unwritten` and stores nothing. When `list_thread_changes` refuses, **that set is what
the fallback reads** — newest first, through the same one classifier, bounded by the same fan-out
— rather than nothing at all, which is how a request under a freshly discovered root went
unanswered for as long as the provider kept refusing. A fallback read is **evidence, never
coverage**: `coverage.threads.status` stays `partial` with the discovery's own reason and
`source` reads `watch_set_fallback`.

Use `runtime/scripts/plan-poll.sh` for the pure cadence transition. Persist its
`next_state` only after inbox capture; after a crash, an early duplicate read is safer than
advancing past uncaptured input. Sleep until the earliest work, observation, or retry
deadline. Native waits remain interruptible and at most 60 seconds.

**An answer recorded in a `/moderate` question's own thread needs no dispatch of its own**
(2026-09-08, mission `turn-quiescent-blockers-into-mature-decisions-and-resume-work`). It is
recorded by `moderate/scripts/record-answer.sh` inside the tick that read the thread, and the
direction it unblocks is re-judged on the **next ordinary `[Propose]` turn**, which reads it
through `moderate/scripts/decision-maturity.sh` before it may report `no_evolutionary_move`. So
there is no reopen signal to route, no new due-role, no cursor to advance and no state to clear:
the answer is derived state, and the cadence that already exists is what picks it up. An answer
that also **asks for something** is a different fact and takes the path it always took — one
`[FB]` issue through `propose/scripts/file-inbound-ask.sh`, which makes propose-then-specificate
due immediately by the rule above.

## Children and reports

Reserve a receipt through `coordinator.sh` before launching, then record `child_id` with `started`.
Keep one child for propose/moderate and at most the configured implement fanout. Record each
terminal result with `finish`, emit commentary once, then mark `reported`. After compaction,
rediscover children. Idle without a readable result is `unknown`, never completed. Native
cadence is derived from receipts, not remembered timestamps.
For native children, also apply the tick's total `WORKAHOLIC_MAX_WORKERS` limit (default 2)
across roles and reserve each launched slot immediately. Capacity-held roles remain due.

Every worker returns the supplied result schema:

- `executed`: whether it actually read and performed its command;
- `outcome`: the command's terminal token;
- `reason`: what stopped or withheld it;
- `report`: the command's report block.

Process exit, execution, work completion, and notification delivery are separate facts.
Missing or malformed results are unreadable, never successful.

**What a child RECEIVES is contracted here, beside what it returns** (2026-09-19, ticket
`20260919095618`). The return half above has always been specified and the input half never was,
so how much conversation a child inherited was a property of whichever harness launched it
rather than of anything declared — and an operator whose objection is the per-child context copy
then has one lever, turning delegation off, which is the wrong one. A repository declares the
policy as `dispatch.context_policy`, its own top-level configuration key beside the count and the
clock and neither of them: **`full_conversation`** or **`bounded_task`**, read through
`runtime/scripts/dispatch-policy.sh` and through nothing else, with **absent meaning today's
behaviour**. Under `bounded_task` a dispatched child receives exactly this and nothing else:

- the bounded task — the one command body to execute, once;
- the artifact paths it needs, named in full;
- its worktree and its claim;
- its receipt id (`workaholic-receipt:<id>`, which the launch guard reads);
- the user constraints currently in force;
- the result schema it must answer in.

It inherits **no conversation**. A bounded child therefore knows less and can claim less, which
is the premise rather than a cost to hide: a worker's finish is **evidence for the parent, never
automatic permission**, and a worker proves only its own unit. `fork_turns` is a **harness**
capability, named as the mapping the bounded policy takes where one exists and never as the
policy itself, so a harness that spells it differently needs no new policy value. A dispatched
child's receipt records the policy it was launched under, both dispatch paths — the native child
launch and `codex-loop.sh --dispatch` — carry the same one, and the policy changes no count and
no cadence: `WORKAHOLIC_MAX_WORKERS`, the implement fanout and every polling value are untouched
by it.

**What the loop guarantees, and which of them a restriction costs** (2026-09-19, ticket
`20260919095618`). The operator turned subagents off; the Tick section says *never run those
roles inline and never wait for them*, so the only way to make progress was to implement in the
parent — and the coordinator, still persisted and still running, stopped receiving role ticks,
with nothing anywhere saying that trade had been made. From the outside a loop whose observation
clock had stopped looked like a loop that was busy. The four properties this loop advertises are
a **closed list**, written here and cited elsewhere, never restated:

- `observation_clock` — an observation clock that runs independently of the work;
- `acknowledgement_on_cadence` — a person who writes is answered on that cadence;
- `work_advances_without_waiting` — due work advances without the parent waiting for it;
- `separable_worker_evidence` — a worker's result is evidence the parent can weigh separately.

**A restriction names WHICH of them lapse, never that some may be affected.**
`work/scripts/delegation-lapse.sh --input <facts.json>` is the one derivation, over `delegation`
(`available` | `refused`) and the declared `context_policy`:

- **delegation refused** — `work_advances_without_waiting` and `separable_worker_evidence`
  lapse; `observation_clock` and `acknowledgement_on_cadence` **hold**, and the coordinator
  keeps them. It does **not** become an inline implementer: if the operator wants inline work
  that is their instruction, and the loop names the lapse rather than performing it silently.
- **bounded context** — all four hold, at one stated cost: a bounded child knows less and can
  therefore claim less, so its finish is **evidence for the parent, never automatic permission**.
- **no restriction** — all four hold, nothing lapses, and the tick announces nothing new.

**It is announced once, through the shape that already exists.** A tick whose reading is
`announce: true` posts `workaholic:notify`'s precondition-stop shape under the reader's own
`signature`, with the existing dedup, escalation and cool-down unchanged — no new shape and no
new transport. That class decides **severity**, never whether a stop is announced at all. An
operator restriction is **not a degraded reading**, and the two vocabularies stay apart: one is
a person's decision and the other is something the loop could not see. The tempting error is to
refuse to run at all when a guarantee lapses; that is worse than the defect, because the
operator restricted delegation for a real reason and a loop that stops observing in protest
helps nobody.

<!-- workaholic:deferred-queue — one wording, byte-identical with commands/infinite-development.md. -->
**A queue held entirely by the operator's own deferral is a healthy idle tick, and it is named**
(2026-09-21, ticket `20260921180419`). An operator writes `deferred: <why>` onto a queued ticket;
`plan-units.sh` counts it, offers it to nobody and names it `operator_deferred`, and
`loops/scripts/claimable-units.sh` answers `claimable: 0` with `deferred: <n>` and **no `readable`
key** — the reading succeeded, so zero is the honest answer. Such a tick spawns **zero** implement
runners, reports **no** failure and posts **no** precondition-stop alert: that shape is for
something the loop could not see, and this is the operator's own decision. The tick report names
what is holding the queue — `implement allocation: 0 (no_claimable_work) — deferred: <n>` — so a
deliberately quiet tick never reads as the loop having stopped. **A declaration the survey could
not read is the opposite case** and takes the degraded path unchanged: `deferral_unreadable`
answers `readable: false` with null counts and falls back to **one** runner, because a reading
nobody could make never becomes zero capacity.
<!-- /workaholic:deferred-queue -->

**Changing the dispatch policy is a correction, not a restart.** Same instance id, same startup
anchor, **no second `start`** — the coordinator answers `already_started` and changes nothing —
and live children reconciled through `coordinator.sh`, so nothing is duplicated and no second
clock appears. The final response is not involved: a lapse is commentary and a channel post, and
the three reserved events do **not** gain a fourth.

**The tick names the context propagation policy it dispatched under.** Read it once through
`bash ${CLAUDE_PLUGIN_ROOT}/skills/runtime/scripts/dispatch-policy.sh --root . --harness <id>`
— the one reader; the policy is declared configuration and is never inferred from a harness
flag — and report `context policy: <word>` from its answer: `absent` when nothing is declared,
the effective policy when the harness honours it, and `<policy> unsupported:<reason>
effective:<policy>` when it cannot. An **absent** declaration is today's behaviour and says so;
an **unsupported** one names the policy that actually governed the child and never reports the
declared one as honoured. An unreadable reading is `unreadable`, never `absent`. A report under
which a bounded dispatch and a full-context one read alike is **non-conformant on its face**.

<!-- workaholic:mention-reread — one wording, byte-identical with commands/infinite-development.md. -->
**Immediately before a completion mention is composed, reread its own thread** (2026-09-19,
ticket `20260919100143`, issue #1146). The existing read answers *have we already posted*, never
*has anything new arrived*, so a request written while the work ran was outside the mention's
scope and the person was told the batch was done while their newest ask was unseen. Reread that
thread and the continuations it **explicitly links** — a link a person wrote, never a similar or
recent thread — through `transport/scripts/observe-channel.sh`, the existing bounded thread read:
no second transport call shape, no second dedup and no full-channel scan. Anything new is captured
through `transport/scripts/capture-inbox.sh` **first**, so a request the reread found is a filed
ask before the mention is even considered. **The reread advances no cursor of its own** —
`observe-channel.sh` is the one writer of observation state, and a second advancing path is a page
the next ordinary observation skips. Pass each read through
`bash ${CLAUDE_PLUGIN_ROOT}/skills/work/scripts/mention-reread.sh --input <file>`: only `allow`
permits the mention, and `no_reread`, `observation_unreadable`, an `unsettled[]` term
(`thread_fanout_truncated`, `thread_coverage_partial`, …), `capture_unreadable`,
`capture_incomplete` or `new_request_found` each **withhold** it by that word. An absence of a
reading is never a proof, so the direction is asymmetric on purpose. **A new request found is the
ordinary good case rather than an error path**: it is captured, the mention is withheld, and
scoped progress goes out instead.
<!-- /workaholic:mention-reread -->

Under a native parent, ordinary ticks and user steering use commentary. A correction does not
reset the startup anchor. On stop, name still-running roles and child identifiers.

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

That path is only an operator-level stop. A single unit awaiting interpretation uses
`task_review`: its receipt records the originating thread, the coordinator stays `running`,
observation and unrelated work continue, and only a reply from that thread makes the receipt
eligible again. Task review never emits `hold` or asks for a separate resume.

**A unit waiting on somebody else's merge is one of those task waits, and never a global hold**
(2026-09-17, ticket `20260917141324`). Measured: a green pull request whose merge is another
authority's act was classified `review_required` — the criterion below says *a refusal that stops
the work is review-required*, and a refused merge reads exactly like one — so the parent persisted
`hold`, asked the one question and ended, with independent runnable work queued behind it. **The
refusal stops that unit, not the loop.** The facts carry it: `blocked_on` names the three per-unit
blockers the loop actually has — **`merge_authority`** (green, and merging is somebody else's act),
**`pull_request_review`** (a person is mid-review), **`verification_handoff`** (a declared
verification cannot run here) — and `final-response-contract.sh` refuses
**`unit_wait_is_not_global_hold`** for `review_required` beside any of them. The reader still reads
no sentence and no refusal word; `blocked_on` is a judgement the run writes out, as
`interruption_kind` already is, and it rides the `task_wait` answer beside `unit` so the receipt
records which unit is waiting and on what.

**And a task wait keeps the same parent observing.** `task_wait` answered `next_action: null` and
`collect_results: false` whatever the host goal was, so a paused-goal parent with interruptible
wait available was told nothing about continuing and ended — the other half of the same measured
stop. Both paths now read the one `interruptible_parent` derivation, because a unit's wait is not
a reason for the **loop** to stop observing or to stop dispatching what is due.

A turn that handled a mid-loop comment names the continuation it returns to — its `kind`
(`interruptible_parent` or `same_chat_schedule`) and `id` — **before** the response ends, and
proves it through the same reader: `final-response-contract.sh` refuses `continuation_unproved`
for a routine turn that names none, and the coordinator's `resumed` is `true` only while
`control` is `running` **and** a recorded continuation's `next_due` has not passed
(`resumed_reason`: `continuation_unproved`, `continuation_lapsed`, or the control mode). `running`
alone is never a resumed loop; a report that calls the loop resumed while `resumed` is `false` is
non-conformant on its face, and a missing continuation mechanism is a refusal to say *resumed*,
never a sentence in the report.

When the host goal is paused but native interruptible wait and child-result reads remain
available, a named clock is not enough: the continuation must be the same
`interruptible_parent`. The reader returns `next_action: wait_interruptibly` and
`collect_results: true`; the parent answers steering in commentary, waits again, then consumes
the child's terminal result without another user message. Worker liveness proves only the worker.

The criterion is a judgement the run writes out, not a detector: *does the human need to read
this before work may continue?* A decision the loop cannot take on its own (a fork that reaches
the operator's ruling), a result that contradicts what the human just asked for, or a refusal
that stops the work is review-required. An ordinary answer, a confirmation, or a status the
human did not ask to gate on is routine. A needless stop is the failure #1126 measured (nine
unattended ticks lost to a wait); a needless resume is corrected by the human's next message,
which is itself an ordinary interruption. A routine interruption under a standing hold is
answered in commentary and the hold stands — an ordinary question never resumes a hold.

Connector-less nested Codex runs may use the documented relay only when a connector-owning
parent is explicitly waiting. Otherwise report `no_slack_transport`.

Historical measurements and compatibility detail live in
[reference/other-agents.md](reference/other-agents.md).
