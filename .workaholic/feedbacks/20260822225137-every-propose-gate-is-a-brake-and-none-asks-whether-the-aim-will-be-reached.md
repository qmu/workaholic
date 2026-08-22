---
type: Feedback
title: Every propose gate is a brake and none asks whether the aim will be reached
kind: instruction
source: discussion
subject: person:a@qmu.jp
created_at: 2026-08-22T22:51:37+09:00
author: a@qmu.jp
supersedes: 
---

# Every propose gate is a brake and none asks whether the aim will be reached

`/propose` のゲートは `not_active` / `not_mine` / `past_target_date` / `no_feedback_refs` / `work_waiting` / `open_proposal` / `attribution_unreadable` の7つで、**全部が「提案を減らす」方向のブレーキ**である。「この方向は期日までに到達しそうか」を問うものが一つも無い。

結果として、**方向は完璧にゲートされたまま一度も到達しない**という状態が成立する。どのブレーキも正しく動き、どのティックも正しい理由で沈黙し、期日が来て何も無い。

実測（導入先リポジトリ、2026-08-22）: 基盤を作る方向の `target_date` は 2026-08-29 で残り7日。その方向に紐づく成果物は19件あり、その全部が仕様の頁だった。`tsconfig` は無く、`wrangler.jsonc` は「この Worker は自分のコードを持たない」と自分で書いていた。すべてのゲートは正常だった。

`target_date` は現在 `past_target_date`（過ぎたら止める）にしか使われていない。**期日を過ぎたことしか見ておらず、期日に間に合うかを見ていない。** 到達しないまま期日を迎える方向と、順調な方向が、ティックからは同じに見える。

同じ形の欠陥を今日3つ直した — `describing_move` が無かったこと、record-only が precedence を上書きしていたこと、`over_cap` が遅い方向を飢えさせていたこと。3つとも「量だけを見て、Aim に近づいたかを見ていない」という同じ根から出ている。個別に直したが、根は残っている。

直してほしい形: **期日に対する進捗を読み、遅れている方向をより強く押すゲート**を持たせる。何をもって進捗とするかは、既存の `attributed-work.sh`（`landed[]` を含む）が既に読んでいる。それを「残り日数に対して十分か」の判断に使い、遅れている方向をティックの中で優先し、到達の見込みが立たない方向は名前を付けて報告する — 沈黙ではなく。

Source: 開発者の直接指示（2026-08-22）。「workaholic が僕の問題を解決できていないという厳然たる事実に対して、workaholic の誤りを表層的にも根本的にも直すのがあなたの役割」
