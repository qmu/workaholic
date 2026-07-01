---
origin_pr: 67
origin_pr_url: https://github.com/qmu/workaholic/pull/67
origin_branch: work-20260701-093015
origin_commit: 21a5f49
created_at: 2026-07-01T13:35:59+09:00
severity: urgent
status: active
resolved_by_pr:
resolved_by_commit:
---

# Resumption tickets must list remaining-only steps

## Description

`/carry` + `/drive` correctness depends on `/drive` implementing every `## Implementation Steps` entry with no "already done" concept; a resumption ticket that includes completed steps risks re-running them (see [386af5e](https://github.com/qmu/workaholic/commit/386af5e) in `plugins/workaholic/skills/carry/SKILL.md`).

## How to Fix

The rule is stated as the first carry Writing Guideline (completed work goes in the Overview as context). Consider enforcing it in a carry-ticket template or a lint that strips completed steps before writing the resumption ticket.
