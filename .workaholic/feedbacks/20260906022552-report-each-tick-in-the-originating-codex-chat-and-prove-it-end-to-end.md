---
type: Feedback
title: Report each tick in the originating Codex chat, and prove it end to end
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-06T02:25:52+09:00
author: a@qmu.jp
supersedes: 
---

# Report each tick in the originating Codex chat, and prove it end to end

Source: https://github.com/qmu/workaholic/issues/989

The operator's **third** request for the same behaviour: the loop's coordination must live in
the originating Codex conversation, and each tick's status — plus every delegated task's
completion or blocker — must arrive there automatically, with no further operator message, no
status file to open, and no move to Slack. The operator states plainly that the repeated
failures are making them consider stopping use of this assistant.

What was measured, in the operator's own words:

- Issue #985 required the main agent to own the loop and report visibly in the main
  conversation on every five-minute tick, including while a delegated task runs longer than
  five minutes. PR #987 closed #984 and #985 on 2026-09-05 but implemented startup-anchored
  timing and **detached** workers, and its verification used a **stub** for `codex exec`,
  explicitly leaving live CLI behaviour unverified. Neither that result nor a status file
  proves delivery into the originating conversation.
- Observed again with Workaholic 1.0.315: asked to start work, the assistant launched the
  external `codex-loop.sh` supervisor, checked its first ready result and **ended its turn**.
  Asked whether completion would be reported, it answered that Slack would receive reports and
  this chat would not. On checking #985 and #987 it acknowledged the requested originating-chat
  reporting was still unmet.

The operator's diagnosis names the root cause as the **choice of execution mode**, not the
timer: the reporting session selected an external supervisor while its own live harness exposed
an interruptible wait and native child agents. The repair named is to stop assuming every
non-Claude agent lacks usable native background agents, and to make mode selection check the
capabilities actually exposed before falling back to a CLI supervisor.

Capabilities the reporting session evidenced from its own tool declarations (harness contracts
for that session, never a claim about every Codex installation):

- `clock.sleep({duration_ms})` returns after a wait and ends early on new user input; 15- and
  20-second waits followed by further tool calls and commentary already executed in that
  conversation with no further user prompt. Waits of at most 60 seconds, shorter when a
  deadline is nearer; never a five-minute blocking shell sleep in the coordinator.
- `clock.curr_time` (as `tools.clock__curr_time` through `functions.exec`) reads UTC time.
- `collaboration.spawn_agent` returns a child identifier and children can send results to the
  active parent; `list_agents`, `send_message`, `followup_task` and `interrupt_agent` are
  available. That harness had **four** concurrent slots — respect the actual capacity.
- The parent can emit commentary into the chat while continuing its turn; a **final** response
  ends the turn. No callable schedule-management or post-final continuation surface was found
  there. Starting a shell process or writing an output file does not establish that return
  path.

The interactive-coordinator branch the operator specifies: keep the parent turn active; derive
the startup anchor once; run a short first tick; send its report as **commentary, not final**;
delegate each due role as a bounded native child and keep a role-to-child map so a running role
is not duplicated. At each wake, process user steering and newly available child outcomes,
report each completion or blocker **once** in the conversation, and compute the next
startup-anchored deadline. Run the Slack turn and the dispatch decisions when due regardless of
worker completion, then emit the tick report and return to interruptible waiting. Recompute the
remaining time after every early wake — an early wake is not a tick boundary — and never
synchronously await a worker across the next boundary.

The tick command's instruction to **end** means returning control to the parent coordinator in
this branch, not emitting the parent's final answer. Final is reserved for an explicit loop stop
or a named inability to continue. An ordinary question or correction during the loop is answered
in commentary and does not cancel the loop. The anchor, the running child identifiers and the
already-reported outcomes must survive context compaction: rediscover the actually running work
before resuming, and never infer that compaction stopped it. An explicit stop must stop further
dispatch and state what remains running. Before switching off an existing external supervisor,
identify and retire **only** that coordinator and account for its workers, so native
coordination does not create duplicate work.

An actually available same-chat scheduler stays a separate, capability-dependent branch, and
the external CLI supervisor is retained only as an explicitly different mode whose output is
**not** claimed to reach the invoking conversation. The absence of a scheduler alone is not
grounds for choosing that fallback when interruptible parent continuation is available. No
promise of continuation after app closure, cancellation or a hard harness limit without a
tested resumption mechanism.

Acceptance the operator states, and it is the part previous attempts failed: an actual run in
the originating Codex chat — start work there, keep a delegated task running for more than ten
minutes, and record at least **two successive five-minute status reports** visibly arriving in
that same conversation with no further operator input; then finish the task and show its
completion report arriving there automatically. Timestamps, the tested environment and the
version. Shell stubs, passing tests, `status.json`, worker transcripts, Slack delivery, or
instructions to create a schedule by hand do **not** establish this result. Verification must
also exercise the native-parent branch with the actual exposed tools: inject a user status
question during a wait and verify it is answered without cancelling the loop or resetting its
anchor, and verify a still-running role is not dispatched again. The short-wait behaviour
already observed is explicitly distinguished from the ten-minute acceptance run still to be
performed; a documented tool capability is an implementation lead, never a substitute for that
end-to-end evidence.

If the active harness cannot provide the required continuation or delivery mechanism, that
specific limitation is to be reported **at startup** and the requirement left explicitly
unresolved — never a silent substitution of an external supervisor, and never closing this as
implemented.

Related: https://github.com/qmu/workaholic/issues/985,
https://github.com/qmu/workaholic/issues/984, https://github.com/qmu/workaholic/issues/974,
https://github.com/qmu/workaholic/pull/987.

Official context the operator cites: <https://developers.openai.com/codex/noninteractive/>
documents `codex exec` as a scripting mode with output through stdout or an output file. It does
not establish automatic delivery into the originating chat. The native tools above are evidenced
by that session's tool declarations and execution, not inferred from that CLI documentation.
