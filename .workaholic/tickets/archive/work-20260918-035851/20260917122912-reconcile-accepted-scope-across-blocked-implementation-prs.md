---
created_at: 2026-09-17T12:29:12+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260917122859-reconcile-accepted-scope-across-blocked-implementation-prs.md]
merge_policy:
verification_handoff: 
claim: work-20260918-035851
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

## Final Report

Development completed as planned.

`work/scripts/delivery-ledger.sh` answers the delivery state of an accepted request whose
implementation is spread over several pull requests. It **composes** `feedback-outcome.sh` rather
than restating it — that reader stays the one derivation of `state` / `notification` /
`deployment` — and adds only what it cannot see: the arithmetic over the pull-request set (folded
with `every`, never `any`), the first absent stage (`merge` → `deployment` →
`public_verification`), a per-row `delivered` that conjoins the two readings so no call site has
to, a bounded dependency-ordered `next[]`, one `blockers[]` entry per gate naming its whole
affected scope, and the `independent[]` work that keeps going. It clears no gate and verifies
nothing. Named at both reconciliation seams (`commands/implement.md`,
`commands/infinite-development.md`).

### Discovered Insights

- **Insight**: `<array> | index(.)` does not test membership — the pipe rebinds `.` to the array,
  so the expression asks whether the array contains itself. Every one of the four membership
  tests in the first draft had it, and the symptom was a silently empty result in one place and
  `Cannot index array with string "number"` in another.
  **Context**: the working form binds the element first (`. as $d | any($set[]; . == $d)`). This
  is worth knowing for any jq in this tree that filters one list against another.
- **Insight**: `feedback-outcome.sh` answers a **bare** `{items:[…]}`, not the
  `runtime_json_result` envelope its siblings in `runtime/scripts/` return.
  **Context**: a composing caller that checks `.status == "ok"` therefore rejects every valid
  answer. The scripts under `work/scripts/` are not uniform about the envelope.
- **Insight**: jq's `//` treats `false` as empty, so `.public_verification // null` turns an
  explicit *not verified* into *nobody looked*. This bit the same batch three times, in three
  different scripts.
  **Context**: any tri-state where `false` is a real answer needs `has("key")` or `!= true`. The
  house comment for it already exists in `adapters/qfs.sh` beside `.ok != false`.
- **Insight**: `state: implemented_and_verified` and `missing: deployment` are both correct and
  together mean *not delivered* — the implementation reading is genuinely about the pull requests
  and says nothing about the deployment.
  **Context**: this is exactly the shape the ticket was written against, so the conjunction lives
  in the reader as `delivered` rather than at each call site; a consumer reading one field would
  report a failed deployment as a finished request.
