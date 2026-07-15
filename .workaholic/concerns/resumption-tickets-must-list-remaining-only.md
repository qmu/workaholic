---
origin_pr: 67
origin_pr_url: https://github.com/qmu/workaholic/pull/67
origin_branch: work-20260701-093015
origin_commit: 21a5f49
created_at: 2026-07-01T13:35:59+09:00
last_seen: 2026-07-01T13:35:59+09:00
first_seen: 2026-07-01T13:35:59+09:00
concern_id: resumption-tickets-must-list-remaining-only
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Resumption tickets must list remaining-only steps

> **Re-graded urgent → moderate on 2026-07-15 (developer decision, triage).** The mechanism
> is unchanged and the concern stays open: the remaining-only rule is prose in four places in
> `carry/SKILL.md`, `carry-checkpoint.sh` never inspects the ticket body, and
> `validate-ticket.sh` checks frontmatter and location only. What changed is the evidence for
> *urgency*. The first real resumption ticket to reach a drive —
> `.workaholic/tickets/archive/work-20260715-112717/20260715181934-invert-secret-pass2-to-match-values.md`
> — follows the rule cleanly: completed work sits in the Overview marked "do not redo", the
> Implementation Steps are all genuinely remaining, and it even declared its own origin
> superseded. The failure needs an agent to ignore four explicit prose statements, and
> `/drive`'s per-ticket approval gate sits downstream of it. It has had two weeks to bite and
> has not. Re-grade to act-now only if a resumption ticket is observed re-listing done steps.

## Description

`/carry` + `/drive` correctness depends on `/drive` implementing every `## Implementation Steps` entry with no "already done" concept; a resumption ticket that includes completed steps risks re-running them (see [386af5e](https://github.com/qmu/workaholic/commit/386af5e) in `plugins/workaholic/skills/carry/SKILL.md`).

## How to Fix

The rule is stated as the first carry Writing Guideline (completed work goes in the Overview as context). Consider enforcing it in a carry-ticket template or a lint that strips completed steps before writing the resumption ticket.
