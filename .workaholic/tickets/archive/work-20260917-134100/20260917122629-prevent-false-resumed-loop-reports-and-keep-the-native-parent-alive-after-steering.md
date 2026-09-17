---
created_at: 2026-09-17T12:26:29+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260917122606-prevent-false-resumed-loop-reports-and-keep-the-native-parent-alive-after-steering.md]
merge_policy:
verification_handoff: 
claim: work-20260917-134100
---

# Prevent false resumed-loop reports and keep the native parent alive after steering

## Overview

resume の報告を実際の native parent 継続証拠に結び付け、steering 後も同じ親が観測と child 結果回収を続ける。

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/runtime/reference/native-loop.md` — native parent の継続契約。
- `plugins/workaholic/skills/work/` — coordinator state と interruptible observation。
- runtime regression tests — paused goal と live tool の組合せを検証。

## Implementation Steps

1. host goal paused・worker running・native tools available の再現を作り、false resume の判定元を特定する。
2. running state や worker liveness と parent observation evidence を分離し、resume claim の条件を後者に限定する。
3. steering/status は commentary で返した後に interruptible wait と再観測へ戻し、child terminal result を同じ親が回収する。

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- continuation evidence がない限り resume を報告しない。
- native continuation が可能なら、追加 user message なしで再観測と child 結果回収まで進む。

**Verification method** — the commands/tests/probes that prove them:

- native-loop focused regression と work runtime suite を実行する。

**Gate** — what must pass before approval:

- paused host goal の fixture が false resume を起こさず、同じ parent の次観測を証明する。

## Considerations

既存 anchor と active work を維持し、duplicate loop や main 直書きを作らない。

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: worker liveness と schedule の存在は親が steering 後も観測を続ける証拠ではない。
  **Context**: paused host で native wait が利用可能な場合、同じ `interruptible_parent` と次の wait/result collection を型付きで要求する必要がある。
