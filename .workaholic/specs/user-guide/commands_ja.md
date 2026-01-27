---
title: Command Reference
description: Complete documentation for all Workaholic commands
category: user
modified_at: 2026-01-27T21:13:30+09:00
commit_hash: 82335e6
---

[English](commands.md) | [日本語](commands_ja.md)

# コマンドリファレンス

Workaholicは統一された**core**プラグインを提供し、gitワークフローコマンドとチケット駆動開発機能を組み合わせています。

## Gitワークフローコマンド

### /branch

一貫した命名のためのタイムスタンプ接頭辞付きトピックブランチを作成します。

```bash
/branch
```

`feat-20260120-205418`のようなブランチを生成し、ユニークなブランチ名と時系列順序を保証します。接頭辞により、機能の作業がいつ開始されたかを識別できます。

### /report

包括的なドキュメントを生成し、プルリクエストを作成または更新します。

```bash
/report
```

コマンドは5つのサブエージェントを調整してドキュメント成果物を生成します：changelog-writerが`CHANGELOG.md`を更新し、story-writerがPRナラティブを生成し、spec-writerが`.workaholic/specs/`を更新し、terms-writerが`.workaholic/terms/`を更新し、pr-creatorがGitHub PRの作成を処理します。最初の4つは並列実行され、その後pr-creatorが生成されたストーリーをボディとして使用してPRを作成します。

PRの説明にはストーリードキュメントの内容が使用されます。ストーリーには以下の11セクションが含まれます：Overview、Motivation、Journey、Changes、Outcome、Historical Analysis、Concerns、Ideas、Performance、Release Preparation、Notes。Journeyセクションには変更をテーマや関心事ごとにグループ化したMermaidフローチャート（Topic Tree）が含まれ、レビュアーにナラティブの視覚的コンテキストを提供します。Changesセクションは各チケットを時系列順に個別のサブセクションとして記載します。Release Preparationセクションにはリリース準備の判定と懸念事項、リリース前後の手順が含まれます。ストーリードキュメントは`.workaholic/stories/<branch-name>.md`に保存され、PR説明文の単一の真実の情報源として機能します。パフォーマンスメトリクスは単一セッションの作業（8時間未満）には時間を、複数日にわたる作業にはbusiness dayを使用し、意味のある速度測定を提供します。

## チケット駆動開発コマンド

### /ticket

コードベースを調査し、実装仕様を記述します。

```bash
/ticket add user authentication
/ticket icebox refactor database layer
```

Claudeは既存のパターンとアーキテクチャを理解するためにコードベースを読み、詳細な実装チケットを生成します。チケットには概要、変更するキーファイル、ステップバイステップの実装計画、考慮事項が含まれます。

チケットはタイムスタンプ付きで`.workaholic/tickets/todo/`に保存されます。`icebox`を使用すると、後で実装するチケットを`.workaholic/tickets/icebox/`に保存できます。

### /drive

キューに入っているチケットを上から順に実装します。

```bash
/drive
/drive icebox
```

Claudeは`.workaholic/tickets/todo/`からチケットを取り出し、一つずつ実装し、承認を求め、逸脱を文書化するFinal Reportを作成し、次に進む前にコミットとアーカイブを行います。`icebox`引数を使用すると、延期されたチケットから選択できます。

## ワークフローサマリー

一般的なワークフローはこれらのコマンドを組み合わせます：

1. `/branch` - 新しいフィーチャーブランチを開始
2. `/ticket <description>` - 実装仕様を記述
3. `/drive` - チケットを実装
4. `/report` - ドキュメントを生成し、レビュー用のPRを作成

各チケットは独自のコミットを取得し、CHANGELOGがPRサマリーのためにすべての変更を追跡します。
