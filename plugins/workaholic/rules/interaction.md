---
paths:
  - '**/*'
---

# Interaction Rules

- **Ask only for genuine decisions; default to act-and-report.** Issue an `AskUserQuestion` (or any blocking prompt) only when **all three** hold: (1) a competent developer could genuinely go either way, (2) the answer materially changes the artifact, and (3) it is not already determined by safety, repo conventions, the stated goal, or an obvious sensible default. When any of those determine it, **decide, state the choice plainly, and let the developer correct it** — asking is the exception, not the default.
- **The Recommended-label test — the mechanical form of the rule above.** Before issuing any `AskUserQuestion`, look at the option you would list first: **if you could honestly mark it "(Recommended)", do not ask.** A recommendable option *is* the answer — **decide it, record the decision and its reason in the artifact you are producing** (the ticket's `## Quality Gate`, the mission changelog, the PR body, the run log — wherever the work is being written), and let the developer veto it later. Ask **only** when no option can honestly carry the label: a true fork where the developer holds information or preference you cannot derive. This is condition (3) sharpened — *a decision with a recommendable default is not genuine.*
- **Why the bar is this high — the economics are part of the rule.** A coding agent's mistake is cheaply amendable: a later agent fixes it, and code keeps getting cheaper to change. A question spends the one scarce resource — the developer's attention — and spends it up front, before the work that might have answered it. The asymmetry runs one way: decide-and-record risks a cheap correction; asking costs the expensive thing every time. So **fewer questions and confirmations are the key to orchestration efficiency**, and a recommendable question — one you already knew the answer to — must not be asked. Recording is what keeps this honest: **decide-and-record, never decide-and-forget** — the later veto is cheap *because* the decision was written where it can be seen, so a saved question never becomes a silent assumption (`workaholic:implementation` / `objective-documentation`). This lowers question *count*, never decision *latency*.
- **Do not under-ask either.** The test narrows *what* qualifies as a prompt; it does not remove the real forks. A genuine design decision, an irreversible or outward-facing action (deploy, send, publish, merge), or an unsignalled preference among genuinely diverging (unrecommendable) options still gets a prompt — and gets *pushed*, one decision at a time, not buried in a report you leave for later.
- **For naming and terminology**, prefer picking a strong default and offering the alternative over a blocking prompt; ask only when the options genuinely diverge and the developer has not signalled one.
- **Necessity is a judgement, not a check.** No hook can read whether a prompt was warranted — a `PreToolUse(AskUserQuestion)` hook sees only the prompt text, not whether a real decision existed, and it certainly cannot read whether an option was *recommendable*. The Recommended-label test above is judgement for the same reason the cross-repository masking step is: it governs meaning, not shape. `hooks/guard-askuserquestion-label.sh` enforces prompt *structure* (the `[<project label>]` prefix); whether a prompt *should have fired* stays with this rule and your judgement, the same division of labour as the cross-repository masking judgement (rules for syntax, judgement for meaning). Do not try to enforce this with a new hook.

## An unattended run never waits for a person

**A run with no human present never blocks on a prompt of any kind** (2026-08-31, mission
`stop-an-unattended-tick-from-waiting-on-a-person`). The rules above govern whether to raise an
`AskUserQuestion`; this one is the same question **one mechanism wider**. A permission prompt, a
tool-approval dialog and an `AskUserQuestion` are one act by three routes — the run stops until
somebody attends to it — and only the first of the three was ever named.

**Three outcomes are conceivable and only two are admitted:**

1. **Proceed under a declared policy** — the action is one this run is configured to take without
   asking, and it takes it.
2. **Refuse the single action and carry on with the rest of the run**, recording what was refused
   and why (`workaholic:moderate`, *A refused action is reported, never silently skipped*).
3. ~~Wait.~~ **Never.**

**Waiting is the worst of the three, and the reason is not squeamishness about latency.** It
produces **no record at all**: the step that would write one is the step the waiting prevents. A
refusal leaves a named line a person can read tomorrow; a wait leaves an hour that looks exactly
like an hour in which nothing needed doing. Measured — three consecutive `[Moderate]` ticks sat at
`requires_action`, and approving one produced another, because nothing bounds how many prompts a
run can raise.

**A notification is not a prompt, and the difference is the whole rule.** A notification tells
someone what happened and they read it when they choose; a prompt stops the run until someone
attends to it, which makes an hourly cadence depend on a person being awake. **That a notification
can reach a person is not a licence to ask them.** This repository posts to Slack, opens issues and
writes run reports precisely so that an unattended run can say a great deal without ever needing an
answer to continue.

**Every unattended contract is an instance of this policy, not a separate question.** `/implement`,
`/specificate`, `/propose` and `/moderate` each say *no `AskUserQuestion` anywhere*; read that as
*no prompt of any kind*, and this section as the reason. Where a run's own reach is what raises the
prompt, the rule that removes it is `rules/shell.md`, *Reading a plugin script: a read tool, never a
Bash text pipeline*.

**This is prose, and its enforcement is a human reading it.** What a machine can hold is the
*configuration* a run inherits — established, with its evidence and its limit, in
`workaholic:workaholify`, *Where an unattended run's prompt policy is configured*. A policy nothing
configures is a policy each run re-decides.
