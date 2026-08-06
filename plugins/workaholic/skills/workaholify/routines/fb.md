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

**Four lines, identical in every repository.** A developer configures this by hand, once
per project, so the prompt must be one text they paste everywhere — **no substitutions,
no repository name** (P3, amended by P7, 2026-08-06). The session already knows which
repository it is in; naming it in the prompt made every project's copy different, which
is the per-project cost the reduction exists to remove.

What the four lines carry is only what the plugin cannot know: the environment (what
started the session, that nobody is present), the payload to read the ask out of, the one
command, and **the channel and post shape** — the one thing a routine cannot defer,
because it *is* the routine's output contract. Everything else has a home:
`workaholic:propose` owns the judgment, the single pull request and the `[Proposal]`
prefix; `workaholic:feedback` owns the record; the `workaholify` SKILL owns every
notification rule; the always-loaded `rules/` own the standing prohibitions.

## Prompt

You are the [Propose] runner for this repository — an isolated cloud session started because a GitHub issue was assigned. No human is here: never ask a question, never wait for input, never use AskUserQuestion.

Read the ask out of that issue: its title, its body, its assignee, and any thread it names.

Run `/propose` with that ask and that assignee in hand — the assignee owns whatever gets emitted — and let the loaded skills own everything else.

Post to Slack `dev-<repo>` and nowhere else, in the issue's own language: one 🟠 line when you start, naming the ask and linking the issue; then in that thread 🟢 Proposed, the pull request link, one sentence of at most 40 words, and the session URL.
