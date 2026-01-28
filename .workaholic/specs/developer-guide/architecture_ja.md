---
title: Architecture
description: Plugin structure and marketplace design
category: developer
modified_at: 2026-01-28T21:38:50+09:00
commit_hash: fe3d558
---

[English](architecture.md) | [日本語](architecture_ja.md)

# アーキテクチャ

WorkaholicはClaude Codeプラグインマーケットプレイスです。ランタイムコードを含まず、プラグインはClaude Codeがコマンド、ルール、スキル、エージェントとして解釈するJSONメタデータを持つマークダウンファイルです。

## マーケットプレイス構造

```mermaid
flowchart TD
    subgraph Marketplace
        M[.claude-plugin/marketplace.json]
    end
    subgraph Core Plugin
        P1[plugins/core/]
        C1[commands/]
        C2[rules/]
        C3[skills/]
        C4[agents/]
    end
    M --> P1
    P1 --> C1
    P1 --> C2
    P1 --> C3
    P1 --> C4
```

## ディレクトリレイアウト

```
.claude-plugin/
  marketplace.json       # マーケットプレイスのメタデータとプラグインリスト

plugins/
  core/
    .claude-plugin/
      plugin.json        # プラグインメタデータ
    agents/
      changelog-writer.md     # チケットからCHANGELOG.mdを更新
      performance-analyst.md  # PRストーリーの意思決定レビュー
      pr-creator.md           # GitHub PRの作成/更新
      release-readiness.md    # リリース準備状況の分析
      spec-writer.md          # .workaholic/specs/を更新
      story-writer.md         # PR用のブランチストーリーを生成
      terms-writer.md         # .workaholic/terms/を更新
    commands/
      branch.md          # /branch コマンド
      drive.md           # /drive コマンド
      report.md          # /report コマンド
      ticket.md          # /ticket コマンド
    rules/
      diagrams.md      # Mermaid図表要件
      general.md       # Gitワークフロールール、マークダウンリンク
      i18n.md          # 多言語ドキュメントルール
      shell.md         # POSIX シェルスクリプト規約
      typescript.md    # TypeScriptコーディング規約
    skills/
      analyze-performance/
        SKILL.md           # パフォーマンス分析フレームワーク
      archive-ticket/
        SKILL.md
        sh/
          archive.sh       # コミットワークフロー用シェルスクリプト
      assess-release-readiness/
        SKILL.md           # リリース準備分析ガイドライン
      create-branch/
        SKILL.md
        sh/
          create.sh        # タイムスタンプ付きトピックブランチを作成
      create-pr/
        SKILL.md
        sh/
          create-or-update.sh  # GitHub PRの作成/更新
      create-ticket/
        SKILL.md           # フォーマットとガイドラインを含むチケット作成
      drive-workflow/
        SKILL.md           # チケット実装ワークフロー
      generate-changelog/
        SKILL.md
        sh/
          generate.sh      # チケットからchangelogエントリを生成
      translate/
        SKILL.md           # 翻訳ポリシーと.workaholic/ i18n強制
      write-changelog/
        SKILL.md           # changelogライティングガイドライン
      write-spec/
        SKILL.md
        sh/
          gather.sh        # コンテキスト収集とスペック作成
      write-story/
        SKILL.md
        sh/
          calculate.sh     # メトリクス計算とストーリー作成
      write-terms/
        SKILL.md
        sh/
          gather.sh        # コンテキスト収集と用語作成
```

## プラグインタイプ

### コマンド

コマンドはスラッシュ構文（`/ticket`、`/drive`、`/report`）でユーザーが呼び出せます。各コマンドは名前と説明を定義するYAMLフロントマター付きのマークダウンファイルで、その後にコマンドが呼び出されたときにClaudeが従う指示が続きます。

### ルール

ルールは会話中ずっとClaudeが従う常時オンのガイドラインです。コーディング規約、ドキュメント要件、ベストプラクティスを定義します。

### スキル

スキルはスクリプトや複数のファイルを含む可能性のある複雑な機能です。Skillツールで呼び出され、インライン指示を提供します。多くのスキルには機械的な操作を処理するbashスクリプトが含まれ、エージェントは意思決定を担当します。coreプラグインには以下が含まれます：

