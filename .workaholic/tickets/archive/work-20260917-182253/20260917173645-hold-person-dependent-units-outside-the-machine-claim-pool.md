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

# Hold person-dependent units outside the machine claim pool

## Overview

初回 handoff 後に人の回答だけを待つ unit を `awaiting_person` として claim pool から外し、同じ測定とhandoffの反復を止める。

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — claimability 判定。
- claim/handoff readers — awaiting-person と unanswered question の durable state。

## Implementation Steps

1. handoff 後に claim release が unit を free pool へ戻す経路を再現する。
2. `awaiting_verification` または unanswered `handoff-unit:` を claim suppression に接続する。
3. 人の回答でだけ unit を eligible に戻し、初回 machine pass は許す regression を追加する。

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- person 待ち unit は回答まで再claimされない。

**Verification method** — the commands/tests/probes that prove them:

- plan-units と handoff lifecycle suite を実行する。

**Gate** — what must pass before approval:

- zero-ticket-completion の反復 claim fixture が一回で停止する。

## Considerations

verification_handoff の存在だけでは初回 claim を拒否しない。

## Final Report

Development completed as planned.

- Reconciliation emits `wait_for_person` only after the claim is durably marked `awaiting_person` and the keyed handoff remains unanswered.
- Answered units re-enter the ordinary adoption/dispatch decision on the next reading.
- Verified by the native coordinator suite (10/10 passing).
