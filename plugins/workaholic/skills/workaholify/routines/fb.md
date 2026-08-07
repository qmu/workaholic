---
type: Routine Template
id: fb
name: "[Propose] {repo_name}"
trigger: github-issue-assigned
trigger_kind: github
trigger_event: issues.assigned
trigger_filters: (none - the session checks the assignee itself)
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Propose] — turn a reported ask into a record and the work it warrants

**Fires when a GitHub issue is assigned — for every developer, and `/propose` decides
whether it is theirs** (the routines UI offers no assignee filter, so the trigger cannot
narrow this). The check is the command's, never this prompt's — `/propose` reports
`not_mine` and stops — so the prompt carries no guard. The wiring lives in the GitHub
integration, outside the routine record (`workaholify` SKILL, *What a routine can be
triggered by*).

**The prompt is the developer's own four lines** (P3) and states no rule
a skill already owns: `workaholic:propose` owns the judgment, the single pull request
and the `[Proposal]` prefix; `workaholic:feedback` owns the record; the `workaholify`
SKILL owns every notification rule; the always-loaded `rules/` own the standing
prohibitions. The reply thread is **found**, never carried (Q1) — the SKILL's exact-token
lookup, not a target read out of the Issue and not a channel name in the prompt — so no
repository is named here and the same four lines paste into every project. `{repo}` in
the format line is the developer's own placeholder for the pull request link.

## Prompt

- Read the feedback (FB) from the Issue and find its reply thread (the workaholify lookup)
- Notify the thread, in the same language as the FB, that consideration has started
- After running `/propose [FB]`, notify the thread in the following format

<@U…> 📐 [#123 Title]({repo}/pull/123)
