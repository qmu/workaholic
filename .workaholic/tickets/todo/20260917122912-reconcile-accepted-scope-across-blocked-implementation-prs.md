---
created_at: 2026-09-17T12:29:12+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260917122859-reconcile-accepted-scope-across-blocked-implementation-prs.md]
merge_policy:
verification_handoff: 
---

# Reconcile accepted scope across blocked implementation PRs

## Overview

accepted request を implementation、merge、deploy、public verification まで追跡し、未配信の関連 PR 群を一つの delivery state として reconcile する。

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/` — delivery gap の検出と統合判断。
- `plugins/workaholic/skills/work/` — accepted scope の durable ledger と dispatch。
- `plugins/workaholic/skills/story/` / `ship/` — merge・deploy・public verification の証拠。

## Implementation Steps

1. feedback/ticket/PR/release の既存 relation を読み、accepted request ごとの delivery ledger を導出する。
2. 複数 PR が一つの conversation を満たす場合、未配信状態と dependency order を判定して bounded integration unit を作る。
3. 共通 external gate は affected scope を束ねた一つの blocker として報告し、独立した統合作業は継続する。
4. PR 作成だけを completion としない回帰 test を追加し、main・deployment・public verification までの状態遷移を固定する。

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- accepted scope ごとに merge、deploy、public verification の欠落を区別できる。
- compatible PR を dependency order どおり統合し、共通 blocker を全 affected scope とともに一度だけ示す。

**Verification method** — the commands/tests/probes that prove them:

- moderate/work の delivery reconciliation fixtures と関連 suite を実行する。

**Gate** — what must pass before approval:

- blocked PR 群を完成扱いせず、独立 integration work を止めない fixture が成功する。

## Considerations

外部 CI gate の解除を自動で主張せず、公開済み証拠と local evidence を分ける。
