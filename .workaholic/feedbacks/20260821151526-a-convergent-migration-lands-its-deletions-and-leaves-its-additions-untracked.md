---
type: Feedback
title: A convergent migration lands its deletions and leaves its additions untracked
kind: instruction
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-08-21T15:15:26+09:00
author: a@qmu.jp
supersedes: 
---

# A convergent migration lands its deletions and leaves its additions untracked

# 収束的移行の削除側だけが commit に乗り、追加側が未追跡のまま main に着地する

Source: https://github.com/qmu/workaholic/issues/548

`/drive` の1回の実行で、レコードの実体が main から消える事故が起きた。原因は移行スクリプトと `commit.sh` の既定ステージングの噛み合わせである。

**観測した挙動。** `list-open-concerns.sh`（ドキュメント上は純粋読み取り）が `migrate-concerns.sh` を走らせ、`.workaholic/concerns/` → `.workaholic/feedbacks/` の移行が working tree に書き出された。移行は契約どおり index に触らないので、移行先の新規ファイル50件は未追跡のまま。その後 `/report` の Phase 4 が `commit.sh` を既定ステージングで呼んだところ、`git add -u` が旧 `concerns/*.md` の削除50件をステージし、移行先は未追跡なので除外された。結果、削除だけを含むコミットがマージされ、concern レコード50件が main 上で実体を失った。追いコミット1本で回復している。同じ原因で `/report` が書いた story 本体（常に新規ファイル）も落ち、tracked な索引の更新だけがマージされて空リンクになり、これも追いコミット1本で回復した。

**事故の核は非対称である。** `commit.sh` は未追跡ファイルを列挙して警告する（これは正しく出ていた）。しかし移行の削除側は `git add -u` の意味論により無警告でステージされる。つまり「移行の両半分を一緒に動かす」責任が警告を目視する人間の側にだけ残っていて、リネームが分断された状態がコミットとして成立してしまう。`migrate-concerns.sh` の「index はキャラーの共有状態だから触らない」という契約自体は妥当だが、その契約が守っているのは追加側だけで、削除側は既定ステージングに素通しされている。

**直し方の候補が3つ挙げられている。** (1) `commit.sh` が「ステージされた削除」と「未追跡の追加」が同時に存在する状態（リネーム分断の兆候）を検出したら、警告ではなく拒否する。(2) `migrate-concerns.sh` が削除側も未ステージのまま残し、両半分が必ず一緒にしか動かないようにする。(3) `/report` Phase 4 と `/drive` §5 の手順に、常に新規ファイルである story 本体と移行の書き出し先を `commit.sh` の `files...` 引数で明示すると書く。(3) は手順の修正なので最も安価だが、機械的に守らせるのは (1) か (2) だと報告者は述べている。

**done の見え方。** 移行が発生した直後に既定ステージングでコミットしたとき、削除だけのコミットが作れないこと。あるいは story を書いた `/report` の実行で、story 本体がコミットから落ちないこと。
