---
title: Security Policy
description: 保護すべき資産、脅威モデル、認証/認可の境界、実装されている保護措置
category: developer
modified_at: 2026-02-09T13:52:23+09:00
commit_hash: d627919
---

[English](security.md) | [Japanese](security_ja.md)

# Security Policy

本文書は、Workaholic リポジトリに実装されている security の実践を説明します。git 操作を自律的に管理する Claude Code plugin として、security に関する考慮事項は、credential の保護、実行境界、入力検証、および安全な運用パターンに集中しています。

## Authentication

### Git Credential 管理

自動化された操作には、repository スコープの GitHub token のみを使用します。release workflow は `${{ secrets.GITHUB_TOKEN }}` を使用しますが、これは GitHub Actions が自動的に提供する一時的な repository スコープの token であり、限定された権限 (`contents: write`) を持ちます。personal access token やカスタム secret は不要です(`.github/workflows/release.yml` に実装)。

### Author Identity の検証

Ticket 作成時に、`author` field で Anthropic email address を拒否することで、本物の作成者であることを強制します。validation hook は `@anthropic.com` の email を明示的にブロックし、開発者に `git config user.email` からの実際の git email の使用を要求します。これにより、AI 生成の attribution が ticket metadata に表示されることを防ぎます(`plugins/core/hooks/validate-ticket.sh` の 110-116 行に実装)。

## Authorization

### Git 操作の透明性

root の `README.md` には、Workaholic が開発者に代わって git を駆動することを示す目立つ警告セクションが含まれています。これには、branch の作成、commit、amend、push、および pull request の作成が含まれます。この透明性により、開発者はインストールについて情報に基づいた意思決定を行い、自動化された操作の範囲を理解できます。

### Permission フリーの実行モデル

Shell script は skill 内にバンドルされ、実行可能権限を必要とせずに `bash` command 経由で実行されます。これにより、plugin インストール時の permission prompt の必要性がなくなり、すべてのユーザー環境で一貫した動作が保証されます。script は厳格なエラー処理のために `#!/bin/sh -eu` パターンを使用します(`plugins/core/skills/*/sh/` 内のすべての script)。

### Hook Timeout の強制

PostToolUse validation hook は 10 秒の timeout を強制し、暴走した validation script が開発 workflow をブロックすることを防ぎます。これにより、validation の失敗が無期限にハングするのではなく、迅速に失敗することが保証されます(`plugins/core/hooks/hooks.json` に実装)。

## Secrets Management

### Git で無視されるローカル設定

`.gitignore` file は `.DS_Store` と `.claude/settings.local.json` を除外し、ローカル設定とユーザー固有の設定が repository に commit されることを防ぎます。ローカル設定には、共有すべきでない file system path やユーザー設定が含まれる可能性があります。

### Secret スキャン不要

観察されず。プロジェクトは実行時の依存関係がゼロであり、codebase 内でユーザー credential、API key、その他の secret を処理しません。すべての authentication は GitHub の組み込み token メカニズムを通じて処理されます。

## Input Validation

### Ticket Frontmatter の検証

PostToolUse hook を通じて、すべての Write および Edit 操作で ticket frontmatter の包括的な検証が強制されます。validation script (`plugins/core/hooks/validate-ticket.sh`) は以下を検証します:

- **File の場所**: `todo/`、`icebox/`、または `archive/<branch>/` directory にある必要があります
- **Filename 形式**: `YYYYMMDDHHmmss-*.md` パターンに一致する必要があります
- **YAML frontmatter の存在**: `---` で始まる必要があります
- **created_at field**: ISO 8601 形式である必要があります(例: `2026-01-29T04:19:24+09:00`)
- **author field**: 有効な email 形式であり、`@anthropic.com` ではない必要があります
- **type field**: `enhancement`、`bugfix`、`refactoring`、`housekeeping` のいずれかである必要があります
- **layer field**: `UX`、`Domain`、`Infrastructure`、`DB`、`Config` のみを含む YAML 配列
- **effort field**: 存在する場合、`0.1h`、`0.25h`、`0.5h`、`1h`、`2h`、`4h` のいずれかである必要があります
- **commit_hash field**: 存在する場合、7-40 文字の 16 進数である必要があります
- **category field**: 存在する場合、`Added`、`Changed`、`Removed` のいずれかである必要があります

Validation エラーは code 2 で終了し、操作をブロックし、権威あるドキュメントへの参照を含む明確なエラーメッセージを提供します。

### Shell Script のエラー処理

すべての shell script は `set -eu`(またはより厳格なバリアント)を使用し、fail-fast 動作を有効にします。これにより、script がエラー時(`-e`)および未定義変数の使用時(`-u`)に即座に終了し、部分的な実行がシステムを一貫性のない状態にすることを防ぎます(`plugins/core/skills/*/sh/` および `plugins/core/hooks/` 全体の 19 の shell script すべてに実装)。

### CI での JSON 検証

GitHub Actions workflow は、すべての push および pull request で JSON 設定 file を検証します:

- **marketplace.json の検証**: `jq empty` を使用して有効な JSON 構造を保証
- **plugin.json の検証**: JSON 構造を検証し、必須 field (`name`、`version`) を確認
- **Skill path の検証**: `plugin.json` で参照されているすべての skill path が file system に存在することを確認
- **Marketplace 整合性チェック**: `marketplace.json` にリストされている plugin に対応する directory があることを確認

これらの検証は `validate-plugins.yml` workflow で実行され、不正な形式の設定がマージされることを防ぎます。

### Git Command Injection の防止

Git command を構築する shell script は、shell quoting を使用し、command 構築でユーザー制御の入力を回避します。Git 操作は、予測可能な引数を持つ固定 command を使用します。たとえば、`gather-git-context/sh/gather.sh` は `git branch --show-current` および `git remote get-url origin` を使用し、ユーザー入力を command 文字列に補間しません。

## Observations

- プロジェクトは repository スコープの GitHub token のみを使用し、長期間有効な personal access token のセキュリティリスクを回避しています。
- ローカル設定は git で無視され、credential の漏洩や path の開示を防ぎます。
- Anthropic email の拒否により、ticket authorship の誤った attribution を防ぎ、監査証跡の整合性を保証します。
- すべての shell script での `set -eu` パターンは fail-fast 動作を提供し、部分的な実行状態を防ぎます。
- Permission フリーのバンドルされた script により、plugin システムにおける一般的なセキュリティ prompt 攻撃ベクトルが排除されます。
- 包括的な frontmatter 検証により、プロジェクト履歴の信頼できる情報源として機能する ticket system のデータ整合性が保証されます。
- CI での JSON 検証により、plugin の誤動作につながる可能性のある設定の破損を防ぎます。
- 10 秒の hook timeout により、暴走した validation script からのサービス拒否を防ぎます。

## Gaps

- 観察されず: 依存関係スキャンまたはサプライチェーンセキュリティツール。これは実行時の依存関係がゼロであることを考えると適切ですが、将来的に npm またはその他の package の追加が必要になる場合はスキャンが必要です。
- 観察されず: git 操作での署名付き commit または GPG 署名検証。
- 観察されず: 脆弱性報告またはセキュリティ連絡先情報のための明示的なセキュリティポリシードキュメント(SECURITY.md)。
- 観察されず: Claude Code の組み込み実行制限を超える Content Security Policy またはサンドボックス化。
- 観察されず: validation hook での単一の 10 秒 timeout を超える shell script 実行のレート制限またはリソース消費制限。
- 観察されず: ticket コンテンツ内の特殊文字の入力サニタイゼーション。ただし、markdown 形式は本質的な安全性を提供します。
