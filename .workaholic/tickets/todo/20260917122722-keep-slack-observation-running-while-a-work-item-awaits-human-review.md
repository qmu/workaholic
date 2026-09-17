---
created_at: 2026-09-17T12:27:22+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260917122710-keep-slack-observation-running-while-a-work-item-awaits-human-review.md]
merge_policy:
verification_handoff: 
claim: work-20260917-135216
---

# Keep Slack observation running while a work item awaits human review

## Overview

task 単位の review/dependency wait を global hold に昇格させず、Slack 観測と独立作業を継続する。

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — task wait と operator hold の意味分離。
- `plugins/workaholic/skills/runtime/reference/native-loop.md` — coordinator の継続状態。
- `plugins/workaholic/skills/work/scripts/final-response-contract.sh` — review_required の終端判定。

## Implementation Steps

1. review_required が global hold を永続化する現行経路を再現し、task dependency state に分離する。
2. 明示的 operator hold だけが coordinator 全体を止め、task review 中も observation と独立 clock を回す。
3. 元の Slack thread の回答を同じ coordinator が取得し、prerequisite 解消時に unit を再び eligible にする test を追加する。

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- task review 中も Slack/assigned issue 観測と独立作業が進む。
- 明示的 operator hold は従来どおり timers から再開されない。

**Verification method** — the commands/tests/probes that prove them:

- review-required sequence と explicit hold の runtime regression を実行する。

**Gate** — what must pass before approval:

- 同一 coordinator/anchor で thread reply を消費し、対象 unit だけが再開可能になる。

## Considerations

task wait の解除を coordinator 全体の resume と誤認しない。
