---
title: Security Policy
description: 保護すべき資産、脅威モデル、認証/認可の境界、実装されている保護措置
category: developer
modified_at: 2026-02-11T15:20:15+00:00
commit_hash: f7f779f
---

[English](security.md) | [Japanese](security_ja.md)

# Security Policy

本文書は、Workaholic リポジトリに実装されている security の実践を説明します。git 操作を自律的に管理する Claude Code plugin として、security に関する考慮事項は、credential の保護、実行境界、入力検証、および安全な運用パターンに集中しています。プロジェクトは実行時の依存関係がゼロであり、git 操作以外でユーザー credential を処理しないため、脅威の対象は git credential 管理、shell script 実行の安全性、および ticket metadata の整合性に絞られます。

## Authentication

### Git Credential 管理

自動化された操作には、repository スコープの GitHub token のみを使用します。release workflow は `${{ secrets.GITHUB_TOKEN }}` を使用しますが、これは GitHub Actions が自動的に提供する一時的な repository スコープの token であり、限定された権限を持ちます。workflow は明示的に `contents: write` 権限スコープを宣言し、release の作成に必要な最小限のアクセスのみを付与します(`.github/workflows/release.yml` の 9-10 行に実装)。personal access token やカスタム secret は不要です。

### Author Identity の検証

Ticket 作成時に、`author` field で Anthropic email address を拒否することで、本物の作成者であることを強制します。validation hook は regex パターンマッチング (`[[ "$author" =~ @anthropic\.com$ ]]`) を使用して `@anthropic.com` の email を明示的にブロックし、開発者に `git config user.email` からの実際の git email の使用を要求します。これにより、AI 生成の attribution が ticket metadata に表示されることを防ぎ、監査証跡の整合性を保証します(`plugins/core/hooks/validate-ticket.sh` の 111-116 行に実装)。

### Email フォーマットの検証

validation hook は、`author` field に対して regex パターン `^[^@]+@[^@]+\.[^@]+$` を使用して email フォーマットを強制し、Anthropic domain チェックの前に基本的な構造的妥当性を保証します。不正な形式の email address を持つ ticket は、権威ある skill ドキュメントを参照する明確なエラーメッセージで拒否されます(`plugins/core/hooks/validate-ticket.sh` の 104-108 行に実装)。

## Authorization

### Git 操作の透明性

root の `README.md` には、GitHub の warning callout 構文を使用した目立つ警告セクション(5-6 行)が含まれており、Workaholic が開発者に代わって git を駆動することを示しています。これには、branch の作成、commit、amend、push、および pull request の作成が含まれます。この透明性により、開発者は plugin を有効にする前にインストールについて情報に基づいた意思決定を行い、自動化された操作の範囲を理解できます。

### Permission フリーの実行モデル

Shell script は skill 内にバンドルされ、実行可能権限を必要とせずに `bash` command 経由で実行されます。リポジトリ内のすべての 19 の shell script は、shebang `#!/bin/sh -eu` パターンまたは同等のものを使用し、chmod +x の必要性を回避しながら厳格なエラー処理を可能にします。これにより、plugin インストール時の permission prompt が排除され、filesystem 権限に関係なくすべてのユーザー環境で一貫した動作が保証されます(`plugins/core/skills/*/sh/` および `plugins/core/hooks/` 内のすべての script)。

### Hook Timeout の強制

PostToolUse validation hook は、ticket validation script に 10 秒の timeout を強制し、暴走した validation が開発 workflow をブロックすることを防ぎます。timeout は command 仕様と並んで hook 設定で宣言され、validation の失敗が無期限にハングするのではなく、迅速に失敗することを保証します(`plugins/core/hooks/hooks.json` の 11 行に実装: `"timeout": 10`)。

### Branch 保護

観察されず。repository 設定に GitHub branch protection rule は設定されていません。main branch は pull request 要件なしで直接 commit できます。これは個人の開発ツール repository には適切ですが、自動化された git 操作がすべての branch に完全な書き込みアクセスを持つことを意味します。

## Secrets Management

### Git で無視されるローカル設定

`.gitignore` file は `.DS_Store` と `.claude/settings.local.json` を除外し、ローカル設定とユーザー固有の設定が repository に commit されることを防ぎます。settings.local.json file には、共有すべきでない file system path やユーザー設定が含まれる可能性があります。macOS metadata file (.DS_Store) も除外され、directory 構造に関する意図しない情報開示を防ぎます。

