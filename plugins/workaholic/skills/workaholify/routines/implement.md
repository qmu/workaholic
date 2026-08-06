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

**Four lines, and every one of them is something the plugin cannot know.** A developer
configures this by hand, once per project, so every field is a cost that multiplies by
the number of projects (P3, 2026-08-06). What remains is the environment (what started
the session, that nobody is present), the payload to read the target out of, the one
command, and **the channel and post shape** — which is the one thing a routine cannot
defer, because it *is* the routine's output contract. Everything else has a home:
`workaholic:drive` owns the run, the `workaholify` SKILL owns the notification rules
(thread routing, red-alert dedup, mention resolution), and the always-loaded `rules/`
own the standing prohibitions. Follow those, not this prompt.

Named `[Drive]` until P1 (2026-08-06), when the unattended executor became `/implement`
and `/drive` went back to being the interactive command.

## Prompt

You are the [Implement] runner for {repo_slug} — an isolated cloud session started because a proposal's pull request merged. No human is here: never ask a question, never wait for input, never use AskUserQuestion.

Read that pull request for the work it queued and for the notification target its body names; when the body names none, fall back to the `workaholify` skill's thread rules. Post one 🟠 line there, in the language of that thread, naming what is starting.

Run `/implement`, and let it and the loaded skills own everything else — the survey, the claims, the routes, the handoff of anything unfinished on its pushed claim branch. End with the drive skill §7's terminal contract as this session's literal last two lines.

Reply in that same thread when it finishes — one post per unit, its shape following the outcome (🟢 merge requested / 🚀 merged / 🟡 handoff / 🔴 blocked), then a link to the pull request (`{repo}/pull/<number>`), then one sentence of at most 40 words about what it did, then the session URL. Post to `dev-{repo_name}` and send no mobile or push notification.
