---
title: File Conventions
description: Naming patterns and directory structures used in Workaholic
category: developer
last_updated: 2026-01-29
commit_hash: 70fa15c
---

[English](file-conventions.md) | [日本語](file-conventions_ja.md)

# ファイル規約

Workaholicで使用される命名パターンとディレクトリ構造。

## kebab-case

ファイルとディレクトリの命名に使用される、ハイフンで区切られた小文字の単語。

### 定義

kebab-caseはWorkaholicのファイルとディレクトリの標準命名規約です。小文字を使用し、単語をハイフンで区切ります（例：`ticket.md`、`report.md`）。この規約は一貫性を確保し、大文字小文字を区別するファイルシステムでの問題を回避します。

### 使用パターン

- **ディレクトリ名**: `core-concepts/`、`file-conventions/`
- **ファイル名**: `ticket.md`、`report.md`、`archive-ticket.md`
- **コード参照**: 「ファイル名にはkebab-caseを使用」

### 例外

- `README.md`は慣例により大文字
- `CHANGELOG.md`は慣例により大文字
- `CLAUDE.md`は慣例により大文字

### 関連用語

- frontmatter

## frontmatter

マークダウンファイルの先頭にあるYAMLメタデータブロック。

### 定義

frontmatterはマークダウンファイルの先頭で`---`で区切られたYAMLブロックです。title、description、category、last_updated、commit_hashなどのメタデータを含みます。`.workaholic/`内のすべてのドキュメントファイルには一貫性と追跡のためにfrontmatterが必要です。

### 使用パターン

- **ディレクトリ名**: N/A（ファイル内容であり、命名ではない）
- **ファイル名**: `.workaholic/`下のすべての`.md`ファイルに存在
- **コード参照**: 「ファイルにfrontmatterを追加」、「frontmatterのcommit_hashを更新」

### 標準フィールド

```yaml
---
title: Document Title
description: Brief description
category: user | developer
last_updated: YYYY-MM-DD
commit_hash: <short-hash>
---
```

### 関連用語

- kebab-case

## todo

実装待ちのアクティブな作業項目の保管場所。

### 定義

todoディレクトリは実装のためにキューに入れられたチケットを保持します。`/ticket`でチケットが作成されると、`.workaholic/tickets/todo/`に配置されます。`/drive`中、チケットはこのディレクトリからソート順（タイムスタンプ接頭辞順）で処理されます。実装とコミットが成功した後、チケットはtodoからarchiveに移動します。

### 使用パターン

- **ディレクトリ名**: `.workaholic/tickets/todo/`
- **ファイル名**: チケットはタイムスタンプ接頭辞付きの元の名前を保持
- **コード参照**: 「todoにキュー」、「todoからチケットを処理」

### 関連用語

- icebox、archive、ticket

## icebox

延期された作業項目の保管場所。

### 定義

iceboxは現在作業中ではないが、将来の検討のために保存すべきチケットを保持します。PRを作成する際、未完了のチケットは`.workaholic/tickets/todo/`から`.workaholic/tickets/icebox/`に移動されます（削除ではありません）。これにより、アクティブキューをクリアしながら計画された作業の損失を防ぎます。

### 使用パターン

- **ディレクトリ名**: `.workaholic/tickets/icebox/`
- **ファイル名**: iceboxされたチケットは元の名前を保持
- **コード参照**: 「iceboxに移動」、「iceboxを確認して...」

### 関連用語

- archive、ticket

## archive

完了した作業項目の保管場所。

### 定義

ファイル規約の文脈では、archiveディレクトリはブランチ名で整理された完了したチケットを保存します。パス`.workaholic/tickets/archive/<branch>/`には、そのブランチでの作業中に実装されたすべてのチケットが含まれます。アーカイブは過去の開発を理解するための履歴コンテキストを提供します。

### 使用パターン

- **ディレクトリ名**: `.workaholic/tickets/archive/`、`.workaholic/tickets/archive/<branch>/`
- **ファイル名**: アーカイブされたファイルは元の名前を保持
- **コード参照**: 「アーカイブを確認」、「アーカイブされたチケットを読む」

### 関連用語

- icebox、ticket

## fail

失敗分析を含む放棄された作業項目の保管場所。

### 定義

failディレクトリは`/drive`ワークフロー中に放棄されたチケットを保持します。実装アプローチが実行不可能であることが判明したか、チケットが根本的に欠陥があったためです。icebox（未完了のチケットを延期する）とは異なり、failディレクトリはFailure Analysisが添付された試みられた作業を保存します。`.workaholic/tickets/fail/`内の各放棄されたチケットは、何が試みられたか、なぜそれが失敗したか、これが将来の試みに何の見方を提供するかを説明する履歴レコードです。これにより、重複した失敗した試みを防ぎ、学習をgit履歴に記録します。

### 使用パターン

- **ディレクトリ名**: `.workaholic/tickets/fail/`
- **ファイル名**: 放棄されたチケットはFailure Analysisが追加された元の名前を保持
- **コード参照**: 「failに移動」、「failの放棄されたチケットを確認」

### 関連用語

- icebox、archive、ticket、abandon、failure-analysis

## guides

コマンド使用とワークフロー用のユーザー向けドキュメント。

### 定義

guidesディレクトリ（`.workaholic/guides/`）は、Workaholicの使用方法を説明するユーザー向けドキュメントを含みます。入門ガイド、コマンドリファレンス、ワークフローの例が含まれます。ガイドは（技術実装詳細をドキュメント化する）specsとは異なり、エンドユーザーにアクセスしやすいように整理されています。このディレクトリはユーザードキュメントと技術仕様の分離を明確にするために導入されました。

### 使用パターン

- **ディレクトリ名**: `.workaholic/guides/`
- **ファイル名**: `getting-started.md`、`commands.md`、`workflow.md`
- **コード参照**: 「ガイドを確認」、「guides/ディレクトリのユーザーガイド」

### 関連用語

- specs、kebab-case
