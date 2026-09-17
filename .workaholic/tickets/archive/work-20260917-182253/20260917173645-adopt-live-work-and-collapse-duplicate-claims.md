---
created_at: 2026-09-17T17:36:45+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: reconcile-waiting-work-without-repeated-machine-claims
merge_policy:
verification_handoff: 
---

# Adopt live work and collapse duplicate claims

## Overview

既存 worktree と claim lineage を採用し、stacked branch の継承 trailer と重複 runner を独立 claim と誤認しない reconciliation を実装する。

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/runtime/` — claim lineage と live worker reconciliation。
- `plugins/workaholic/skills/work/` — startup adoption と runner arbitration。

## Implementation Steps

1. live worktree、stale heartbeat、stacked inheritance、duplicate runner の複合 fixture を作る。
2. lineage と liveness から一つの owner を選び、既存 worktree を再作成せず adopt する。
3. loser runner を待機させ、同じ unit の duplicate dispatch を防ぐ。

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- 一つの unit に一つの live claim/runner だけが残る。

**Verification method** — the commands/tests/probes that prove them:

- runtime/work reconciliation suite を実行する。

**Gate** — what must pass before approval:

- 複合履歴 fixture が再作成・二重claimなしで収束する。

## Considerations

lineage が読めない場合は推測で worker を終了しない。

## Final Report

Development completed as planned.

- Added a single turn reconciliation reader that adopts an existing live worktree and chooses one oldest live receipt as owner.
- Duplicate runners are reported as losers to wait; unreadable lineage never authorizes cancellation.
- Verified by the native coordinator suite (10/10 passing).
