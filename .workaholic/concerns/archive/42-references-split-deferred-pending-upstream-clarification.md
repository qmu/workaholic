---
origin_pr: 42
origin_pr_url: https://github.com/qmu/workaholic/pull/42
origin_branch: work-20260528-122941
origin_commit: 0915802
created_at: 2026-06-16T08:57:05+09:00
severity: low
status: resolved
disposition: deferred
resolved_by_pr:
resolved_by_commit:
---

# references/ split deferred pending upstream clarification

## Description

Splitting `drive`/`report` operational detail into sibling `references/` files was scoped out because the `skills` CLI and OpenAI agent SDK docs do not document how a `references/` directory beside `SKILL.md` is loaded (see commit 5c6f35d Final Report).

## How to Fix

Confirm `references/` loading behavior upstream before reopening; once verified, the split can land in a follow-up ticket.

## Triage Disposition (work-20260623-181237)

**Deferred — blocked on an external dependency** (upstream `skills` CLI / agent SDK `references/`-loading semantics). Nothing actionable in this repo until upstream clarifies, so closed at triage to stop re-surfacing as open work; archived for audit. Reopen when upstream documents `references/` loading. Canonical for the duplicate chain `43-carried-from-pr-42-references-split`, `44-…`.
