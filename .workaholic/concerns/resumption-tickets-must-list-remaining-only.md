---
origin_pr: 67
origin_pr_url: https://github.com/qmu/workaholic/pull/67
origin_branch: work-20260701-093015
origin_commit: 21a5f49
created_at: 2026-07-01T13:35:59+09:00
last_seen: 2026-07-15T20:55:56+09:00
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

The remaining-only rule is prose in four places in `carry/SKILL.md`; `carry-checkpoint.sh` never inspects the ticket body and `validate-ticket.sh` checks frontmatter and location only, so nothing enforces it. Re-graded urgent → moderate during this branch's triage ([9d81dd3a](https://github.com/qmu/workaholic/commit/9d81dd3a)): the first real resumption ticket to reach a drive — `20260715181934-invert-secret-pass2-to-match-values.md` — follows the rule cleanly and even declared its own origin superseded, and `/drive`'s approval gate sits downstream.

## How to Fix

Add a body-section lint. Re-grade to urgent only if a resumption ticket is observed re-listing done steps.

