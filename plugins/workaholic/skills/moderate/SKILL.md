---
name: moderate
description: "Run the unattended maintenance tick: inspect repository health, reconcile human questions, carry bounded repair findings, and report meaningful changes in the standing Slack thread."
allowed-tools: Bash
user-invocable: false
skills:
  - workaholic:notify
  - workaholic:feedback
  - workaholic:create-ticket
metadata:
  internal: true
---

# Moderate

Maintain the space around the development loop. This is unattended: no `AskUserQuestion` at any step.
Honor the native coordinator's hold/stop before dispatch.

## Authority

Use the proof-versus-judgement boundary in `../drive/reference/claims.md`. Re-derive each act's
preconditions at the moment of writing. An unreadable observation is unknown, not an empty result.
Report a refused action and its reason while continuing independent work. Never change caller,
account or command spelling to escape a permission refusal.

| Finding | Allowed action |
| --- | --- |
| `superseded` claim | Existing `retire-claim.sh` after its re-proof; preserve every other claim |
| Fully checked mission with no queued ticket | Existing `close.sh <slug> achieved` publication seam |
| Standing-ruling candidate | Draft one operator-facing PR; never auto-merge its ruling |
| Finding classified `repairable` in the step contract | File one deduplicated feedback issue through `file-inbound-ask.sh` |
| Conflicted claim or publication | Report the writer's result; implementation owns catch-up and delivery |
| `base-health` | It reports and nothing else: no rerun, revert, merge or invented repair ticket |
| Unclassified or decision-dependent finding | Report or ask; do not invent repair authority |

This tick never merges a PR, pushes into a claim branch, or edits a live strategy. Operator-facing
PRs remain the operator's decision after the implementation role catches their branch up.

## Run

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/moderate/scripts/run-planned.sh
```

The registry `scripts/steps.json` owns step order and cadence. The wrapper records each step as
executed, skipped, degraded or blocked and advances cadence only for steps actually run.
`--deadline-seconds <n>` bounds the tick; a step not reached is `skipped:budget`, not successful.

For every returned `needs_agent` item, read **that step's section** in
[reference/workflow.md](reference/workflow.md) before acting. Do not load every step's history.
After acting, record the actual result through `log-append.sh` under `<step>-filed` or
`<step>-refused`. A probe and its effect are separate facts, not overwriteable entries.

Carry each created feedback record's exact path with `persist-log.sh --record <path>`.
An unlanded record is not filed merely because the log says so. Never sweep unrelated staged
files into that publication. GitHub operations use `gather/scripts/gh-rest.sh` over REST.

## Questions and answers

Read [reference/question-lifecycle.md](reference/question-lifecycle.md) when candidates or answers
are present. Reconcile current premises and verified answers before presenting a question.
The full key, owning step, subject, coordinate and answer live in the local runtime registry;
rotating logs retain the operational trace, not the only copy of question identity.

Use `decision-maturity.sh` for direction blockers and the Recommended-label test for judgement:
decide routine authorized choices; ask only the irreducible human decision. A direction question
names what landed and what remains; it names what the reading could not see from supplied
residue rather than asserting the direction is finished.
`direction-last:<slug>` names the last live direction before it closes.

The question gate owns quiet hours, work days, per-tick/day caps, asked-once and bounded re-asks.
The original thread, a verified outside-thread message and the live conversation can each supply
an answer. Ambiguous association never retires a question. A legacy hash without a verifiable
preimage is `question_identity_unavailable`, not a question to invent or silently drop.

## Communication

Every Slack effect uses `workaholic:transport`: resolve the declared binding, call `perform.sh`,
and complete an exact `needs_parent` request through `accept-observation.sh`. Preserve the chosen
sender. Read the permitted shapes from `workaholic:notify`.

`render-tick-post.sh` decides whether the tick speaks from questions, morning digest, changed
impairment or failed delivery, within the speaking window. Resolve `tick-day:<YYYYMMDD>`: one
standing root per speaking day, subsequent deltas and directed questions as replies.
Only confirmed digest delivery earns `strategy-digest-rendered-<YYYY-MM-DD>` with status `filed`.

Report project facts, not raw control tags or promises of future work. An unreadable channel is
not quiet. File an undelivered root through the existing feedback path; never mark an undelivered
question as asked. Issue closure proves intake disposition, not implementation. Implementation,
merge, deployed behavior and notification each need their own evidence.

## Local state and cadence declarations

Operational logs stay local and git-ignored; never commit them to main or recreate a log branch.
Question metadata shares the Git common directory across worktrees through `runtime/state.sh`.
A fresh unrelated clone cannot recover that local state; do not claim cross-machine durability.

Optional `.claude/settings.json` `env.WORKAHOLIC_CADENCES` declares
`name|repository-relative-git-pathspec|<n>d-or-<n>h`, separated by semicolons. Absent means no declared
cadence. `cadence-state.sh` reads age from git, not checkout mtime, and names malformed entries.
It observes missing output; it does not execute arbitrary commands from configuration.
