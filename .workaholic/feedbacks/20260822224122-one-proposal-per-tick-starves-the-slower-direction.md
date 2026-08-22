---
type: Feedback
title: One proposal per tick starves the slower direction
kind: instruction
source: discussion
subject: person:a@qmu.jp
created_at: 2026-08-22T22:41:22+09:00
author: a@qmu.jp
supersedes: 
---

# One proposal per tick starves the slower direction

1ティックにつき1提案（`over_cap`、`WORKAHOLIC_PROPOSE_MAX` 既定 1）では全く足りない。**そのティックで結論づけられることは全部**提案されるべきである。

実測（導入先リポジトリ）: active な strategy が2つあり、target_date が **どちらも 2026-08-29** で並んでいる。片方（基盤を作る方向）は自分の build 仕事がキューにある間ずっと `work_waiting` で機械的にスキップされ、もう片方（文書の方向）は仕事の消化が速く `work_waiting` が立たないので、**毎ティック文書側が勝つ**。結果としてチャンネルは片方の方向の産物ばかりになり、もう片方は自分の番が回ってこない。

現行の根拠は「8つの方向を抱える開発者が :40 に8件のイシューで起こされてはならない」。これは他のゲートで既に満たされている: `work_waiting` と `open_proposal` が「1つの strategy につき同時に1提案」を保証しているので、8件が同時に出るのは8つの方向すべてが手空きのときだけであり、そのときは8つの方向が本当にそれぞれ次の一手を必要としている。

つまり cap は総量を減らしていない。**順序を固定して、一部の方向を他の方向の後ろに無期限に置いているだけ**である。しかも待たされる側は「仕事が進行中だから待たされる」ので、仕事が遅い方向ほど提案が来なくなる — 進みの遅い方向こそ一手を必要としているのに、逆向きに働く。

直してほしい形: ティックは**その時点で eligible な strategy すべて**に対して提案する。cap は撤廃する。総量を抑えるのは `work_waiting` と `open_proposal` の仕事であり、それらは既にそうしている。

Source: 開発者の直接指示（2026-08-22、#dev-csnet の配分について）
