---
title: ルーティンループ
description: 4つの定期実行ジョブが毎時間どう連携して開発を1周させるのか、人間はどこで関わるのかの解説
---

# Workaholic のルーティンループ

Workaholic は、AI エージェントが開発作業を自律的に進めるための仕組みをプラグインとして配布するリポジトリです。この記事では、その中心にある4つの定期実行ジョブが毎時間どう連携して開発を1周させるのか、各ジョブがどのファイル・コマンド・スキルとつながっているのか、そして人間はどこでどう関わるのかを、初めて読む人向けに解説します。なお本記事ではプルリクエストを PR と表記します。

## この仕組みの前提と登場人物

図に入る前に、4つの前提を押さえておくと以降がすべて読みやすくなります。

- ルーティンは毎時起動する AI ジョブです。ルーティンとは、Claude Code の定期実行機能に登録されたジョブのことで、決まった時刻になると AI のセッションが自動で立ち上がり、決められたコマンドを1つ実行して終了します。このリポジトリでは4種類のルーティンが毎時、時間差で起動します。
- 実行するのは AI、決めるのは人間です。チケットを書く、実装する、PR を出すといった作業は AI が行います。人間の役割は、進む方向を決めること、PR を承認すること、AI からの質問に答えることの3つです。
- すべての仕事はチケットに集まります。依頼がどこから来ても、最終的にはチケットと呼ばれる作業指示書のファイル1枚に変換され、実行係のルーティンがそれを消化します。チケットが仕事の共通単位です。
- 記録はすべて Markdown で残ります。依頼・計画・作業・報告は、すべて `.workaholic/` ディレクトリ配下の Markdown 文書として Git 管理されます。データベースはなく、Git の履歴そのものが台帳です。

最初に覚える成果物の名前は次の6つです。

| 用語 | 説明 |
| --- | --- |
| フィードバック | 誰が何を依頼・発言したかの記録です。すべての仕事の出発点で、一度書いたら書き換えません。 |
| チケット | 1件分の作業指示書です。未着手のものは `tickets/todo/` に置かれ、これがやることの待ち行列になります。 |
| ミッション | 関連するチケット2枚以上をまとめた束です。一般的な開発用語でいうエピックに相当します。 |
| ストラテジ | 開発者が決めた中期的な方向です。狙い・期日・担当者の3点を必ず持ちます。 |
| ストーリー | 実装を終えたときに書かれる作業のまとめです。PR の説明文の元になります。 |
| tick | ルーティンの1回分の実行のことです。毎時の tick といえば、その時刻に走った1回を指します。 |

## 1時間に1周する毎時のタイムライン

4つのルーティンはすべて cron による毎時の固定時刻で起動し、起動時刻の並びがそのまま処理の順番になっています。[Propose] が起票した依頼は、同じ時間内ではなく翌時刻の [Specificate] が拾うため、ループは1時間で1周します。[Moderate] が最後の :50 なのは、他の3本がその時間にやったことを見てから全体を点検するためです。

<svg viewBox="0 0 1000 210" role="img" aria-label="1時間のタイムライン。15分にSpecificate、30分にImplement、40分にPropose、50分にModerateが起動し、Proposeが起票した依頼は翌時刻の15分のSpecificateに引き継がれる。" style="max-width:100%;height:auto">
  <defs>
    <marker id="tl-arr" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="7" markerHeight="7" orient="auto">
      <path d="M0 0 L8 4 L0 8 z" fill="currentColor"/>
    </marker>
  </defs>
  <line x1="60" y1="130" x2="940" y2="130" stroke="currentColor" stroke-opacity=".35" stroke-width="1.5"/>
  <line x1="60" y1="122" x2="60" y2="138" stroke="currentColor" stroke-opacity=".5"/>
  <line x1="940" y1="122" x2="940" y2="138" stroke="currentColor" stroke-opacity=".5"/>
  <text x="60" y="158" font-size="11" text-anchor="middle" fill="currentColor" opacity=".45">:00</text>
  <text x="940" y="158" font-size="11" text-anchor="middle" fill="currentColor" opacity=".45">:60</text>
  <g style="color:#cf8a2e">
    <path d="M 647 108 C 700 50, 880 42, 938 66" fill="none" stroke="#cf8a2e" stroke-width="1.6" stroke-dasharray="5 4" marker-end="url(#tl-arr)"/>
    <path d="M 62 66 C 120 44, 230 52, 280 106" fill="none" stroke="#cf8a2e" stroke-width="1.6" stroke-dasharray="5 4" marker-end="url(#tl-arr)"/>
  </g>
  <text x="500" y="36" font-size="12" text-anchor="middle" fill="#cf8a2e">:40 に起票された依頼は、翌時刻の :15 が受け取る。1周は1時間</text>
  <g>
    <circle cx="280" cy="130" r="8" fill="#4a8ad4"/>
    <text x="280" y="112" font-size="12.5" text-anchor="middle" fill="#4a8ad4">:15</text>
    <text x="280" y="180" font-size="13" font-weight="700" text-anchor="middle" fill="#4a8ad4">[Specificate]</text>
    <text x="280" y="198" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">依頼を仕様にする</text>
  </g>
  <g>
    <circle cx="500" cy="130" r="8" fill="#3fa06b"/>
    <text x="500" y="112" font-size="12.5" text-anchor="middle" fill="#3fa06b">:30</text>
    <text x="500" y="180" font-size="13" font-weight="700" text-anchor="middle" fill="#3fa06b">[Implement]</text>
    <text x="500" y="198" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">仕様を実装する</text>
  </g>
  <g>
    <circle cx="647" cy="130" r="8" fill="#cf8a2e"/>
    <text x="647" y="112" font-size="12.5" text-anchor="middle" fill="#cf8a2e">:40</text>
    <text x="647" y="180" font-size="13" font-weight="700" text-anchor="middle" fill="#cf8a2e">[Propose]</text>
    <text x="647" y="198" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">次の依頼を生み出す</text>
  </g>
  <g>
    <circle cx="793" cy="130" r="8" fill="#9468cf"/>
    <text x="793" y="112" font-size="12.5" text-anchor="middle" fill="#9468cf">:50</text>
    <text x="793" y="180" font-size="13" font-weight="700" text-anchor="middle" fill="#9468cf">[Moderate]</text>
    <text x="793" y="198" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">全体を見回り、人に質問する</text>
  </g>
