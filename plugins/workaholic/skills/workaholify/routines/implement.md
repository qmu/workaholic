---
type: Routine Template
id: implement
name: "[Implement] {repo_name}"
trigger: github-pr-merged
trigger_kind: github
trigger_event: pull_request.closed
trigger_filters: is merged = true; title contains [Proposal]; author = the developer
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Implement] — the unattended executor

**Fires when a proposal's pull request merges**: the merge that queues the work is the
event that starts the run that drains it. The wiring is set in the routines UI; the
`trigger_*` keys declare the design, not a stored field.

**`author = the developer` is part of that trigger, and it is not cosmetic** (P6,
2026-08-06). Without it every developer's `[Implement]` fires on *anyone's* merged
proposal, so N developers means N sessions per merge and N-1 of them do nothing.
The filter is the **cost** half of the fix. The **correctness** half is elsewhere and
does not depend on it: a proposal now carries the triggering issue's assignee as its
`assignees`, so a runner that fires anyway surveys, finds the work is someone else's
(`owned_by_other`), takes nothing, and ends `ok`. Both halves matter — the filter
alone would be a UI setting nothing verifies, and ownership alone would leave a pile
of empty sessions.

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
