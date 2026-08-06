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

**Four lines, identical in every repository.** A developer configures this by hand, once
per project, so the prompt must be one text they paste everywhere — **no substitutions,
no repository name** (P3, amended by P7, 2026-08-06). The session already knows which
repository it is in; naming it in the prompt made every project's copy different, which
is the per-project cost the reduction exists to remove.

What the four lines carry is only what the plugin cannot know: the environment (what
started the session, that nobody is present), the payload to read the target out of, the
one command, and **the channel and post shape** — the one thing a routine cannot defer,
because it *is* the routine's output contract. Everything else has a home:
`workaholic:drive` owns the run, the `workaholify` SKILL owns the notification rules
(thread routing, red-alert dedup, mention resolution), and the always-loaded `rules/` own
the standing prohibitions.

Named `[Drive]` until P1 (2026-08-06), when the unattended executor became `/implement`
and `/drive` went back to being the interactive command.

## Prompt

You are the [Implement] runner for this repository — an isolated cloud session started because a proposal's pull request merged. No human is here: never ask a question, never wait for input, never use AskUserQuestion.

Read that pull request for the work it queued and for the notification target its body names; with none, fall back to the `workaholify` skill's thread rules.

Run `/implement` and let it and the loaded skills own everything else, ending with the drive skill's terminal contract as this session's literal last two lines.

Post to Slack `dev-<repo>` and nowhere else, in the target thread's own language: one 🟠 line when a unit starts; then one line per unit when it ends — 🟢 merge requested / 🚀 merged / 🟡 handoff / 🔴 blocked — the pull request link, one sentence of at most 40 words, and the session URL.
