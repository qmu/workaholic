---
type: Feedback
title: The alert cool-down swallows a whole working day when a failure starts in the evening
kind: instruction
source: discussion
subject: person:a@qmu.jp
created_at: 2026-08-23T09:26:38+09:00
author: a@qmu.jp
supersedes: 
---

# The alert cool-down swallows a whole working day when a failure starts in the evening

赤アラートの cool-down は「同じシグネチャを最初の報告から 24 時間、最上位の投稿だけ抑制する」と定めている。繰り返しはスレッド内の `↳ still failing - <signature>, first reported <time>, <N> ticks` 返信になり、これは rate-limit されない。

この設計は「同じ知らせを繰り返さない」ためのもので、そこは正しい。欠陥は **cool-down の起点が最初の報告時刻であること**にある。夕方に始まった障害は、翌日の同時刻まで新しい最上位投稿を出さない — つまり**翌営業日を丸ごと沈黙で潰す**。

実測（導入先リポジトリ、2026-08-22→23）: ある単位が事業主の裁定待ちで 21:38 JST から停止。11 ティック連続で blocked、agent-hours 2.1h を消費。エスカレーションは仕様どおり出ていたが、全部が前日のフィードバック項目のスレッド内への返信だった。開発者がチャンネルを見て「22:25 から更新が止まっている、なぜ」と尋ねるまで、最上位には何も無かった。cool-down は正常に動作していた。

これは `over_cap` で今日直したものと同じ形の欠陥である。毎ティックの抑制はそれ自体は正しく、その総和が沈黙になる。「毎ティックの拒否は遅延に見え、20回繰り返された遅延は何も無いのと同じに読める」。

直してほしい形: cool-down の満了を「最初の報告から 24 時間」と「**次の営業日の始まり**（ワークスペースのタイムゾーン）」の**早い方**にする。営業日の境界は `WORKAHOLIC_WORK_DAYS` と quiet-hours の窓が既に持っており、新しい定数を導入しない。夜に始まった障害は、人が読み始める朝に一度だけ最上位に出る。日中に始まったものの挙動は変わらない。

Source: 開発者の直接指摘（2026-08-23、#dev-csnet が 10 時間更新されていないように見えた件）
