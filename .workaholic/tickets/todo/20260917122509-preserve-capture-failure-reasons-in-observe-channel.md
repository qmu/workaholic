---
created_at: 2026-09-17T12:25:09+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260917122500-preserve-capture-failure-reasons-in-observe-channel.md]
merge_policy:
verification_handoff: 
---

# Preserve capture failure reasons in observe-channel

## Overview

`observe-channel` の capture 失敗を成功へ丸めず、typed reason と retryable cursor を保持する。

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/scripts/observe-channel.sh` — observation と capture の結果集約。
- 関連 runtime tests — capture failure の回帰証明。

## Implementation Steps

1. transport read 成功後に inbox capture が失敗する再現を固定し、reason が失われる境界を特定する。
2. capture の typed reason を top-level outcome と `data.unreadable` に非空で伝播する。
3. 失敗時は `observation_proved:false` とし、cursor を進めず再試行可能に保つ回帰 test を追加する。

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- unsuccessful capture は必ず非空の診断と `observation_proved:false` を返す。
- 空文字の unreadable entry を出さず、cursor は retryable なままになる。

**Verification method** — the commands/tests/probes that prove them:

- observe-channel の focused test と runtime suite を実行する。

**Gate** — what must pass before approval:

- transport read 成功・capture 失敗の fixture を含む全テストが成功する。

## Considerations

read 自体の失敗と capture 後段の失敗を同じ reason に潰さない。