- **analyze-performance**: 5つの次元にわたる意思決定品質の評価フレームワーク
- **archive-ticket**: 完全なコミットワークフロー（チケットのアーカイブ、フロントマターにコミットハッシュ/カテゴリを更新、コミット）を処理
- **assess-release-readiness**: 変更を分析しリリース準備状況を判定するガイドライン
- **create-branch**: 設定可能なプレフィックス付きでタイムスタンプ付きトピックブランチを作成
- **create-pr**: gh CLIを使用して適切なフォーマットでGitHub PRを作成/更新
- **create-ticket**: フォーマット、調査、関連履歴を含む完全なチケット作成ワークフロー
- **drive-workflow**: チケット処理の実装ワークフローステップ
- **generate-changelog**: アーカイブされたチケットからchangelogエントリを生成、カテゴリ別にグループ化
- **translate**: 翻訳ポリシーと`.workaholic/` i18n強制（spec-writer、terms-writer、story-writerがプリロード）
- **write-changelog**: changelogエントリのライティングガイドライン
- **write-spec**: コンテキスト収集とspecドキュメントのライティングガイドライン
- **write-story**: メトリクス計算、テンプレート、ブランチストーリーのガイドライン
- **write-terms**: コンテキスト収集と用語ドキュメントのガイドライン

### エージェント

エージェントは複雑なタスクを処理するために生成できる特殊なサブエージェントです。特定のプロンプトとツールを持つサブプロセスで実行され、メイン会話のコンテキストウィンドウをインタラクティブな作業用に保持します。coreプラグインには以下が含まれます：

- **changelog-writer**: アーカイブされたチケットからルート`CHANGELOG.md`をカテゴリ別（Added、Changed、Removed）に更新
- **performance-analyst**: PRストーリーのために5つの観点（Consistency、Intuitivity、Describability、Agility、Density）で意思決定の質を評価
- **pr-creator**: ストーリーファイルをPRボディとして使用してGitHub PRを作成または更新、タイトル導出と`gh` CLI操作を処理
- **release-readiness**: 変更をリリース準備状況について分析、判定・懸念事項・リリース前後の手順を提供
- **spec-writer**: 現在のコードベースの状態を反映するように`.workaholic/specs/`ドキュメントを更新
- **story-writer**: PR内容の単一の真実の情報源として機能する`.workaholic/stories/`にブランチストーリーを生成、11のセクション（Overview、Motivation、Journey（Topic Treeフローチャートを含む）、Changes、Outcome、Historical Analysis、Concerns、Ideas、Performance、Release Preparation、Notes）で構成
- **terms-writer**: 一貫した用語定義を維持するために`.workaholic/terms/`を更新

## 依存関係グラフ

この図は、コマンド、エージェント、スキルが実行時にどのように相互呼び出しするかを示しています。

```mermaid
flowchart LR
    subgraph コマンド
        report[/report]
        drive[/drive]
        ticket[/ticket]
        branch[/branch]
    end

    subgraph エージェント
        cw[changelog-writer]
        sw[story-writer]
        spw[spec-writer]
        tw[terms-writer]
        pc[pr-creator]
        pa[performance-analyst]
        rr[release-readiness]
    end

    subgraph スキル
        at[archive-ticket]
        gc[generate-changelog]
        cb[create-branch]
        ct[create-ticket]
        dw[drive-workflow]
        tr[translate]
        ws[write-story]
        wsp[write-spec]
        wt[write-terms]
        wc[write-changelog]
        cp[create-pr]
        ap[analyze-performance]
        arr[assess-release-readiness]
    end

    report --> cw & spw & tw & rr
    report -.-> sw
    report --> pc
    drive --> at & dw
    ticket --> ct
    branch --> cb

    cw --> gc & wc
    sw --> ws & tr
    sw --> pa
    spw --> wsp & tr
    tw --> wt & tr
    pc --> cp
    pa --> ap
    rr --> arr
```

注: `/report`コマンドは4つのエージェント（changelog-writer、spec-writer、terms-writer、release-readiness）を並列実行し、その後story-writerをrelease-readiness出力と共に実行し、最後にpr-creatorを実行します。

## Claude Codeがプラグインをロードする方法

ユーザーが`/plugin marketplace add qmu/workaholic`でマーケットプレイスをインストールすると、Claude Codeは：

1. `.claude-plugin/marketplace.json`を読んで利用可能なプラグインを見つける
2. 各プラグインについて`plugins/<name>/.claude-plugin/plugin.json`を読む
3. プラグインディレクトリからコマンド、ルール、スキルをロードする
4. コマンドを会話内のスラッシュコマンドとして利用可能にする

## データフロー