</svg>

起動分がすべて :00 ちょうどでないのは、毎時0分を指定するとサーバ側で時刻を振り直されてしまい、順番が保証できなくなるためです。なお [Specificate]・[Implement]・[Propose] は開発者ごとに1本ずつ持つルーティンで `/setup-dev-routines` が設定し、[Moderate] はリポジトリ全体で1本だけのルーティンで代表者1名が `/setup-repo-routines` で設定します。

## 依頼が形を変えて流れる1周分のデータフロー

上から下へが毎時の本流です。ポイントは2つあります。第一に、AI が main ブランチへ文書を書くときは必ず PR 経由で、しかも publish tree と呼ばれる隔離された作業コピーから提出するため、進行中の作業を壊しません。第二に、コードを書くのは [Implement] だけで、それも claim した専用ブランチの上だけです。これらの言葉は末尾の用語集で説明しています。

<svg viewBox="0 0 980 950" role="img" aria-label="ストラテジから Propose、GitHub Issues の受信箱、Specificate、main ブランチの記録置き場、Implement、Moderate へと流れ、Moderate の質問への回答が新しいフィードバックとして戻ってくる循環図。" style="max-width:100%;height:auto">
  <defs>
    <marker id="fl-arr" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="7" markerHeight="7" orient="auto">
      <path d="M0 0 L8 4 L0 8 z" fill="currentColor"/>
    </marker>
  </defs>
  <g stroke="currentColor" stroke-opacity=".55" stroke-width="1.5" fill="none">
    <line x1="330" y1="96"  x2="330" y2="140" marker-end="url(#fl-arr)"/>
    <line x1="330" y1="232" x2="330" y2="276" marker-end="url(#fl-arr)"/>
    <line x1="330" y1="352" x2="330" y2="396" marker-end="url(#fl-arr)"/>
    <line x1="330" y1="492" x2="330" y2="536" marker-end="url(#fl-arr)"/>
    <line x1="330" y1="612" x2="330" y2="656" marker-end="url(#fl-arr)"/>
    <line x1="330" y1="768" x2="330" y2="812" marker-end="url(#fl-arr)"/>
  </g>
  <g font-size="11.5" fill="currentColor" opacity=".62">
    <text x="344" y="122">ストラテジの狙い・期日・担当を読む</text>
    <text x="344" y="258">Issue を起票して受信箱に入れる</text>
    <text x="344" y="378">古い順に1件ずつ取り込む</text>
    <text x="344" y="518">PR が自動マージされ main に載る</text>
    <text x="344" y="638">待ち行列を調べ、作業を宣言する</text>
    <text x="344" y="794">1時間分の結果と滞留を読む</text>
  </g>
  <g style="color:#9468cf">
    <path d="M 165 852 L 84 852 C 62 852 62 840 62 820 L 62 340 C 62 318 66 312 88 312 L 158 312" fill="none" stroke="#9468cf" stroke-width="1.6" stroke-dasharray="5 4" marker-end="url(#fl-arr)"/>
  </g>
  <text x="48" y="590" font-size="11.5" transform="rotate(-90 48 590)" text-anchor="middle" fill="#9468cf">質問に人が答えると、新しい依頼や方向修正として戻る</text>
  <g style="color:#3fa06b">
    <path d="M 165 700 L 122 700 C 104 700 104 690 104 674 L 104 214 C 104 196 108 190 126 190 L 158 190" fill="none" stroke="#3fa06b" stroke-width="1.4" stroke-dasharray="4 4" marker-end="url(#fl-arr)"/>
  </g>
  <text x="92" y="452" font-size="11.5" transform="rotate(-90 92 452)" text-anchor="middle" fill="#3fa06b">完成した作業の実績が、次の提案の判断材料になる</text>
  <g>
    <rect x="165" y="28" width="330" height="68" rx="10" fill="currentColor" fill-opacity=".05" stroke="currentColor" stroke-opacity=".5" stroke-width="1.3"/>
    <text x="330" y="56" font-size="14" font-weight="700" text-anchor="middle" fill="currentColor">ストラテジ</text>
    <text x="330" y="78" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">開発者が決めた方向。狙い・期日・担当者を持つ</text>
    <text x="520" y="48" font-size="11.5" fill="currentColor" opacity=".62">ストラテジの提案 PR だけは自動マージされず、</text>
    <text x="520" y="64" font-size="11.5" fill="currentColor" opacity=".62">開発者が自分でマージして初めて成立する。</text>
    <text x="520" y="80" font-size="11.5" fill="currentColor" opacity=".62">成立後は誰も内容を書き換えない。終了の手続きだけがある</text>
  </g>
  <g>
    <rect x="165" y="144" width="330" height="88" rx="10" fill="#cf8a2e" fill-opacity=".1" stroke="#cf8a2e" stroke-width="1.5"/>
    <text x="330" y="170" font-size="14.5" font-weight="700" text-anchor="middle" fill="#cf8a2e">[Propose] :40</text>
    <text x="330" y="192" font-size="12" text-anchor="middle" fill="currentColor">Slack の依頼を拾い、ストラテジを進める次の一手を考える</text>
    <text x="330" y="212" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">実行コマンドは /propose。リポジトリにも Slack にも書かない</text>
    <text x="520" y="164" font-size="11.5" fill="currentColor" opacity=".62">読むもの: 自分の担当ストラテジと、開発チャンネルの</text>
    <text x="520" y="180" font-size="11.5" fill="currentColor" opacity=".62">直近26時間の発言。メンションは不要</text>
    <text x="520" y="196" font-size="11.5" fill="currentColor" opacity=".62">書くもの: GitHub の Issue だけ</text>
  </g>
  <g>
    <rect x="165" y="280" width="330" height="72" rx="10" fill="currentColor" fill-opacity=".05" stroke="currentColor" stroke-opacity=".5" stroke-width="1.3"/>
    <text x="330" y="306" font-size="14" font-weight="700" text-anchor="middle" fill="currentColor">GitHub Issues</text>
    <text x="330" y="328" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">依頼の受信箱。自分宛ての open な Issue が未処理の依頼を表す</text>
    <text x="520" y="300" font-size="11.5" fill="currentColor" opacity=".62">人が /fb で送った依頼もここに入る。</text>
    <text x="520" y="316" font-size="11.5" fill="currentColor" opacity=".62">Slack の発言もスイープ経由でここに集まる。</text>
    <text x="520" y="332" font-size="11.5" fill="currentColor" opacity=".62">入口が違っても、受信箱は1つに揃えてある</text>
  </g>
  <g>
    <rect x="165" y="400" width="330" height="92" rx="10" fill="#4a8ad4" fill-opacity=".1" stroke="#4a8ad4" stroke-width="1.5"/>
    <text x="330" y="426" font-size="14.5" font-weight="700" text-anchor="middle" fill="#4a8ad4">[Specificate] :15</text>
    <text x="330" y="447" font-size="12" text-anchor="middle" fill="currentColor">依頼を読み、フィードバック記録と作業計画に変換する</text>
    <text x="330" y="466" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">規模に応じてミッション・チケット1枚・ストラテジ・記録のみを選ぶ</text>
    <text x="330" y="484" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">実行コマンドは /specificate。成果は1本の PR にまとめる</text>
    <text x="520" y="420" font-size="11.5" fill="currentColor" opacity=".62">PR は通常そのまま自動マージされる。</text>
    <text x="520" y="436" font-size="11.5" fill="currentColor" opacity=".62">開発者がすでに決めたことは前提として</text>
    <text x="520" y="452" font-size="11.5" fill="currentColor" opacity=".62">尊重し、蒸し返さない</text>
  </g>
  <g>
    <rect x="165" y="540" width="330" height="72" rx="10" fill="currentColor" fill-opacity=".05" stroke="currentColor" stroke-opacity=".5" stroke-width="1.3"/>
    <text x="330" y="566" font-size="14" font-weight="700" text-anchor="middle" fill="currentColor">main ブランチの記録置き場</text>
    <text x="330" y="588" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">未着手チケットの待ち行列は tickets/todo/ の1か所だけ</text>
    <text x="520" y="560" font-size="11.5" fill="currentColor" opacity=".62">人が /ticket や /mission で作った作業も、</text>
    <text x="520" y="576" font-size="11.5" fill="currentColor" opacity=".62">PR がマージされれば同じ待ち行列に入る。</text>
    <text x="520" y="594" font-size="11.5" fill="currentColor" opacity=".62">AI と人間の入口は最後に合流する</text>
  </g>
  <g>
    <rect x="165" y="660" width="330" height="108" rx="10" fill="#3fa06b" fill-opacity=".1" stroke="#3fa06b" stroke-width="1.5"/>
    <text x="330" y="686" font-size="14.5" font-weight="700" text-anchor="middle" fill="#3fa06b">[Implement] :30</text>
    <text x="330" y="707" font-size="12" text-anchor="middle" fill="currentColor">作業を宣言し、実装して PR を作る</text>
    <text x="330" y="727" font-size="12" text-anchor="middle" fill="currentColor">その後はチケット作成時に決めたマージ方針に従う</text>
    <text x="330" y="746" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">自動でマージ、検査後にマージ、人に引き継いで PR を残すの3通り</text>
    <text x="330" y="762" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">実行コマンドは /implement</text>
    <text x="520" y="682" font-size="11.5" fill="currentColor" opacity=".62">人が手動で同じ処理を走らせたいときは</text>
    <text x="520" y="698" font-size="11.5" fill="currentColor" opacity=".62">対話版の /drive を使う。中身は同一。</text>
    <text x="520" y="718" font-size="11.5" fill="currentColor" opacity=".62">完了したチケットは完了置き場の</text>
    <text x="520" y="734" font-size="11.5" fill="currentColor" opacity=".62">tickets/archive/ へ移り、まとめとして</text>
    <text x="520" y="750" font-size="11.5" fill="currentColor" opacity=".62">ストーリーが書かれる</text>
  </g>
  <g>
    <rect x="165" y="816" width="330" height="100" rx="10" fill="#9468cf" fill-opacity=".1" stroke="#9468cf" stroke-width="1.5"/>
    <text x="330" y="842" font-size="14.5" font-weight="700" text-anchor="middle" fill="#9468cf">[Moderate] :50</text>
    <text x="330" y="863" font-size="12" text-anchor="middle" fill="currentColor">リポジトリ全体を点検し、滞りを見つける</text>
    <text x="330" y="883" font-size="12" text-anchor="middle" fill="currentColor">人が判断すべきことだけを Slack で質問する。1時間に5件まで</text>
    <text x="330" y="903" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">実行コマンドは /moderate。点検の記録は専用ログに残す</text>
    <text x="520" y="840" font-size="11.5" fill="currentColor" opacity=".62">PR のマージや他人のブランチへの介入は</text>
    <text x="520" y="856" font-size="11.5" fill="currentColor" opacity=".62">一切しない。見つけた問題は質問にするか、</text>
    <text x="520" y="874" font-size="11.5" fill="currentColor" opacity=".62">チケットとして正規の手順で登録する。</text>
    <text x="520" y="890" font-size="11.5" fill="currentColor" opacity=".62">質問への回答は次の tick が読み取る</text>
  </g>
