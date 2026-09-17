---
created_at: 2026-09-17T17:36:45+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: reconcile-waiting-work-without-repeated-machine-claims
merge_policy:
verification_handoff: 
---

# Own every reconciliation action before returning to cadence

## Overview

moderation が列挙する `needs_agent` を同tick dispatch または durable follow-up receipt に必ず割り当て、unit handoff で親loopをholdしない。

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/` — actionable finding の出力。
- `plugins/workaholic/skills/work/` — receipt ownership と cadence 復帰。

## Implementation Steps

1. `needs_agent` が列挙だけで失われる複合 tick を再現する。
2. 各 action に dispatch または durable receipt を割り当て、未所有 action を terminal success にしない。
3. task-level pending/handoff 中も coordinator cadence が継続する統合 test を追加する。

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- 全 `needs_agent` に一つの owner/receipt があり、親loopは独立 work を継続する。

**Verification method** — the commands/tests/probes that prove them:

- moderate/work end-to-end reconciliation suite を実行する。

**Gate** — what must pass before approval:

- action loss と global hold を起こさず通常 cadence に戻る。

## Considerations

同じ action の receipt と live child を二重 owner にしない。

## Final Report

Development completed as planned.

- Every moderation action is assigned either to one live role owner or a deterministic durable `follow-up:<key>` receipt.
- The cadence-ready verdict refuses ownerless actions and keeps task-level person waits separate from the parent control mode.
- Verified by the native coordinator suite (10/10 passing).
