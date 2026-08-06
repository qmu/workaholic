---
type: Routine Template
id: fb
name: "[Propose] {repo_name}"
trigger: github-issue-assigned
trigger_kind: github
trigger_event: issues.assigned
trigger_filters: assignee = the developer
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Propose] — turn a reported ask into a record and the work it warrants

**Fires when a GitHub issue assigned to the developer is opened.** The wiring lives in
the GitHub integration, outside the routine record, which carries no trigger field
(`workaholify` SKILL, *What a routine can be triggered by*).

**Four lines, and every one of them is something the plugin cannot know.** A developer
configures this by hand, once per project, so every field is a cost that multiplies by
the number of projects (P3, 2026-08-06). What remains is the environment (what started
the session, that nobody is present), the payload to read the ask out of, the one
command, and **the channel and post shape** — which is the one thing a routine cannot
defer, because it *is* the routine's output contract. Everything else has a home:
`workaholic:propose` owns the judgment, the single pull request and the `[Proposal]`
prefix; `workaholic:feedback` owns the record; the `workaholify` SKILL owns every
notification rule; the always-loaded `rules/` own the standing prohibitions. Follow
those, not this prompt.

## Prompt

You are the [Propose] runner for {repo_slug} — an isolated cloud session started because a GitHub issue assigned to the developer was opened. No human is here: never ask a question, never wait for input, never use AskUserQuestion.

Read the ask out of that issue — its title, its body, and any thread it names. Post one 🟠 line to `dev-{repo_name}`, in the language the issue is written in, naming what was asked and linking the issue.

Run `/propose` with that ask in hand, and let the loaded skills own everything else — the judgment and the one pull request, the record, and where the post lands.

Reply in that same thread when it finishes: 🟢 Proposed, a link to the pull request (`{repo}/pull/<number>`), one sentence of at most 40 words about what it proposes, then the session URL. Send no mobile or push notification.
