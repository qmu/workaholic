---
type: Feedback
title: Nothing closes a finished mission so completion accumulates in the active area
kind: instruction
source: development
subject: person:a@qmu.jp
created_at: 2026-08-22T18:22:37+09:00
author: a@qmu.jp
supersedes: 
---

# Nothing closes a finished mission so completion accumulates in the active area

`.workaholic/missions/active/` に 21 件あり、うち 11 件が acceptance 全チェック＋キュー 0 — 誰が見ても終わっている二つの事実で、数日前から終わっていた。

影響は見た目の問題ではない。plan-units.sh の survey が毎回それらを歩き、mission lens が毎プロンプトで 11 件を「あなたの仕事」として列挙するので、セッションが誘導されるロードマップの三分の二がノイズだった。さらに同じセッションで run が終わらせた 12 件目について、run 自身の報告がそれをまだ claimable として名指しせざるを得ず、terminal token を ok にできなかった。

なぜ起きるか: unified run はチケットを archive し、acceptance を tick し、changelog を追記し、PR を開いてマージまでするが、mission を終わらせない。これは設計どおりで明文化もされている — close.sh が end state の唯一の書き手で、/drive も /implement もそれを呼ばない。

その根拠は妥当。achieved / abandoned / carried は別の判断であり、自分の仕事をマージした run はその判断に不向き。しかし規則は「答えが本当に判断であるケース」のために書かれていて、判断でないケースまで覆っている。acceptance 全チェックかつキュー 0 は算術であり、run は終了前にその両方を計算済み。

つまり欠落は「mission に人間が要る」ことではなく、機械が決められる唯一のケースにだけ seam が無く、決められないものの滞留と見分けがつかないこと。

直してほしい形: 計算できるケースのための closing seam を run に与える。mission の最後のチケットが archive され、acceptance が全チェックで、キューに何も残っていないとき、close.sh を通して achieved で終わらせる — 書き手は同じ一つのまま、終わったと知っている場所から呼ぶ。close は他の結果と同様に run report に出す。

機械が決められないものは一切動かさない。acceptance 未達、未リンク項目、キューあり の mission は不可侵。abandoned と carried は運用者だけのもの — どちらも完了ではなく意図についての主張だから。

この経路を採らない場合の誠実な代案: 滞留を無音でなく可視にする。/moderate か /story に「acceptance 満了かつキュー 0 の mission 集合」を報告させ、21 件をレンズで発見する形にしない。

Source: https://github.com/qmu/workaholic/issues/572
