---
title: Technical Specifications
description: Viewpoint-based architecture specifications for the Workaholic plugin system
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](README.md) | [日本語](README_ja.md)

# 技術仕様

Workaholic plugin システムの viewpoint ベースのアーキテクチャ仕様です。各 viewpoint はコードベースを異なる視点から分析します。Viewpoint ドキュメントは scanner subagent によって生成されます。

- [Stakeholder](stakeholder_ja.md) - システムの利用者、目標、インタラクションパターン
- [Model](model_ja.md) - ドメイン概念、関係性、コア抽象化
- [Use Case](usecase_ja.md) - ユーザーワークフロー、command シーケンス、入出力契約
- [Infrastructure](infrastructure_ja.md) - 外部依存関係、ファイルシステムレイアウト、インストール
- [Application](application_ja.md) - ランタイム動作、エージェントオーケストレーション、データフロー
- [Component](component_ja.md) - 内部構造、モジュール境界、分解
- [Data](data_ja.md) - データ形式、frontmatter スキーマ、命名規則
- [Feature](feature_ja.md) - 機能インベントリ、機能マトリクス、設定

ユーザー向けドキュメントは [../guides/](../guides/README_ja.md) を参照。
ポリシードキュメントは [../policies/](../policies/README_ja.md) を参照。
