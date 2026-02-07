---
title: Accessibility Policy
description: Internationalization, localization, and content accessibility practices
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](accessibility.md) | [Japanese](accessibility_ja.md)

# 1. Accessibility Policy

このドキュメントは Workaholic リポジトリで観測されるアクセシビリティと国際化の実践を記述します。CLI ベースの開発者ツールとして、アクセシビリティは UI アクセシビリティ標準よりも言語サポートとドキュメントの明確さに関するものです。

## 2. Internationalization（i18n）

### 2-1. バイリンガルドキュメント

[Explicit] `.workaholic/` 内のすべてのドキュメントは対応する `_ja.md` 日本語翻訳を持つ必要があります。`translate` skill で critical rule として強制されています。

### 2-2. 翻訳ポリシー

[Explicit] `translate` skill が日本語翻訳の包括的なポリシーを提供します：コードブロック、frontmatter キー、ファイルパス、URL は保持し、散文コンテンツ、frontmatter 値、テーブルセルは翻訳します。技術用語は開発者ドキュメントでは英語を保持します。

### 2-3. README ミラーリング

[Explicit] 各言語の README は同じ言語のドキュメントにリンクし、並列ナビゲーション構造を維持します。

### 2-4. 言語境界

[Explicit] `.workaholic/` ディレクトリのコンテンツのみが日本語を含むことができます。

## 3. Content Accessibility

### 3-1. ドキュメント構造

[Explicit] 番号付き見出しが明確なドキュメント階層を提供します。Mermaid ダイアグラムがプラットフォーム間の表示改善のため ASCII アートを置き換えます。

### 3-2. 自己完結的定義

[Explicit] `.workaholic/terms/` の用語定義は定義、使用コンテキスト、例、関連概念を組み込んだ自己完結的な段落として記述されます。

## 4. Supported Languages

| コード | 言語 | カバレッジ |
| --- | --- | --- |
| en | 英語 | すべてのコンテンツの主要言語 |
| ja | 日本語 | `.workaholic/` ドキュメントの完全翻訳 |

## 5. Observations

- [Explicit] バイリンガルドキュメントは guide、spec、terms、story、policy を網羅しています。
- [Explicit] 技術用語は精度を維持するため日本語翻訳でも意図的に英語のまま保持されます。
- [Inferred] 広範な i18n インフラストラクチャは、主要な developer 対象に日本語話者が含まれることを示唆しています。

## 6. Gaps

- 観測されません：右から左への（RTL）言語サポート。
- 観測されません：英語版と日本語版間の自動翻訳品質チェックや一貫性検証。
- 観測されません：translate skill に記載された追加4言語（zh、ko、de、fr、es）の翻訳。