### ゼロ実行時依存関係

プロジェクトは、shell command と GitHub Actions 以外の npm 依存関係、Python package、その他の実行時 library がゼロです。これにより、supply chain 攻撃のクラス全体が排除されます。validation workflow は JSON 構造を検証しますが、外部 package をインストールまたは実行しません(package.json、requirements.txt、または同様の依存関係 manifest の不在により検証)。

### GitHub Actions Token スコープ

release workflow は、デフォルトの workflow 権限を使用するのではなく、明示的な権限スコープ (`contents: write`) を宣言します。これは、workflow の機能を release の作成に必要なもののみに制限することで、最小権限の原則に従います。他の権限スコープ(issue、pull request、deployment)は付与されません(`.github/workflows/release.yml` の 9-10 行に実装)。

### Secret スキャンなし

観察されず。repository は GitHub の secret スキャン機能を設定しておらず、サードパーティの secret 検出ツールも使用していません。実行時依存関係がゼロで、GitHub の組み込み token メカニズム以外でユーザー credential を処理しないため、このギャップはリスクが低いですが、将来の追加で誤って commit された personal token や API key を検出するには価値があります。

## Input Validation

### Ticket Frontmatter の検証

PostToolUse hook を通じて、すべての Write および Edit 操作で ticket frontmatter の包括的な検証が強制されます。validation script (`plugins/core/hooks/validate-ticket.sh`) は、file の場所、filename フォーマット、および複数の frontmatter field を検証します:

**File 制約:**
- **場所**: `todo/`、`icebox/`、または `archive/<branch>/` directory に存在する必要があります(32-42 行)
- **Filename フォーマット**: regex `^[0-9]{14}-.*\.md$` を使用して `YYYYMMDDHHmmss-*.md` パターンに一致する必要があります(49-54 行)
- **Frontmatter の存在**: `---` で開始する必要があります(65-68 行)

**検証付き必須 field:**
- **created_at**: パターン `^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}$` に一致する ISO 8601 フォーマットである必要があります(83-95 行)
- **author**: 有効な email フォーマットで、`@anthropic.com` ではない必要があります(97-116 行)
- **type**: `enhancement`、`bugfix`、`refactoring`、`housekeeping` のいずれかである必要があります(118-127 行)
- **layer**: `UX`、`Domain`、`Infrastructure`、`DB`、`Config` のみを含む YAML 配列である必要があります(129-145 行)

**存在する場合に検証される任意 field:**
- **effort**: `0.1h`、`0.25h`、`0.5h`、`1h`、`2h`、`4h` のいずれかである必要があります(147-156 行)
- **commit_hash**: 7-40 文字の 16 進数である必要があります(158-167 行)
- **category**: `Added`、`Changed`、`Removed` のいずれかである必要があります(169-178 行)

検証エラーは exit code 2 で終了し、操作をブロックし、`print_skill_reference()` を通じて権威あるドキュメントへの参照を含む明確なエラーメッセージを提供します。

### Shell Script エラー処理

すべての shell script は `set -eu` またはより厳格なバリアント (`#!/bin/sh -eu`) を使用し、fail-fast の動作を有効にします。`-e` flag は、ゼロ以外を返すコマンドで script を直ちに終了させ、`-u` flag は未定義の変数使用時に終了します。これにより、部分的な実行がシステムを不整合な状態に残すことを防ぎます。すべての 19 の shell script で shebang および set command のパターンマッチングにより検証されました。

### CI での JSON 検証

GitHub Actions workflow は、jq を使用した構造検証により、すべての push および pull request で JSON 設定 file を検証します(`.github/workflows/validate-plugins.yml`):

- **marketplace.json の検証**: `jq empty` を使用して有効な JSON 構造を保証します(23-29 行)
- **plugin.json の検証**: `jq empty` で JSON 構造を検証します(33-40 行)
- **必須 field チェック**: jq セレクタを使用して `name` および `version` field を抽出して検証します(42-56 行)
- **Skill path の検証**: `jq -r '.skills[]?.path // empty'` で plugin.json から skill path を読み取り、file が存在することを確認します(61-79 行)
- **Marketplace 整合性チェック**: marketplace.json 内の plugin 名と実際の directory を比較します(81-102 行)

