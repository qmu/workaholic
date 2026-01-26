---
title: Inconsistencies
description: Known terminology issues and potential resolutions
category: developer
last_updated: 2026-01-27
commit_hash: f034f63
---

[English](inconsistencies.md) | [日本語](inconsistencies_ja.md)

# 不整合

既知の用語問題と潜在的な解決策。

## 「Spec」用語の過負荷

### 問題

`/ticket`コマンドの説明でチケットを記述する際に「implementation spec」を使用していますが、「spec」はWorkaholicでは（`.workaholic/specs/`内の現状ドキュメントという）異なる意味を持っています。

### 現在の使用状況

- `/ticket`の説明：「Explore codebase and write implementation ticket」
- しかし歴史的に一部のコンテキストでは「implementation spec」と呼ばれていた
- `.workaholic/specs/`には現状ドキュメントが含まれ、実装計画ではない

### 推奨される解決策

実装作業リクエストには一貫して「ticket」を使用し、「spec」は現状ドキュメントにのみ使用します。「implementation spec」への残りの参照を「ticket」に更新してください。

## レガシー「doc-specs」および「sync-src-doc」参照

### 問題

過去のドキュメントは`/sync-work`に改名された`/sync-doc-specs`または`/sync-src-doc`を参照している可能性があります。

### 現在の使用状況

- 現在のコマンド名：`sync-work`
- 過去の名前：`sync-doc-specs`、`sync-src-doc`
- ターゲット：`.workaholic/specs/`と`.workaholic/terms/`

### 推奨される解決策

残りの参照を`/sync-doc-specs`または`/sync-src-doc`から`/sync-work`に更新します。新しい名前はコマンドの目的をより良く反映しています：`.workaholic/`ディレクトリに同期する。

## レガシー「terminology」参照

### 問題

ディレクトリ`.workaholic/terminology/`は簡潔さのため`.workaholic/terms/`に改名されました。同様に、エージェント`terminology-writer`は`terms-writer`になりました。

### 現在の使用状況

- 現在のディレクトリ：`.workaholic/terms/`
- 現在のエージェント：`terms-writer`
- 過去のディレクトリ：`.workaholic/terminology/`
- 過去のエージェント：`terminology-writer`

### 推奨される解決策

残りの`terminology`参照を`terms`に更新します。過去のドキュメント（アーカイブされたチケット、ストーリー）はその時点の状態を反映しているため、変更しないでください。

## レガシー「/sync-workaholic」コマンド参照

### 問題

`/sync-workaholic`コマンドは削除されました。その機能は現在`/pull-request`の一部であり、spec-writerとterms-writerサブエージェントを自動的に実行します。

### 現在の使用状況

- 現在のワークフロー：`/pull-request`は4つのドキュメントエージェントを同時実行（changelog-writer、story-writer、spec-writer、terms-writer）
- 過去のコマンド：`/sync-workaholic`はspec-writerとterms-writerをオーケストレート

### 推奨される解決策

`/sync-workaholic`への参照を、ドキュメント同期が`/pull-request`中に自動的に行われることを説明するように更新します。過去のドキュメントは変更しないでください。

## 過去の`doc/`および`.work/`ディレクトリ参照

### 問題

古いドキュメントやコメントは、現在の構造では`.workaholic/`に改名された`doc/`や`.work/`ディレクトリを参照している可能性があります。

### 現在の使用状況

- 現在：`.workaholic/`にすべての作業成果物が含まれる
- 過去：`doc/` → `.work/` → `.workaholic/`（移行パス）

### 推奨される解決策

すべての現在のドキュメントが一貫して`.workaholic/`を参照するようにします。`doc/`や`.work/`参照に遭遇した場合は、`.workaholic/`に更新してください。

## 「Archive」の二重の意味

### 問題

「Archive」は動詞（アーカイブするアクション）と名詞（アーカイブディレクトリ）の両方として使用されており、これは標準的ですが指示の中で混乱を引き起こす可能性があります。

### 現在の使用状況

- 動詞：「完了後にチケットをアーカイブ」
- 名詞：「以前のチケットをアーカイブで確認」
- ディレクトリ：`.workaholic/tickets/archive/`

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
