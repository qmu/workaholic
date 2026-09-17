---
created_at: 2026-09-17T12:23:36+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260917122237-discover-codex-plugin-caches-before-selecting-an-older-registry-install.md]
merge_policy:
verification_handoff: 
claim: work-20260917-124009
---

# Discover Codex plugin caches before selecting an older registry install

## Overview

Codex と Claude の双方にある versioned plugin cache を同じ候補集合として探索し、
新しい Workaholic bundle を古い registry entry より優先して実行できるようにする。

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` — plugin source 候補の列挙・選択。
- `plugins/workaholic/skills/check-deps/tests/plugin-src.test.sh` — host を跨ぐ version 選択の回帰 fixture。

## Implementation Steps

1. 現行 resolver が Claude registry だけを列挙する経路を再現し、Codex cache の配置規則を特定する。
2. Codex と Claude の候補を共通の version・immutable tie-break に入力し、選択元を正確に返す。
3. Codex 1.0.349 と Claude registry 1.0.343 の fixture を追加し、1.0.349 が選ばれることを固定する。

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Codex cache の 1.0.349 が Claude registry の 1.0.343 より優先される。
- 同一 version では既存の immutable tie-break が維持され、`source` と `call_src_source` が実体を示す。

**Verification method** — the commands/tests/probes that prove them:

- plugin source resolver の unit suite と既存の Workaholic test suite を実行する。

**Gate** — what must pass before approval:

- host を跨ぐ候補選択の回帰 fixture を含む全テストが成功する。

## Considerations

Codex cache の探索を広げても、checkout 優先と実行可能な `call_src` の制約を崩さない。
