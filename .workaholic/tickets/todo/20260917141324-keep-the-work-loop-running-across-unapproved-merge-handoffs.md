---
created_at: 2026-09-17T14:13:24+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260917141206-the-work-loop-must-not-stop-at-an-unapproved-merge-handoff.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
claim: work-20260918-035851
---

# Keep the work loop running across unapproved merge handoffs

## Overview

継続中の `/work` loop が merge authority 待ちの PR に到達しても parent turn を終えず、状態を記録して独立 work の polling と dispatch を続ける。

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — review-required handoff と loop 終端の契約。
- `plugins/workaholic/skills/runtime/reference/native-loop.md` — parent の継続・待機条件。
- `plugins/workaholic/skills/work/scripts/final-response-contract.sh` — final response を許す terminal state。

## Implementation Steps

1. green PR が別 authority の merge を待つと parent が質問して終了する再現を固定する。
2. unmerged/review-required を task-level handoff として永続化し、coordinator の global hold や terminal result から分離する。
3. handoff 中も同じ parent が interruptible polling と due work dispatch を続けるよう runtime contract を更新する。
4. explicit stop または継続不能の証拠がある場合だけ final response を許す regression test を追加する。

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- unapproved merge handoff は active loop の終端にならない。
- independent runnable work がある間は同じ coordinator が polling と dispatch を継続する。

**Verification method** — the commands/tests/probes that prove them:

- native-loop、final-response-contract、review handoff の focused tests を実行する。

**Gate** — what must pass before approval:

- PR merge authority 待ちの fixture が final response を出さず次の observation に進む。

## Considerations

権限なしの merge は実行せず、待機継続と authority 拡張を混同しない。
