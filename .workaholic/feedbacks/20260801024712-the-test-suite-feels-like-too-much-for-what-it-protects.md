---
type: Feedback
title: The test suite feels like too much for what it protects
kind: concern
source: discussion
created_at: 2026-08-01T02:47:12+09:00
author: a@qmu.jp
supersedes: 
---

# The test suite feels like too much for what it protects

テストが too much な感じがする。

測定（2026-08-01）: `scripts/test-workflow-scripts.mjs` は単一ファイルで 8,999 行、テスト関数 145 個、アサーション呼び出し 1,437 箇所（実行時 1,589 件）。1つのチケットを drive するたびに 20〜30 のアサーションが積み増され、直近3ブランチでいずれも増えた。設計判断を1つ変えるとその判断を固定していた既存アサーションが落ち、書き換えが必要になる（このセッションだけで3件: /ticket の publish 失敗文言、mission テンプレートのセクション順、carried 後継の Scope 継承）。有効な回帰検知と、変更のたびに払う税との比率が割に合っていないのではないか、という感触。
