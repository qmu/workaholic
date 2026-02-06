---
title: Technical Specifications
description: Viewpoint-based architecture specifications for the Workaholic plugin system
category: developer
modified_at: 2026-02-07T03:08:37+09:00
commit_hash: 82ffc1b
---

[English](README.md) | [日本語](README_ja.md)

# 技術仕様

Workaholicプラグインシステムのviewpointベースのアーキテクチャ仕様。各viewpointはコードベースを異なる視点から分析します。

- [Stakeholder](stakeholder_ja.md) - システムの利用者、その目標、インタラクションパターン
- [Model](model_ja.md) - ドメインコンセプト、関係性、コア抽象化
- [Use Case](usecase_ja.md) - ユーザーワークフロー、コマンドシーケンス、入出力コントラクト
- [Infrastructure](infrastructure_ja.md) - 外部依存関係、ファイルシステムレイアウト、インストール
- [Application](application_ja.md) - ランタイム動作、エージェントオーケストレーション、データフロー
- [Component](component_ja.md) - 内部構造、モジュール境界、分解
- [Data](data_ja.md) - データフォーマット、フロントマタースキーマ、命名規約
- [Feature](feature_ja.md) - 機能インベントリ、機能マトリクス、設定

### レガシードキュメント

- [アーキテクチャ](architecture_ja.md) - プラグイン構造とマーケットプレイス設計（ComponentとInfrastructure viewpointに置き換え）
- [コマンドフロー](command-flows_ja.md) - コマンドがエージェントとスキルを呼び出す方法（ApplicationとUse Case viewpointに置き換え）
- [コントリビュート](contributing_ja.md) - プラグインの追加・修正方法（Stakeholder viewpointに置き換え）

ユーザー向けドキュメントは [../guides/](../guides/README_ja.md) を参照。
ポリシードキュメントは [../policies/](../policies/README_ja.md) を参照。