これらの検証により、不正な形式の設定がマージされることを防ぎ、plugin 読み込み失敗の原因となる構文エラーから保護します。

### Git Command Injection の防止

git command を構築する shell script は、ユーザー制御の入力を補間せずに固定の command 構造を使用します。たとえば、`gather-git-context/sh/gather.sh` は、`git branch --show-current`、`git remote show origin`、`git remote get-url origin` などの静的 command を使用し、command 文字列自体への変数補間はありません。変数は command 実行が完了した後にのみ使用され、command 構築ではなく出力に対して操作します(8-16 行)。

URL 変換操作は、ユーザー提供の regex ではなく固定パターンを持つ sed を使用し(`sed 's|^git@github\.com:|https://github.com/|'`)、悪意のある remote URL を通じた injection を防ぎます。

### Markdown コンテンツの安全性

観察されず。frontmatter 検証以外に、ticket の markdown 本文コンテンツに対してサニタイゼーションや検証は実行されません。悪意のある markdown には、web コンテキストでレンダリングされた場合に安全でない script tag、XSS payload、その他のコンテンツが含まれる可能性があります。ticket は AI 消費用のローカル file であるためリスクは低いですが、ticket コンテンツが web UI に表示される場合には関連する可能性があります。

## Observations

プロジェクトは、脅威モデルに対する多層防御を複数の保護層を通じて示しています:

- 明示的な最小権限を持つ repository スコープの GitHub token により、長期間の credential リスクを回避
- ローカル設定は git で無視され、credential 漏洩や path 開示を防止
- Anthropic email の拒否により、監査証跡の整合性を保証し、誤った attribution を防止
- すべての 19 の shell script での `set -eu` パターンにより、fail-fast の動作を提供し、部分的な実行状態を防止
- Permission フリーのバンドルされた script により、plugin system における一般的な security prompt 攻撃ベクトルを排除
- 7 つの検証された field を持つ包括的な frontmatter 検証により、ticket system のデータ整合性を保証
- 必須 field チェックを含む CI での JSON 検証により、設定の破損を防止
- 10 秒の hook timeout により、暴走した validation script からのサービス拒否を防止
- ゼロ実行時依存関係により、supply chain 攻撃の対象を完全に排除
- Git command 構築は、ユーザー入力の補間なしに固定パターンを使用
- README の透明な警告により、ユーザーは git 自動化範囲についてインフォームドコンセントを得る

security 態勢は、network service、ユーザー認証システム、または platform が管理する git credential 以外の機密データストレージを持たない、ローカル git 操作を処理する開発ツールに適切です。

## Gaps

実装が観察されなかったが、将来の考慮に関連する可能性がある領域:

- 観察されず: Dependabot や Snyk などの依存関係スキャンや supply chain security ツールはありません。現在、実行時依存関係がゼロであるため適切ですが、npm package、Python library、または GitHub Actions の将来の追加には、既知の脆弱性を監視するための依存関係スキャンが必要になります。

- 観察されず: git 操作での署名付き commit や GPG 署名検証はありません。Ticket authorship 検証は metadata レベルで監査証跡の整合性を提供しますが、git commit 自体は暗号的に署名または検証されません。

- 観察されず: 脆弱性報告や security 連絡先情報のための明示的な security policy document (SECURITY.md) はありません。外部の研究者が脆弱性を発見した場合、責任ある開示のための文書化されたチャネルがありません。

- 観察されず: Claude Code の組み込み実行制限を超える Content Security Policy やサンドボックス化はありません。Shell script は、file system アクセスや git 操作を含む、ユーザーの完全な権限で実行されます。

- 観察されず: validation hook の単一の 10 秒 timeout を超える、shell script 実行でのレート制限やリソース消費制限はありません。skill での長時間実行される script は、過度の CPU やメモリを消費する可能性があります。

- 観察されず: ticket markdown 本文コンテンツでの特殊文字の入力サニタイゼーションはありません。frontmatter は検証されますが、markdown コンテンツ自体は潜在的に悪意のあるコンテンツに対してサニタイズされません。

- 観察されず: GitHub branch protection rule はありません。main branch は、pull request レビュー要件、code owner 承認、またはステータスチェックなしで直接 commit できます。

- 観察されず: command injection パターン、eval の安全でない使用、または危険なコンテキストでの引用符なしの変数展開などの一般的な脆弱性に対する shell script の自動化された security スキャンはありません。
