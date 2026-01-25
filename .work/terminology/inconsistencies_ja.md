---
title: Inconsistencies
description: Known terminology issues and potential resolutions
category: developer
last_updated: 2026-01-24
commit_hash: 6843f78
---

[English](inconsistencies.md) | [日本語](inconsistencies_ja.md)

# 不整合

既知の用語問題と潜在的な解決策。

## 「Spec」用語の過負荷

### 問題

`/ticket`コマンドの説明でチケットを記述する際に「implementation spec」を使用していますが、「spec」はWorkaholicでは（`.work/specs/`内の現状ドキュメントという）異なる意味を持っています。

### 現在の使用状況

- `/ticket`の説明：「Explore codebase and write implementation ticket」
- しかし歴史的に一部のコンテキストでは「implementation spec」と呼ばれていた
- `.work/specs/`には現状ドキュメントが含まれ、実装計画ではない

### 推奨される解決策

実装作業リクエストには一貫して「ticket」を使用し、「spec」は現状ドキュメントにのみ使用します。「implementation spec」への残りの参照を「ticket」に更新してください。

## レガシー「doc-specs」および「sync-src-doc」参照

### 問題

過去のドキュメントは`/sync-work`に改名された`/sync-doc-specs`または`/sync-src-doc`を参照している可能性があります。

### 現在の使用状況

- 現在のコマンド名：`sync-work`
- 過去の名前：`sync-doc-specs`、`sync-src-doc`
- ターゲット：`.work/specs/`と`.work/terminology/`

### 推奨される解決策

残りの参照を`/sync-doc-specs`または`/sync-src-doc`から`/sync-work`に更新します。新しい名前はコマンドの目的をより良く反映しています：`.work/`ディレクトリに同期する。

## 過去の`doc/`対`.work/`ディレクトリ参照

### 問題

古いドキュメントやコメントは、現在の構造では`.work/`に改名された`doc/`ディレクトリを参照している可能性があります。

### 現在の使用状況

- 現在：`.work/`にすべての作業成果物が含まれる
- 過去：`doc/`が古いコミットや外部参照に現れる可能性がある

### 推奨される解決策

すべての現在のドキュメントが一貫して`.work/`を参照するようにします。`doc/`参照に遭遇した場合は、`.work/`に更新してください。

## 「Archive」の二重の意味

### 問題

「Archive」は動詞（アーカイブするアクション）と名詞（アーカイブディレクトリ）の両方として使用されており、これは標準的ですが指示の中で混乱を引き起こす可能性があります。

### 現在の使用状況

- 動詞：「完了後にチケットをアーカイブ」
- 名詞：「以前のチケットをアーカイブで確認」
- ディレクトリ：`.work/tickets/archive/`

### 推奨される解決策

これは標準的な英語の使用法であり、許容されます。明確さが必要な場合は、名詞形には「archive directory」、アクションには「archive」（動詞）を優先してください。

## レガシー「TDD Plugin」参照

### 問題

過去のドキュメントは、coreプラグインに統合された別の「TDD plugin」（`plugins/tdd/`）を参照している可能性があります。

### 現在の使用状況

- 現在：すべてのコマンド、スキル、ルールは`plugins/core/`にある
- 過去：一部のドキュメントは`plugins/tdd/`や「TDD plugin」を参照している可能性がある

### 推奨される解決策

TDDプラグインへの残りの参照をcoreプラグインへの参照に更新します。チケット駆動開発コマンド（`/ticket`、`/drive`、`/sync-work`）は現在、統一されたcoreプラグインの一部です。
