---
title: Accessibility Policy
description: Internationalization, localization, and content accessibility practices
category: developer
modified_at: 2026-02-11T15:20:19+00:00
commit_hash: f7f779f
---

[English](accessibility.md) | [Japanese](accessibility_ja.md)

# Accessibility Policy

このドキュメントは Workaholic リポジトリに実装されているアクセシビリティと国際化の実践を記述します。CLI ベースの開発者ツールとして、アクセシビリティは主に言語サポート、ドキュメントの明確さ、コンテンツ構造に関するもので、UI アクセシビリティ標準とは異なります。

## Internationalization

### バイリンガルドキュメント要件

`.workaholic/` 内のすべてのドキュメントは対応する `_ja.md` 日本語翻訳を持つ必要があります（`plugins/core/skills/translate/SKILL.md`、119-121行目：「CRITICAL RULE: `.workaholic/` 内の `.md` ファイルを作成または編集する際は、対応する `_ja.md` 翻訳も作成または更新する必要があります」）。この要件はすべてのドキュメント writer subagent にプリロードされる `translate` skill を通じて強制されます。

### 翻訳ガイドライン

`translate` skill（`plugins/core/skills/translate/SKILL.md`）は日本語翻訳の包括的なポリシーを提供します：

- 変更せず保持：code block、frontmatter キー、ファイルパス、URL、markdown 構造、HTML タグ
- 翻訳：散文コンテンツ、frontmatter 値（title、description）、テーブルセル、画像の alt テキスト
- 開発者ドキュメントでは技術用語を英語で保持（plugin、command、skill、rule、ticket、workflow など）
- 丁寧な文体を使用（日本語では desu/masu スタイル）
- 逐語訳よりも元の意味を保持

### 言語境界

コンテンツの言語は場所によって決定されます（`CLAUDE.md`、9-16行目）：

- `.workaholic/` ディレクトリ：英語または日本語（i18n 強制）
- その他すべてのコンテンツ：英語のみ（code、comment、commit message、pull request、`.workaholic/` 外のドキュメント）

この境界は project レベルのポリシーとして文書化され、ドキュメントレビュープロセスを通じて強制されます。

### README Link ミラーリング

各言語の README は同じ言語のドキュメントにリンクする必要があります（`plugins/core/skills/translate/SKILL.md`、135-143行目）。`README.md` は英語ドキュメントにリンクし、`README_ja.md` は `_ja.md` 翻訳にリンクし、並列ナビゲーション構造を維持します。これによりユーザーはドキュメントをナビゲートする際に言語コンテキスト内にとどまることができます。

## Supported Languages

| Code | 言語 | カバレッジ | 実装 |
| --- | --- | --- | --- |
| en | 英語 | すべてのコンテンツの主要言語 | 完全 |
| ja | 日本語 | `.workaholic/` ドキュメントの完全翻訳 | 完全 |
| zh | 中国語 | translate skill にリスト | 未実装 |
| ko | 韓国語 | translate skill にリスト | 未実装 |
| de | ドイツ語 | translate skill にリスト | 未実装 |
| fr | フランス語 | translate skill にリスト | 未実装 |
| es | スペイン語 | translate skill にリスト | 未実装 |

日本語翻訳は包括的で、guide、spec、terms、story、policy をカバーしています（`.workaholic/` ディレクトリ内の366個の markdown ファイルのうち42個の `_ja.md` ファイルが観測され、バイリンガルコンテンツの11.5%カバレッジを表しています）。

## Translation Workflow

### ファイル命名規則

翻訳は元のファイルと同じディレクトリに suffix ベースの命名を使用します（`plugins/core/rules/i18n.md`、14-21行目、38-39行目）：

```
.workaholic/specs/
  feature.md           # 英語
  feature_ja.md        # 日本語翻訳
  README.md            # 英語 index
  README_ja.md         # 日本語 index
```

ISO 639-1 言語コード（2文字コード）が suffix として使用されます。

### 手動翻訳プロセス

翻訳は `translate` skill ガイドラインに従って手動で実行されます。自動翻訳ツールやサービスは統合されていません。workflow は次のとおりです：

1. 英語ドキュメントを作成または更新
2. 日本語翻訳（`_ja.md`）を作成または更新
3. 並列リンク構造を維持するため `README.md` と `README_ja.md` の両方を更新

この workflow は `plugins/core/skills/translate/SKILL.md`（145-149行目）に文書化されています。

### 技術用語の保持

技術用語は日本語翻訳でも英語のまま保持されます（`plugins/core/skills/translate/SKILL.md`、78-83行目）。core concept（plugin、command、skill、rule、ticket、workflow）、git 用語（repository、branch、commit）、プログラミング概念（function、class、module、component）は技術的精度を維持し曖昧さを避けるため英語で保持されます。

## Accessibility Testing

### 設定検証

GitHub Actions workflow（`.github/workflows/validate-plugins.yml`）は以下を検証します：

- marketplace と plugin 設定ファイルの JSON 構文（23-29行目、32-59行目）
- plugin manifest の必須フィールド（name、version）
- skill ファイルの存在（61-79行目）
- marketplace-directory の整合性（81-102行目）

これは main branch へのすべての push と pull request で実行されます。

### Ticket フォーマット検証

検証 hook（`plugins/core/hooks/validate-ticket.sh`）は ticket ファイル標準を強制します：