</svg>

実線は毎時の本流、破線は時間をまたいで戻る流れです。菫色の破線は [Moderate] の質問に人が答えるとそれが新しい依頼や方向修正として上流に戻ること、緑の破線は [Propose] が実際に何が完成したかを見てから次の一手を判断することを表します。図の各段階を順に説明します。

1. 出発点は開発者が決めた方向であるストラテジです。AI は提案こそできますが、成立させるのは開発者のマージ操作です。
2. [Propose] がストラテジを読み、期日までに狙いへ近づくために次にやるべき1件を判断して、依頼として Issue に起票します。あわせて Slack に書かれた人間の依頼も拾って Issue 化します。
3. GitHub Issues がすべての依頼の受信箱です。AI が起票したものも、人が `/fb` で送ったものも、Slack から拾われたものも、ここで1本の列に並びます。
4. [Specificate] が受信箱の依頼を1件ずつ読み、フィードバック記録と作業計画に変換して PR で提出します。
5. main ブランチにマージされた時点で、チケットは正式な待ち行列に入ります。
6. [Implement] が待ち行列を消化します。作業宣言、実装、PR 作成、マージ方針に沿った後処理まで人手なしで進みます。
7. [Moderate] が最後に全体を見回り、止まっているものやズレているものを見つけて、人の判断が必要なことだけを Slack で質問します。

