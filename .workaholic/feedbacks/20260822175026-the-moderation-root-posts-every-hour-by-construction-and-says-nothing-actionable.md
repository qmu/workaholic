---
type: Feedback
title: The Moderation root posts every hour by construction and says nothing actionable
kind: instruction
source: development
subject: person:a@qmu.jp
created_at: 2026-08-22T17:50:26+09:00
author: a@qmu.jp
supersedes: 
---

# The Moderation root posts every hour by construction and says nothing actionable

`🔎 Moderation` のルートが毎時投稿され、しかも読んだ人に何も起こせない内容になっている。実測された投稿:

🔎 Moderation - 2 change(s), 0 question(s)
inbound-sweep: GitHub read since <ISO8601>: 1 updated, 0 already captured, 1 to judge; slack/gmail/drive left for the agent to probe
doc-drift: no new documentation drift since <sha> (0 finding(s) already filed by an earlier tick)

これは中身の薄い一時間だったのではなく、構造的にこうなる。

(1) 「変化したステップ」ゲートが偽になりえない。変化の定義は「同じステップの要約が一時間前と異なること」だが、inbound-sweep は要約に ISO8601 のタイムスタンプを、doc-drift は sha を埋めている。どちらも構造上毎ティック動くので、両ステップは永久に「変化した」。render-tick-post.sh の判定は要約文字列の生比較（[ "$was" = "$summary" ]）。「diff なので変わっていない答えを繰り返すことは構造的に不可能」という、毎時ルートを許容する根拠そのものが成立していない。

(2) 2つのゲートが OR なので、質問ゼロのティックでも投稿される。ルートの存在理由は「質問を下にぶら下げること」と定められている。0 question(s) のルートは目的を失った、誰にも宛てていないステータス行 — キー付きのルート2本を退役させた理由と同一物。

(3) 行の内容がティックの内部帳簿で、プロジェクトの出来事ではない。1 to judge / 0 already captured / 0 finding(s) already filed は内部カウンタ。doc-drift: no new documentation drift に至っては、何も起きなかったことを変化として報告している。

(4) キーが本文に描画されている（他の投稿形と同じ既知の欠陥。既存 mission が受け持つ）。

直してほしい形: 自分で動く値の入っていないものから変化を導く（要約にタイムスタンプ/sha を入れない、または正規化した形で diff を取る）。質問をルートの前提条件にする、あるいは質問なしで声を持つに値する変化の種別を明示する（「要約文字列が違う」ではありえない）。ティックが数えたものではなくリポジトリに起きたことを書く。何も変わらず質問も無い一時間は沈黙すること — 現状は決して沈黙しない。

Source: https://github.com/qmu/workaholic/issues/569
