---
title: Contributing
description: How to add or modify plugins in Workaholic
category: developer
modified_at: 2026-01-27T09:57:08+09:00
commit_hash: a525e04
---

[English](contributing.md) | [日本語](contributing_ja.md)

# コントリビュート

このガイドでは、新しいコマンドの追加、バグ修正、新しいプラグインの作成など、Workaholicへの貢献方法を説明します。

## 開発環境のセットアップ

リポジトリをクローンし、プラグインコマンドを使用して開発を管理します：

```bash
git clone https://github.com/qmu/workaholic
cd workaholic
claude
```

## 重要: plugins/を編集し、.claude/は編集しない

このリポジトリはプラグインを開発します。すべての変更は`plugins/`ディレクトリに行い、明示的に要求されない限り`.claude/`には変更を加えません。ユーザーインストール時の`.claude/`ディレクトリはClaude Codeによって管理されます。

## ワークフロー

workaholic自体の開発にworkaholicワークフローを使用します：

```mermaid
flowchart LR
    A[/ticket] --> B[/drive] --> C[/report]
```

1. **チケットを作成**: `/ticket add new validation rule`
2. **実装**: `/drive` - チケットに従い、ドキュメントを更新し、承認時にコミット
3. **PRを作成**: `/report` - ドキュメントを生成しPRを作成

すべての実装にはドキュメント更新が含まれます。これは必須であり、スキップできません。

## コマンドの追加

コマンドは`plugins/<plugin>/commands/`に配置されます。マークダウンファイルを作成します：

```markdown
---
name: mycommand
description: Brief description of what it does
---

# My Command

このコマンドが呼び出されたときにClaudeが従う指示。

## Instructions

1. 最初のステップ
2. 2番目のステップ
```

フロントマターの`name`がスラッシュコマンド（`/mycommand`）になります。

## ルールの追加

ルールは`plugins/<plugin>/rules/`に配置されます。常にアクティブです：

```markdown
---
name: myrule
description: Coding standard this rule enforces
---

# My Rule

会話中ずっとClaudeが従うガイドライン。
```

## スキルの追加

スキルはより複雑で、スクリプトを含む場合があります。ディレクトリを作成します：

```
plugins/<plugin>/skills/my-skill/
  SKILL.md           # スキルドキュメント
  scripts/
    run.sh           # 実行可能スクリプト
```

## ドキュメント基準

ドキュメント更新はすべての変更に対して必須です。`/report`コマンドは4つのドキュメントサブエージェント（changelog-writer、story-writer、spec-writer、terms-writer）を自動的に並列実行するため、PR作成前にドキュメントは常に更新されます。

spec-writerとterms-writerサブエージェントが強制するドキュメント基準：

- すべてのマークダウンファイルにYAMLフロントマター（`commit_hash`フィールドを含む）
- 図にはMermaidを使用（ASCII図は禁止）
- 箇条書きの断片ではなく、散文の段落を書く
- ルートREADMEからのリンク階層を維持
- ドキュメント修正時に`modified_at`と`commit_hash`フィールドを更新
- ドキュメントは適切なサブディレクトリに配置: `user-guide/`はユーザー向け、`developer-guide/`はアーキテクチャ向け

ドキュメントは任意ではありません。すべてのコード変更は何らかの形でドキュメントに影響します。既存のドキュメントの更新、新しいドキュメントの作成、古いファイルの削除、構造の再編成など。

## 変更のテスト

このプロジェクトにはビルドステップがありません。テストするには：

1. フォークをマーケットプレイスとしてインストール: `/plugin marketplace add youruser/workaholic`
2. 別のプロジェクトでコマンドをテスト
3. 動作が期待通りであることを確認

## コミットメッセージ

コミットメッセージのルールに従います：

- プレフィックスなし（`feat:`、`fix:`などなし）
- 現在形の動詞で開始（Add、Update、Fix、Remove）
- 変更が行われた理由に焦点を当てる
- タイトルは50文字以内

## プルリクエスト

`/report`でPRを作成します。サマリーはストーリーファイルから自動生成され、アーカイブされたチケットを一貫したナラティブに統合します。PRが以下を満たしていることを確認してください：

- クリーンなコミット履歴（1チケット = 1コミット）
- ドキュメント更新を含む（サブエージェントによって自動的に処理）
- コードベースの既存パターンに従う