```mermaid
sequenceDiagram
    participant User
    participant Claude
    participant Plugin
    participant Filesystem

    User->>Claude: /ticket add auth
    Claude->>Plugin: ticket.mdをロード
    Plugin-->>Claude: コマンド指示
    Claude->>Filesystem: コードベースを調査
    Claude->>Filesystem: .workaholic/tickets/にチケットを書き込み
    Claude-->>User: チケット作成完了
```

## ドキュメント強制

Workaholicは並列サブエージェントアーキテクチャを通じて包括的なドキュメントを強制します。`/report`コマンドはドキュメントエージェントを2つのフェーズで調整します：最初に4つのエージェントが並列実行され、その後story-writerがrelease-readiness出力と共に実行されます。

### 仕組み

```mermaid
flowchart TD
    A[/report コマンド] --> B[残りのチケットをiceboxに移動]
    B --> C[フェーズ1: 4つのサブエージェントを並列で呼び出し]

    subgraph フェーズ1 - 並列
        D[changelog-writer]
        F[spec-writer]
        G[terms-writer]
        RR[release-readiness]
    end

    C --> D
    C --> F
    C --> G
    C --> RR

    D --> H[CHANGELOG.md]
    F --> J[.workaholic/specs/]
    G --> K[.workaholic/terms/]
    RR --> RL[リリースJSON]

    H --> P2[フェーズ2: story-writer]
    J --> P2
    K --> P2
    RL --> P2

    P2 --> I[.workaholic/stories/]
    I --> L[docsをコミット]

    L --> M[pr-creator サブエージェント]
    M --> N[PRを作成/更新]
```

ドキュメントは`/report`ワークフロー中に自動的に更新されます。

サブエージェントアーキテクチャにはいくつかの利点があります：

1. **並列実行** - フェーズ1で4つのエージェントが同時に実行され、待ち時間を短縮
2. **コンテキスト分離** - 各エージェントが独自のコンテキストウィンドウで動作し、メイン会話を保持
3. **単一責任** - 各エージェントが1つのドキュメントドメインを担当
4. **データ依存関係の処理** - story-writerはフェーズ2でrelease-readiness出力を受け取る

### 重要な要件

すべてのドキュメントエージェントは厳格な要件を強制します：

- **すべての変更をドキュメント化** - 例外なし、何が「ドキュメント化する価値がある」かの判断なし
- **ドキュメントをスキップしない** - 「内部実装の詳細」は決して有効な理由にならない
- **常に更新を報告** - どのファイルが作成または変更されたかを指定する必要がある
- **「更新不要」は受け入れられない** - すべての変更は何らかの形でドキュメントに影響する

### 設計ポリシー

ドキュメントは任意ではなく必須です。これはWorkaholicのコア原則である**認知投資**を反映しています：開発者の認知負荷はソフトウェア生産性の主要なボトルネックであり、この負荷を軽減するために構造化された知識成果物の生成に積極的に投資します。

3つの主要な成果物タイプは：

- **Tickets** - 構造化メタデータ（date、author、type、layer、effort、commit_hash、category）を持つ変更リクエスト
- **Specs** - リファレンスドキュメントとして機能する現状のスナップショット
- **Stories** - ブランチごとの開発者の旅のナラティブ

チケットは変更メタデータの単一の真実の情報源として機能します。ルート`CHANGELOG.md`はPR作成時にアーカイブされたチケットから生成されます。

## アーキテクチャポリシー

Workaholicはオーケストレーションと知識の明確な分離を維持するため、コンポーネント呼び出しに厳格なネストルールを設けています。

| 呼び出し元 | 呼び出し可能     | 呼び出し不可        |
| ---------- | ---------------- | ------------------- |
| コマンド   | スキル、サブエージェント | -            |
| サブエージェント | スキル      | サブエージェント、コマンド |
| スキル     | -                | サブエージェント、コマンド |

コマンドとサブエージェントはオーケストレーション層であり、ワークフローステップを定義し他のコンポーネントを呼び出します。スキルは知識層であり、テンプレート、ガイドライン、ルール、bashスクリプトを含みます。この分離により、深いネストとコンテキスト爆発を防ぎながら、包括的な知識をスキルに集約します。

## バージョン管理

バージョンは2箇所で追跡されます：

- **マーケットプレイスバージョン**: `.claude-plugin/marketplace.json` - `/release`でバンプ
- **プラグインバージョン**: `plugins/<name>/.claude-plugin/plugin.json` - プラグイン変更時に更新

リリース時にこれらを同期させてください。
