---
title: Delivery Policy
description: CI/CD pipeline, release process, and deployment practices
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](delivery.md) | [Japanese](delivery_ja.md)

# 1. Delivery Policy

このドキュメントは Workaholic リポジトリで観測される継続的インテグレーション、デリバリー、リリースの実践を記述します。デリバリーは GitHub Actions workflow と plugin 組み込みの `/release` command で自動化されています。

## 2. Continuous Integration

### 2-1. Plugin Validation

[Explicit] `validate-plugins.yml` workflow が `main` への全プッシュと pull request で実行されます。4つの検証ステップを実行します：JSON 構文検証、必須フィールド検証、skill ファイル存在確認、ディレクトリ対応確認。

### 2-2. CI Environment

[Explicit] CI は Node.js 20 を使用する `ubuntu-latest` で実行されます。

## 3. Release Process

### 3-1. Automated Release

[Explicit] `release.yml` workflow は `main` へのプッシュまたは手動ディスパッチでトリガーされます。`marketplace.json` のバージョンを最新の GitHub Release と比較し、新しい場合は GitHub Release を作成します。

### 3-2. Version Management

[Explicit] 2つのバージョンファイルを同期する必要があります。`/release` command が両方を更新しコミットを作成します。バージョン形式はセマンティックバージョニング（現在 `1.0.32`）です。

### 3-3. Release Notes

[Explicit] release workflow は `.workaholic/release-notes/` の生成されたリリースノートを探し、存在しない場合は git log にフォールバックします。

## 4. Branch Strategy

[Explicit] 開発ブランチは `drive-<YYYYMMDD>-<HHMMSS>` または `trip-<YYYYMMDD>-<HHMMSS>` パターンを使用します。base branch は `main` です。

## 5. Observations

- [Explicit] CI 検証は動作テストではなく構造的整合性に焦点を当てています。
- [Explicit] リリースプロセスは半自動化：developer が `/release` でバージョンをバンプし、GitHub Action が `main` マージ時にリリースを作成します。
- [Inferred] release workflow の git log へのフォールバックは、正式なリリースノートが生成されていなくてもリリースが常に説明付きで作成されることを保証します。

## 6. Gaps

- 観測されません：リリース前に plugin 変更をテストするステージングやプレビュー環境。
- 観測されません：新バージョンのカナリアや段階的ロールアウトメカニズム。
- 観測されません：リリースに問題がある場合の自動ロールバック機能。
