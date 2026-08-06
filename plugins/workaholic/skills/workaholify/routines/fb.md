---
type: Routine Template
id: fb
name: "[Propose] {repo_name}"
trigger: github-issue-assigned
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Propose] — turn a reported ask into a record and the work it warrants

**Fires when a GitHub issue assigned to the developer is opened** (the developer's
instruction, restated 2026-08-06). Not a schedule, and not a merge — a merged pull
request is `[Consent]`'s event. The wiring lives in the GitHub integration, outside the
routine record, which carries no trigger field (`workaholify` SKILL, *What a routine can
be triggered by*).

**The prompt is a pointer, and nothing else.** A first slimming (morning of 2026-08-06)
still restated three plugin rules; the developer rejected that too, correctly — every
rule the prompt restates is a copy that drifts, and each already has one home:
`workaholic:propose` (the judgment, the single pull request, the `[Proposal]` prefix),
`workaholic:feedback` (the record), the `workaholify` SKILL (every notification rule and
the 🟢 Proposed shape). What remains below is only what the plugin cannot know: what
started the session, and that nobody is present.

## Prompt

You are the [Propose] runner for {repo_slug} — an isolated cloud session, started because a GitHub issue assigned to the developer was opened. No human is here: never ask a question, never wait for input.

If the `workaholic` plugin is not loaded, report per the `workaholify` skill's alert rule and stop. Otherwise run `/propose` with the reported ask in hand, and let the loaded skills own everything else — the judgment and the one pull request (`workaholic:propose`), the record (`workaholic:feedback`), the Slack post and its thread (the `workaholify` skill). Follow them, not this prompt.
