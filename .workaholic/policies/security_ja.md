---
title: Security Policy
description: Authentication, authorization, secrets management, and security practices
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](security.md) | [Japanese](security_ja.md)

# 1. Security Policy

このドキュメントは Workaholic リポジトリで観測されるセキュリティ実践を記述します。git 操作を自律的に管理する Claude Code plugin として、セキュリティの考慮事項は資格情報の保護、入力検証、安全な実行境界に集中しています。

## 2. Credential Protection

### 2-1. Git-Ignored Secrets

[Explicit] `.gitignore` は `.DS_Store` と `.claude/settings.local.json` を除外し、ローカル設定がコミットされることを防ぎます。

### 2-2. Author Validation

[Explicit] ticket 作成プロセスは `author` フィールドで Anthropic メールアドレスを明示的に拒否し、developer 自身の git メールを要求します。

### 2-3. GitHub Token Handling

[Explicit] release GitHub Action は `${{ secrets.GITHUB_TOKEN }}` を認証に使用します。これはリポジトリスコープのトークンで、カスタム secret は不要です。

## 3. Execution Boundaries

### 3-1. Git Operation Warning

[Explicit] ルート `README.md` に Workaholic が developer に代わって git を操作する旨の警告が含まれています。

### 3-2. Permission-Free Shell Scripts

[Explicit] shell script は skill 内にバンドルされ `bash` command で実行され、実行権限が不要です。`#!/bin/sh -eu` で厳格なエラーハンドリングを使用します。

### 3-3. Hook Timeout

[Explicit] PostToolUse 検証 hook は10秒のタイムアウトを持ち、暴走する検証スクリプトが開発をブロックすることを防ぎます。

## 4. Observations

- [Explicit] プロジェクトはリポジトリスコープの GitHub token を使用し、個人アクセストークンは使用しません。
- [Explicit] ローカル設定は資格情報漏洩を防ぐため git-ignore されています。
- [Inferred] shell script の `set -eu` パターンはフェイルファスト動作を提供し、部分的な実行がシステムを不整合な状態に置くことを防ぎます。

## 5. Gaps

- 観測されません：依存関係スキャンやサプライチェーンセキュリティツール。
- 観測されません：署名付きコミットやタグ検証。
- 観測されません：脆弱性報告のための明示的なセキュリティポリシー（SECURITY.md）。