## 各ルーティンの処理内容

各ルーティンの実体は、1つのコマンドを実行せよという短い指示文だけです。テンプレートは `plugins/workaholic/skills/workaholify/routines/` にあり、手順やルールはすべてコマンドが呼び出すスキル側に書かれています。ここでは各ルーティンについて、実行するコマンド、手順を所有するスキル、主要スクリプト、読み書きするファイル、Slack への報告形式をまとめます。

### [Specificate] は依頼を記録と作業計画に変換する

| 項目 | 内容 |
| --- | --- |
| 起動時刻 | 毎時15分 |
| 設定単位 | 開発者ごとに1本 |
| 実行コマンド | `/specificate` |
| 手順を所有するスキル | `workaholic:specificate` に加えて discover、feedback、notify を併用 |

処理の流れは次のとおりです。

1. 依頼を探します。自分宛ての open な Issue を古い順に列挙し（`list-inbound-issues.sh`）、1件ずつ以降の全工程にかけます。1件もなければ依頼なし（`nothing_in_hand`）と報告して終わります。
2. 現状を確認します。main ブランチ上の既存の記録を読み込みます（`survey-state.sh`）。開発者がすでに決めたこと、つまり有効なストラテジの狙いや本人の発言として残る記録は前提条件として扱い、蒸し返しません。
3. 調査します。不具合報告なら、修正案に飛びつく前に再現と原因特定の手順を組み立てます。調べても決めきれない分岐が残った場合は、何を調べどの資料に何が書いてあったかを添えて、未決事項の章（`## Open Decisions`）としてチケットに書き残します。
4. 重複を確認します。同じ依頼をすでに提案済みでないか、未マージのブランチまで含めて確認します（`list-proposed-refs.sh`）。
5. 形を選びます。作業の規模と性質に応じて、ミッションとチケット一式、チケット1枚、ストラテジ、記録のみ、の4形態から選びます。記録のみに倒してよいのは、規模を判断できなかった場合だけです。
6. 1本の PR で提出します。フィードバック記録と選んだ形をまとめ、`[Proposal]` と題した PR にします。通常はそのまま自動マージされ、ストラテジを含む場合だけ開発者の手動マージを待ちます。

読むものは、GitHub Issues のうち自分宛てのもの、前提条件としての `.workaholic/strategies/` と `feedbacks/`、そして依頼が参照する資料の全文です。書くものはすべて PR 経由で main に提出され、`feedbacks/` のフィードバック記録は毎回必ず、`tickets/todo/` または `missions/active/` は作業計画を選んだとき、`strategies/` はストラテジの形を選んだときだけ書かれます。

Slack への報告は、その依頼が話されていた Slack スレッドを探し当てて `🔵 Proposed` の1行を返信します。該当スレッドがなければ、まずフィードバックの紹介投稿 `📝 FB` を立て、その返信として報告します。

やらないことも決まっています。実行中に人へ質問することはありません。判断できないことは文書に書き残します。ストラテジの提案を自動マージすることもありません。また、機密情報らしき文字列を検出した場合は提出を止めます。

### [Implement] はたまったチケットを人手なしで実装する

| 項目 | 内容 |
| --- | --- |
| 起動時刻 | 毎時30分 |
| 設定単位 | 開発者ごとに1本 |
| 実行コマンド | `/implement` |
| 手順を所有するスキル | `workaholic:drive` に加えて story、ship、release-scan、notify を併用 |

手動用の `/drive` と完全に同じ手順で、違いは途中で人に確認するかどうかだけです。処理の流れは次のとおりです。

1. 最新化します。main ブランチの最新状態を取り込みます（`sync-main.sh`）。
2. 調査します。未着手チケットとミッションを一覧し、着手できるまとまりを洗い出します（`plan-units.sh`）。担当者が決まっている作業は担当者本人のルーティンだけが取り、他人の担当分は候補から外れます。
3. 作業を宣言します。まとまりごとに専用ブランチ `work-日時` と作業用の複製ディレクトリを作って push します。push されたブランチの存在自体が、作業中であることを示す全員向けの合図になります。
4. 実装します。チケットを1枚ずつ実装し、終えるたびに完了置き場の `tickets/archive/` へ移してコミットします（`archive.sh`）。チケットに未決事項が書かれていても鵜呑みにはせず、そこに挙がった資料を実際に読んでから、本当に進められないかを判断します。進められないと報告するときは根拠にした資料名を必ず添えます。
5. まとめます。`/story` を使って作業のまとめであるストーリーを書き、PR を作成します。
6. マージ方針に従って仕分けます。チケット作成時に決めてあったマージ方針を読み（`gate-decision.sh`）、自動なら `/ship` がデプロイ計画を書いた上でマージ、要確認なら安全スキャンに通った時点でマージ、検証の引き継ぎが指定されていれば PR を開いたまま人へ引き継ぎます。
7. 決算します。`N units: X shipped, Y PR'd, Z blocked` という形式で結果を数え上げ、残作業がないときに限って `ok` で終わります。

読むものは `tickets/todo/` と `missions/active/`、各チケットの方針と品質基準の章、検証の引き継ぎ指定の有無（`verification-handoff.sh`）です。書くものはすべて宣言済みの専用ブランチの上で、実装コードそのもの、`tickets/archive/` への完了チケットの移動、`stories/` とミッションの変更履歴・達成条件のチェックです。ミッションの達成条件がすべて満たされたと計算で証明できた場合のみ、ミッションを達成として閉じます。

