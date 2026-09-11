# Native loop protocol

The host observes conversation and children; `runtime/scripts/coordinator.sh` owns control,
receipts and role cadence. Invoke it from the repository with `--instance <session-id>
--input <event.json>`. IDs use letters, digits, dots, underscores or dashes. Every event contains
`event` (the event name below) and `now`, UTC epoch seconds; for example,
`{"event":"tick","now":1788884000}`. Check the returned `status` and `reason`, not process exit alone.

On Claude Code, use the actual native `session_id` as the instance ID. Include
`workaholic-receipt:<id>` in every child prompt. `guard-work-control.sh` rejects launches while
held/stopped or without a reserved receipt, and rejects unattended `AskUserQuestion` while the
loop is active. Other hosts use the same reducer but must enforce it in their own dispatch seam;
the Claude hook is not a claim of host-independent enforcement.

| Event | Other fields | Host action |
| --- | --- | --- |
| `start` | `session_id`; optional positive `max_workers` (2), `fanout` (1); optional `continuation` | Keep the instance ID across compaction and scheduled ticks; start one clock and record it as the continuation. |
| `tick` | none | Read `control,resumed,live,completed,due` before observing or dispatching; `resumed` is `true` only under a live continuation. |
| `hold` | `explicit:true` | Acknowledge once; suppress timer reports and new work; preserve schedule and anchor. |
| `resume` | `explicit:true` | Resume only on the human's instruction; time never resumes it. |
| `continued` | `continuation` | Re-establish the continuation a turn returns to (an interruptible parent or a same-chat schedule); never a second `start`. |
| `stop` | `explicit:true` | Cancel schedule and stop the exact `cancel_children` identifiers; preserve code and claims; report cancellation failures. |
| `cancelled` | `id,child_id,confirmed:true` | Record only a successful native stop result for this exact child. Cancellation releases its slot without claiming execution, completion or advancing role cadence. |
| `reserve` | `id,role,workers_readable,available_capacity,formation_pending`; optional `target` | Launch only on `reason:reserved`; the receipt already owns its slot. |
| `started` | `id,child_id` | Bind the native child to its receipt. |
| `launch` | `id` | Claude's PreToolUse guard consumes the reservation atomically; never launch the same receipt twice. |
| `unknown` | `id` | Idle without a readable result keeps its slot pending reconciliation. |
| `finish` | `id,terminal:true,result`; optional `process_exit` | Persist terminal execution, including failed attempts. |
| `reported` | `id` | Mark a completed result after commentary was emitted. |

`result` is `{executed:boolean,outcome:string,reason:string,report:string}`. The role supplies its
terminal token; process exit does not establish it. Duplicate finishes retain the first timestamp;
conflicting results are reported. Finish also writes `loop-finish-<role>-<receipt-hash>` through
`log-append.sh`; replay repairs a missing log write. Cadence reads receipts, so log failure cannot
turn every role due. Reservations use revision-checked atomic updates, including hold races.
`due` is oldest first; apply formation, claimable work, load and capacity before reserving.

`continuation` is `{kind:"interruptible_parent"|"same_chat_schedule",id,next_due}` — the parent's
own interruptible wait or the same-chat schedule that fires the next tick, its identifier, and the
epoch seconds it next fires. `start`, `resume` and `continued` record it (`kind` is a closed set;
anything else is refused as invalid input). Every result carries **`resumed`**, derived and never
stored: `true` only when `control` is `running` **and** the recorded continuation's `next_due` is
not in the past; otherwise `false` with `resumed_reason` `continuation_unproved` (none recorded),
`continuation_lapsed` (its `next_due` has passed) or the control mode (`held`, `stopped`). There
is no fourth control mode; `running` alone is never `resumed`.

The **live conversation is the first inbound source**, ahead of Slack and GitHub. Interpret
“wait”, “let me send feedback first” and equivalent requests as hold. An ordinary question is
answered without discarding the anchor. During hold only persist child results and honor the
human. Hold does not kill an existing worker: say those workers may finish their current operation.
When also instructed to stop workers, stop the known identifiers. On compaction read the same
instance and rediscover actual children, matched by `child_id`, not a role nickname. An unknown
inventory grants no free slots. A stopped instance requires a new explicit `/work` in a new
native session; never invent another instance ID inside the stopped Claude session to evade its hook.
Render role results, never raw monitor/control tags.

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

The criterion is a judgement the run writes out, not a detector: *does the human need to read
this before work may continue?* A decision the loop cannot take on its own (a fork that reaches
the operator's ruling), a result that contradicts what the human just asked for, or a refusal
that stops the work is review-required. An ordinary answer, a confirmation, or a status the
human did not ask to gate on is routine. A needless stop is the failure #1126 measured (nine
unattended ticks lost to a wait); a needless resume is corrected by the human's next message,
which is itself an ordinary interruption. A routine interruption under a standing hold is
answered in commentary and the hold stands — an ordinary question never resumes a hold.
The reducer needs no fourth mode: the handoff is the existing `hold`, and the human's answer
is the existing explicit `resume`; `anchor` is set once at `start` and carried, so neither
path emits a second `start`.

After stopping a child successfully, record `cancelled` even if it has no role result. A failed
stop or unreadable outcome leaves the child live pending reconciliation. A later valid terminal
result may still be recorded with `finish`; malformed late results never reopen a cancelled slot.

## Communication and evidence

All native coordinator and role effects use `transport/scripts/perform.sh --request FILE` after
`resolve-target.sh --request FILE`; read `transport/SKILL.md` for discovery and request fields.
Channel observation uses `observe-channel.sh`. A connector carries only an exact `needs_parent`
request, and its result passes through `accept-observation.sh`. Never run QFS ad hoc or substitute
another account after a provider error. Keep an unavailable selected route visibly undelivered.

The tick is unattended: never call `AskUserQuestion`. The Recommended-label test resolves routine
decisions within existing authorization; missing authority uses the existing decision path while
independent work continues. Diagnose from implementation and observed effects before filing.
An unreadable source is unknown, not an empty queue or channel.

For agent-composed writes, read a gate in one call before constructing the merge, push or deletion.
Internally gated scripts may compose both because they branch on the result. Host permission
denial is not an invitation to change spelling, transport or agent. An unsupported API may use
another supported route only when that route is already authorized.

Implementation, merge, deployment and notification are separate outcomes. A closed feedback
issue or merged proposal proves capture, not implementation. Reconcile the queue, claims and
implementation PRs before claiming all work complete; retain deployment and delivery failures.
