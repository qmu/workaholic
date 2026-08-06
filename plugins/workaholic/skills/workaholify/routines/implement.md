---
type: Routine Template
id: implement
name: "[Implement] {repo_name}"
trigger: github-pr-merged
trigger_kind: github
trigger_event: pull_request.closed
trigger_filters: is merged = true; title contains [Proposal]
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Implement] — the unattended executor

**Fires when a proposal's pull request merges**: the merge that queues the work is the
event that starts the run that drains it. The wiring is set in the routines UI; the
`trigger_*` keys declare the design, not a stored field.

**Every developer's copy fires on every merged proposal, and that is accepted**
(developer's ruling, 2026-08-06). An `author` filter was tried and dropped: the ruling
is that the trigger does not narrow anything and the **data** decides instead. A
proposal carries the triggering issue's assignee as its `assignees`, so a runner whose
work this is not surveys, sees `owned_by_other`, takes nothing, and ends `ok`. The cost
is N−1 empty sessions per merge; the benefit is that ownership lives in the repository
where every runner reads it through one oracle, rather than in a UI setting nothing can
read or verify. **No prompt change is needed for this** — the survey already does it,
which is what makes `[Implement]` different from `[Propose]`, where the session must
check the assignee itself because proposing *creates* an artifact rather than claiming
one.

**The prompt is the developer's own four lines, rendered into English** (P3, 2026-08-06;
the source is the ruling recorded as feedback `20260806183556`). It says only: read the
notification target and the payload out of the triggering artifact, tell the target — in
the payload's own language — that work has started, run the one command, and post the
result in the given format.

**Nothing else, and the omissions are the point.** No plugin gate, no procedure, no rule
a skill already owns: `workaholic:drive` owns the run and its terminal contract, the
`workaholify` SKILL owns every notification rule (thread routing, red-alert dedup,
mention resolution), and the always-loaded `rules/` own the standing prohibitions. The
routine is unattended by virtue of running `/implement`, which prompts at no step, so the
prompt does not restate that either.

**The notification target comes from the pull request** (P4's `Notify-Thread:` line), not
from a channel name in the prompt — which is why no repository is named here and the same
four lines paste into every project. `{repo}` in the format line is the developer's own
placeholder for the pull request link.

Named `[Drive]` until P1 (2026-08-06), when the unattended executor became `/implement`
and `/drive` went back to being the interactive command.

## Prompt

- Read the notification target (Slack Thread URL) and the Mission/Ticket from the PR
- Notify the target, in the same language as the PR, that implementation has started
- After running `/implement [Mission/Ticket]`, notify the target in the following format

<@U…> 🛠️ [#123 Title]({repo}/pull/123)
