---
type: Mission
title: Refuse ok under a placeholder identity
slug: refuse-ok-under-a-placeholder-identity
status: active
merge_policy:
created_at: 2026-08-21T15:12:42+09:00
author: a@qmu.jp
assignees: [tamura.yoshiya@gmail.com]
assignee:
predicted_hours:
actual_hours:
feedback: [20260821151227-a-survey-run-under-a-placeholder-git-identity-returns-an-indistinguishable-ok.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Refuse ok under a placeholder identity

## Goal

An `[Implement]` tick walked past a full day of the developer's own missions and tickets and
returned `ok` every hour. The consuming repository had no `.claude/git-identities`, so the
bootstrap's step 0b fail-opened — one log line — and the container kept
`noreply@anthropic.com`. `owns.sh` compares that against each artifact's owner, answers
`other`, and `plan-units.sh` excludes the work as `owned_by_other`. Empty `missions[]`, empty
`backlog[]`, no `backlog_error`, `current: true`, `owner_unresolved: false` — §7's table calls
that `ok`.

`owned_by_other` is the survey's **confident** answer; `owner_unresolved` is its "cannot tell",
and that one forbids `ok`. This was a third state neither covers: it could tell, but the
identity it compared against was a placeholder — so the output is indistinguishable from
"nothing is assigned to me". `owners.sh`'s header records this exact failure shape as the one
the ownership model exists to end.

## Scope

`plan-units.sh`'s trustworthiness fields and §7's token table; `check-bootstrap.sh`. Not
`owns.sh`'s comparison, which is correct.

## Experience

A runner whose identity is the container default says so, and never reports `ok`. A repository
carrying the hook but not the mapping is told, and the mapping can be installed.

## Acceptance

- [ ] A placeholder identity is a named survey fact and forbids `ok` (#20260821151250-forbid-ok-under-a-placeholder-identity.md)
- [ ] `/workaholify` installs and audits the mapping the hook requires (#20260821151250-install-and-audit-the-identity-mapping.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