Slack への報告は、作業のまとまりごとに1行の `🟢 Implemented` を該当スレッドに返信します。進行不能のときは `🔴 Blocked` を報告し、同じ失敗が続く間は既存スレッドへの継続報告に抑えます。翌営業日には改めて報告し直します。

やらないことは、実行中に人へ質問すること、安全スキャンなどの検査を飛ばしてマージすること、他の人が宣言中の作業に手を出すことです。途中で見つけた問題はチケットとして登録するか、引き継ぎに切り替えます。

### [Propose] はストラテジから次の依頼を導き出す

| 項目 | 内容 |
| --- | --- |
| 起動時刻 | 毎時40分 |
| 設定単位 | 開発者ごとに1本 |
| 実行コマンド | `/propose` |
| 手順を所有するスキル | `workaholic:propose` に加えて strategy を参照 |

このルーティンだけはリポジトリへの書き込み権限そのものを持ちません。処理の流れは次のとおりです。

1. Slack の依頼を拾います。開発チャンネル（既定では `dev-リポジトリ名`）の直近26時間の発言を読み、依頼と読めるものをメンションなしでも Issue に変換して受信箱に入れます（`file-inbound-ask.sh`）。同じ発言を二度 Issue 化しないよう、起票済み Issue に埋め込んだ印を照合します。
2. 自分のストラテジを調べます。担当している有効なストラテジを一覧し（`survey-strategies.sh`）、進み具合を添えます。遅れているストラテジから順に検討します。
3. 提案してよい状態か確かめます。そのストラテジの作業が進行中である、前回の提案が未処理である、といった場合は提案を見送り、見送った理由を名前付きで報告します。これにより、1つのストラテジにつき同時に1件だけ提案が流れる状態が保たれます。進行中の作業が解説文書の執筆だけである場合には、実物を作る提案を止めない工夫があります（`work-kind.sh`）。
4. 次の一手を判断します。提案できるストラテジそれぞれについて、狙いに近づく具体的な1件を、深掘り・横展開・整理縮小のどれに当たるかまで明示し、なぜ他の候補ではなくこれなのかを書きます。何かを作るストラテジに対して、それについての文書を書くという提案は、安易な逃げ道として明示的に禁止されています。
5. Issue として起票します。自分宛てに assign した Issue を作ります。本文には依頼の分類と、元になったストラテジとフィードバックへの参照を明記するため、次の [Specificate] がそれをそのまま引き継げます。

読むものは、自分が担当する有効な `.workaholic/strategies/`、各ストラテジに紐づく作業の実績（`attributed-work.sh`）、Slack の開発チャンネル、そして自分が過去に起票した未処理の提案です。書くものは GitHub の Issue だけで、これはリポジトリの外側です。ファイルの新規作成・編集の権限自体を持ちません。

Slack への投稿は一切しません。起票した Issue は GitHub が担当者に通知するので、Slack にも流すと同じ知らせが二重になるためです。実行結果は Claude のプッシュ通知で本人にだけ届きます。

やらないことは、PR を開くこと、マージすること、リポジトリ内のファイルに触れることです。掃除や整頓のような無難な小仕事は提案として認められず、判断できなかった事柄を勝手にどちらかへ倒すこともしません。

### [Moderate] は全体を見回り人の判断が要ることだけを届ける

| 項目 | 内容 |
| --- | --- |
| 起動時刻 | 毎時50分 |
| 設定単位 | リポジトリ全体で1本 |
| 実行コマンド | `/moderate` |
| 手順を所有するスキル | `workaholic:moderate` に加えて notify、feedback、mission、standup を併用 |

22ステップある手順の要約は次のとおりです。

1. 自分のログを読み込みます。過去の tick が何を報告済みかを専用ログから復元します（`log-read.sh`）。同じことを二度報告しないための記憶がこれです。
2. 横断的に点検します。放置された Issue、マージに失敗した PR、ドキュメントと実装のズレ、デプロイ待ちの変更、リリースノートの下書き状況などを順に確認します。
3. 止まっている作業を見つけます。宣言されたまま24時間以上動きのない作業を検出し（`step-stalled-units.sh`）、その宣言をした本人への質問に変換します。同じ件で二度は聞きません。
4. 終わっているのに開いたままのミッションを閉じます。達成条件がすべて満たされていることを計算で再証明できた場合に限り、達成として閉じます。証明できなければ閉じずに報告だけします。
5. 人に質問します。1時間に最大5件までです。各質問には未質問・質問済み・回答済みの3状態があります。返事のない質問は翌営業日に一度だけ聞き直し、解消を確認できたら確認の返信を一度だけ返します。
6. 質問への返事を読み取って仕事に戻します。質問を投稿した座標は投稿した時点でログに記録してあるので、次の tick はそのスレッドだけを1件ずつ読みます（チャンネルの検索も履歴の読み込みもしません）。人が書いた返事は回答として記録し（`record-answer.sh`）、依頼を含む返事は `[FB]` Issue として起票し、読み取った返事にはリアクションを付けます。機械自身の投稿は回答として扱いません。
7. 朝は活動報告を添えます。日本時間の朝の tick に限り、ストラテジごとの前日実績を投稿の冒頭に載せます。
8. 自分のログを保存して終わります。点検の記録を main ブランチへ直接コミットして残します（`persist-log.sh`）。ルーティンの実行環境は毎回使い捨てのため、ここで保存しないと次の tick の記憶が消えてしまうからです。

読むものはリポジトリ全域と GitHub の Issue・PR・CI の状態、作業宣言の一覧、デプロイ状況、ドキュメントのズレです。書くものは `moderations/` の点検ログ（1日1ファイルの追記専用で、専用スクリプトだけが書きます）と、見つけた問題のフィードバック記録やチケットとしての登録です。登録は正規の手順、つまり PR 経由で行われます。

Slack への報告は、聞きたいことが1件以上あるときだけ、1時間に1本の `🔎 Moderation` という親投稿を立て、各質問を宛先へのメンション付き返信としてぶら下げます。質問がない時間は完全に沈黙します。土日や夜間の質問は破棄せず、翌営業日まで保留します。

