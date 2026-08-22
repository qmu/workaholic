---
type: Feedback
title: The loop refuses housekeeping but not documentation so a build strategy produces only documents
kind: instruction
source: development
subject: person:a@qmu.jp
created_at: 2026-08-22T19:47:00+09:00
author: a@qmu.jp
supersedes: 
---

# The loop refuses housekeeping but not documentation so a build strategy produces only documents

導入先リポジトリに、アプリケーション基盤をあるクラウド事業者の上で **作る** ことを明記した active な strategy がある。基底へのマージがそのまま配備になり、認証はその事業者の中で閉じ、プロトコル・サーバも同じ実行環境を共有する — target_date も assignee も feedback ref もある、正しい strategy。

その strategy に対してループが生んだ成果物は、全部 **文書** だった。active mission 3本が全部その strategy 自身の feedback ref を引いており（帰属は成立している）、その下のキュー済みチケットは「経路に自分のページを与える」「依存の判断を記録する」「節を設計木に置く」。リポジトリの package.json は文書サイトを名乗り、配備設定のコメントは worker が **自分のコードを持たない** と述べ、ビルド済み文書資産を配っている。ある mission の Goal はそれを率直に書いている — 配備の道筋は「述べられてはいるが、設計されていない」。その欠けを、設計して埋めた。作ってではなく。

なぜ起きるか、そしてなぜ自己永続するか。/propose は既に安全な小さい変更を拒否する: すべての提案は depth / breadth / contraction のうち一つを宣言し、何に対して選んだかを名指しし、名指しできない tick は何も開かない。このゲートは機能しており、**housekeeping** を拒否している。

しかし **documentation** を拒否しないし、できない。depth は strategy の Aim に対して定義されており、Aim *について* の文書は文書が無い状態より自明に深いから。「マージが配備になる」ことを説明するページを書くのは「マージが配備になる」に対する完璧な depth 手であり、次のページも、その次もそうである。

そして循環が閉じる: (1) /propose が文書の depth 手を名指しする。(2) /specificate がそれを mission にし、チケットが strategy の refs を持つ。(3) attributed-work.sh が帰属させるので work_waiting がその strategy を塞ぐ。(4) 文書がマージされるまで追加の提案は出ない。(5) マージされてゲートが下り、(1) が次の文書手を名指しする。

この循環のどの部分も壊れていない。全部が仕様どおりに動いている。Aim に一度も近づかないのは、Aim を **進める** 成果物と Aim を **記述する** 成果物を区別するゲートがどこにも無いから — 帰属は feedback ref の交差であり、仕事について書いたページは仕事自身と同じ ref を引く。

止めるはずだった一手も失敗した。開発者は正しい ask を出した: 「この strategy は文書ばかりで実装されない、実装を駆動するよう strategy を改めよ」。イシューは実行環境・データベース・オブジェクトストア・アクセス層・言語・ビルドとテストの道具・フレームワーク・認証・プロトコルサーバを名指ししていた。/specificate はそれを **record-only** と判定した。mission も ticket も無し。

これは skill 自身の優先順位に反する: 「2つ以上に分解できる → mission。計画できる方向は計画する」。9つの部品を名指しする ask はどう読んでも分解可能。飲み込んだのは「迷ったら record-only」の既定 — ループが仕事を捏造しないための bar が、内容が丸ごと仕事である ask に適用された。結果、ループは「文書しか出ない」という苦情についての文書を出した。

直してほしい形（順序付き）: (1) /propose に記述する一手への拒否を与える。Aim が何かを作ることである strategy に対し、Aim についての文書を生む move は housekeeping と同じく名指しで拒否する。Aim 自体が文書である strategy は影響を受けず、それがこれを趣味でなく検査可能にする。(2) 「記述する」と「進める」を区別可能にする。feedback ref による帰属では両者が同一に見えるので、work_waiting が文書を作る仕事の進捗と数え、作る仕事自身の提案を塞ぐ。得るべき性質は「記述的な仕事しか帰属していない strategy は、仕事が進行中の strategy に見えない」こと。(3) 分解可能な ask を record-only に飲ませない。優先順位規則は既に mission と言っている。「迷ったら」の既定が明示的な優先順位に負けるようにし、どちらの規則が決めたかを報告する。

順序が重要: (3) だけでも今回は計画が出た。(1) と (2) は、次の strategy が自分についてのページに一ヶ月を使うのを止めるもの。

Source: https://github.com/qmu/workaholic/issues/574
