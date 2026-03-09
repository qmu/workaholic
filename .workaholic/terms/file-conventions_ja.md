---
title: File Conventions
description: Naming patterns and directory structures used in Workaholic
category: developer
last_updated: 2026-03-10
commit_hash: f76bde2
---

[English](file-conventions.md) | [日本語](file-conventions_ja.md)

# ファイル規約

Workaholicで使用される命名パターンとディレクトリ構造。

## kebab-case

kebab-caseはWorkaholicのファイルとディレクトリの標準命名規約で、単語をハイフンで区切った小文字を使用します（例：`ticket.md`、`archive-ticket.md`、`core-concepts/`）。この規約は一貫性を確保し、大文字小文字を区別するファイルシステムでの問題を回避します。例外：`README.md`、`CHANGELOG.md`、`CLAUDE.md`は慣例により大文字を使用します。関連用語：frontmatter。

## frontmatter

frontmatterはマークダウンファイルの先頭に`---`で区切られたYAMLメタデータブロックです。title、description、category、last_updated、commit_hashなどのメタデータを含みます。`.workaholic/`内のすべてのドキュメントファイルは一貫性と追跡のためにfrontmatterが必要です。標準フィールド：title（ドキュメントタイトル）、description（簡単な説明）、category（user | developer）、last_updated（YYYY-MM-DD）、commit_hash（短いハッシュ）。関連用語：kebab-case。

## todo

todoディレクトリ（`.workaholic/tickets/todo/`）は実装待ちのチケットを保持します。`/ticket`でチケットが作成されると、ここに配置されます。`/drive`中、チケットはタイムスタンプ接頭辞のソート順でこのディレクトリから処理されます。実装とコミットが成功すると、チケットはtodoからarchiveに移動します。関連用語：icebox、archive、ticket。

## icebox

iceboxディレクトリ（`.workaholic/tickets/icebox/`）は現在作業中ではないが将来の検討のために保存されているチケットを保持します。PRを作成する際、未完了のチケットは削除されずにtodoからiceboxに移動されます。これにより計画された作業の喪失を防ぎながらアクティブキューをクリアします。iceboxされたチケットは元のファイル名を保持します。関連用語：archive、ticket。

## archive

archiveディレクトリ（`.workaholic/tickets/archive/<branch>/`）はブランチ名で整理された完了チケットを保存します。そのブランチでの作業中に実装されたすべてのチケットはコミット後にここに保存され、過去の開発を理解するための履歴コンテキストを提供します。アーカイブされたファイルは元のファイル名を保持します。関連用語：icebox、ticket。

## abandoned

abandonedディレクトリ（`.workaholic/tickets/abandoned/`）は実装アプローチが実行不可能と判明したため`/drive`ワークフロー中に放棄されたチケットを保持します。icebox（未完了の作業を延期する）とは異なり、abandonedは試みられた作業をFailure Analysis付きで保存し、何が試みられたか、なぜ失敗したか、将来の試みへの洞察を説明します。これにより重複した失敗した試みを防ぎ、学習をgit履歴に記録します。関連用語：icebox、archive、ticket、abandon、failure-analysis。

## guides

guidesディレクトリ（`.workaholic/guides/`）はWorkaholicの使用方法を説明するユーザー向けドキュメントを含み、入門ガイド、コマンドリファレンス、ワークフロー例が含まれます。guidesは（技術的な実装詳細を記録する）specsとは異なり、エンドユーザーにアクセスしやすいように整理されています。関連用語：specs、kebab-case。

## policies

policiesディレクトリ（`.workaholic/policies/`）は7つの運用ドメインにわたるリポジトリのプラクティスを記述するポリシードキュメントを含みます：test、security、quality、accessibility、observability、delivery、recovery。各ドメインは2つのファイルを生成します：`<slug>.md`（英語）と`<slug>_ja.md`（日本語）。ポリシードキュメントは`/scan`中にpolicy-writerサブエージェントによって生成され、各ドメインは並列のpolicy-analystによって分析されます。ディレクトリには`README.md`と`README_ja.md`インデックスファイルが含まれます。関連用語：specs、terms、scan、policy、constraints。

## constraints

constraintsディレクトリ（`.workaholic/constraints/`）はleadエージェントの決定空間を狭めるmanagerによって生成された規範的な境界を含みます。3つのファイルが存在します：`project.md`、`architecture.md`、`quality.md`で、3つのmanagerドメインに対応します。各constraintファイルはmanagers-principleで定義された構造化されたテンプレートに従い、frontmatter（manager名、last_updated）、要約、および何が制限されるか、根拠、影響を受けるleader、反証可能な基準、レビュートリガーを指定するconstraintエントリを含みます。constraintはpolicyと意味的に異なります：constraintはmanagerによって設定された戦略的な境界で、policyはleadによって生成された実装されたプラクティスの観察的ドキュメントです。関連用語：manager、lead、managers-principle、policies。

## trips

tripsディレクトリ（`.workaholic/.trips/`）はtrippinプラグインの`/trip`セッション中に生成されたアーティファクトを保存します。各tripセッションはtrip名のサブディレクトリ（例：`.workaholic/.trips/trip-20260309-214650/`）を作成し、3つのアーティファクトサブディレクトリを含みます：`directions/`（Planner出力）、`models/`（Architect出力）、`designs/`（Constructor出力）。アーティファクトは数値サフィックスでバージョン管理されます（`direction-v1.md`、`direction-v2.md`）。このディレクトリは`init-trip.sh`によって作成され、tripセッションは隔離されたgit worktreeで動作するため、メインの作業ツリーではgit追跡されません。関連用語：trip、direction、model、design、worktree。
