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
whether it is theirs** (developer's ruling, 2026-08-06). The routines UI offers no
assignee filter, so the trigger cannot narrow this at all.

**The check is `/propose`'s, not this prompt's** — symmetric with `[Implement]`, whose
survey already drops what it does not own. Both prompts therefore stay the developer's
own lines with no guard in them: a prompt states nothing a command already owns, and
"whose work is this" is exactly the kind of rule that must live in one place rather than
in two routine prompts that can drift apart. `/propose` reports `not_mine` and stops.

The wiring lives in the GitHub integration, outside the routine record, which carries no
trigger field (`workaholify` SKILL, *What a routine can be triggered by*).

**The prompt is the developer's own four lines, rendered into English** (P3, 2026-08-06;
the source is the ruling recorded as feedback `20260806183556`). It says only: read the
notification target and the payload out of the triggering artifact, tell the target — in
the payload's own language — that work has started, run the one command, and post the
result in the given format.

**Nothing else, and the omissions are the point.** No plugin gate, no procedure, no rule
a skill already owns: `workaholic:propose` owns the judgment, the single pull request and
the `[Proposal]` prefix; `workaholic:feedback` owns the record; the `workaholify` SKILL
owns every notification rule; the always-loaded `rules/` own the standing prohibitions.
The routine is also unattended by virtue of running `/propose`, which prompts at no step,
so the prompt does not restate that either.

**The notification target comes from the Issue**, not from a channel name in the prompt —
which is why no repository is named here and the same four lines paste into every
project. `{repo}` in the format line is the developer's own placeholder for the pull
request link.

## Prompt

- Read the notification target (Slack Thread URL) and the feedback (FB) from the Issue
- Notify the target, in the same language as the FB, that consideration has started
- After running `/propose [FB]`, notify the target in the following format

<@U…> 📐 [#123 Title]({repo}/pull/123)
