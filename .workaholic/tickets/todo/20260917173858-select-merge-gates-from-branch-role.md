---
created_at: 2026-09-17T17:38:58+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260917173839-main-release-branch-ci-merge-gate.md]
merge_policy:
verification_handoff: 
claim: work-20260917-184248
---

# Select merge gates from branch role

## Overview

branch role または repository 設定から merge gate を機械的に選び、開発中 main では local proof 後のmerge、release昇格では全remote CI成功を要求できるようにする。

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/` — branch role と merge policy の解決。
- `plugins/workaholic/skills/drive/` / `ship/` — unit merge と release promotion のgate適用。
- CI policy tests — local-development と release の二段階 fixture。

## Implementation Steps

1. 現行 remote CI wait が main unit merge を止める経路と既存 repository settings を診断する。
2. development main と release branch の role を一つの resolver で判定し、許可されたgate setを返す。
3. development policyでは対象local test/build/safety scan成功後のmergeを許し、remote CIをpost-merge detectionとして記録する。
4. release promotionでは全remote CI成功を必須にし、secret/leak と authorization denial は両policyで常にblockする。

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- worker が branch role から gate を決定し、毎unitで人の判断を待たない。
- release path と security/authorization gate は緩和されない。

**Verification method** — the commands/tests/probes that prove them:

- branching/drive/ship の二段階 policy fixture と safety suite を実行する。

**Gate** — what must pass before approval:

- development main と release branch の双方で期待するmerge可否が機械的に再現される。

## Considerations

remote CI失敗はdevelopment merge後も検知・reconciliation対象として失わない。