やらないことは、PR のマージ、作業宣言中のブランチへの介入、有効なストラテジの書き換え、Issue のクローズです。人へ質問するのは Slack 上だけで、実行中のセッション内で対話を求めることもありません。

## 成果物ドキュメントの相互関係

ルーティン間で受け渡される成果物は、すべて `.workaholic/` 配下の Markdown 文書です。文書同士は、文書冒頭のメタ情報である frontmatter の参照フィールドでつながっており、この参照をたどることで、この作業はどの依頼から生まれ、どのストラテジに属するのかを後から機械的に答えられます。まず参照の全体像を図で示します。

<svg viewBox="0 0 980 470" role="img" aria-label="フィードバックを中心に、ストラテジ・ミッション・チケットが参照でつながり、完了チケットからストーリーとリリースノートが生成される関係図。" style="max-width:100%;height:auto">
  <defs>
    <marker id="rel-arr" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="7" markerHeight="7" orient="auto">
      <path d="M0 0 L8 4 L0 8 z" fill="currentColor"/>
    </marker>
  </defs>
  <rect x="360" y="24" width="260" height="64" rx="10" fill="#4a8ad4" fill-opacity=".1" stroke="#4a8ad4" stroke-width="1.5"/>
  <text x="490" y="50" font-size="14" font-weight="700" text-anchor="middle" fill="#4a8ad4">フィードバック</text>
  <text x="490" y="72" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">すべての仕事の出発点となる不変の記録</text>
  <rect x="60" y="190" width="250" height="64" rx="10" fill="#cf8a2e" fill-opacity=".1" stroke="#cf8a2e" stroke-width="1.5"/>
  <text x="185" y="216" font-size="14" font-weight="700" text-anchor="middle" fill="#cf8a2e">ストラテジ</text>
  <text x="185" y="238" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">開発者が決めた方向</text>
  <rect x="380" y="190" width="220" height="64" rx="10" fill="#3fa06b" fill-opacity=".1" stroke="#3fa06b" stroke-width="1.5"/>
  <text x="490" y="216" font-size="14" font-weight="700" text-anchor="middle" fill="#3fa06b">ミッション</text>
  <text x="490" y="238" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">チケット2枚以上の束</text>
  <rect x="680" y="190" width="230" height="64" rx="10" fill="#3fa06b" fill-opacity=".1" stroke="#3fa06b" stroke-width="1.5"/>
  <text x="795" y="216" font-size="14" font-weight="700" text-anchor="middle" fill="#3fa06b">チケット</text>
  <text x="795" y="238" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">作業の最小単位</text>
  <rect x="380" y="366" width="220" height="64" rx="10" fill="currentColor" fill-opacity=".05" stroke="currentColor" stroke-opacity=".5" stroke-width="1.3"/>
  <text x="490" y="392" font-size="14" font-weight="700" text-anchor="middle" fill="currentColor">ストーリー</text>
  <text x="490" y="414" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">実装のまとめ。PR 本文の元</text>
  <rect x="680" y="366" width="230" height="64" rx="10" fill="currentColor" fill-opacity=".05" stroke="currentColor" stroke-opacity=".5" stroke-width="1.3"/>
  <text x="795" y="392" font-size="14" font-weight="700" text-anchor="middle" fill="currentColor">リリースノート</text>
  <text x="795" y="414" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">出荷内容とデプロイの記録</text>
  <rect x="60" y="366" width="250" height="64" rx="10" fill="#9468cf" fill-opacity=".1" stroke="#9468cf" stroke-width="1.3" stroke-dasharray="4 3"/>
  <text x="185" y="392" font-size="14" font-weight="700" text-anchor="middle" fill="#9468cf">点検ログ</text>
  <text x="185" y="414" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">他の文書と参照関係を持たない例外</text>
  <path d="M 205 190 C 240 140, 300 100, 356 70" fill="none" stroke="currentColor" stroke-opacity=".55" stroke-width="1.4" marker-end="url(#rel-arr)"/>
  <text x="242" y="118" font-size="11.5" fill="currentColor" opacity=".62">feedback: で引用する。</text>
  <text x="242" y="134" font-size="11.5" fill="currentColor" opacity=".62">向きは記録への一方向のみ</text>
  <line x1="490" y1="190" x2="490" y2="94" stroke="currentColor" stroke-opacity=".55" stroke-width="1.4" marker-end="url(#rel-arr)"/>
  <text x="502" y="140" font-size="11.5" fill="currentColor" opacity=".62">feedback: を引き継ぎ、</text>
  <text x="502" y="156" font-size="11.5" fill="currentColor" opacity=".62">どの依頼から生まれたかを示す</text>
  <path d="M 775 190 C 740 130, 680 96, 626 66" fill="none" stroke="currentColor" stroke-opacity=".55" stroke-width="1.4" marker-end="url(#rel-arr)"/>
  <text x="712" y="120" font-size="11.5" fill="currentColor" opacity=".62">feedback: で出典を明記する</text>
  <line x1="680" y1="222" x2="606" y2="222" stroke="currentColor" stroke-opacity=".55" stroke-width="1.4" marker-end="url(#rel-arr)"/>
  <text x="643" y="210" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">mission: で所属を示す</text>
  <path d="M 795 254 C 795 310, 680 370, 606 386" fill="none" stroke="currentColor" stroke-opacity=".55" stroke-width="1.4" marker-end="url(#rel-arr)"/>
  <text x="742" y="316" font-size="11.5" fill="currentColor" opacity=".62">完了チケットから生成</text>
  <line x1="600" y1="398" x2="676" y2="398" stroke="currentColor" stroke-opacity=".55" stroke-width="1.4" marker-end="url(#rel-arr)"/>
  <text x="638" y="386" font-size="11.5" text-anchor="middle" fill="currentColor" opacity=".62">集約</text>
  <path d="M 680 246 C 640 280, 600 280, 566 254" fill="none" stroke="currentColor" stroke-opacity=".4" stroke-width="1.2" stroke-dasharray="3 3" marker-end="url(#rel-arr)"/>
  <text x="622" y="288" font-size="11" text-anchor="middle" fill="currentColor" opacity=".45">完了のたびに進捗を反映</text>
