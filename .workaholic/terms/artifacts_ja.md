---
title: Artifacts
description: Documentation artifacts generated during development workflows
category: developer
last_updated: 2026-02-07
commit_hash: 82ffc1b
---

[English](artifacts.md) | [日本語](artifacts_ja.md)

# 成果物

開発ワークフロー中に生成されるドキュメント成果物。

## ticket

チケットは何を変更すべきかを記録し、何が起こったかを記録する実装作業リクエストです。チケットはYAMLフロントマター（created_at、author、type、layer、effort、commit_hash、category）とOverview、Key Files、Implementation Steps、Final Reportのセクションで作業の離散的な単位を定義します。アクティブなチケットは`.workaholic/tickets/todo/`、延期されたものは`icebox/`、完了したものは`archive/<branch>/`に存在します。ファイルは`20260123-123456-feature-name.md`のようなタイムスタンプ接頭辞命名に従います。`/ticket`で作成され、`/drive`で処理されます。関連用語：spec、story。

## spec

スペックはコードベースの権威あるリファレンススナップショットを提供する現状ドキュメントです。（変更を記述する）チケットとは異なり、スペックは現在存在するものを記述し、`/scan`または`/report`中にspec-writerサブエージェントを介して変更後の現在の状態を反映するように更新されます。スペックは`.workaholic/specs/`にviewpointベースのアーキテクチャドキュメントとして存在します：`stakeholder.md`、`model.md`、`usecase.md`、`infrastructure.md`、`application.md`、`component.md`、`data.md`、`feature.md`（それぞれ`_ja.md`翻訳付き）。以前のアドホック構造（`architecture.md`、`command-flows.md`、`contributing.md`）はこの体系的な8-viewpointアプローチに置き換えられました。関連用語：ticket、story、viewpoint。注：`/ticket`コマンドの説明で「implementation spec」と言及しており、ticketとspecの用語が混同されています。

## policy

policyは特定の運用ドメインにおけるリポジトリのプラクティスと基準を記述するドキュメントです。Workaholicは7つのポリシードメインを定義しています：test、security、quality、accessibility、observability、delivery、recovery。ポリシードキュメントは`.workaholic/policies/`に`<slug>.md`と`<slug>_ja.md`ファイルとして存在します。各ポリシーは`[Explicit]`と`[Inferred]`のアノテーション付きで観察可能なプラクティスを記録し、証拠のないエリアは「Not observed」としてマークします。`/scan`中にpolicy-writerサブエージェントによって生成されます。関連用語：spec、scan、policy-analyst。

## story

ストーリーはブランチ上の複数のチケットにわたる開発作業の動機、進行、結果を統合する包括的なドキュメントです。ストーリーはPR説明文の単一の真実の情報源として機能し、11のセクションを含みます：Summary、Motivation、Journey（Topic Treeフローチャート付き）、Changes、Outcome、Performance、Decisions、Risks、Release Preparation、Notes。ストーリーは`.workaholic/stories/<branch-name>.md`に存在し、その内容（フロントマターを除く）はPRボディとしてそのままGitHubにコピーされます。関連用語：ticket。

## changelog

changelogはすべてのブランチにわたるすべての変更の履歴記録を維持するルートCHANGELOG.mdファイルです。エントリはPR作成時にアーカイブされたチケットから生成され、コミットハッシュ、簡単な説明、元のチケットへのリンクを含みます。ブランチchangelogはもう存在せず、チケットが変更メタデータの単一の真実の情報源として機能します。関連用語：ticket、story。

## journey

journeyはストーリードキュメントのセクション3で、開発がどのように進行したかのハイレベルなナラティブ（通常100〜200語）を提供し、個々のチケットの詳細ではなくフェーズと転換点に焦点を当てます。「どのようにしてここに至ったか？」に答え、Changesセクションは詳細な「何が変わったか？」を提供します。Topic Treeフローチャートはジャーニーセクションの冒頭に埋め込まれます。`.workaholic/stories/<branch-name>.md`内に表示されます。関連用語：story、topic-tree、changes。

## topic-tree

topic treeはストーリーのジャーニーセクション内に埋め込まれるMermaidフローチャート図で、チケット同士がどのように関連しているかを示します。サブグラフを使用して関心事別にチケットをグループ化し、矢印で意思決定の進行を示し、`&`構文で並行作業を表現します。形式：テーマを表すサブグラフを持つ`flowchart LR`。PRレビュアーが変更の範囲と構造をすばやく理解するのに役立ちます。`.workaholic/stories/<branch-name>.md`内に表示されます。関連用語：story、ticket。

## changes

changesセクションはストーリードキュメントのセクション4で、`### 4-N. <チケットタイトル> ([hash](commit-url))`の形式でサブセクションとしてすべての変更の包括的なリストを提供します。各サブセクションにはチケットのOverviewからの1〜2文の説明が含まれ、Journeyの「どのようにしてここに至ったか？」に対する詳細な「何が変わったか？」の補完として機能します。注：H3見出しの番号付けは以前のドット記法（`4.1.`）ではなくハイフン記法（`4-1.`）を使用します。`.workaholic/stories/<branch-name>.md`内に表示されます。関連用語：story、journey、ticket。

## related-history

Related Historyは同様のファイル、レイヤー、または関心事に触れた過去のアーカイブされたチケットへリンクするチケットセクションです。各エントリはGitHubナビゲーション用のリポジトリ相対パスを持つマークダウンリンクを使用します。形式は要約文の後にチケットリンクと説明を含むバレットポイントを含みます。create-ticketスキルは同じファイル、レイヤー、用語を検索して関連履歴を見つける方法をガイドします。`.workaholic/tickets/todo/<ticket>.md`内に表示されます。関連用語：ticket、archive。

## failure-analysis

Failure Analysisは開発者が`/drive`承認中にチケットを放棄したときに追加されるチケットセクションです。何が試みられたか、なぜそれが失敗したか、将来の試みへの見方を記録します。チケットは`.workaholic/tickets/abandoned/`に移動され、学習をgit履歴に保存するためにコミットされます。handle-abandonスキルは包括的な分析の構成をガイドします。関連用語：ticket、abandon、final-report。

## final-report

Final Reportは計画された実装と実際の実装の違いを記録するチケット末尾のオプションセクションです。開発が計画どおりに進行した場合、「Development completed as planned」と述べることができます。それ以外の場合は逸脱を説明し、Discovered Insightsサブセクションを含むことができます。`.workaholic/tickets/archive/<branch>/<ticket>.md`内に表示されます。関連用語：ticket、discovered-insights、archive。

## discovered-insights

Discovered InsightsはFinal Report内のオプションサブセクションで、実装中に発見されたアーキテクチャパターン、コード関係、歴史的コンテキスト、またはエッジケースを記録します。洞察は実行可能で具体的であり、将来の開発者にとって価値のある学習を記録する必要があります。カテゴリには隠された設計決定、非明白な依存関係、驚くべき動作が含まれます。`.workaholic/tickets/archive/<branch>/<ticket>.md`内に表示されます。関連用語：ticket、final-report、archive。
