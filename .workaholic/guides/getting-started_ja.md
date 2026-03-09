---
title: Getting Started
description: Installation and first steps with Workaholic
category: user
modified_at: 2026-03-10T01:13:03+09:00
commit_hash: f76bde2
---

[English](getting-started.md) | [日本語](getting-started_ja.md)

# はじめに

Workaholicは開発ワークフローコマンドを提供するClaude Codeプラグインマーケットプレイスです。このガイドではインストールと基本設定について説明します。

## 前提条件

Claude Codeがインストールされ、実行されている必要があります。WorkaholicはClaude Codeのプラグインマーケットプレイスシステムを通じてインストールされます。

## インストール

ターミナルでClaude Codeを起動します：

```bash
claude
```

マーケットプレイスをインストールします：

```bash
/plugin marketplace add qmu/workaholic
```

プロンプトが表示されたら、個人使用の場合はユーザースコープを選択してください。最新の機能と修正を受け取るために、自動更新を有効にすることをお勧めします。

## 確認

インストール後、以下のcommandが利用可能になります：

**Drivin plugin**（チケット駆動開発）：
```bash
/ticket         # 実装仕様を記述
/drive          # チケットを一つずつ実装
/scan           # フルドキュメントスキャン
/report         # ドキュメントを生成しPRを作成
```

**Trippin plugin**（探索的・創造的開発）：
```bash
/trip           # Agent Teamsセッションを起動
```

## 次のステップ

各コマンドの詳細は[コマンドリファレンス](commands_ja.md)を、チケット駆動開発のアプローチについては[ワークフローガイド](workflow_ja.md)をお読みください。