</svg>

矢印は参照する側から参照される側へ向かいます。中心にあるのはフィードバックで、ストラテジ・ミッション・チケットのすべてが `feedback:` フィールドで元の依頼を指します。どの作業がどのストラテジに属するかという帰属の問いは、専用フィールドを増やす代わりに、ストラテジと作業が同じフィードバックを引用しているかどうかから計算されます（`attributed-work.sh`）。点検ログだけは意図的にこの網の外にあり、どの文書からも参照されない純粋な運用記録です。

### フィードバック

置き場所は `.workaholic/feedbacks/` です。依頼と発言を残す不変の記録で、誰の意見か（`subject`）、どの経路で届いたか（`source`）、誰が記録したか（`author`）を区別して冒頭のメタ情報に持ちます。一度書いたら書き換えず、訂正は新しい記録を重ねて表現します。

- 冒頭メタ情報の `subject` は必須で、省略も既定値もありません
- 懸念事項の記録は、後続の記録が `supersedes` で名指しするまで未解消として扱われます
- 書き手は `/specificate`、`/ship`、`/story` と `/fb` の予備経路で、検査は `validate-feedback.sh` が行います

### チケット

置き場所は `.workaholic/tickets/` です。作業指示書で、未着手のものは `todo/`、完了・終了したものは実装に使ったブランチ名ごとの `archive/` に置かれます。状態は場所ではなくメタ情報の `status` フィールドで表します。

- 冒頭メタ情報にマージ方針の `merge_policy`（未記載は要確認扱い）、所属先の `mission:`、担当の `assignees`（空欄はチーム共有）、出典の `feedback:` を持ちます
- 必須の章は方針を示す `## Policies` と、完了の判定基準を示す `## Quality Gate` です
- 任意の章として、触るファイルを挙げる `## Key Files` と、未決事項の `## Open Decisions` があります。未決事項は問い・調べた資料とその内容・選択肢の3点セットで書き、答えられないとだけ書くことは禁止です
- 書き手は `/ticket`、`/specificate`、`/mission` で、検査は `validate-ticket.sh` ほかが行います

### ミッション

置き場所は `.workaholic/missions/` です。チケット2枚以上の束で、全体を約60行以内に収めます。達成時にどんな体験が得られるかと達成条件を先に決め、チケット一式と同時に作られます。進捗は保存せず、達成条件のチェック数から毎回計算します。

- 必須の章は `## Experience` と、1項目以上の `## Acceptance` です。達成条件は通常3項目までとします
- `## Changelog` にはチケット完了などの節目が1行ずつ自動追記されます
- 終了は専用スクリプト `close.sh` だけが書けます。状態は達成・断念・引き継ぎの3種で、検査は `validate-mission.sh` が行います

### ストラテジ

置き場所は `.workaholic/strategies/` です。開発者が決めた方向で、狙い・スケジュール・担当者の3点を必ず持ちます。担当者欄を空にできない唯一の文書です。他の文書では空欄はチーム共有を意味しますが、ストラテジでは拒否されます。

- 冒頭メタ情報に期日の `target_date`、必須の `assignees`、根拠にした記録を引用する `feedback:` を持ちます
- 必須の章は `## Aim` と `## Schedule` です
- 書き手は作成と終了の2スクリプトだけで、有効なストラテジの本文は誰も編集しません。検査は `validate-strategy.sh` が行います

### 点検ログ

置き場所は `.workaholic/moderations/` です。[Moderate] の作業記録で、知識ではなく運用ログです。1日1ファイルで、tick ごとの見出しの下に1ステップ1行で追記されます。同じことを二度報告しないための記憶として機能するため、他の文書と違って索引にも載せず、メタ情報も持ちません。

- 書けるのは専用スクリプト `log-append.sh` だけです。追記専用で、削除は人間の操作としてのみ許されます
- 同じ日に複数の tick が走っても、記録は行単位で合流し、既存の行は書き換えられません
- 各 tick の最後に `persist-log.sh` が main ブランチへ直接コミットして保存します

### ストーリーとリリースノート

置き場所は `stories/`、`release-notes/`、`releases/` です。出荷の記録で、ストーリーは完了チケットから生成される実装のまとめとして PR 本文の元になります。リリースノートはデプロイ計画、リリース履歴、検証結果の順に構成され、検証結果の章は追記専用です。

- ストーリーの構成は動機・成果・懸念・うまくいったパターンの4章です
- リリース記録は QA 用ブランチ `release/日時` ごとに1ファイル作られます
- 書き手は `/story`、`/ship` と CI のワークフローで、検査は `validate-story.sh` と安全スキャンが行います

## ループが回っている間の手動操作

ルーティンを止めて待つ必要はありません。手動コマンドはルーティンと同じ合流点、つまり Issue の受信箱・PR・作業宣言の仕組みに流れ込むよう設計されているため、人と AI が同じルールの下で並走できます。目的別に4通りに分かれます。

### 依頼や作業をループに渡す

手で入れたものが、次の tick に自然に拾われます。

- `/fb 依頼内容`：依頼を Issue として自分宛てに起票します。次の :15 の [Specificate] がそれを取り込みます。`to 別リポジトリ名` を付けると他のリポジトリにも送れます。送信前に内容の逐語確認が入ります。
- Slack に書くだけ：開発チャンネルに普通に書いた依頼は、メンションしなくても :40 の [Propose] が拾って Issue 化します。いちばん手軽な入口です。
- `/ticket 説明`：AI と対話しながら作業指示書を作ります。PR をマージした時点で待ち行列に入り、次の :30 の [Implement] が見つけて着手します。
- `/mission`：ミッションとそのチケット一式をまとめて作ります。人に確認されるのはマージ方針の1点だけです。
- ストラテジの提案をマージする：[Specificate] がストラテジを提案してきたときだけは自動マージされません。開発者がマージする操作そのものが、その方向で進めるという承認になります。

### 自分の手で実行する

ルーティンと同じ手順と同じ検査を、対話しながら実行できます。

