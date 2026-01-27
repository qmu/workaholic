---
title: Inconsistencies
description: Known terminology issues and potential resolutions
category: developer
last_updated: 2026-01-27
commit_hash: a525e04
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

## レガシー「doc-specs」、「sync-src-doc」、「sync-work」参照

### 問題

過去のドキュメントは、もう存在しない`/sync-doc-specs`、`/sync-src-doc`、または`/sync-work`コマンドを参照している可能性があります。これらのコマンドは`/pull-request`に統合されました。

### 現在の使用状況

- 現在のワークフロー：`/report`はspec-writerとterms-writerサブエージェントを自動的に実行
- 過去のコマンド：`sync-doc-specs`、`sync-src-doc`、`sync-work`、`sync-workaholic`
- ターゲット：`.workaholic/specs/`と`.workaholic/terms/`

### 推奨される解決策

残りの参照を、ドキュメント同期が`/report`中に自動的に行われることを説明するように更新します。過去のドキュメントは変更しないでください。

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

`/sync-workaholic`コマンドは削除されました。その機能は現在`/report`の一部であり、spec-writerとterms-writerサブエージェントを自動的に実行します。

### 現在の使用状況

- 現在のワークフロー：`/report`は4つのドキュメントエージェントを同時実行（changelog-writer、story-writer、spec-writer、terms-writer）
- 過去のコマンド：`/sync-workaholic`はspec-writerとterms-writerをオーケストレート

### 推奨される解決策

`/sync-workaholic`への参照を、ドキュメント同期が`/report`中に自動的に行われることを説明するように更新します。過去のドキュメントは変更しないでください。

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

TDDプラグインへの残りの参照をcoreプラグインへの参照に更新します。チケット駆動開発コマンド（`/ticket`、`/drive`）は現在、統一されたcoreプラグインの一部です。

## レガシー「/pull-request」コマンド参照

### 問題

`/pull-request`コマンドは`/report`に改名されました。新しい名前は、GitHub PRの作成に加えて、このコマンドが包括的なドキュメント（changelog、story、specs、terms）を生成することをより適切に反映しています。

### 現在の使用状況

- 現在のコマンド：`/report`
- 過去のコマンド：`/pull-request`
- `pr-creator`エージェント名は変更されていない（内部実装の詳細）

### 推奨される解決策

`/pull-request`への参照を`/report`に更新します。過去のドキュメント（アーカイブされたチケット、ストーリー）はその時点の状態を反映しているため、変更しないでください。

## レガシー「/commit」コマンド参照

### 問題

`/commit`コマンドは削除されました。`/drive`セッション中に`/commit`を実行するとコンテキストがフラッシュされ、ワークフローが中断されます。さらに、このコマンドはチケットなしのアドホックコミットを促進し、チケット駆動開発の哲学を損なっていました。

### 現在の使用状況

- 現在のワークフロー：コミットは`/drive`（チケット実装用）または`/report`（ドキュメント用）を通じて行われる
- 過去のコマンド：`/commit`はスタンドアロンコミットを許可していた

### 推奨される解決策

`/commit`への参照を、コミットがチケット駆動ワークフロー（`/drive`、`/report`）を通じて行われることを説明するように更新します。適切なドキュメント化のため、すべての変更はチケットを通じて流れるべきです。

## スキルディレクトリ構造の進化

### 問題

スキルは単一のマークダウンファイルから、SKILL.mdとscripts/サブディレクトリを持つディレクトリベースの構造に進化しました。一部の古いドキュメントはフラットファイルパターンを参照している可能性があります。

### 現在の使用状況

- 現在の構造：`plugins/<name>/skills/<skill-name>/SKILL.md`とオプションの`scripts/`ディレクトリ
- 現在のスキル：archive-ticket、changelog、story-metrics、spec-context、pr-ops
- 過去のパターン：`archive-ticket.md`のような単一マークダウンファイル

### 推奨される解決策

スキルを参照する際は、ディレクトリベースのパターンを使用します。`SKILL.md`ファイルにはスキル定義が含まれ、`scripts/`にはエージェントが呼び出せる再利用可能なbashスクリプトが含まれます。
