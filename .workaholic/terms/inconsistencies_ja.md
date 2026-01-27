---
title: Inconsistencies
description: Known terminology issues and potential resolutions
category: developer
last_updated: 2026-01-28
commit_hash: 88b4b18
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

スキルは単一のマークダウンファイルから、SKILL.mdとsh/サブディレクトリを持つディレクトリベースの構造に進化しました。一部の古いドキュメントはフラットファイルパターンや`scripts/`ディレクトリ名を参照している可能性があります。

### 現在の使用状況

- 現在の構造：`plugins/<name>/skills/<skill-name>/SKILL.md`とオプションの`sh/`ディレクトリ
- 現在のスキル（動詞-名詞形式）：archive-ticket、generate-changelog、calculate-story-metrics、gather-spec-context、gather-terms-context、manage-pr、define-ticket-format、drive-workflow、block-commands、enforce-i18n、write-story、write-spec、write-terms、write-changelog、analyze-performance、create-pr、assess-release-readiness
- 過去のパターン：`archive-ticket.md`のような単一マークダウンファイル
- 過去のディレクトリ：`scripts/`（現在は`sh/`に改名、POSIXシェル互換性のため）

### 推奨される解決策

スキルを参照する際は、ディレクトリベースのパターンを使用します。`SKILL.md`ファイルにはスキル定義が含まれ、`sh/`にはエージェントが呼び出せる再利用可能なPOSIXシェルスクリプトが含まれます。

## レガシーチケットルートディレクトリ参照

### 問題

アクティブチケットは`.workaholic/tickets/`（ルート）から`.workaholic/tickets/todo/`サブディレクトリに移動しました。これにより、より整理された3層構造（todo/icebox/archive）が作成されます。

### 現在の使用状況

- 現在の構造：アクティブチケットは`.workaholic/tickets/todo/`
- 過去の場所：`.workaholic/tickets/`（ルートディレクトリ）
- 変更なし：`.workaholic/tickets/icebox/`と`.workaholic/tickets/archive/<branch>/`

### 推奨される解決策

チケット保存場所への参照を`.workaholic/tickets/`から`.workaholic/tickets/todo/`に更新します。過去のドキュメントはその時点の構造を反映しているため、変更しないでください。

## レガシー「scripts/」ディレクトリ参照

### 問題

スキル内のシェルスクリプトディレクトリは、簡潔さとこれらがPOSIXシェルスクリプト（bash固有ではない）であることを明確にするため、`scripts/`から`sh/`に改名されました。

### 現在の使用状況

- 現在のディレクトリ：`sh/`（例：`plugins/core/skills/generate-changelog/sh/generate.sh`）
- 過去のディレクトリ：`scripts/`（例：`plugins/core/skills/archive-ticket/scripts/archive.sh`）

### 推奨される解決策

`scripts/`から`sh/`への残りの参照を更新します。すべてのシェルスクリプトはPOSIX準拠である必要があります（`#!/bin/sh`を使用し、bash固有の機能を避ける）。

## レガシー「セクション0 Topic Tree」参照

### 問題

過去のドキュメントはストーリーの「セクション0」や「Topic Treeを独立したセクションとして」参照している可能性があります。Topic treeは当初ストーリーの先頭にセクション0として追加されましたが、その後ジャーニーセクション（セクション3）内に埋め込まれるように移動されました。

### 現在の使用状況

- 現在の構造：ストーリーは7つのセクション（1-7）を持ち、Topic Treeフローチャートはジャーニー（セクション3）内に埋め込まれている
- 過去の参照：一部のドキュメントは「セクション0」やTopic Treeを別セクションとして言及している可能性がある

### 推奨される解決策

「セクション0 Topic Tree」への参照を、Topic Treeフローチャートが現在ジャーニーセクション（セクション3）内に埋め込まれていることを明確にするように更新します。過去のドキュメント（アーカイブされたチケット、ストーリー）はその時点の構造を反映しているため、変更しないでください。

## ストーリーセクション数の進化

### 問題

過去のドキュメントはストーリーが7つのセクションを持つと参照している可能性がありますが、現在のストーリーフォーマットは追加の分析セクションを含む11セクションに拡張されています。

### 現在の使用状況

- 現在のセクション数：11セクション（Summary、Motivation、Journey、Changes、Outcome、Performance、Decisions、Risks、Release Preparation、Notes）
- 過去の参照：7セクション（Summary、Motivation、Journey、Changes、Outcome、Performance、Notes）

### 推奨される解決策

ストーリーセクションを参照する際は、現在のセクション番号を使用してください。過去のドキュメントは変更しないでください。追加セクション（Decisions、Risks、Release Preparation）は、より包括的なPRコンテキストを提供するために追加されました。

## レガシースキル命名参照

### 問題

スキル名は動詞-名詞形式に標準化されました。古いドキュメントは以前の名前を参照している可能性があります。

### 現在の使用状況

| 旧名称 | 新名称 |
|--------|--------|
| changelog | generate-changelog |
| story-metrics | calculate-story-metrics |
| spec-context | gather-spec-context |
| terms-context | gather-terms-context |
| pr-ops | manage-pr |
| ticket-format | define-ticket-format |
| command-prohibition | block-commands |
| i18n | enforce-i18n |

### 推奨される解決策

スキル名参照を新しい動詞-名詞形式に更新してください。この命名規則により、スキルの目的がより明確になります（動詞がスキルが実行するアクションを示します）。

## レガシースキル統合参照

### 問題

フラグメンテーションを減らしスキル階層を簡素化するために、いくつかのスキルがマージされました。過去のドキュメントは、もはや独立したエンティティとして存在しないスキルを参照している可能性があります。

### 現在の使用状況

| 削除されたスキル | 統合先 | 備考 |
|-----------------|--------|------|
| manage-pr | create-pr | シェルスクリプトとPR操作を統合 |
| gather-terms-context | write-terms | コンテキスト収集をwriteスキルに統合 |
| gather-spec-context | write-spec | コンテキスト収集をwriteスキルに統合 |
| calculate-story-metrics | write-story | メトリクス計算をwriteスキルに統合 |
| enforce-i18n | translate | 翻訳要件を統合 |
| define-ticket-format | create-ticket | チケットフォーマットを作成ワークフローにマージ |
| block-commands | (削除) | プラグイン配布では無効なため削除 |

### 推奨される解決策

削除されたスキルへの参照を、統合先の場所に更新してください。例えば、`gather-terms-context`への参照は、`write-terms`内の「Gather Context」セクションを参照するようにしてください。

## レガシー「5エージェント同時実行」参照

### 問題

過去のドキュメントは`/report`が5つのエージェントを同時に実行すると記載している可能性があります。現在のアーキテクチャは2フェーズ実行を使用：最初に4つのエージェントが並列実行され、その後story-writerがrelease-readiness出力とともに実行されます。

### 現在の使用状況

- フェーズ1: changelog-writer、spec-writer、terms-writer、release-readiness（並列）
- フェーズ2: story-writer（release-readiness出力が必要）
- フェーズ3: pr-creator（ストーリーコンテンツが必要）

### 推奨される解決策

2フェーズ実行モデルを明確にするために参照を更新してください。過去のドキュメントはその時点のアーキテクチャを反映しているため、変更しないでください。