- `/drive`：[Implement] とまったく同じ手順の対話版です。違いは、どの作業を取るかを最初に1回だけ聞いてくれることです。作業宣言の仕組みを共有しているので、直後に毎時のルーティンが走っても同じ作業を取り合うことはありません。
- `/story` と `/commit`：手作業ブランチのまとめと PR 作成、および小さな変更のコミットに使います。コミットメッセージの規約は自動検査されます。
- `/ship` のデプロイ実行：ルーティンが行う `/ship` はデプロイ計画の起草とマージまでで、実際のデプロイは開発者が指示したときだけ実行・検証・記録されます。
- QA 用ブランチを切る：リリース前検証用のブランチ `release/日時` は自動では作られず、明示的に実行したときだけ切られます。

### 状況をいつでも安全に眺める

何も書き込まない、読み取り専用のコマンドです。

- `/catch`：最近の活動、つまりコミット・チケット・ストーリー・ミッション進捗を開発者別にまとめ、続けて質問もできます。
- `/standup`：ストラテジごとの前日実績を表示します。毎朝の自動版は [Moderate] に組み込まれていますが、手動でいつでも見られます。
- `/prepare-release`：デプロイ待ちの変更とリリースノート下書きの状況を、デプロイ先ごとに報告します。
- `/explain` と引数なしの `/ticket`、`/mission`：リポジトリへの質問に PDF で回答するもの、自分の待ち行列の一覧、ミッション一覧の表示です。

### ループ自体を整備し質問に答える

仕組みのメンテナンスと、AI からの問いへの応答です。

- 質問に Slack で返信する：[Moderate] の質問スレッドに普通に返事を書くだけで、次の tick がそれを回答として記録します。返事の内容を機械が解釈するのではなく、次の実行の判断材料として人の言葉のまま渡されます。
- `/workaholify`：リポジトリをこの仕組みに接続する準備コマンドです。初期設定の修復、ディレクトリ構成の整備、ルーティンの設定までを一括で行います。
- `/setup-dev-routines` と `/setup-repo-routines`：前者は開発者用の3本を各自が実行して設定します。後者はリポジトリ共有の [Moderate] 1本を設定するもので、代表者1名だけが実行してください。複数人が設定すると同じ点検が毎時その人数分だけ走ってしまいます。
- `/mission-close`：ミッションを断念や引き継ぎで閉じる判断はここだけでできます。達成による終了は、条件が満たされれば自動で閉じられます。

## 人と AI の衝突を防ぐ4つの共通ルール

手動コマンドもルーティンも同じルールの上で動くため、誰がいつ実行しても、作業の取り合い・上書き・迷子のコミットが構造的に起きないようになっています。

1. 作業宣言。未マージの `work-` ブランチが存在することだけが作業中の証拠であり、全員がそれを見て動きます。1つの作業単位に対してブランチ・作業ディレクトリ・PR は各1つです。他人の宣言には、どれだけ古くても手を出しません。
2. 担当者。各文書の担当者欄を共通の判定スクリプトが、自分のもの・誰のものでもない・他人のもの、に振り分けます。ルーティンも人も、調査の段階で他人の作業を候補から外します。
3. publish tree。文書を main へ送るときは、隔離された main の複製上で変更して PR にします。いま手元で進めている作業ディレクトリには1バイトも影響しません。
4. 検査は誰も免除されません。マージ方針と安全スキャンは、手動でも自動でも同じ基準で適用され、どの経路からも上書きできません。機密情報の検出は即停止、サイズ超過などは要確認への格下げです。

## 仕組みの用語集

本文中で出てきた仕組み側の用語をまとめます。成果物の名前は冒頭の一覧を参照してください。

| 用語 | 説明 |
| --- | --- |
| claim / 作業宣言 | 自分が実装中であることを示す占有宣言です。専用ブランチ `work-日時` を push することで成立し、マージされると自動的に解除されます。 |
| worktree / 作業用複製 | 1つのリポジトリから作る追加の作業ディレクトリです。作業単位ごとに1つ作られ、出荷時に片付けられます。 |
| publish tree / 提出用複製 | main ブランチの隔離された複製です。文書の提出はここで変更して PR にするため、手元の作業に影響しません。 |
| PR-unit / 作業のまとまり | 1本の PR にする作業の単位です。ミッション1件、または独立したチケットの一括りがこれに当たります。 |
| merge_policy / マージ方針 | チケット作成時に決める完成後の扱いです。自動でマージする auto と、検査に通ればマージする review の2値で、未記載は review 扱いです。 |
| verification_handoff / 検証の引き継ぎ | この検証は無人環境では実行できない、という宣言です。認証情報や実機が要る作業に付けられ、PR を開いたまま人に引き継がれます。 |
| frontmatter / 冒頭メタ情報 | Markdown 文書の先頭に書く機械可読のメタ情報です。文書同士の参照である `feedback:` や `mission:` はここに書かれます。 |
| survey / 調査 | 着手前に待ち行列とミッションを一覧して、いま何ができるかを洗い出す工程です。 |
| release-scan / 安全スキャン | 提出前の差分検査です。機密情報は即停止、変更サイズ超過は要確認へ格下げ、禁止用語の混入は要確認、の3系統を機械的に調べます。 |
| スキルとコマンド | コマンドは入口となる数行の定義、スキルは手順・ルール・スクリプトの実体です。コマンドは薄く、知識はスキルに置くのがこのリポジトリの設計方針です。 |
| scope / 設定の単位 | ルーティンを誰が何本持つべきかの区分です。developer は開発者ごとに1本、repository はリポジトリ全体で1本を意味します。 |
| notify のスレッド逆引き | 報告先の Slack スレッドを、設定に持たせず、投稿済みメッセージの検索で毎回探し当てる仕組みです。どのリポジトリでも同じ設定文が使い回せます。 |

出典は `CLAUDE.md`、`plugins/workaholic/skills/workaholify/routines/` 配下の4テンプレート、`plugins/workaholic/skills/` 配下の各スキル定義です。内容は 2026-08-25 時点のリポジトリの記述に基づく要約です。
