---
type: Feedback
title: The /setup-routines report presents a template-declared trigger as if it were live wiring
kind: instruction
source: slack
created_at: 2026-08-06T03:21:20+00:00
author: a@qmu.jp
supersedes: 
---

# The /setup-routines report presents a template-declared trigger as if it were live wiring

The `/setup-routines` report shows a `trigger` line for every routine, and a reader takes it for the live wiring. It is not: the RemoteTrigger API exposes no event-subscription field at all, so `render-routine.sh` and `list-routine-templates.sh` read `trigger` from the **template's** frontmatter, and the report prints that declared intent beside genuinely live fields (`enabled`, `schedule`, `target_repo`) with nothing marking the difference.

On 2026-08-06 that cost a manual investigation. This repository's `[Propose]` routine was wired to fire on a merged pull request — the wrong event, since a merge belongs to `[Consent]` — and the report said `github-issue-assigned` throughout, because that is what the template declares. The misconfiguration was found by hand, not from the report that exists to answer exactly this question.

The ask is to stop the report claiming knowledge it does not have: state in the report itself that trigger wiring cannot be read from the API and must be confirmed in the routines UI at https://claude.ai/code/routines. The API limitation is already recorded in the `workaholify` skill; what is missing is that the developer reading the report is told.

Slack thread: https://qmu.slack.com/archives/C0BLL9J7FMY/p1785986026964319
GitHub issue: https://github.com/qmu/workaholic/issues/266