- ファイル名フォーマット：`YYYYMMDDHHmmss-*.md`（49-54行目）
- YAML frontmatter の存在（65-69行目）
- フォーマット検証付き必須フィールド：`created_at`（ISO 8601）、`author`（email）、`type`、`layer`、`effort`、`commit_hash`、`category`（83-186行目）
- ディレクトリ位置制約（todo/、icebox/、archive/）（32-43行目）
- anthropic.com アドレスを拒否する author email 検証（111-116行目）

この hook は `.workaholic/tickets/` ファイルを対象とする Write/Edit 操作によって呼び出されます。

### コンテキスト認識 Rule 読み込み

i18n rule（`plugins/core/rules/i18n.md`）はパスベースのアクティベーションを使用します：

```yaml
---
paths:
  - '**/README*.md'
  - '.workaholic/**/*.md'
  - 'docs/**/*.md'
---
```

これにより i18n ポリシーは関連するドキュメントファイルにのみ適用され、code や設定ファイルには適用されません。

### Diagram 構文検証

diagrams rule（`plugins/core/rules/diagrams.md`）は Mermaid diagram 構文を強制します：

- ボックス描画文字を使用した ASCII アート diagram を禁止（18-22行目）
- GitHub レンダリングエラーを防ぐため特殊文字（`/`、`{`、`}`、`[`、`]`）を含むラベルの引用符を要求（34-48行目）
- `paths: ['**/*.md']` を介してすべての markdown ファイルに適用

## Content Accessibility

### 構造化見出し

番号付き見出しは明確なドキュメント階層を提供します。policy ドキュメントは `## 1. Section`、`### 1-1. Subsection` フォーマットを使用します。この規則はドキュメント構造を明示的にし、目次ツールを通じたナビゲーションを改善します。

### ビジュアルダイアグラムフォーマット

Mermaid diagram はクロスプラットフォームレンダリングの改善のため ASCII アートを置き換えます（`plugins/core/rules/diagrams.md`、8-21行目）：

- GitHub、VS Code、ほとんどのドキュメントシステムでネイティブにレンダリング
- version 管理可能で差分可能
- プラットフォーム間で一貫したレンダリング
- インタラクティブ（ズーム可能、クリック可能）

ボックス描画文字を使用した ASCII アート diagram は禁止されています（`plugins/core/rules/diagrams.md`、18-22行目）。

### 自己完結的定義

`.workaholic/terms/` の用語定義は、定義、使用コンテキスト、例、関連概念を組み込んだ包括的な単一段落として記述されます（`plugins/core/skills/write-terms/SKILL.md`、62-72行目）。これにより各エントリは相互参照を必要とせずに読みやすくなり、認知負荷が軽減され読者のアクセシビリティが向上します。

### オンボーディングドキュメント

`.workaholic/guides/` のユーザーガイドは以下をカバーします：

- はじめに
- command リファレンス
- 開発 workflow

root の `README.md` は具体的な例を含むクイックスタートを提供します。これらの資料は新規ユーザーのエントリーポイントとして機能します。すべての guide は対応する日本語翻訳（`getting-started_ja.md`、`commands_ja.md`、`workflow_ja.md`）を持ちます。

### 用語の一貫性

`.workaholic/terms/` ディレクトリは5つのカテゴリファイルにわたって一貫した用語定義を維持します：

- `core-concepts.md` - plugin、command、skill、rule、agent
- `artifacts.md` - ticket、spec、story、changelog
- `workflow-terms.md` - drive、archive、sync、release
- `file-conventions.md` - kebab-case、frontmatter、icebox、archive
- `inconsistencies.md` - 既知の用語の問題

各用語は定義、使用コンテキスト、他の用語との関係とともに文書化されています（`plugins/core/skills/write-terms/SKILL.md`、61-71行目）。

## Observations

- バイリンガルドキュメントは包括的で、すべての `.workaholic/` サブディレクトリ（guide、spec、terms、story、policy）をカバーしています
- 技術用語は技術的精度を維持するため日本語翻訳でも意図的に英語で保持されます
- i18n rule はパスベースのアクティベーション（`paths` frontmatter）を使用してドキュメントファイルにのみ適用されます
- 検証メカニズムはコンテンツ品質ではなく構造的整合性（JSON 構文、frontmatter フォーマット、ファイル存在）に焦点を当てています
- 翻訳 workflow は手動で人間主導であり、自動整合性チェックはありません
- 広範な i18n インフラストラクチャ（専用 translate skill、i18n rule、_ja suffix 規則、必須翻訳要件）は、主要な developer 対象に日本語話者が含まれることを示しています
- コンテキスト認識 rule は i18n 要件が code や設定ファイルに適用されるのを防ぎます
- diagram 検証は適切な Mermaid 構文を強制することでレンダリングエラーを防ぎます

## Gaps

- 観測されません：英語版と日本語版間の自動翻訳品質チェックまたは整合性検証
- 観測されません：右から左への（RTL）言語サポートまたは双方向テキスト処理
- 観測されません：screen reader 最適化または ARIA 属性（CLI ツールには適用されません）
- 観測されません：translate skill にリストされた追加言語の翻訳（zh、ko、de、fr、es）
- 観測されません：自動アクセシビリティテストツール（axe、Pa11y など、CLI ツールには適用されません）
- 観測されません：カラーコントラスト検証または terminal カラースキーム考慮
- 観測されません：フォントレンダリングまたは文字エンコーディング検証
- 観測されません：ドキュメント間の整合性のための翻訳メモリまたは用語データベース
